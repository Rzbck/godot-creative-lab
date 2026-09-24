extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 72
const ROWS := 40
const CELL_W := 1280.0 / float(COLS)
const CELL_H := 720.0 / float(ROWS)
const BG := Color(0.018, 0.014, 0.035, 1.0)
const COLD := Color(0.08, 0.16, 0.34, 1.0)
const WARM := Color(0.91, 0.18, 0.31, 1.0)
const HOT := Color(0.98, 0.88, 0.61, 1.0)

@export_range(0.0, 1.8, 0.01) var coupling: float = 0.88
@export_range(0.08, 0.95, 0.01) var threshold: float = 0.46
@export_range(0.1, 1.8, 0.01) var excitation: float = 0.92
@export_range(0.01, 0.8, 0.01) var decay: float = 0.14
@export_range(0.1, 3.0, 0.05) var refractory_time: float = 0.92
@export_range(0.0, 1.5, 0.01) var feedback: float = 0.64
@export_range(0.01, 0.8, 0.01) var memory_decay: float = 0.19
@export_range(0.0, 1.5, 0.01) var morphology: float = 0.62
@export_range(1.0, 8.0, 1.0) var seed_radius: float = 4.0

var _activity: PackedFloat32Array = PackedFloat32Array()
var _refractory: PackedFloat32Array = PackedFloat32Array()
var _history_a: PackedFloat32Array = PackedFloat32Array()
var _history_b: PackedFloat32Array = PackedFloat32Array()
var _next_activity: PackedFloat32Array = PackedFloat32Array()
var _next_refractory: PackedFloat32Array = PackedFloat32Array()
var _accum: float = 0.0
var _autoseed_clock: float = 0.0
var _autoseed_index: int = 0


