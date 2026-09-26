extends "res://sketches/_shared/design_sketch_base.gd"

const CHARGE_HIT_RADIUS: float = 42.0

@export_range(36, 120, 1) var line_density: int = 78
@export_range(0.6, 3.0, 0.01) var field_gain: float = 1.42
@export_range(2.0, 10.0, 0.1) var integration_step: float = 5.2
@export_range(0.04, 0.45, 0.01) var curvature: float = 0.22
@export_range(0.4, 1.8, 0.01) var line_length: float = 1.08
@export_range(0.1, 2.0, 0.01) var charge_motion: float = 0.72
@export_range(0.0, 1.0, 0.01) var spectral: float = 0.42
@export_range(0.0, 2.0, 0.01) var halo: float = 0.94

var _positions := PackedVector2Array([
    Vector2(0.22, 0.31), Vector2(0.46, 0.21), Vector2(0.74, 0.39), Vector2(0.58, 0.72), Vector2(0.29, 0.70)
])
var _targets := PackedVector2Array([
    Vector2(0.28, 0.24), Vector2(0.51, 0.29), Vector2(0.71, 0.47), Vector2(0.62, 0.68), Vector2(0.34, 0.64)
])
var _velocities := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _charges := PackedFloat32Array([1.0, 0.76, -1.05, -0.82, 0.68])
var _lines: Array[PackedVector2Array] = []
var _line_energy := PackedFloat32Array()
var _rebuild_accum: float = 0.0
var _event_counter: int = 7
var _active_charge: int = -1
var _was_down: bool = false
var _last_pointer: Vector2 = DESIGN_SIZE * 0.5
var _gesture_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
    super._ready()
    _rebuild_lines()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"line_density","label":"LINE DENSITY","type":"int","min":36,"max":120,"step":1},
        {"id":"field_gain","label":"FIELD GAIN","type":"float","min":0.6,"max":3.0,"step":0.01},
        {"id":"integration_step","label":"TRACE STEP","type":"float","min":2.0,"max":10.0,"step":0.1},
        {"id":"curvature","label":"CURVATURE","type":"float","min":0.04,"max":0.45,"step":0.01},
        {"id":"line_length","label":"LINE LENGTH","type":"float","min":0.4,"max":1.8,"step":0.01},
        {"id":"charge_motion","label":"CHARGE MOTION","type":"float","min":0.1,"max":2.0,"step":0.01},
        {"id":"spectral","label":"SPECTRAL BIAS","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"halo","label":"HALO","type":"float","min":0.0,"max":2.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "line_density": return line_density
        "field_gain": return field_gain
        "integration_step": return integration_step
        "curvature": return curvature
        "line_length": return line_length
        "charge_motion": return charge_motion
        "spectral": return spectral
        "halo": return halo
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "line_density": line_density = clampi(int(value), 36, 120)
        "field_gain": field_gain = clampf(float(value), 0.6, 3.0)
        "integration_step": integration_step = clampf(float(value), 2.0, 10.0)
        "curvature": curvature = clampf(float(value), 0.04, 0.45)
        "line_length": line_length = clampf(float(value), 0.4, 1.8)
        "charge_motion": charge_motion = clampf(float(value), 0.1, 2.0)
        "spectral": spectral = clampf(float(value), 0.0, 1.0)
        "halo": halo = clampf(float(value), 0.0, 2.0)
        _: return
    _rebuild_lines()
    queue_redraw()


func _on_pointer_changed() -> void:
    var delta_pos := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pos, 0.58)
    _last_pointer = pointer_position

    if pointer_down and not _was_down:
        _active_charge = _charge_at_point(pointer_position)
        if _active_charge >= 0:
            _event_counter += 1
            _charges[_active_charge] = clampf(_charges[_active_charge] * 1.035, -1.35, 1.35)
            _grab_active_charge(pointer_position)

    if pointer_down and _active_charge >= 0:
        _grab_active_charge(pointer_position)

    if not pointer_down and _active_charge >= 0:
        _velocities[_active_charge] = _gesture_velocity / DESIGN_SIZE * 1.9
        _targets[_active_charge] = _positions[_active_charge]
        _active_charge = -1

    _was_down = pointer_down
    _rebuild_lines()
    queue_redraw()


func _grab_active_charge(design_position: Vector2) -> void:
    if _active_charge < 0:
        return
    var uv := (design_position / DESIGN_SIZE).clamp(Vector2(0.06, 0.08), Vector2(0.94, 0.92))
    var previous := _positions[_active_charge]
    _positions[_active_charge] = uv
    _targets[_active_charge] = uv
    _velocities[_active_charge] = (uv - previous) * 22.0


func _charge_at_point(design_position: Vector2) -> int:
    var best := -1
    var best_distance := CHARGE_HIT_RADIUS
    for i: int in range(5):
        var d := design_position.distance_to(_positions[i] * DESIGN_SIZE)
        if d <= best_distance:
            best_distance = d
            best = i
    return best


