extends "res://sketches/_shared/design_sketch_base.gd"

@export_range(0.45, 1.75, 0.01) var architecture: float = 1.02
@export_range(0.2, 2.4, 0.01) var facet_density: float = 1.12
@export_range(0.02, 1.0, 0.01) var roughness: float = 0.26
@export_range(0.0, 1.0, 0.01) var spectral: float = 0.38
@export_range(0.45, 1.65, 0.01) var camera_depth: float = 0.94
@export_range(0.1, 2.5, 0.01) var stress_gain: float = 1.15
@export_range(0.1, 2.5, 0.01) var fracture_memory: float = 1.28
@export_range(0.1, 3.0, 0.01) var touch_torque: float = 1.32

var _angle := -0.32
var _tilt := 0.18
var _angle_velocity := 0.0
var _tilt_velocity := 0.0
var _target_angle := 0.44
var _target_tilt := -0.12
var _target_index := 0
var _crack_positions := PackedVector2Array([Vector2(0.28, 0.42), Vector2(0.71, 0.31), Vector2(0.62, 0.72), Vector2(0.38, 0.66)])
var _crack_strength := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _crack_targets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _crack_seeds := PackedFloat32Array([0.13, 0.41, 0.67, 0.89])
var _crack_cursor := 0
var _active_crack := -1
var _was_down := false
var _last_pointer := Vector2(640.0, 360.0)
var _gesture_velocity := Vector2.ZERO

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"architecture","label":"ARCHITECTURE","type":"float","min":0.45,"max":1.75,"step":0.01},
        {"id":"facet_density","label":"MICRO FACETS","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"roughness","label":"ROUGHNESS","type":"float","min":0.02,"max":1.0,"step":0.01},
        {"id":"spectral","label":"SPECTRAL EDGE","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"camera_depth","label":"CAMERA DEPTH","type":"float","min":0.45,"max":1.65,"step":0.01},
        {"id":"stress_gain","label":"STRESS RESPONSE","type":"float","min":0.1,"max":2.5,"step":0.01},
        {"id":"fracture_memory","label":"FRACTURE MEMORY","type":"float","min":0.1,"max":2.5,"step":0.01},
        {"id":"touch_torque","label":"TOUCH TORQUE","type":"float","min":0.1,"max":3.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "architecture": return architecture
        "facet_density": return facet_density
        "roughness": return roughness
        "spectral": return spectral
        "camera_depth": return camera_depth
        "stress_gain": return stress_gain
        "fracture_memory": return fracture_memory
        "touch_torque": return touch_torque
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "architecture": architecture = clampf(float(value), 0.45, 1.75)
        "facet_density": facet_density = clampf(float(value), 0.2, 2.4)
        "roughness": roughness = clampf(float(value), 0.02, 1.0)
        "spectral": spectral = clampf(float(value), 0.0, 1.0)
        "camera_depth": camera_depth = clampf(float(value), 0.45, 1.65)
        "stress_gain": stress_gain = clampf(float(value), 0.1, 2.5)
        "fracture_memory": fracture_memory = clampf(float(value), 0.1, 2.5)
        "touch_torque": touch_torque = clampf(float(value), 0.1, 3.0)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    var delta_pos := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pos, 0.38)
    _last_pointer = pointer_position

    if pointer_down and not _was_down:
        _active_crack = _crack_cursor
        _crack_cursor = (_crack_cursor + 1) % 4
        _crack_positions[_active_crack] = (pointer_position / DESIGN_SIZE).clamp(Vector2(0.04, 0.04), Vector2(0.96, 0.96))
        _crack_targets[_active_crack] = 1.0
        _crack_seeds[_active_crack] = _hash01(_target_index * 71 + _active_crack * 19 + 11)

    if pointer_down and _active_crack >= 0:
        var uv := (pointer_position / DESIGN_SIZE).clamp(Vector2(0.04, 0.04), Vector2(0.96, 0.96))
        _crack_positions[_active_crack] = _crack_positions[_active_crack].lerp(uv, 0.16)
        _crack_targets[_active_crack] = minf(1.0, _crack_targets[_active_crack] + 0.08)
        _angle_velocity += _gesture_velocity.x * 0.000018 * touch_torque
        _tilt_velocity += _gesture_velocity.y * 0.000014 * touch_torque

    if not pointer_down:
        _active_crack = -1
    _was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    # No shader TIME and no looped camera choreography. Orientation is a damped
    # mechanical state that seeks irregular targets; fractures then bias it.
    var angle_error := _target_angle - _angle
    var tilt_error := _target_tilt - _tilt
    if absf(angle_error) < 0.018 and absf(tilt_error) < 0.014 and absf(_angle_velocity) < 0.025:
        _target_index += 1
        _target_angle = lerpf(-0.72, 0.72, _hash01(_target_index * 37 + 5))
        _target_tilt = lerpf(-0.34, 0.34, _hash01(_target_index * 53 + 17))

    var total_stress := 0.0
    for i: int in range(4):
        _crack_targets[i] = maxf(0.0, _crack_targets[i] - delta * (0.045 / maxf(0.1, fracture_memory)))
        var response := clampf(delta * (1.8 + stress_gain * 0.7), 0.0, 1.0)
        _crack_strength[i] = lerpf(_crack_strength[i], _crack_targets[i], response)
        total_stress += _crack_strength[i]

    var spring := 0.46 + architecture * 0.34
    _angle_velocity += angle_error * spring * delta
    _tilt_velocity += tilt_error * spring * 0.82 * delta
    _angle_velocity += (_crack_strength[0] - _crack_strength[2]) * stress_gain * delta * 0.055
    _tilt_velocity += (_crack_strength[1] - _crack_strength[3]) * stress_gain * delta * 0.045
    _angle_velocity *= exp(-delta * (0.72 + roughness * 0.58))
    _tilt_velocity *= exp(-delta * (0.82 + roughness * 0.52))
    _angle += _angle_velocity * delta
    _tilt += _tilt_velocity * delta
    _gesture_velocity *= exp(-delta * 6.0)
    _push_shader()


func _push_shader() -> void:
    if not is_instance_valid(_surface):
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_angle", _angle)
    material.set_shader_parameter("u_tilt", _tilt)
    material.set_shader_parameter("u_architecture", architecture)
    material.set_shader_parameter("u_facets", facet_density)
    material.set_shader_parameter("u_roughness", roughness)
    material.set_shader_parameter("u_spectral", spectral)
    material.set_shader_parameter("u_camera_depth", camera_depth)
    material.set_shader_parameter("u_stress_gain", stress_gain)
    material.set_shader_parameter("u_crack0", Vector4(_crack_positions[0].x, _crack_positions[0].y, _crack_strength[0], _crack_seeds[0]))
    material.set_shader_parameter("u_crack1", Vector4(_crack_positions[1].x, _crack_positions[1].y, _crack_strength[1], _crack_seeds[1]))
    material.set_shader_parameter("u_crack2", Vector4(_crack_positions[2].x, _crack_positions[2].y, _crack_strength[2], _crack_seeds[2]))
    material.set_shader_parameter("u_crack3", Vector4(_crack_positions[3].x, _crack_positions[3].y, _crack_strength[3], _crack_seeds[3]))


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "angle": _angle,
        "tilt": _tilt,
        "angle_velocity": _angle_velocity,
        "tilt_velocity": _tilt_velocity,
        "target_angle": _target_angle,
        "target_tilt": _target_tilt,
        "target_index": _target_index,
        "crack_positions": _crack_positions.duplicate(),
        "crack_strength": _crack_strength.duplicate(),
        "crack_targets": _crack_targets.duplicate(),
        "crack_seeds": _crack_seeds.duplicate(),
        "crack_cursor": _crack_cursor,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _angle = float(state.get("angle", _angle))
    _tilt = float(state.get("tilt", _tilt))
    _angle_velocity = float(state.get("angle_velocity", _angle_velocity))
    _tilt_velocity = float(state.get("tilt_velocity", _tilt_velocity))
    _target_angle = float(state.get("target_angle", _target_angle))
    _target_tilt = float(state.get("target_tilt", _target_tilt))
    _target_index = int(state.get("target_index", _target_index))
    var v: Variant = state.get("crack_positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 4: _crack_positions = (v as PackedVector2Array).duplicate()
    v = state.get("crack_strength", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 4: _crack_strength = (v as PackedFloat32Array).duplicate()
    v = state.get("crack_targets", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 4: _crack_targets = (v as PackedFloat32Array).duplicate()
    v = state.get("crack_seeds", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 4: _crack_seeds = (v as PackedFloat32Array).duplicate()
    _crack_cursor = int(state.get("crack_cursor", _crack_cursor))
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "orientation": Vector2(_angle, _tilt),
        "fracture_energy": _crack_strength[0] + _crack_strength[1] + _crack_strength[2] + _crack_strength[3],
        "render_mode": "raymarch_volume",
    }


func _draw() -> void:
    pass
