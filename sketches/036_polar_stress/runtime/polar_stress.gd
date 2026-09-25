extends "res://sketches/_shared/design_sketch_base.gd"

@export_range(0.35, 2.2, 0.01) var load_gain: float = 1.18
@export_range(0.25, 2.0, 0.01) var glass_thickness: float = 0.92
@export_range(2.0, 18.0, 0.1) var fringe_density: float = 8.4
@export_range(0.0, 1.0, 0.01) var spectral_mix: float = 0.72
@export_range(0.15, 2.2, 0.01) var elasticity: float = 0.86
@export_range(0.2, 3.0, 0.01) var memory: float = 1.42
@export_range(0.0, 1.6, 0.01) var anisotropy: float = 0.58
@export_range(0.35, 2.4, 0.01) var exposure: float = 1.16

var _positions := PackedVector2Array([
    Vector2(0.24, 0.31), Vector2(0.73, 0.24), Vector2(0.66, 0.74), Vector2(0.34, 0.69)
])
var _targets := PackedVector2Array([
    Vector2(0.29, 0.25), Vector2(0.76, 0.36), Vector2(0.61, 0.77), Vector2(0.27, 0.61)
])
var _velocities := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _strengths := PackedFloat32Array([0.62, 0.48, 0.58, 0.42])
var _target_strengths := PackedFloat32Array([0.62, 0.48, 0.58, 0.42])
var _seeds := PackedFloat32Array([0.13, 0.37, 0.63, 0.89])
var _event_counter: int = 4
var _active_load: int = -1
var _was_down: bool = false
var _last_pointer: Vector2 = DESIGN_SIZE * 0.5
var _gesture_velocity: Vector2 = Vector2.ZERO

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"load_gain","label":"LOAD","type":"float","min":0.35,"max":2.2,"step":0.01},
        {"id":"glass_thickness","label":"THICKNESS","type":"float","min":0.25,"max":2.0,"step":0.01},
        {"id":"fringe_density","label":"FRINGE DENSITY","type":"float","min":2.0,"max":18.0,"step":0.1},
        {"id":"spectral_mix","label":"SPECTRAL MIX","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"elasticity","label":"ELASTICITY","type":"float","min":0.15,"max":2.2,"step":0.01},
        {"id":"memory","label":"STRESS MEMORY","type":"float","min":0.2,"max":3.0,"step":0.01},
        {"id":"anisotropy","label":"ANISOTROPY","type":"float","min":0.0,"max":1.6,"step":0.01},
        {"id":"exposure","label":"EXPOSURE","type":"float","min":0.35,"max":2.4,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "load_gain": return load_gain
        "glass_thickness": return glass_thickness
        "fringe_density": return fringe_density
        "spectral_mix": return spectral_mix
        "elasticity": return elasticity
        "memory": return memory
        "anisotropy": return anisotropy
        "exposure": return exposure
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "load_gain": load_gain = clampf(float(value), 0.35, 2.2)
        "glass_thickness": glass_thickness = clampf(float(value), 0.25, 2.0)
        "fringe_density": fringe_density = clampf(float(value), 2.0, 18.0)
        "spectral_mix": spectral_mix = clampf(float(value), 0.0, 1.0)
        "elasticity": elasticity = clampf(float(value), 0.15, 2.2)
        "memory": memory = clampf(float(value), 0.2, 3.0)
        "anisotropy": anisotropy = clampf(float(value), 0.0, 1.6)
        "exposure": exposure = clampf(float(value), 0.35, 2.4)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    var delta_pos := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pos, 0.42)
    _last_pointer = pointer_position

    if pointer_down and not _was_down:
        var uv := (pointer_position / DESIGN_SIZE).clamp(Vector2(0.05, 0.05), Vector2(0.95, 0.95))
        _active_load = _nearest_load(uv)
        _targets[_active_load] = uv
        _target_strengths[_active_load] = minf(1.3, _target_strengths[_active_load] + 0.42)
        _event_counter += 1
        _seeds[_active_load] = _hash01(_event_counter * 97 + _active_load * 23)

    if pointer_down and _active_load >= 0:
        var uv := (pointer_position / DESIGN_SIZE).clamp(Vector2(0.04, 0.04), Vector2(0.96, 0.96))
        _targets[_active_load] = _targets[_active_load].lerp(uv, 0.34)
        _velocities[_active_load] += Vector2(_gesture_velocity.x, _gesture_velocity.y) / DESIGN_SIZE * 0.018
        _target_strengths[_active_load] = minf(1.5, _target_strengths[_active_load] + 0.018)

    if not pointer_down:
        _active_load = -1
    _was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    for i: int in range(4):
        var to_target := _targets[i] - _positions[i]
        _velocities[i] += to_target * (0.55 + elasticity * 0.52) * delta
        _velocities[i] *= exp(-delta * (1.5 + 0.55 / maxf(0.2, memory)))
        _positions[i] += _velocities[i] * delta
        _positions[i] = _positions[i].clamp(Vector2(0.06, 0.07), Vector2(0.94, 0.93))

        var response := clampf(delta * (0.9 + memory * 0.48), 0.0, 1.0)
        _strengths[i] = lerpf(_strengths[i], _target_strengths[i], response)
        _target_strengths[i] = maxf(0.24, _target_strengths[i] - delta * (0.026 / maxf(0.2, memory)))

        if to_target.length() < 0.015 and _velocities[i].length() < 0.01 and i != _active_load:
            _event_counter += 1
            var hx := _hash01(_event_counter * 53 + i * 17)
            var hy := _hash01(_event_counter * 79 + i * 31)
            _targets[i] = Vector2(lerpf(0.14, 0.86, hx), lerpf(0.14, 0.86, hy))
            _target_strengths[i] = lerpf(0.34, 0.82, _hash01(_event_counter * 113 + i * 7))

    _gesture_velocity *= exp(-delta * 7.0)
    _push_shader()


func _nearest_load(uv: Vector2) -> int:
    var best := 0
    var best_distance := INF
    for i: int in range(4):
        var d := uv.distance_squared_to(_positions[i])
        if d < best_distance:
            best_distance = d
            best = i
    return best


func _push_shader() -> void:
    if not is_instance_valid(_surface):
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_load0", Vector4(_positions[0].x, _positions[0].y, _strengths[0], _seeds[0]))
    material.set_shader_parameter("u_load1", Vector4(_positions[1].x, _positions[1].y, _strengths[1], _seeds[1]))
    material.set_shader_parameter("u_load2", Vector4(_positions[2].x, _positions[2].y, _strengths[2], _seeds[2]))
    material.set_shader_parameter("u_load3", Vector4(_positions[3].x, _positions[3].y, _strengths[3], _seeds[3]))
    material.set_shader_parameter("u_load_gain", load_gain)
    material.set_shader_parameter("u_thickness", glass_thickness)
    material.set_shader_parameter("u_fringe_density", fringe_density)
    material.set_shader_parameter("u_spectral_mix", spectral_mix)
    material.set_shader_parameter("u_elasticity", elasticity)
    material.set_shader_parameter("u_anisotropy", anisotropy)
    material.set_shader_parameter("u_exposure", exposure)


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
        "strengths": _strengths.duplicate(),
        "target_strengths": _target_strengths.duplicate(),
        "seeds": _seeds.duplicate(),
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 4: _positions = (v as PackedVector2Array).duplicate()
    v = state.get("targets", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 4: _targets = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 4: _velocities = (v as PackedVector2Array).duplicate()
    v = state.get("strengths", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 4: _strengths = (v as PackedFloat32Array).duplicate()
    v = state.get("target_strengths", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 4: _target_strengths = (v as PackedFloat32Array).duplicate()
    v = state.get("seeds", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == 4: _seeds = (v as PackedFloat32Array).duplicate()
    _event_counter = int(state.get("event_counter", _event_counter))
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "active_load": _active_load,
        "stress_energy": _strengths[0] + _strengths[1] + _strengths[2] + _strengths[3],
        "render_mode": "photoelastic_full_resolution",
    }


func _draw() -> void:
    pass
