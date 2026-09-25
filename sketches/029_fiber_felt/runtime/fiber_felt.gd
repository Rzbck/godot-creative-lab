extends "res://sketches/_shared/design_sketch_base.gd"

const STRANDS := 30
const POINTS := 13
const MASK_W := 32
const MASK_H := 18
const BG := Color(0.94, 0.91, 0.82, 1.0)
const INK := Color(0.08, 0.09, 0.10, 1.0)
const ACCENT := Color(0.76, 0.20, 0.12, 1.0)

@export_range(0.1, 3.0, 0.01) var cohesion: float = 1.08
@export_range(0.1, 3.0, 0.01) var compaction: float = 1.16
@export_range(0.05, 2.0, 0.01) var memory: float = 0.72
@export_range(0.1, 3.0, 0.01) var displacement: float = 1.02
@export_range(0.1, 1.8, 0.01) var transition_threshold: float = 0.78
@export_range(0.05, 1.5, 0.01) var relaxation: float = 0.34
@export_range(25.0, 190.0, 1.0) var pressure_radius: float = 82.0
@export_range(0.4, 3.0, 0.01) var line_weight: float = 1.18

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _rest := PackedVector2Array()
var _mask := PackedFloat32Array()
var _mask_next := PackedFloat32Array()
var _phase := 0.0
var _pressure_memory := 0.0
var _last_pointer := Vector2.ZERO
var _pointer_velocity := Vector2.ZERO
var _accum := 0.0


