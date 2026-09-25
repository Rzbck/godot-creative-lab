extends "res://sketches/_shared/design_sketch_base.gd"

@export_range(0.0, 1.6, 0.01) var field_strength: float = 0.92
@export_range(40.0, 360.0, 1.0) var magnet_radius: float = 190.0
@export_range(0.05, 1.0, 0.01) var viscosity: float = 0.46
@export_range(0.0, 1.0, 0.01) var surface_tension: float = 0.48
@export_range(0.5, 5.0, 0.05) var peak_sharpness: float = 2.4
@export_range(0.0, 1.5, 0.01) var mode_coupling: float = 0.74
@export_range(0.0, 1.0, 0.01) var hysteresis: float = 0.58
@export_range(0.1, 2.0, 0.01) var relaxation: float = 0.82

var _magnet_pos := Vector2(640.0, 360.0)
var _field_memory := 0.0
var _instability := 0.0
var _last_magnet_pos := Vector2(640.0, 360.0)

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"field_strength","label":"FIELD STRENGTH","type":"float","min":0.0,"max":1.6,"step":0.01},
        {"id":"magnet_radius","label":"MAGNET RADIUS","type":"float","min":40.0,"max":360.0,"step":1.0},
        {"id":"viscosity","label":"VISCOSITY","type":"float","min":0.05,"max":1.0,"step":0.01},
        {"id":"surface_tension","label":"SURFACE TENSION","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"peak_sharpness","label":"PEAK SHARPNESS","type":"float","min":0.5,"max":5.0,"step":0.05},
        {"id":"mode_coupling","label":"MODE COUPLING","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"hysteresis","label":"HYSTERESIS","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"relaxation","label":"RELAXATION","type":"float","min":0.1,"max":2.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "field_strength": return field_strength
        "magnet_radius": return magnet_radius
        "viscosity": return viscosity
        "surface_tension": return surface_tension
        "peak_sharpness": return peak_sharpness
        "mode_coupling": return mode_coupling
        "hysteresis": return hysteresis
        "relaxation": return relaxation
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "field_strength": field_strength = clampf(float(value), 0.0, 1.6)
        "magnet_radius": magnet_radius = clampf(float(value), 40.0, 360.0)
        "viscosity": viscosity = clampf(float(value), 0.05, 1.0)
        "surface_tension": surface_tension = clampf(float(value), 0.0, 1.0)
        "peak_sharpness": peak_sharpness = clampf(float(value), 0.5, 5.0)
        "mode_coupling": mode_coupling = clampf(float(value), 0.0, 1.5)
        "hysteresis": hysteresis = clampf(float(value), 0.0, 1.0)
        "relaxation": relaxation = clampf(float(value), 0.1, 2.0)
        _: return
    _push_shader()


func _update_source_simulation(delta: float) -> void:
    var auto_target := Vector2(
        640.0 + cos(sketch_time * 0.19) * 310.0,
        360.0 + sin(sketch_time * 0.137) * 205.0
    )
    var target := pointer_position if pointer_down else auto_target
    var follow := lerpf(5.2, 1.0, viscosity)
    _magnet_pos = _magnet_pos.lerp(target, clampf(delta * follow, 0.0, 1.0))

    var motion := _magnet_pos.distance_to(_last_magnet_pos) / maxf(delta, 0.0001)
    _last_magnet_pos = _magnet_pos
    var threshold := 0.54 + surface_tension * 0.23
    var drive := field_strength + (0.12 if pointer_down else 0.0) + clampf(motion / 1600.0, 0.0, 0.12)
    var desired := smoothstep(threshold - 0.08, threshold + 0.16, drive)
    if desired < _instability:
        desired = lerpf(desired, _instability, hysteresis * 0.72)
    var relax_speed := lerpf(0.45, 3.2, relaxation / 2.0)
    _instability = lerpf(_instability, desired, clampf(delta * relax_speed, 0.0, 1.0))

    var memory_target := 1.0 if pointer_down else 0.0
    var memory_speed := lerpf(0.28, 1.4, 1.0 - viscosity)
    _field_memory = lerpf(_field_memory, memory_target, clampf(delta * memory_speed, 0.0, 1.0))
    _push_shader()


func _push_shader() -> void:
    if not is_instance_valid(_surface):
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_time", sketch_time)
    material.set_shader_parameter("u_field_strength", field_strength)
    material.set_shader_parameter("u_magnet_pos", _magnet_pos / DESIGN_SIZE)
    material.set_shader_parameter("u_magnet_radius", magnet_radius / DESIGN_SIZE.x)
    material.set_shader_parameter("u_surface_tension", surface_tension)
    material.set_shader_parameter("u_viscosity", viscosity)
    material.set_shader_parameter("u_peak_sharpness", peak_sharpness)
    material.set_shader_parameter("u_mode_coupling", mode_coupling)
    material.set_shader_parameter("u_hysteresis", hysteresis)
    material.set_shader_parameter("u_instability", _instability)
    material.set_shader_parameter("u_memory", _field_memory)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "magnet_pos": _magnet_pos,
        "last_magnet_pos": _last_magnet_pos,
        "field_memory": _field_memory,
        "instability": _instability,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var p: Variant = state.get("magnet_pos", _magnet_pos)
    if p is Vector2: _magnet_pos = p as Vector2
    var lp: Variant = state.get("last_magnet_pos", _last_magnet_pos)
    if lp is Vector2: _last_magnet_pos = lp as Vector2
    _field_memory = float(state.get("field_memory", _field_memory))
    _instability = float(state.get("instability", _instability))
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    return {"instability": _instability, "field_memory": _field_memory, "render_mode":"single_shader_pass"}


func _draw() -> void:
    pass
