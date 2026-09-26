extends "res://sketches/_shared/design_sketch_base.gd"

const COLS: int = 10
const ROWS: int = 7
const CELLS: int = COLS * ROWS
const SAFE := Rect2(72.0, 58.0, 1136.0, 604.0)

@export_range(0.70, 1.35, 0.01) var packing: float = 1.02
@export_range(0.0, 2.5, 0.01) var adhesion: float = 0.62
@export_range(0.05, 3.0, 0.01) var damping: float = 0.84
@export_range(0.2, 2.5, 0.01) var pressure_gain: float = 1.22
@export_range(0.0, 2.0, 0.01) var pulse: float = 0.46
@export_range(0.2, 2.5, 0.01) var response: float = 1.18

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _pressure := PackedFloat32Array()
var _contact := PackedFloat32Array()
var _grabbed: int = -1
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _pulse_timer: float = 1.2
var _pulse_counter: int = 53


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _positions.clear()
    _velocities.clear()
    _pressure.clear()
    _contact.clear()
    _grabbed = -1
    _pointer_was_down = false
    _last_pointer = DESIGN_SIZE * 0.5
    _pulse_timer = 1.2
    _pulse_counter = 53
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _positions.resize(CELLS)
    _velocities.resize(CELLS)
    _pressure.resize(CELLS)
    _contact.resize(CELLS)
    var step_x := SAFE.size.x / float(COLS)
    var step_y := SAFE.size.y / float(ROWS)
    for row: int in range(ROWS):
        for col: int in range(COLS):
            var i := row * COLS + col
            var jitter := Vector2((_hash01i(i * 73 + 5) - 0.5) * 22.0, (_hash01i(i * 97 + 13) - 0.5) * 22.0)
            _positions[i] = SAFE.position + Vector2((float(col) + 0.5) * step_x, (float(row) + 0.5) * step_y) + jitter
            _velocities[i] = Vector2((_hash01i(i * 29 + 7) - 0.5) * 8.0, (_hash01i(i * 41 + 17) - 0.5) * 8.0)
            _pressure[i] = (_hash01i(i * 61 + 3) - 0.5) * 0.22
            _contact[i] = 0.0


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"packing","label":"PACKING","type":"float","min":0.70,"max":1.35,"step":0.01},
        {"id":"adhesion","label":"FILM ADHESION","type":"float","min":0.0,"max":2.5,"step":0.01},
        {"id":"damping","label":"FILM VISCOSITY","type":"float","min":0.05,"max":3.0,"step":0.01},
        {"id":"pressure_gain","label":"CELL PRESSURE","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"pulse","label":"BREATH PULSES","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"response","label":"HAND RESPONSE","type":"float","min":0.2,"max":2.5,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "packing": return packing
        "adhesion": return adhesion
        "damping": return damping
        "pressure_gain": return pressure_gain
        "pulse": return pulse
        "response": return response
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "packing": packing = clampf(float(value), 0.70, 1.35)
        "adhesion": adhesion = clampf(float(value), 0.0, 2.5)
        "damping": damping = clampf(float(value), 0.05, 3.0)
        "pressure_gain": pressure_gain = clampf(float(value), 0.2, 2.5)
        "pulse": pulse = clampf(float(value), 0.0, 2.0)
        "response": response = clampf(float(value), 0.2, 2.5)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down and not _pointer_was_down:
        _grabbed = _nearest_cell(pointer_position, 70.0)

    if pointer_down:
        var motion := pointer_position - _last_pointer
        if _grabbed >= 0:
            var to_pointer := pointer_position - _positions[_grabbed]
            _velocities[_grabbed] += to_pointer * 0.30 * response + motion * 0.72 * response
            _pressure[_grabbed] = minf(1.6, _pressure[_grabbed] + 0.18 * response)

        var brush := 112.0
        for i: int in range(CELLS):
            var offset := _positions[i] - pointer_position
            var distance := offset.length()
            if distance >= brush or distance <= 0.001:
                continue
            var falloff := 1.0 - distance / brush
            var tangent := Vector2(-offset.y, offset.x).normalized()
            _velocities[i] += (-offset.normalized() * 34.0 * falloff + tangent * motion.length() * 0.34 * falloff) * response
            _pressure[i] = minf(1.6, _pressure[i] + falloff * 0.08 * response)

    if not pointer_down and _pointer_was_down:
        _grabbed = -1

    _last_pointer = pointer_position
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _pulse_timer -= delta * maxf(0.08, pulse)
    if _pulse_timer <= 0.0 and pulse > 0.01:
        _pulse_counter += 1
        _pulse_timer = 0.7 + _hash01i(_pulse_counter * 83 + 11) * 2.8
        var i := int(_hash01i(_pulse_counter * 109 + 19) * float(CELLS - 1))
        var direction := Vector2(_hash01i(_pulse_counter * 131 + 7) - 0.5, _hash01i(_pulse_counter * 149 + 23) - 0.5).normalized()
        _velocities[i] += direction * pulse * 34.0
        _pressure[i] = minf(1.6, _pressure[i] + pulse * 0.52)

    var forces := PackedVector2Array()
    forces.resize(CELLS)
    for i: int in range(CELLS):
        forces[i] = Vector2.ZERO
        _contact[i] *= exp(-delta * 3.6)
        _pressure[i] *= exp(-delta * (0.24 + damping * 0.08))

    var target_distance := 51.0 * packing
    var near_distance := target_distance * 1.65
    for i: int in range(CELLS):
        for j: int in range(i + 1, CELLS):
            var offset := _positions[j] - _positions[i]
            var distance := offset.length()
            if distance <= 0.001 or distance > near_distance:
                continue
            var normal := offset / distance

            if distance < target_distance:
                var overlap := (target_distance - distance) / target_distance
                var force := normal * overlap * pressure_gain * 160.0
                forces[i] -= force
                forces[j] += force
                _pressure[i] = minf(1.6, _pressure[i] + overlap * delta * 2.2)
                _pressure[j] = minf(1.6, _pressure[j] + overlap * delta * 2.2)
                _contact[i] = maxf(_contact[i], overlap)
                _contact[j] = maxf(_contact[j], overlap)
            elif adhesion > 0.001:
                var bridge := 1.0 - (distance - target_distance) / maxf(1.0, near_distance - target_distance)
                var pull := normal * bridge * adhesion * 18.0
                forces[i] += pull
                forces[j] -= pull

    for i: int in range(CELLS):
        var pos := _positions[i]
        var edge_force := Vector2.ZERO
        var margin := 34.0
        if pos.x < SAFE.position.x + margin:
            edge_force.x += (SAFE.position.x + margin - pos.x) * 8.0
        elif pos.x > SAFE.end.x - margin:
            edge_force.x -= (pos.x - (SAFE.end.x - margin)) * 8.0
        if pos.y < SAFE.position.y + margin:
            edge_force.y += (SAFE.position.y + margin - pos.y) * 8.0
        elif pos.y > SAFE.end.y - margin:
            edge_force.y -= (pos.y - (SAFE.end.y - margin)) * 8.0

        if i != _grabbed:
            _velocities[i] += (forces[i] + edge_force) * delta
        _velocities[i] *= exp(-delta * damping)
        _velocities[i] = _velocities[i].limit_length(220.0)
        _positions[i] += _velocities[i] * delta

    queue_redraw()


func _nearest_cell(point: Vector2, radius: float) -> int:
    var best := -1
    var best_distance := radius
    for i: int in range(CELLS):
        var distance := point.distance_to(_positions[i])
        if distance < best_distance:
            best_distance = distance
            best = i
    return best


func _draw() -> void:
    begin_design_draw(Color(0.055, 0.062, 0.064, 1.0))
    for i: int in range(CELLS):
        var center := _positions[i]
        var radius := 21.0 * packing + clampf(_pressure[i], 0.0, 1.4) * 7.0
        var velocity := _velocities[i]
        var stretch := clampf(velocity.length() / 150.0, 0.0, 0.42)
        var axis := velocity.normalized() if velocity.length() > 0.5 else Vector2.RIGHT
        var normal := Vector2(-axis.y, axis.x)
        var points := PackedVector2Array()
        for k: int in range(9):
            var a := TAU * float(k) / 9.0
            var wobble := 0.90 + _hash01i(i * 197 + k * 31 + 7) * 0.20
            var local := axis * cos(a) * radius * (1.0 + stretch)
            local += normal * sin(a) * radius * (1.0 - stretch * 0.58)
            points.append(center + local * wobble)

        var contact := clampf(_contact[i], 0.0, 1.0)
        var pressure := clampf(_pressure[i] / 1.4, 0.0, 1.0)
        var base := Color(0.23, 0.66, 0.63, 0.72)
        base = base.lerp(Color(0.95, 0.55, 0.22, 0.90), maxf(contact, pressure * 0.72))
        if i == _grabbed:
            base = base.lerp(Color(0.98, 0.82, 0.42, 0.98), 0.72)
        draw_colored_polygon(points, base)
        draw_polyline(points, Color(0.90, 0.95, 0.88, 0.16 + contact * 0.34), 1.1 + contact * 1.4, true)
    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {"positions": _positions.duplicate(), "velocities": _velocities.duplicate(), "pressure": _pressure.duplicate(), "contact": _contact.duplicate(), "pulse_timer": _pulse_timer, "pulse_counter": _pulse_counter}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("positions", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == CELLS:
        _positions = (value as PackedVector2Array).duplicate()
    value = state.get("velocities", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == CELLS:
        _velocities = (value as PackedVector2Array).duplicate()
    value = state.get("pressure", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == CELLS:
        _pressure = (value as PackedFloat32Array).duplicate()
    value = state.get("contact", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == CELLS:
        _contact = (value as PackedFloat32Array).duplicate()
    _pulse_timer = float(state.get("pulse_timer", _pulse_timer))
    _pulse_counter = int(state.get("pulse_counter", _pulse_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {"cells": CELLS, "grabbed": _grabbed}