func _ready() -> void:
    super._ready()
    _seed_fibers()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"cohesion", "label":"FIBER COHESION", "type":"float", "min":0.1, "max":3.0, "step":0.01},
        {"id":"compaction", "label":"COMPACTION", "type":"float", "min":0.1, "max":3.0, "step":0.01},
        {"id":"memory", "label":"FELT MEMORY", "type":"float", "min":0.05, "max":2.0, "step":0.01},
        {"id":"displacement", "label":"FIBER DISPLACEMENT", "type":"float", "min":0.1, "max":3.0, "step":0.01},
        {"id":"transition_threshold", "label":"PHASE THRESHOLD", "type":"float", "min":0.1, "max":1.8, "step":0.01},
        {"id":"relaxation", "label":"RELAXATION", "type":"float", "min":0.05, "max":1.5, "step":0.01},
        {"id":"pressure_radius", "label":"PRESSURE RADIUS", "type":"float", "min":25.0, "max":190.0, "step":1.0},
        {"id":"line_weight", "label":"FIBER WEIGHT", "type":"float", "min":0.4, "max":3.0, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "cohesion": return cohesion
        "compaction": return compaction
        "memory": return memory
        "displacement": return displacement
        "transition_threshold": return transition_threshold
        "relaxation": return relaxation
        "pressure_radius": return pressure_radius
        "line_weight": return line_weight
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "cohesion": cohesion = clampf(float(value), 0.1, 3.0)
        "compaction": compaction = clampf(float(value), 0.1, 3.0)
        "memory": memory = clampf(float(value), 0.05, 2.0)
        "displacement": displacement = clampf(float(value), 0.1, 3.0)
        "transition_threshold": transition_threshold = clampf(float(value), 0.1, 1.8)
        "relaxation": relaxation = clampf(float(value), 0.05, 1.5)
        "pressure_radius": pressure_radius = clampf(float(value), 25.0, 190.0)
        "line_weight": line_weight = clampf(float(value), 0.4, 3.0)
        _: return


func _seed_fibers() -> void:
    if _positions.size() == STRANDS * POINTS:
        return
    var count := STRANDS * POINTS
    _positions.resize(count)
    _velocities.resize(count)
    _rest.resize(count)
    for strand: int in range(STRANDS):
        var base_y := 68.0 + float(strand) / float(STRANDS - 1) * 584.0
        var slant := (_hash01(strand * 17 + 3) - 0.5) * 96.0
        for point_index: int in range(POINTS):
            var t := float(point_index) / float(POINTS - 1)
            var p := Vector2(
                54.0 + t * 1172.0,
                base_y + slant * (t - 0.5) + (_hash01(strand * 97 + point_index * 13) - 0.5) * 24.0
            )
            var i := _pidx(strand, point_index)
            _positions[i] = p
            _rest[i] = p
            _velocities[i] = Vector2.ZERO
    _mask.resize(MASK_W * MASK_H)
    _mask_next.resize(MASK_W * MASK_H)
    _mask.fill(0.0)
    _mask_next.fill(0.0)
    _last_pointer = DESIGN_SIZE * 0.5


func _update_source_simulation(delta: float) -> void:
    _seed_fibers()
    _pointer_velocity = _pointer_velocity * 0.74 + (pointer_position - _last_pointer) / maxf(delta, 0.001) * 0.26
    _last_pointer = pointer_position

    if pointer_down:
        _stamp_pressure(pointer_position)
        _pressure_memory = minf(2.0, _pressure_memory + delta * 1.5)
    else:
        _pressure_memory = maxf(0.0, _pressure_memory - delta * (0.20 + relaxation * 0.18))

    _accum += delta
    while _accum >= 1.0 / 30.0:
        _accum -= 1.0 / 30.0
        _step_fibers(1.0 / 30.0)


func _step_fibers(dt: float) -> void:
    _rebuild_mask(dt)
    var average_mask := 0.0
    for v: float in _mask:
        average_mask += v
    average_mask /= float(_mask.size())

    var phase_drive := average_mask * compaction + _pressure_memory * 0.36
    if phase_drive > transition_threshold:
        _phase = minf(1.0, _phase + dt * (0.18 + compaction * 0.14))
    else:
        _phase = maxf(0.0, _phase - dt * relaxation * 0.13)

    var target_segment := 1172.0 / float(POINTS - 1)
    for strand: int in range(STRANDS):
        for point_index: int in range(POINTS):
            var i := _pidx(strand, point_index)
            var p := _positions[i]
            var force := (_rest[i] - p) * relaxation * (0.08 + (1.0 - _phase) * 0.12)

            var grid_pos := Vector2(p.x / DESIGN_SIZE.x * float(MASK_W - 1), p.y / DESIGN_SIZE.y * float(MASK_H - 1))
            var gx := clampi(int(grid_pos.x), 1, MASK_W - 2)
            var gy := clampi(int(grid_pos.y), 1, MASK_H - 2)
            var grad := Vector2(
                _mask[_midx(gx + 1, gy)] - _mask[_midx(gx - 1, gy)],
                _mask[_midx(gx, gy + 1)] - _mask[_midx(gx, gy - 1)]
            )
            force += grad * (38.0 * displacement + 44.0 * _phase * cohesion)

            var local_density := _mask[_midx(gx, gy)]
            var cell_center := Vector2((float(gx) + 0.5) / float(MASK_W) * DESIGN_SIZE.x, (float(gy) + 0.5) / float(MASK_H) * DESIGN_SIZE.y)
            force += (cell_center - p) * local_density * _phase * cohesion * 0.22

            if pointer_down:
                var delta_p := p - pointer_position
                var d := delta_p.length()
                if d < pressure_radius:
                    var falloff := 1.0 - d / pressure_radius
                    force += (pointer_position - p) * falloff * compaction * 0.85
                    force += _pointer_velocity * falloff * displacement * 0.018

            _velocities[i] = (_velocities[i] + force * dt) * pow(0.90 - _phase * 0.08, dt * 60.0)
            _positions[i] += _velocities[i] * dt

        for iteration: int in range(2):
            for point_index: int in range(POINTS - 1):
                var a := _pidx(strand, point_index)
                var b := _pidx(strand, point_index + 1)
                var delta_p := _positions[b] - _positions[a]
                var length := maxf(0.001, delta_p.length())
                var correction := delta_p / length * (length - target_segment) * 0.48
                if point_index > 0:
                    _positions[a] += correction
                if point_index + 1 < POINTS - 1:
                    _positions[b] -= correction

    for i: int in range(_positions.size()):
        _positions[i].x = clampf(_positions[i].x, 30.0, 1250.0)
        _positions[i].y = clampf(_positions[i].y, 28.0, 692.0)


func _rebuild_mask(dt: float) -> void:
    _mask_next.fill(0.0)
    for i: int in range(_positions.size()):
        var p := _positions[i]
        var x := clampi(int(p.x / DESIGN_SIZE.x * float(MASK_W)), 0, MASK_W - 1)
        var y := clampi(int(p.y / DESIGN_SIZE.y * float(MASK_H)), 0, MASK_H - 1)
        _mask_next[_midx(x, y)] += 0.10 + _phase * 0.07

    for y: int in range(MASK_H):
        for x: int in range(MASK_W):
            var i := _midx(x, y)
            var neighbour := 0.0
            var count := 0.0
            if x > 0:
                neighbour += _mask[_midx(x - 1, y)]; count += 1.0
            if x < MASK_W - 1:
                neighbour += _mask[_midx(x + 1, y)]; count += 1.0
            if y > 0:
                neighbour += _mask[_midx(x, y - 1)]; count += 1.0
            if y < MASK_H - 1:
                neighbour += _mask[_midx(x, y + 1)]; count += 1.0
            var diffused := _mask[i] if count <= 0.0 else neighbour / count
            var accumulated := _mask_next[i]
            _mask_next[i] = clampf(lerpf(_mask[i], diffused, 0.10 + memory * 0.06) + accumulated, 0.0, 1.5)
            _mask_next[i] = maxf(0.0, _mask_next[i] - dt * (0.05 + relaxation * 0.03))

    var temp := _mask
    _mask = _mask_next
    _mask_next = temp


func _stamp_pressure(point: Vector2) -> void:
    var cx := int(point.x / DESIGN_SIZE.x * float(MASK_W))
    var cy := int(point.y / DESIGN_SIZE.y * float(MASK_H))
    var rx := maxi(1, int(pressure_radius / DESIGN_SIZE.x * float(MASK_W)))
    var ry := maxi(1, int(pressure_radius / DESIGN_SIZE.y * float(MASK_H)))
    for oy: int in range(-ry, ry + 1):
        for ox: int in range(-rx, rx + 1):
            var x := cx + ox
            var y := cy + oy
            if x < 0 or x >= MASK_W or y < 0 or y >= MASK_H:
                continue
            var n := Vector2(float(ox) / float(maxi(rx, 1)), float(oy) / float(maxi(ry, 1))).length()
            if n <= 1.0:
                var i := _midx(x, y)
                _mask[i] = minf(1.5, _mask[i] + (1.0 - n) * compaction * 0.14)


func _draw() -> void:
    begin_design_draw(BG)
    var accent_mix := clampf(_phase * 0.82 + _pressure_memory * 0.12, 0.0, 1.0)
    for strand: int in range(STRANDS):
        var points := PackedVector2Array()
        for point_index: int in range(POINTS):
            points.append(_positions[_pidx(strand, point_index)])
        var c := INK.lerp(ACCENT, accent_mix * (0.18 + _hash01(strand * 43 + 9) * 0.42))
        c.a = 0.42 + _phase * 0.42
        draw_polyline(points, c, line_weight + _phase * 1.6, true)
    end_design_draw()


func _pidx(strand: int, point_index: int) -> int:
    return strand * POINTS + point_index


func _midx(x: int, y: int) -> int:
    return y * MASK_W + x


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(), "velocities": _velocities.duplicate(),
        "mask": _mask.duplicate(), "phase": _phase, "pressure_memory": _pressure_memory,
        "pointer_velocity": _pointer_velocity, "accum": _accum,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array: _positions = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array: _velocities = (v as PackedVector2Array).duplicate()
    v = state.get("mask", PackedFloat32Array())
    if v is PackedFloat32Array: _mask = (v as PackedFloat32Array).duplicate()
    _phase = float(state.get("phase", _phase))
    _pressure_memory = float(state.get("pressure_memory", _pressure_memory))
    var pv: Variant = state.get("pointer_velocity", _pointer_velocity)
    if pv is Vector2: _pointer_velocity = pv as Vector2
    _accum = float(state.get("accum", _accum))
    _mask_next.resize(_mask.size())