func _update_source_simulation(delta: float) -> void:
    for i: int in range(5):
        if i == _active_charge and pointer_down:
            continue

        var force := (_targets[i] - _positions[i]) * (0.34 + charge_motion * 0.58)
        for j: int in range(5):
            if i == j:
                continue
            var d := _positions[i] - _positions[j]
            var r2 := maxf(0.0035, d.length_squared())
            force += d.normalized() * (0.0009 / r2)
        _velocities[i] += force * delta
        _velocities[i] *= exp(-delta * 1.28)
        _positions[i] += _velocities[i] * delta
        _positions[i] = _positions[i].clamp(Vector2(0.07, 0.09), Vector2(0.93, 0.91))

        if _positions[i].distance_to(_targets[i]) < 0.018 and _velocities[i].length() < 0.012:
            _event_counter += 1
            _targets[i] = Vector2(
                lerpf(0.12, 0.88, _hash01(_event_counter * 47 + i * 13)),
                lerpf(0.14, 0.86, _hash01(_event_counter * 71 + i * 29))
            )

    _gesture_velocity *= exp(-delta * 7.5)
    _rebuild_accum += delta
    if _rebuild_accum >= 1.0 / 24.0:
        _rebuild_accum = 0.0
        _rebuild_lines()
        queue_redraw()


func _field_at(point: Vector2) -> Vector2:
    var field := Vector2.ZERO
    for i: int in range(5):
        var center := _positions[i] * DESIGN_SIZE
        var d := point - center
        var r2 := maxf(180.0, d.length_squared())
        field += d.normalized() * (_charges[i] * field_gain / r2)
    return field


func _rebuild_lines() -> void:
    _lines.clear()
    _line_energy = PackedFloat32Array()
    var positives := PackedInt32Array([0, 1, 4])
    var max_steps := clampi(int(round(64.0 * line_length)), 28, 120)
    var golden := 2.399963229728653

    for line_index: int in range(line_density):
        var source_index := positives[line_index % positives.size()]
        var source := _positions[source_index] * DESIGN_SIZE
        var angle := float(line_index) * golden + float(source_index) * 0.73
        var direction := Vector2(cos(angle), sin(angle))
        var point := source + direction * 15.0
        var poly := PackedVector2Array()
        poly.append(point)
        var energy_sum := 0.0

        for step_index: int in range(max_steps):
            var field := _field_at(point)
            var magnitude := field.length()
            if magnitude < 0.0000001:
                break
            var desired := field / magnitude
            direction = direction.lerp(desired, curvature).normalized()
            point += direction * integration_step
            poly.append(point)
            energy_sum += minf(1.0, magnitude * 28000.0)

            if point.x < 18.0 or point.y < 18.0 or point.x > DESIGN_SIZE.x - 18.0 or point.y > DESIGN_SIZE.y - 18.0:
                break
            if _near_negative_charge(point):
                break

        if poly.size() >= 5:
            _lines.append(poly)
            _line_energy.append(energy_sum / float(maxi(1, poly.size() - 1)))


func _near_negative_charge(point: Vector2) -> bool:
    for i: int in range(5):
        if _charges[i] >= 0.0:
            continue
        if point.distance_to(_positions[i] * DESIGN_SIZE) < 13.0:
            return true
    return false


func _draw() -> void:
    begin_design_draw(Color(0.006, 0.008, 0.014, 1.0))

    for i: int in range(_lines.size()):
        var poly := _lines[i]
        var e := _line_energy[i] if i < _line_energy.size() else 0.4
        var hue := lerpf(0.51, 0.86, clampf(spectral * 0.7 + e * 0.3, 0.0, 1.0))
        var core := Color.from_hsv(hue, 0.34 + spectral * 0.34, 0.72 + e * 0.24, 0.78)
        if halo > 0.01:
            draw_polyline(poly, Color(core.r, core.g, core.b, 0.055 * halo), 5.0 + halo * 1.8, true)
        draw_polyline(poly, core, 1.05, true)

    for i: int in range(5):
        var p := _positions[i] * DESIGN_SIZE
        var positive := _charges[i] > 0.0
        var c := Color(0.36, 0.92, 1.0, 0.92) if positive else Color(1.0, 0.42, 0.72, 0.92)
        draw_circle(p, 18.0 + absf(_charges[i]) * 5.0, Color(c.r, c.g, c.b, 0.035 * halo), true)
        if i == _active_charge:
            draw_arc(p, 14.0, 0.0, TAU, 32, Color(c.r, c.g, c.b, 0.88), 1.4, true)
            draw_arc(p, CHARGE_HIT_RADIUS, 0.0, TAU, 48, Color(c.r, c.g, c.b, 0.14), 1.0, true)
        draw_circle(p, 4.4, Color(c.r, c.g, c.b, 0.94), true)
        draw_circle(p, 1.6, Color(1.0, 1.0, 1.0, 0.96), true)

    end_design_draw()


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "targets": _targets.duplicate(),
        "velocities": _velocities.duplicate(),
        "charges": _charges.duplicate(),
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 5:
        _positions = (v as PackedVector2Array).duplicate()
    v = state.get("targets", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 5:
        _targets = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 5:
        _velocities = (v as PackedVector2Array).duplicate()
    v = state.get("charges", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 5:
        _charges = (v as PackedFloat32Array).duplicate()
    _event_counter = int(state.get("event_counter", _event_counter))
    _rebuild_lines()
    queue_redraw()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "field_line_count": _lines.size(),
        "active_charge": _active_charge,
        "render_mode": "direct_manipulation_vector_field",
    }
