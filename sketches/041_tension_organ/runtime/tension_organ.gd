extends "res://sketches/_shared/design_sketch_base.gd"

const COLS: int = 17
const ROWS: int = 10
const STEP_SECONDS: float = 1.0 / 60.0

@export_range(0.2, 2.4, 0.01) var tension: float = 1.05
@export_range(0.2, 2.6, 0.01) var elasticity: float = 1.18
@export_range(0.4, 5.0, 0.01) var damping: float = 2.15
@export_range(0.0, 2.2, 0.01) var autonomic_drive: float = 0.82
@export_range(0.0, 1.5, 0.01) var sheen: float = 0.88
@export_range(0.0, 1.5, 0.01) var depth: float = 0.74

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _rest := PackedVector2Array()
var _forces := PackedVector2Array()
var _accum: float = 0.0
var _drive_position := Vector2(620.0, 330.0)
var _drive_velocity := Vector2.ZERO
var _drive_target := Vector2(820.0, 250.0)
var _drive_timer: float = 0.8
var _event_counter: int = 11
var _grabbed: int = -1
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _gesture_velocity := Vector2.ZERO


func _ready() -> void:
    _allocate_mesh()
    super._ready()


func _allocate_mesh() -> void:
    var margin := Vector2(86.0, 72.0)
    var span := DESIGN_SIZE - margin * 2.0
    for row: int in range(ROWS):
        for col: int in range(COLS):
            var u := float(col) / float(COLS - 1)
            var v := float(row) / float(ROWS - 1)
            var rest := margin + Vector2(u * span.x, v * span.y)
            var falloff := 1.0 - absf(u - 0.5) * 0.55
            var offset := Vector2(
                (_hash01i(row * 97 + col * 31 + 5) - 0.5) * 32.0,
                (_hash01i(row * 53 + col * 71 + 17) - 0.5) * 42.0 * falloff
            )
            _rest.append(rest)
            _positions.append(rest + offset)
            _velocities.append(Vector2.ZERO)
            _forces.append(Vector2.ZERO)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"tension","label":"REST TENSION","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"elasticity","label":"CELL ELASTICITY","type":"float","min":0.2,"max":2.6,"step":0.01},
        {"id":"damping","label":"DAMPING","type":"float","min":0.4,"max":5.0,"step":0.01},
        {"id":"autonomic_drive","label":"AUTONOMIC DRIVE","type":"float","min":0.0,"max":2.2,"step":0.01},
        {"id":"sheen","label":"MATERIAL SHEEN","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"depth","label":"RELIEF DEPTH","type":"float","min":0.0,"max":1.5,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "tension": return tension
        "elasticity": return elasticity
        "damping": return damping
        "autonomic_drive": return autonomic_drive
        "sheen": return sheen
        "depth": return depth
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "tension": tension = clampf(float(value), 0.2, 2.4)
        "elasticity": elasticity = clampf(float(value), 0.2, 2.6)
        "damping": damping = clampf(float(value), 0.4, 5.0)
        "autonomic_drive": autonomic_drive = clampf(float(value), 0.0, 2.2)
        "sheen": sheen = clampf(float(value), 0.0, 1.5)
        "depth": depth = clampf(float(value), 0.0, 1.5)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    var delta_pointer := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pointer, 0.42)
    _last_pointer = pointer_position

    if pointer_down and not _pointer_was_down:
        _grabbed = _nearest_node(pointer_position, 52.0)

    if pointer_down and _grabbed >= 0:
        _positions[_grabbed] = pointer_position.clamp(Vector2(24.0, 24.0), DESIGN_SIZE - Vector2(24.0, 24.0))
        _velocities[_grabbed] = _gesture_velocity * 4.0

    if not pointer_down and _pointer_was_down and _grabbed >= 0:
        _velocities[_grabbed] = _velocities[_grabbed] + _gesture_velocity * 2.8
        _grabbed = -1

    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _accum += delta
    var steps := 0
    while _accum >= STEP_SECONDS and steps < 3:
        _simulate_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        steps += 1


func _simulate_step(dt: float) -> void:
    _drive_timer -= dt
    if _drive_timer <= 0.0:
        _event_counter += 1
        _drive_timer = 1.25 + _hash01i(_event_counter * 43) * 2.4
        _drive_target = Vector2(
            lerpf(170.0, 1110.0, _hash01i(_event_counter * 67 + 3)),
            lerpf(130.0, 590.0, _hash01i(_event_counter * 89 + 19))
        )

    _drive_velocity += (_drive_target - _drive_position) * dt * (0.34 + autonomic_drive * 0.32)
    _drive_velocity *= exp(-dt * 1.15)
    _drive_position += _drive_velocity * dt

    for i: int in range(_forces.size()):
        _forces[i] = (_rest[i] - _positions[i]) * tension * 0.82

    var rest_x := (_rest[1] - _rest[0]).length()
    var rest_y := (_rest[COLS] - _rest[0]).length()
    var rest_diag := sqrt(rest_x * rest_x + rest_y * rest_y)

    for row: int in range(ROWS):
        for col: int in range(COLS):
            var i := _idx(col, row)
            if col + 1 < COLS:
                _spring(i, _idx(col + 1, row), rest_x, 5.2 * elasticity)
            if row + 1 < ROWS:
                _spring(i, _idx(col, row + 1), rest_y, 5.0 * elasticity)
            if col + 1 < COLS and row + 1 < ROWS:
                _spring(i, _idx(col + 1, row + 1), rest_diag, 1.8 * elasticity)
            if col > 0 and row + 1 < ROWS:
                _spring(i, _idx(col - 1, row + 1), rest_diag, 1.8 * elasticity)

    for i: int in range(_positions.size()):
        if _is_pinned(i) or i == _grabbed:
            continue
        var to_drive := _positions[i] - _drive_position
        var distance := to_drive.length()
        if distance < 280.0 and distance > 0.001:
            var falloff := 1.0 - distance / 280.0
            var direction := to_drive / distance
            _forces[i] = _forces[i] + direction * falloff * falloff * autonomic_drive * 250.0

        var velocity := _velocities[i] + _forces[i] * dt
        velocity *= exp(-damping * dt)
        if velocity.length() > 320.0:
            velocity = velocity.normalized() * 320.0
        _velocities[i] = velocity
        _positions[i] = _positions[i] + velocity * dt

    for i: int in range(_positions.size()):
        if _is_pinned(i) and i != _grabbed:
            _positions[i] = _rest[i]
            _velocities[i] = Vector2.ZERO


