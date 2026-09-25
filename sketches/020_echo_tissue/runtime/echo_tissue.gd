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

var _activity := PackedFloat32Array()
var _refractory := PackedFloat32Array()
var _history_a := PackedFloat32Array()
var _history_b := PackedFloat32Array()
var _density := PackedFloat32Array()
var _next_activity := PackedFloat32Array()
var _next_refractory := PackedFloat32Array()
var _accum := 0.0
var _autoseed_clock := 0.0
var _autoseed_index := 0
var _field_image: Image
var _field_texture: ImageTexture


func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _seed_system()
    _refresh_field_texture()


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
    _density.resize(count)
    _next_activity.resize(count)
    _next_refractory.resize(count)
    _activity.fill(0.0)
    _refractory.fill(0.0)
    _history_a.fill(0.0)
    _history_b.fill(0.0)
    _density.fill(0.0)
    _next_activity.fill(0.0)
    _next_refractory.fill(0.0)
    _seed_cell_cluster(16, 11, 4, 0.92)
    _seed_cell_cluster(41, 25, 5, 0.76)
    _seed_cell_cluster(59, 13, 3, 0.84)
    _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    _field_texture = ImageTexture.create_from_image(_field_image)


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
    _seed_cell_cluster(clampi(int(point.x / CELL_W), 0, COLS - 1), clampi(int(point.y / CELL_H), 0, ROWS - 1), int(round(seed_radius)), 1.0)


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

    var stepped := false
    _accum += delta
    while _accum >= 1.0 / 30.0:
        _accum -= 1.0 / 30.0
        _step_tissue(1.0 / 30.0)
        stepped = true
    if stepped:
        _refresh_field_texture()


func _neighbour_stats(x: int, y: int) -> Vector2:
    var v0 := _activity[_idx(x - 1, y - 1)]
    var v1 := _activity[_idx(x, y - 1)]
    var v2 := _activity[_idx(x + 1, y - 1)]
    var v3 := _activity[_idx(x - 1, y)]
    var v4 := _activity[_idx(x + 1, y)]
    var v5 := _activity[_idx(x - 1, y + 1)]
    var v6 := _activity[_idx(x, y + 1)]
    var v7 := _activity[_idx(x + 1, y + 1)]
    var total := v0 + v1 + v2 + v3 + v4 + v5 + v6 + v7
    var active := 0.0
    active += 1.0 if v0 > 0.42 else 0.0
    active += 1.0 if v1 > 0.42 else 0.0
    active += 1.0 if v2 > 0.42 else 0.0
    active += 1.0 if v3 > 0.42 else 0.0
    active += 1.0 if v4 > 0.42 else 0.0
    active += 1.0 if v5 > 0.42 else 0.0
    active += 1.0 if v6 > 0.42 else 0.0
    active += 1.0 if v7 > 0.42 else 0.0
    return Vector2(total * 0.125, active * 0.125)


func _step_tissue(dt: float) -> void:
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var current := _activity[i]
            var ref := _refractory[i]
            var stats := _neighbour_stats(x, y)
            var neighbour := stats.x
            var density := stats.y
            _density[i] = density
            var delayed := _history_b[i]
            var next_value := current
            var next_ref := maxf(0.0, ref - dt)

            if ref > 0.0:
                next_value = maxf(0.0, current - decay * dt * 2.8)
            else:
                var drive := neighbour * coupling + delayed * feedback + maxf(0.0, density - 0.25) * morphology * 0.24
                if drive > threshold:
                    next_value += excitation * (0.045 + (drive - threshold) * 0.16)
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


func _refresh_field_texture() -> void:
    if _field_image == null:
        _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var value := _activity[i]
            var echo := _history_b[i]
            if value < 0.012 and echo < 0.018:
                _field_image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
                continue
            var density := _density[i]
            var t := smoothstep(0.02, 0.94, value)
            var c := COLD.lerp(WARM, t).lerp(HOT, smoothstep(0.72, 1.0, value))
            var connect := clampf(t + density * morphology * 0.28, 0.0, 1.0)
            var echo_gain := maxf(0.0, echo - value)
            c = c.lerp(HOT, clampf(echo_gain * 0.42, 0.0, 0.35))
            c.a = 0.12 + maxf(connect, echo * 0.6) * 0.88
            _field_image.set_pixel(x, y, c)
    if _field_texture == null:
        _field_texture = ImageTexture.create_from_image(_field_image)
    else:
        _field_texture.update(_field_image)


func _rebuild_density() -> void:
    if _density.size() != COLS * ROWS:
        _density.resize(COLS * ROWS)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            _density[_idx(x, y)] = _neighbour_stats(x, y).y


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "activity": _activity.duplicate(), "refractory": _refractory.duplicate(),
        "history_a": _history_a.duplicate(), "history_b": _history_b.duplicate(),
        "accum": _accum, "autoseed_clock": _autoseed_clock, "autoseed_index": _autoseed_index,
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
    _rebuild_density()
    _refresh_field_texture()


func _get_custom_live_debug_state() -> Dictionary:
    var mass := 0.0
    for value: float in _activity: mass += value
    return {"tissue_mass": mass, "autoseeds": _autoseed_index, "render_mode":"field_texture"}


func _draw() -> void:
    begin_design_draw(BG)
    if _field_texture != null:
        draw_texture_rect(_field_texture, Rect2(Vector2.ZERO, DESIGN_SIZE), false)
    end_design_draw()
