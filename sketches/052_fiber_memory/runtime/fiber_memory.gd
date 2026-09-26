extends "res://sketches/_shared/design_sketch_base.gd"

const STRANDS: int = 42
const POINTS: int = 13
const SAFE := Rect2(64.0, 54.0, 1152.0, 612.0)

@export_range(0.2, 3.0, 0.01) var stiffness: float = 1.32
@export_range(0.0, 1.0, 0.01) var memory: float = 0.76
@export_range(0.0, 2.0, 0.01) var twist: float = 0.62
@export_range(30.0, 190.0, 1.0) var comb_radius: float = 104.0
@export_range(0.0, 2.0, 0.01) var current: float = 0.48
@export_range(0.4, 2.4, 0.01) var spacing: float = 1.0

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _rest := PackedVector2Array()
var _memory_offset := PackedVector2Array()
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _gesture_velocity := Vector2.ZERO
var _event_counter: int = 17


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _positions.clear()
    _velocities.clear()
    _rest.clear()
    _memory_offset.clear()
    _event_counter = 17
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _positions.resize(STRANDS * POINTS)
    _velocities.resize(STRANDS * POINTS)
    _rest.resize(STRANDS * POINTS)
    _memory_offset.resize(STRANDS * POINTS)
    for s: int in range(STRANDS):
        var y := lerpf(92.0, 628.0, float(s) / float(STRANDS - 1))
        var phase := (_hash01i(s * 61 + 7) - 0.5) * 1.4
        for p: int in range(POINTS):
            var u := float(p) / float(POINTS - 1)
            var base := Vector2(92.0 + u * 1096.0, y + sin(u * 5.2 + phase) * 6.0)
            var i := _idx(s, p)
            _rest[i] = base
            _positions[i] = base
            _velocities[i] = Vector2.ZERO
            _memory_offset[i] = Vector2.ZERO


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"stiffness","label":"FIBER STIFFNESS","type":"float","min":0.2,"max":3.0,"step":0.01},
        {"id":"memory","label":"COMB MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"twist","label":"TWIST COUPLING","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"comb_radius","label":"COMB RADIUS","type":"float","min":30.0,"max":190.0,"step":1.0},
        {"id":"current","label":"AUTONOMOUS CURRENT","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"spacing","label":"WEFT SPACING","type":"float","min":0.4,"max":2.4,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "stiffness": return stiffness
        "memory": return memory
        "twist": return twist
        "comb_radius": return comb_radius
        "current": return current
        "spacing": return spacing
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "stiffness": stiffness = clampf(float(value), 0.2, 3.0)
        "memory": memory = clampf(float(value), 0.0, 1.0)
        "twist": twist = clampf(float(value), 0.0, 2.0)
        "comb_radius": comb_radius = clampf(float(value), 30.0, 190.0)
        "current": current = clampf(float(value), 0.0, 2.0)
        "spacing": spacing = clampf(float(value), 0.4, 2.4)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    var delta_pointer := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pointer, 0.50)
    _last_pointer = pointer_position
    if pointer_down:
        var velocity_direction := _gesture_velocity
        if velocity_direction.length() < 0.1:
            velocity_direction = Vector2.RIGHT
        for i: int in range(_positions.size()):
            var distance := _positions[i].distance_to(pointer_position)
            if distance < comb_radius:
                var falloff := pow(1.0 - distance / comb_radius, 1.6)
                var kick := velocity_direction * falloff * 7.5
                _velocities[i] += kick
                _memory_offset[i] = (_memory_offset[i] + kick * 0.11 * memory).limit_length(92.0)
    elif _pointer_was_down:
        _event_counter += 1
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    var memory_decay := lerpf(2.6, 0.045, memory)
    for s: int in range(STRANDS):
        var strand_t := float(s) / float(STRANDS - 1)
        for p: int in range(POINTS):
            var i := _idx(s, p)
            var pos := _positions[i]
            var vel := _velocities[i]
            var u := float(p) / float(POINTS - 1)

            _memory_offset[i] *= exp(-delta * memory_decay)
            var spacing_shift := (strand_t - 0.5) * 96.0 * (spacing - 1.0)
            var target := _rest[i] + _memory_offset[i] + Vector2(0.0, spacing_shift)
            var force := (target - pos) * (0.9 + stiffness * 1.8)

            var wave := sin(sketch_time * (0.42 + current * 0.12) + u * 8.0 + strand_t * 5.0)
            force.y += wave * current * 16.0
            force.x += cos(sketch_time * 0.29 + strand_t * 7.0) * current * 5.0

            if p > 0 and p + 1 < POINTS:
                var left := _positions[_idx(s, p - 1)]
                var right := _positions[_idx(s, p + 1)]
                force += ((left + right) * 0.5 - pos) * stiffness * 5.6

            if twist > 0.0:
                if s > 0:
                    force += (_positions[_idx(s - 1, p)] - pos) * twist * 0.22
                if s + 1 < STRANDS:
                    force += (_positions[_idx(s + 1, p)] - pos) * twist * 0.22

            vel += force * delta
            vel *= exp(-delta * (2.0 + stiffness * 0.45))
            if vel.length() > 280.0:
                vel = vel.normalized() * 280.0
            pos += vel * delta

            if p == 0 or p == POINTS - 1:
                pos.x = _rest[i].x
                vel.x *= 0.15
            _positions[i] = pos.clamp(SAFE.position, SAFE.end)
            _velocities[i] = vel

    queue_redraw()


func _draw() -> void:
    begin_design_draw(Color(0.045, 0.038, 0.033, 1.0))
    draw_rect(SAFE, Color(0.31, 0.24, 0.17, 0.12), true)

    for s: int in range(STRANDS):
        var points := PackedVector2Array()
        for p: int in range(POINTS):
            points.append(_positions[_idx(s, p)])
        var band := float(s % 7) / 6.0
        var base := Color(0.77, 0.66, 0.49, 0.22 + band * 0.12)
        if s % 5 == 0:
            base = Color(0.72, 0.31, 0.18, 0.48)
        draw_polyline(points, Color(0.0, 0.0, 0.0, 0.18), 4.2, true)
        draw_polyline(points, base, 1.2 + stiffness * 0.34, true)

    for p: int in range(1, POINTS - 1, 2):
        var stitch := PackedVector2Array()
        for s: int in range(0, STRANDS, 2):
            stitch.append(_positions[_idx(s, p)])
        draw_polyline(stitch, Color(0.82, 0.74, 0.59, 0.09 + twist * 0.08), 0.8, true)

    if pointer_down:
        draw_arc(pointer_position, comb_radius, 0.0, TAU, 48, Color(0.95, 0.76, 0.45, 0.24), 1.0, true)
    end_design_draw()


func _idx(strand: int, point: int) -> int:
    return strand * POINTS + point


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "memory_offset": _memory_offset.duplicate(),
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("positions", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == STRANDS * POINTS:
        _positions = (value as PackedVector2Array).duplicate()
    value = state.get("velocities", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == STRANDS * POINTS:
        _velocities = (value as PackedVector2Array).duplicate()
    value = state.get("memory_offset", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == STRANDS * POINTS:
        _memory_offset = (value as PackedVector2Array).duplicate()
    _event_counter = int(state.get("event_counter", _event_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {"fibers": STRANDS, "points_per_fiber": POINTS}
