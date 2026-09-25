extends "res://sketches/_shared/design_sketch_base.gd"

@export_range(0.2, 2.4, 0.01) var surface_tension: float = 1.12
@export_range(0.2, 2.5, 0.01) var pressure_gain: float = 1.06
@export_range(0.2, 2.4, 0.01) var viscosity: float = 0.92
@export_range(0.0, 1.6, 0.01) var buoyancy: float = 0.38
@export_range(0.2, 2.8, 0.01) var film_width: float = 1.18
@export_range(0.0, 1.0, 0.01) var iridescence: float = 0.78
@export_range(0.0, 1.0, 0.01) var translucency: float = 0.58
@export_range(0.0, 2.0, 0.01) var micro_detail: float = 1.12
@export_range(0.4, 2.4, 0.01) var exposure: float = 1.08

var _positions := PackedVector2Array([
    Vector2(0.31,0.34), Vector2(0.45,0.27), Vector2(0.61,0.34), Vector2(0.70,0.51),
    Vector2(0.59,0.66), Vector2(0.42,0.68), Vector2(0.27,0.56), Vector2(0.48,0.48)
])
var _velocities := PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
var _radii := PackedFloat32Array([0.118,0.096,0.132,0.088,0.112,0.101,0.084,0.139])
var _target_radii := PackedFloat32Array([0.118,0.096,0.132,0.088,0.112,0.101,0.084,0.139])
var _pressures := PackedFloat32Array([0.72,0.54,0.78,0.48,0.62,0.59,0.44,0.86])
var _event_index: int = 9
var _rest_accum: float = 0.0
var _active_bubble: int = -1
var _was_down: bool = false
var _last_pointer: Vector2 = DESIGN_SIZE * 0.5
var _gesture_velocity: Vector2 = Vector2.ZERO

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"surface_tension","label":"SURFACE TENSION","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"pressure_gain","label":"PRESSURE","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"viscosity","label":"VISCOSITY","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"buoyancy","label":"BUOYANCY","type":"float","min":0.0,"max":1.6,"step":0.01},
        {"id":"film_width","label":"FILM WIDTH","type":"float","min":0.2,"max":2.8,"step":0.01},
        {"id":"iridescence","label":"IRIDESCENCE","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"translucency","label":"TRANSLUCENCY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"micro_detail","label":"MICRO DETAIL","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"exposure","label":"EXPOSURE","type":"float","min":0.4,"max":2.4,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "surface_tension": return surface_tension
        "pressure_gain": return pressure_gain
        "viscosity": return viscosity
        "buoyancy": return buoyancy
        "film_width": return film_width
        "iridescence": return iridescence
        "translucency": return translucency
        "micro_detail": return micro_detail
        "exposure": return exposure
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "surface_tension": surface_tension = clampf(float(value), 0.2, 2.4)
        "pressure_gain": pressure_gain = clampf(float(value), 0.2, 2.5)
        "viscosity": viscosity = clampf(float(value), 0.2, 2.4)
        "buoyancy": buoyancy = clampf(float(value), 0.0, 1.6)
        "film_width": film_width = clampf(float(value), 0.2, 2.8)
        "iridescence": iridescence = clampf(float(value), 0.0, 1.0)
        "translucency": translucency = clampf(float(value), 0.0, 1.0)
        "micro_detail": micro_detail = clampf(float(value), 0.0, 2.0)
        "exposure": exposure = clampf(float(value), 0.4, 2.4)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    var delta_pos := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pos, 0.42)
    _last_pointer = pointer_position
    var uv := (pointer_position / DESIGN_SIZE).clamp(Vector2(0.04,0.06), Vector2(0.96,0.94))

    if pointer_down and not _was_down:
        _active_bubble = _nearest_bubble(uv)
        _target_radii[_active_bubble] = minf(0.18, _target_radii[_active_bubble] + 0.018 * pressure_gain)
        _pressures[_active_bubble] = minf(1.4, _pressures[_active_bubble] + 0.26 * pressure_gain)
        _event_index += 1

    if pointer_down and _active_bubble >= 0:
        var force := uv - _positions[_active_bubble]
        _velocities[_active_bubble] += force * 0.024 + _gesture_velocity / DESIGN_SIZE * 0.018
        _pressures[_active_bubble] = minf(1.5, _pressures[_active_bubble] + 0.006)

    if not pointer_down:
        _active_bubble = -1
    _was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    var average_speed := 0.0
    for i: int in range(8):
        var force := Vector2(0.0, -0.0045 * buoyancy * (0.7 + _radii[i] * 3.0))
        var center_pull := (Vector2(0.49,0.49) - _positions[i]) * 0.018
        force += center_pull

        for j: int in range(8):
            if i == j:
                continue
            var d := _positions[i] - _positions[j]
            var dist := maxf(0.0005, d.length())
            var desired := (_radii[i] + _radii[j]) * 0.86
            if dist < desired:
                force += d / dist * (desired - dist) * (2.7 * surface_tension)
            elif dist < desired * 1.55:
                force -= d / dist * (dist - desired) * 0.035 * surface_tension

        force += Vector2(
            (_pressures[i] - 0.62) * (0.006 if i % 2 == 0 else -0.005),
            (_pressures[i] - 0.62) * (0.004 if i % 3 == 0 else -0.003)
        )
        _velocities[i] += force * delta
        _velocities[i] *= exp(-delta * (1.45 + viscosity * 1.05))
        _positions[i] += _velocities[i] * delta
        _positions[i] = _positions[i].clamp(Vector2(_radii[i] + 0.04, _radii[i] + 0.05), Vector2(0.96 - _radii[i], 0.94 - _radii[i]))
        average_speed += _velocities[i].length()

        var radius_response := clampf(delta * (0.65 + surface_tension * 0.42), 0.0, 1.0)
        _radii[i] = lerpf(_radii[i], _target_radii[i], radius_response)
        _pressures[i] = lerpf(_pressures[i], 0.58 + _radii[i] * 1.2, clampf(delta * 0.18 / maxf(0.2, viscosity),0.0,1.0))

    average_speed /= 8.0
    if average_speed < 0.0028 and not pointer_down:
        _rest_accum += delta
    else:
        _rest_accum = maxf(0.0, _rest_accum - delta * 0.7)

    if _rest_accum > 1.35:
        _rest_accum = 0.0
        _event_index += 1
        var index := int(floor(_hash01(_event_index * 83) * 8.0)) % 8
        _target_radii[index] = lerpf(0.075, 0.155, _hash01(_event_index * 113 + index * 7))
        _pressures[index] = lerpf(0.45, 1.12, _hash01(_event_index * 149 + index * 19))

    _gesture_velocity *= exp(-delta * 7.0)
    _push_shader()


