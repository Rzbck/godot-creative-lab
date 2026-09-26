extends "res://sketches/_shared/design_sketch_base.gd"

const OSCILLATORS: int = 64
const SAFE := Rect2(72.0, 62.0, 1136.0, 596.0)

@export_range(0.0, 3.0, 0.01) var coupling: float = 1.18
@export_range(0.1, 5.0, 0.01) var damping: float = 1.34
@export_range(0.0, 2.0, 0.01) var drive: float = 0.36
@export_range(-1.0, 1.0, 0.01) var phase_bias: float = 0.0
@export_range(18.0, 82.0, 1.0) var lever_length: float = 46.0
@export_range(0.2, 2.2, 0.01) var impulse_memory: float = 1.04

var _angles := PackedFloat32Array()
var _angular_velocity := PackedFloat32Array()
var _impulse := PackedFloat32Array()
var _grabbed: int = -1
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _event_timer: float = 1.1
var _event_counter: int = 29


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _angles.clear()
    _angular_velocity.clear()
    _impulse.clear()
    _grabbed = -1
    _event_timer = 1.1
    _event_counter = 29
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _angles.resize(OSCILLATORS)
    _angular_velocity.resize(OSCILLATORS)
    _impulse.resize(OSCILLATORS)
    for i: int in range(OSCILLATORS):
        _angles[i] = (_hash01i(i * 79 + 11) - 0.5) * 0.34
        _angular_velocity[i] = 0.0
        _impulse[i] = 0.0


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"coupling","label":"COUPLING","type":"float","min":0.0,"max":3.0,"step":0.01},
        {"id":"damping","label":"DAMPING","type":"float","min":0.1,"max":5.0,"step":0.01},
        {"id":"drive","label":"SELF DRIVE","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"phase_bias","label":"PHASE BIAS","type":"float","min":-1.0,"max":1.0,"step":0.01},
        {"id":"lever_length","label":"LEVER LENGTH","type":"float","min":18.0,"max":82.0,"step":1.0},
        {"id":"impulse_memory","label":"IMPULSE MEMORY","type":"float","min":0.2,"max":2.2,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "coupling": return coupling
        "damping": return damping
        "drive": return drive
        "phase_bias": return phase_bias
        "lever_length": return lever_length
        "impulse_memory": return impulse_memory
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "coupling": coupling = clampf(float(value), 0.0, 3.0)
        "damping": damping = clampf(float(value), 0.1, 5.0)
        "drive": drive = clampf(float(value), 0.0, 2.0)
        "phase_bias": phase_bias = clampf(float(value), -1.0, 1.0)
        "lever_length": lever_length = clampf(float(value), 18.0, 82.0)
        "impulse_memory": impulse_memory = clampf(float(value), 0.2, 2.2)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down and not _pointer_was_down:
        _grabbed = _nearest_hinge(pointer_position, 76.0)
    if pointer_down and _grabbed >= 0:
        var pivot := _pivot(_grabbed)
        var direction := pointer_position - pivot
        if direction.length() > 4.0:
            var target := clampf(direction.angle() - PI * 0.5, -1.25, 1.25)
            var delta_angle := wrapf(target - _angles[_grabbed], -PI, PI)
            _angular_velocity[_grabbed] += delta_angle * 8.0
            _angles[_grabbed] = lerpf(_angles[_grabbed], target, 0.44)
            _impulse[_grabbed] = minf(1.0, _impulse[_grabbed] + absf(delta_angle) * 0.4)
    elif not pointer_down and _pointer_was_down and _grabbed >= 0:
        var delta_pointer := pointer_position - _last_pointer
        _angular_velocity[_grabbed] += delta_pointer.x * 0.025
        _impulse[_grabbed] = 1.0
        _grabbed = -1
    _last_pointer = pointer_position
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _event_timer -= delta * maxf(0.1, drive)
    if _event_timer <= 0.0 and drive > 0.02:
        _event_counter += 1
        _event_timer = 1.1 + _hash01i(_event_counter * 61 + 5) * 3.4
        var index := int(_hash01i(_event_counter * 101 + 17) * float(OSCILLATORS - 1))
        _angular_velocity[index] += (_hash01i(_event_counter * 131 + 23) - 0.5) * drive * 4.2
        _impulse[index] = minf(1.0, _impulse[index] + 0.7)

    var next_velocity := _angular_velocity.duplicate()
    for i: int in range(OSCILLATORS):
        if i == _grabbed:
            continue
        var angle := _angles[i]
        var force := -sin(angle - phase_bias * 0.42) * (0.8 + drive * 0.22)

        var row := int(i / 8)
        var col := i % 8
        if col > 0:
            force += wrapf(_angles[i - 1] - angle, -PI, PI) * coupling
        if col < 7:
            force += wrapf(_angles[i + 1] - angle, -PI, PI) * coupling
        if row > 0:
            force += wrapf(_angles[i - 8] - angle, -PI, PI) * coupling * 0.52
        if row < 7:
            force += wrapf(_angles[i + 8] - angle, -PI, PI) * coupling * 0.52

        force += sin(float(i) * 1.618 + sketch_time * (0.7 + drive * 0.13)) * _impulse[i] * drive * 0.52
        var velocity := _angular_velocity[i] + force * delta
        velocity *= exp(-delta * damping / impulse_memory)
        next_velocity[i] = clampf(velocity, -5.0, 5.0)
        _impulse[i] *= exp(-delta * (0.28 + 0.52 / impulse_memory))

    _angular_velocity = next_velocity
    for i: int in range(OSCILLATORS):
        if i == _grabbed:
            continue
        _angles[i] = clampf(_angles[i] + _angular_velocity[i] * delta, -1.42, 1.42)

    queue_redraw()


func _pivot(index: int) -> Vector2:
    var row := int(index / 8)
    var col := index % 8
    return Vector2(
        lerpf(SAFE.position.x + 74.0, SAFE.end.x - 74.0, float(col) / 7.0),
        lerpf(SAFE.position.y + 56.0, SAFE.end.y - 56.0, float(row) / 7.0)
    )


func _nearest_hinge(point: Vector2, radius: float) -> int:
    var best := -1
    var best_distance := radius
    for i: int in range(OSCILLATORS):
        var distance := point.distance_to(_pivot(i))
        if distance < best_distance:
            best_distance = distance
            best = i
    return best


func _tip(index: int) -> Vector2:
    var angle := _angles[index] + PI * 0.5
    return _pivot(index) + Vector2(cos(angle), sin(angle)) * lever_length


func _draw() -> void:
    begin_design_draw(Color(0.925, 0.915, 0.875, 1.0))
    draw_rect(SAFE, Color(0.06, 0.07, 0.08, 0.035), true)

    for row: int in range(8):
        for col: int in range(7):
            var a := row * 8 + col
            var b := a + 1
            var energy := minf(1.0, absf(_angular_velocity[a] - _angular_velocity[b]) * 0.28)
            draw_line(_pivot(a), _pivot(b), Color(0.14, 0.17, 0.18, 0.08 + energy * 0.18), 1.0 + energy * 1.2, true)

    for i: int in range(OSCILLATORS):
        var pivot := _pivot(i)
        var tip := _tip(i)
        var energy := clampf(absf(_angular_velocity[i]) * 0.25 + _impulse[i] * 0.55, 0.0, 1.0)
        draw_line(pivot + Vector2(2.0, 2.0), tip + Vector2(2.0, 2.0), Color(0.05, 0.05, 0.04, 0.12), 5.0, true)
        draw_line(pivot, tip, Color(0.16, 0.20, 0.20, 0.78).lerp(Color(0.78, 0.30, 0.13, 0.96), energy), 2.2 + energy * 1.8, true)
        draw_circle(pivot, 5.5, Color(0.16, 0.15, 0.13, 0.94), true)
        draw_circle(tip, 4.0 + energy * 2.4, Color(0.72, 0.55, 0.31, 0.82), true)

    if _grabbed >= 0:
        draw_arc(_pivot(_grabbed), 22.0, 0.0, TAU, 36, Color(0.86, 0.38, 0.15, 0.52), 1.5, true)
    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "angles": _angles.duplicate(),
        "angular_velocity": _angular_velocity.duplicate(),
        "impulse": _impulse.duplicate(),
        "event_timer": _event_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("angles", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == OSCILLATORS:
        _angles = (value as PackedFloat32Array).duplicate()
    value = state.get("angular_velocity", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == OSCILLATORS:
        _angular_velocity = (value as PackedFloat32Array).duplicate()
    value = state.get("impulse", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == OSCILLATORS:
        _impulse = (value as PackedFloat32Array).duplicate()
    _event_timer = float(state.get("event_timer", _event_timer))
    _event_counter = int(state.get("event_counter", _event_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {"oscillators": OSCILLATORS, "grabbed": _grabbed}