func _ready() -> void:
    super._ready()
    _seed_system()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"coupling", "label":"NEIGHBOUR COUPLING", "type":"float", "min":0.0, "max":1.8, "step":0.01},
        {"id":"threshold", "label":"FIRE THRESHOLD", "type":"float", "min":0.08, "max":0.95, "step":0.01},
        {"id":"excitation", "label":"EXCITATION", "type":"float", "min":0.1, "max":1.8, "step":0.01},
        {"id":"decay", "label":"TISSUE DECAY", "type":"float", "min":0.01, "max":0.8, "step":0.01},
        {"id":"refractory_time", "label":"REFRACTORY TIME", "type":"float", "min":0.1, "max":3.0, "step":0.05},
        {"id":"feedback", "label":"DELAYED FEEDBACK", "type":"float", "min":0.0, "max":1.5, "step":0.01},
        {"id":"memory_decay", "label":"MEMORY DECAY", "type":"float", "min":0.01, "max":0.8, "step":0.01},
        {"id":"morphology", "label":"MERGE / CONSUME", "type":"float", "min":0.0, "max":1.5, "step":0.01},
        {"id":"seed_radius", "label":"SEED RADIUS", "type":"float", "min":1.0, "max":8.0, "step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "coupling": return coupling
        "threshold": return threshold
        "excitation": return excitation
        "decay": return decay
        "refractory_time": return refractory_time
        "feedback": return feedback
        "memory_decay": return memory_decay
        "morphology": return morphology
        "seed_radius": return seed_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "coupling": coupling = clampf(float(value), 0.0, 1.8)
        "threshold": threshold = clampf(float(value), 0.08, 0.95)
        "excitation": excitation = clampf(float(value), 0.1, 1.8)
        "decay": decay = clampf(float(value), 0.01, 0.8)
        "refractory_time": refractory_time = clampf(float(value), 0.1, 3.0)
        "feedback": feedback = clampf(float(value), 0.0, 1.5)
        "memory_decay": memory_decay = clampf(float(value), 0.01, 0.8)
        "morphology": morphology = clampf(float(value), 0.0, 1.5)
        "seed_radius": seed_radius = clampf(float(value), 1.0, 8.0)
        _: return


func _idx(x: int, y: int) -> int:
    return posmod(y, ROWS) * COLS + posmod(x, COLS)


func _seed_system() -> void:
    if _activity.size() == COLS * ROWS:
        return

    var count := COLS * ROWS
    _activity.resize(count)
    _refractory.resize(count)
    _history_a.resize(count)
    _history_b.resize(count)
    _next_activity.resize(count)
    _next_refractory.resize(count)
    _activity.fill(0.0)
    _refractory.fill(0.0)
    _history_a.fill(0.0)
    _history_b.fill(0.0)
    _next_activity.fill(0.0)
    _next_refractory.fill(0.0)

    _seed_cell_cluster(16, 11, 4, 0.92)
    _seed_cell_cluster(41, 25, 5, 0.76)
    _seed_cell_cluster(59, 13, 3, 0.84)


func _seed_cell_cluster(cx: int, cy: int, radius_cells: int, strength: float) -> void:
    for oy: int in range(-radius_cells, radius_cells + 1):
        for ox: int in range(-radius_cells, radius_cells + 1):
            var d := Vector2(float(ox), float(oy)).length()
            if d > float(radius_cells) + 0.2:
                continue
            var w := 1.0 - d / maxf(1.0, float(radius_cells + 1))
            var i := _idx(cx + ox, cy + oy)
            _activity[i] = maxf(_activity[i], strength * (0.45 + w * 0.55))
            _refractory[i] = 0.0


func _seed_at(point: Vector2) -> void:
    var cx := clampi(int(point.x / CELL_W), 0, COLS - 1)
    var cy := clampi(int(point.y / CELL_H), 0, ROWS - 1)
    _seed_cell_cluster(cx, cy, int(round(seed_radius)), 1.0)


func _update_source_simulation(delta: float) -> void:
    _seed_system()

    if pointer_down:
        _seed_at(pointer_position)

    _autoseed_clock += delta
    var interval := lerpf(7.0, 2.2, clampf(feedback / 1.5, 0.0, 1.0))
    if _autoseed_clock >= interval:
        _autoseed_clock = 0.0
        var x := 6 + int(hash01(float(_autoseed_index) * 17.7 + 2.0) * float(COLS - 12))
        var y := 5 + int(hash01(float(_autoseed_index) * 29.3 + 9.0) * float(ROWS - 10))
        _seed_cell_cluster(x, y, 2 + (_autoseed_index % 2), 0.54 + feedback * 0.18)
        _autoseed_index += 1

    _accum += delta
    while _accum >= 1.0 / 30.0:
        _accum -= 1.0 / 30.0
        _step_tissue(1.0 / 30.0)


func _neighbour_stats(x: int, y: int) -> Vector2:
    var total := 0.0
    var active_count := 0.0
    for oy: int in range(-1, 2):
        for ox: int in range(-1, 2):
            if ox == 0 and oy == 0:
                continue
            var value := _activity[_idx(x + ox, y + oy)]
            total += value
            if value > 0.42:
                active_count += 1.0
    return Vector2(total / 8.0, active_count / 8.0)


func _step_tissue(dt: float) -> void:
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var current := _activity[i]
            var ref := _refractory[i]
            var stats := _neighbour_stats(x, y)
            var neighbour := stats.x
            var density := stats.y
            var delayed := _history_b[i]

            var next_value := current
            var next_ref := maxf(0.0, ref - dt)

            if ref > 0.0:
                next_value = maxf(0.0, current - decay * dt * 2.8)
            else:
                var drive := neighbour * coupling + delayed * feedback
                drive += maxf(0.0, density - 0.25) * morphology * 0.24

                if drive > threshold:
                    var excess := drive - threshold
                    next_value += excitation * (0.045 + excess * 0.16)
                else:
                    next_value -= decay * dt * (0.9 + (1.0 - density) * 0.8)

                if density >= 0.75:
                    next_value *= 1.0 - clampf(morphology * 0.055, 0.0, 0.22)
                elif density >= 0.38:
                    next_value += morphology * 0.012
                elif density <= 0.12 and current < 0.18:
                    next_value -= morphology * 0.006

                if next_value > 0.96:
                    next_ref = refractory_time

            _next_activity[i] = clampf(next_value, 0.0, 1.0)
            _next_refractory[i] = next_ref

    for i: int in range(_activity.size()):
        var old_a := _history_a[i]
        _history_a[i] = lerpf(_history_a[i], _activity[i], 0.16)
        _history_b[i] = lerpf(_history_b[i], old_a, clampf(memory_decay, 0.01, 0.8) * 0.22)

    var temp_a := _activity
    _activity = _next_activity
    _next_activity = temp_a
    var temp_r := _refractory
    _refractory = _next_refractory
    _next_refractory = temp_r


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "activity": _activity.duplicate(),
        "refractory": _refractory.duplicate(),
        "history_a": _history_a.duplicate(),
        "history_b": _history_b.duplicate(),
        "accum": _accum,
        "autoseed_clock": _autoseed_clock,
        "autoseed_index": _autoseed_index,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var av: Variant = state.get("activity", PackedFloat32Array())
    if av is PackedFloat32Array:
        _activity = (av as PackedFloat32Array).duplicate()
        _next_activity.resize(_activity.size())
    var rv: Variant = state.get("refractory", PackedFloat32Array())
    if rv is PackedFloat32Array:
        _refractory = (rv as PackedFloat32Array).duplicate()
        _next_refractory.resize(_refractory.size())
    var ha: Variant = state.get("history_a", PackedFloat32Array())
    if ha is PackedFloat32Array: _history_a = (ha as PackedFloat32Array).duplicate()
    var hb: Variant = state.get("history_b", PackedFloat32Array())
    if hb is PackedFloat32Array: _history_b = (hb as PackedFloat32Array).duplicate()
    _accum = float(state.get("accum", _accum))
    _autoseed_clock = float(state.get("autoseed_clock", _autoseed_clock))
    _autoseed_index = int(state.get("autoseed_index", _autoseed_index))


func _get_custom_live_debug_state() -> Dictionary:
    var mass := 0.0
    for value: float in _activity:
        mass += value
    return {"tissue_mass": mass, "autoseeds": _autoseed_index}


func _draw() -> void:
    begin_design_draw(BG)

    if _activity.size() == COLS * ROWS:
        for y: int in range(ROWS):
            for x: int in range(COLS):
                var i := _idx(x, y)
                var value := _activity[i]
                var echo := _history_b[i]
                if value < 0.012 and echo < 0.018:
                    continue

                var stats := _neighbour_stats(x, y)
                var density := stats.y
                var t := smoothstep(0.02, 0.94, value)
                var c := COLD.lerp(WARM, t)
                c = c.lerp(HOT, smoothstep(0.72, 1.0, value))
                c.a = 0.14 + maxf(t, echo * 0.65) * 0.86

                var connect := clampf(t + density * morphology * 0.28, 0.0, 1.0)
                var pad := lerpf(3.0, 0.25, connect)
                var rect := Rect2(
                    Vector2(float(x) * CELL_W + pad, float(y) * CELL_H + pad),
                    Vector2(CELL_W - pad * 2.0, CELL_H - pad * 2.0)
                )
                draw_rect(rect, c, true)

                if echo > value + 0.08:
                    var ec := HOT
                    ec.a = clampf((echo - value) * 0.32, 0.02, 0.18)
                    var centre := Vector2((float(x) + 0.5) * CELL_W, (float(y) + 0.5) * CELL_H)
                    draw_circle(centre, minf(CELL_W, CELL_H) * 0.34, ec, false, 0.8)

    end_design_draw()