func _nearest_bubble(uv: Vector2) -> int:
    var best := 0
    var best_distance := INF
    for i: int in range(8):
        var d := uv.distance_squared_to(_positions[i])
        if d < best_distance:
            best_distance = d
            best = i
    return best


func _push_shader() -> void:
    if not is_instance_valid(_surface): return
    var material := _surface.material as ShaderMaterial
    if material == null: return
    for i: int in range(8):
        material.set_shader_parameter("u_b%d" % i, Vector4(_positions[i].x, _positions[i].y, _radii[i], _pressures[i]))
    material.set_shader_parameter("u_film_width", film_width)
    material.set_shader_parameter("u_iridescence", iridescence)
    material.set_shader_parameter("u_translucency", translucency)
    material.set_shader_parameter("u_micro", micro_detail)
    material.set_shader_parameter("u_exposure", exposure)


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {"positions":_positions.duplicate(),"velocities":_velocities.duplicate(),"radii":_radii.duplicate(),"target_radii":_target_radii.duplicate(),"pressures":_pressures.duplicate(),"event_index":_event_index,"rest_accum":_rest_accum}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 8: _positions = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 8: _velocities = (v as PackedVector2Array).duplicate()
    v = state.get("radii", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 8: _radii = (v as PackedFloat32Array).duplicate()
    v = state.get("target_radii", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 8: _target_radii = (v as PackedFloat32Array).duplicate()
    v = state.get("pressures", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 8: _pressures = (v as PackedFloat32Array).duplicate()
    _event_index = int(state.get("event_index", _event_index))
    _rest_accum = float(state.get("rest_accum", _rest_accum))
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    var kinetic := 0.0
    for v: Vector2 in _velocities: kinetic += v.length()
    return {"bubble_kinetic":kinetic,"render_mode":"sdf_thin_film_full_resolution"}


func _draw() -> void:
    pass