func _spring(a: int, b: int, rest_length: float, stiffness: float) -> void:
    var delta := _positions[b] - _positions[a]
    var distance := maxf(0.0001, delta.length())
    var force := delta / distance * ((distance - rest_length) * stiffness)
    _forces[a] = _forces[a] + force
    _forces[b] = _forces[b] - force


func _is_pinned(index: int) -> bool:
    var row := int(index / COLS)
    var col := index - row * COLS
    var middle := int(COLS / 2)
    return (row == 0 and (col == 0 or col == middle or col == COLS - 1)) \
        or (row == ROWS - 1 and (col == 0 or col == COLS - 1))


func _nearest_node(point: Vector2, radius: float) -> int:
    var best := -1
    var best_d := radius * radius
    for i: int in range(_positions.size()):
        var d := point.distance_squared_to(_positions[i])
        if d < best_d:
            best_d = d
            best = i
    return best


func _cell_stress(col: int, row: int) -> float:
    var i0 := _idx(col, row)
    var i1 := _idx(col + 1, row)
    var i2 := _idx(col + 1, row + 1)
    var i3 := _idx(col, row + 1)
    var current := (_positions[i0].distance_to(_positions[i1]) + _positions[i1].distance_to(_positions[i2]) + _positions[i2].distance_to(_positions[i3]) + _positions[i3].distance_to(_positions[i0])) * 0.25
    var base := (_rest[i0].distance_to(_rest[i1]) + _rest[i1].distance_to(_rest[i2]) + _rest[i2].distance_to(_rest[i3]) + _rest[i3].distance_to(_rest[i0])) * 0.25
    return clampf(absf(current - base) / maxf(1.0, base) * 4.0, 0.0, 1.0)


func _draw() -> void:
    begin_design_draw(Color(0.009, 0.010, 0.015, 1.0))

    var cold := Color(0.075, 0.18, 0.24, 0.94)
    var mid := Color(0.25, 0.46, 0.54, 0.96)
    var hot := Color(0.96, 0.48, 0.22, 0.98)

    for row: int in range(ROWS - 1):
        for col: int in range(COLS - 1):
            var i0 := _idx(col, row)
            var i1 := _idx(col + 1, row)
            var i2 := _idx(col + 1, row + 1)
            var i3 := _idx(col, row + 1)
            var stress := _cell_stress(col, row)
            var shade := clampf((_positions[i0].y + _positions[i2].y - _rest[i0].y - _rest[i2].y) / 120.0 * depth + 0.5, 0.0, 1.0)
            var base_color := cold.lerp(mid, shade)
            var color := base_color.lerp(hot, stress * sheen * 0.78)
            color.a = 0.88
            draw_colored_polygon(PackedVector2Array([_positions[i0], _positions[i1], _positions[i2], _positions[i3]]), color)

    for row: int in range(ROWS):
        var line := PackedVector2Array()
        for col: int in range(COLS):
            line.append(_positions[_idx(col, row)])
        draw_polyline(line, Color(0.72, 0.86, 0.90, 0.20 + sheen * 0.11), 1.0, true)

    for col: int in range(COLS):
        var line := PackedVector2Array()
        for row: int in range(ROWS):
            line.append(_positions[_idx(col, row)])
        draw_polyline(line, Color(0.95, 0.67, 0.42, 0.09 + sheen * 0.08), 0.8, true)

    if _grabbed >= 0:
        draw_circle(_positions[_grabbed], 11.0, Color(1.0, 0.78, 0.52, 0.18), true)
        draw_circle(_positions[_grabbed], 4.0, Color(1.0, 0.88, 0.72, 0.95), true)

    end_design_draw()


func _idx(col: int, row: int) -> int:
    return row * COLS + col


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "drive_position": _drive_position,
        "drive_velocity": _drive_velocity,
        "drive_target": _drive_target,
        "drive_timer": _drive_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == COLS * ROWS:
        _positions = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == COLS * ROWS:
        _velocities = (v as PackedVector2Array).duplicate()
    v = state.get("drive_position", _drive_position)
    if v is Vector2: _drive_position = v as Vector2
    v = state.get("drive_velocity", _drive_velocity)
    if v is Vector2: _drive_velocity = v as Vector2
    v = state.get("drive_target", _drive_target)
    if v is Vector2: _drive_target = v as Vector2
    _drive_timer = float(state.get("drive_timer", _drive_timer))
    _event_counter = int(state.get("event_counter", _event_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "mesh_nodes": _positions.size(),
        "grabbed_node": _grabbed,
        "render_mode": "stateful_constraint_mesh",
    }
