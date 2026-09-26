extends "res://sketches/_shared/design_sketch_base.gd"

# State-driven mechanical motion only: gravity, coupling, collisions, direct
# manipulation and center-crossing escapement. No direct clock wobble.

const COLS: int = 8
const ROWS: int = 6
const OSCILLATORS: int = COLS * ROWS
const SAFE := Rect2(70.0, 58.0, 1140.0, 604.0)
const BOB_RADIUS: float = 8.0

@export_range(0.0, 3.0, 0.01) var coupling: float = 0.82
@export_range(0.05, 3.0, 0.01) var damping: float = 0.42
@export_range(0.0, 2.0, 0.01) var drive: float = 0.56
@export_range(0.4, 4.0, 0.01) var gravity: float = 1.72
@export_range(28.0, 90.0, 1.0) var lever_length: float = 68.0
@export_range(0.0, 1.0, 0.01) var rebound: float = 0.64

var _angles := PackedFloat32Array()
var _angular_velocity := PackedFloat32Array()
var _impact := PackedFloat32Array()
var _grabbed: int = -1
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _last_drag_angle: float = 0.0


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _angles.clear()
    _angular_velocity.clear()
    _impact.clear()
    _grabbed = -1
    _pointer_was_down = false
    _last_pointer = DESIGN_SIZE * 0.5
    _last_drag_angle = 0.0
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _angles.resize(OSCILLATORS)
    _angular_velocity.resize(OSCILLATORS)
    _impact.resize(OSCILLATORS)
    for i: int in range(OSCILLATORS):
        _angles[i] = (_hash01i(i * 79 + 11) - 0.5) * 0.48
        _angular_velocity[i] = (_hash01i(i * 43 + 7) - 0.5) * 0.12
        _impact[i] = 0.0


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"coupling","label":"LINK COUPLING","type":"float","min":0.0,"max":3.0,"step":0.01},
        {"id":"damping","label":"BEARING DRAG","type":"float","min":0.05,"max":3.0,"step":0.01},
        {"id":"drive","label":"ESCAPEMENT DRIVE","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"gravity","label":"PENDULUM GRAVITY","type":"float","min":0.4,"max":4.0,"step":0.01},
        {"id":"lever_length","label":"LEVER LENGTH","type":"float","min":28.0,"max":90.0,"step":1.0},
        {"id":"rebound","label":"COLLISION REBOUND","type":"float","min":0.0,"max":1.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "coupling": return coupling
        "damping": return damping
        "drive": return drive
        "gravity": return gravity
        "lever_length": return lever_length
        "rebound": return rebound
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "coupling": coupling = clampf(float(value), 0.0, 3.0)
        "damping": damping = clampf(float(value), 0.05, 3.0)
        "drive": drive = clampf(float(value), 0.0, 2.0)
        "gravity": gravity = clampf(float(value), 0.4, 4.0)
        "lever_length": lever_length = clampf(float(value), 28.0, 90.0)
        "rebound": rebound = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down and not _pointer_was_down:
        _grabbed = _nearest_hinge(pointer_position, 54.0)
        if _grabbed >= 0:
            _last_drag_angle = _angles[_grabbed]

    if pointer_down and _grabbed >= 0:
        var pivot := _pivot(_grabbed)
        var direction := pointer_position - pivot
        if direction.length() > 8.0:
            var target := clampf(atan2(direction.x, direction.y), -1.48, 1.48)
            var angular_delta := wrapf(target - _angles[_grabbed], -PI, PI)
            _angular_velocity[_grabbed] = lerpf(
                _angular_velocity[_grabbed],
                angular_delta * 14.0,
                0.34
            )
            _angles[_grabbed] = lerpf(_angles[_grabbed], target, 0.58)
            _impact[_grabbed] = minf(1.0, _impact[_grabbed] + absf(angular_delta) * 0.8)
            _last_drag_angle = target
    elif not pointer_down and _pointer_was_down and _grabbed >= 0:
        _impact[_grabbed] = 1.0
        _grabbed = -1

    _last_pointer = pointer_position
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    var previous_angles := _angles.duplicate()
    var next_velocity := _angular_velocity.duplicate()

    for i: int in range(OSCILLATORS):
        if i == _grabbed:
            continue

        var angle := _angles[i]
        var torque := -sin(angle) * gravity * (56.0 / _length(i))

        var row := int(i / COLS)
        var col := i % COLS
        if col > 0:
            torque += wrapf(_angles[i - 1] - angle, -PI, PI) * coupling
        if col + 1 < COLS:
            torque += wrapf(_angles[i + 1] - angle, -PI, PI) * coupling
        if row > 0:
            torque += wrapf(_angles[i - COLS] - angle, -PI, PI) * coupling * 0.58
        if row + 1 < ROWS:
            torque += wrapf(_angles[i + COLS] - angle, -PI, PI) * coupling * 0.58

        var velocity := _angular_velocity[i] + torque * delta * 2.15
        velocity *= exp(-delta * damping)
        next_velocity[i] = clampf(velocity, -6.5, 6.5)
        _impact[i] *= exp(-delta * 2.8)

    _angular_velocity = next_velocity

    for i: int in range(OSCILLATORS):
        if i == _grabbed:
            continue
        _angles[i] = clampf(_angles[i] + _angular_velocity[i] * delta, -1.50, 1.50)

        if drive > 0.001 \
        and previous_angles[i] * _angles[i] <= 0.0 \
        and absf(_angular_velocity[i]) > 0.035:
            var direction := 1.0 if _angular_velocity[i] >= 0.0 else -1.0
            var variation := 0.82 + _hash01i(i * 97 + 31) * 0.36
            _angular_velocity[i] += direction * drive * 0.22 * variation

    _resolve_bob_collisions()
    queue_redraw()


func _resolve_bob_collisions() -> void:
    var diameter := BOB_RADIUS * 2.0 + rebound * 4.0
    for i: int in range(OSCILLATORS):
        var pivot_i := _pivot(i)
        var length_i := _length(i)
        var tip_i := _tip(i)
        var tangent_i := Vector2(cos(_angles[i]), -sin(_angles[i]))

        for j: int in range(i + 1, OSCILLATORS):
            var pivot_j := _pivot(j)
            var length_j := _length(j)
            if pivot_i.distance_to(pivot_j) > length_i + length_j + diameter:
                continue

            var tip_j := _tip(j)
            var offset := tip_j - tip_i
            var distance := offset.length()
            if distance <= 0.001 or distance >= diameter:
                continue

            var normal := offset / distance
            var tangent_j := Vector2(cos(_angles[j]), -sin(_angles[j]))
            var velocity_i := tangent_i * (_angular_velocity[i] * length_i)
            var velocity_j := tangent_j * (_angular_velocity[j] * length_j)
            var closing_speed := (velocity_j - velocity_i).dot(normal)
            if closing_speed >= 0.0:
                continue

            var impulse := -closing_speed * (0.34 + rebound * 0.52)
            if i != _grabbed:
                _angular_velocity[i] -= impulse * tangent_i.dot(normal) / maxf(24.0, length_i)
            if j != _grabbed:
                _angular_velocity[j] += impulse * tangent_j.dot(normal) / maxf(24.0, length_j)

            var impact_energy := clampf(absf(closing_speed) / 180.0, 0.0, 1.0)
            _impact[i] = maxf(_impact[i], impact_energy)
            _impact[j] = maxf(_impact[j], impact_energy)


func _pivot(index: int) -> Vector2:
    var row := int(index / COLS)
    var col := index % COLS
    return Vector2(
        lerpf(SAFE.position.x + 66.0, SAFE.end.x - 66.0, float(col) / float(COLS - 1)),
        lerpf(SAFE.position.y + 62.0, SAFE.end.y - 62.0, float(row) / float(ROWS - 1))
    )


func _length(index: int) -> float:
    var spread := (_hash01i(index * 131 + 19) - 0.5) * 0.28
    return lever_length * (1.0 + spread)


func _tip(index: int) -> Vector2:
    var angle := _angles[index]
    return _pivot(index) + Vector2(sin(angle), cos(angle)) * _length(index)


func _nearest_hinge(point: Vector2, radius: float) -> int:
    var best := -1
    var best_distance := radius
    for i: int in range(OSCILLATORS):
        var distance := _distance_to_segment(point, _pivot(i), _tip(i))
        if distance < best_distance:
            best_distance = distance
            best = i
    return best


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
    var ab := b - a
    var denom := maxf(0.0001, ab.length_squared())
    var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
    return point.distance_to(a + ab * t)


func _draw() -> void:
    begin_design_draw(Color(0.91, 0.895, 0.845, 1.0))

    for row: int in range(ROWS):
        for col: int in range(COLS - 1):
            var a := row * COLS + col
            var b := a + 1
            var transfer := clampf(
                absf(_angular_velocity[a] - _angular_velocity[b]) * 0.18,
                0.0,
                1.0
            )
            draw_line(
                _pivot(a),
                _pivot(b),
                Color(0.12, 0.14, 0.14, 0.07 + transfer * 0.12),
                1.0 + transfer,
                true
            )

    for i: int in range(OSCILLATORS):
        var pivot := _pivot(i)
        var tip := _tip(i)
        var direction := (tip - pivot).normalized()
        var tangent := Vector2(-direction.y, direction.x)
        var energy := clampf(absf(_angular_velocity[i]) * 0.18 + _impact[i] * 0.75, 0.0, 1.0)
        if i == _grabbed:
            energy = 1.0

        draw_line(pivot + Vector2(2.0, 3.0), tip + Vector2(2.0, 3.0), Color(0.03, 0.035, 0.035, 0.16), 7.0, true)
        draw_line(pivot, tip, Color(0.12, 0.16, 0.16, 0.92).lerp(Color(0.78, 0.31, 0.12, 0.98), energy), 3.0 + energy * 2.2, true)

        var half_w := BOB_RADIUS + energy * 2.0
        var half_h := 5.0 + energy
        var bob := PackedVector2Array([
            tip + tangent * half_w + direction * half_h,
            tip - tangent * half_w + direction * half_h,
            tip - tangent * half_w - direction * half_h,
            tip + tangent * half_w - direction * half_h,
        ])
        draw_colored_polygon(bob, Color(0.54, 0.42, 0.25, 0.96).lerp(Color(0.94, 0.48, 0.16, 0.98), energy))
        draw_circle(pivot, 4.2, Color(0.11, 0.105, 0.095, 0.96), true)

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
        "impact": _impact.duplicate(),
        "grabbed": _grabbed,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("angles", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == OSCILLATORS:
        _angles = (value as PackedFloat32Array).duplicate()
    value = state.get("angular_velocity", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == OSCILLATORS:
        _angular_velocity = (value as PackedFloat32Array).duplicate()
    value = state.get("impact", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == OSCILLATORS:
        _impact = (value as PackedFloat32Array).duplicate()
    _grabbed = int(state.get("grabbed", -1))


func _get_custom_live_debug_state() -> Dictionary:
    var kinetic := 0.0
    for velocity: float in _angular_velocity:
        kinetic += absf(velocity)
    return {"oscillators": OSCILLATORS, "grabbed": _grabbed, "mean_angular_speed": kinetic / float(OSCILLATORS)}
