extends "res://sketches/_shared/design_sketch_base.gd"

@export_range(12.0, 72.0, 0.5) var line_density: float = 34.0
@export_range(0.08, 1.35, 0.01) var layer_angle: float = 0.48
@export_range(0.0, 1.6, 0.01) var shear: float = 0.28
@export_range(0.0, 2.2, 0.01) var lens_power: float = 0.86
@export_range(0.08, 0.52, 0.01) var aperture: float = 0.29
@export_range(0.1, 1.4, 0.01) var contrast: float = 0.82
@export_range(0.0, 1.0, 0.01) var chroma: float = 0.20
@export_range(0.0, 1.6, 0.01) var drift: float = 0.34

var _anchors := PackedVector2Array([
    Vector2(358.0, 254.0),
    Vector2(914.0, 230.0),
    Vector2(716.0, 520.0),
])
var _base := PackedVector2Array([
    Vector2(358.0, 254.0),
    Vector2(914.0, 230.0),
    Vector2(716.0, 520.0),
])
var _targets := PackedVector2Array([
    Vector2(310.0, 218.0),
    Vector2(968.0, 284.0),
    Vector2(662.0, 548.0),
])
var _velocities := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _grabbed: int = -1
var _pointer_was_down: bool = false
var _last_pointer := Vector2.ZERO
var _target_timer: float = 2.2
var _event_counter: int = 47

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _push_shader()


func reset_state() -> void:
    _anchors = _base.duplicate()
    _targets = PackedVector2Array([
        Vector2(310.0, 218.0),
        Vector2(968.0, 284.0),
        Vector2(662.0, 548.0),
    ])
    _velocities = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
    _grabbed = -1
    _target_timer = 2.2
    _event_counter = 47
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"line_density","label":"LINE DENSITY","type":"float","min":12.0,"max":72.0,"step":0.5},
        {"id":"layer_angle","label":"LAYER ANGLE","type":"float","min":0.08,"max":1.35,"step":0.01},
        {"id":"shear","label":"SHEAR","type":"float","min":0.0,"max":1.6,"step":0.01},
        {"id":"lens_power","label":"LENS POWER","type":"float","min":0.0,"max":2.2,"step":0.01},
        {"id":"aperture","label":"APERTURE","type":"float","min":0.08,"max":0.52,"step":0.01},
        {"id":"contrast","label":"INK CONTRAST","type":"float","min":0.1,"max":1.4,"step":0.01},
        {"id":"chroma","label":"REGISTRATION","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"drift","label":"APERTURE DRIFT","type":"float","min":0.0,"max":1.6,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "line_density": return line_density
        "layer_angle": return layer_angle
        "shear": return shear
        "lens_power": return lens_power
        "aperture": return aperture
        "contrast": return contrast
        "chroma": return chroma
        "drift": return drift
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "line_density": line_density = clampf(float(value), 12.0, 72.0)
        "layer_angle": layer_angle = clampf(float(value), 0.08, 1.35)
        "shear": shear = clampf(float(value), 0.0, 1.6)
        "lens_power": lens_power = clampf(float(value), 0.0, 2.2)
        "aperture": aperture = clampf(float(value), 0.08, 0.52)
        "contrast": contrast = clampf(float(value), 0.1, 1.4)
        "chroma": chroma = clampf(float(value), 0.0, 1.0)
        "drift": drift = clampf(float(value), 0.0, 1.6)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    if pointer_down and not _pointer_was_down:
        _grabbed = _nearest_anchor(pointer_position, 138.0)
        _last_pointer = pointer_position
    elif pointer_down and _grabbed >= 0:
        var delta := pointer_position - _last_pointer
        _anchors[_grabbed] = pointer_position.clamp(Vector2(84.0, 74.0), DESIGN_SIZE - Vector2(84.0, 74.0))
        _targets[_grabbed] = _anchors[_grabbed]
        _velocities[_grabbed] = delta * 7.2
        _last_pointer = pointer_position
        _push_shader()
    elif not pointer_down and _pointer_was_down:
        _grabbed = -1
    _pointer_was_down = pointer_down


func _nearest_anchor(position: Vector2, max_distance: float) -> int:
    var best := -1
    var best_distance := max_distance
    for i: int in range(_anchors.size()):
        var distance := position.distance_to(_anchors[i])
        if distance < best_distance:
            best_distance = distance
            best = i
    return best


func _update_source_simulation(delta: float) -> void:
    _target_timer -= delta
    if _target_timer <= 0.0:
        _event_counter += 1
        _target_timer = 1.8 + _hash01i(_event_counter * 37 + 5) * 3.6
        var index := _event_counter % 3
        var amount := drift * 82.0
        _targets[index] = (_base[index] + Vector2(
            (_hash01i(_event_counter * 71 + 11) - 0.5) * amount * 2.0,
            (_hash01i(_event_counter * 89 + 17) - 0.5) * amount * 1.5
        )).clamp(Vector2(94.0, 84.0), DESIGN_SIZE - Vector2(94.0, 84.0))

    for i: int in range(3):
        if i == _grabbed:
            continue
        var velocity := _velocities[i]
        var spring := 0.38 + drift * 0.54
        velocity += (_targets[i] - _anchors[i]) * spring * delta
        velocity *= exp(-delta * (1.1 + (1.0 - drift * 0.3)))
        _anchors[i] = (_anchors[i] + velocity * delta).clamp(Vector2(84.0, 74.0), DESIGN_SIZE - Vector2(84.0, 74.0))
        _velocities[i] = velocity

    _push_shader()


func _push_shader() -> void:
    if not is_instance_valid(_surface):
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_anchor0", _anchors[0] / DESIGN_SIZE)
    material.set_shader_parameter("u_anchor1", _anchors[1] / DESIGN_SIZE)
    material.set_shader_parameter("u_anchor2", _anchors[2] / DESIGN_SIZE)
    material.set_shader_parameter("u_density", line_density)
    material.set_shader_parameter("u_angle", layer_angle)
    material.set_shader_parameter("u_shear", shear)
    material.set_shader_parameter("u_lens", lens_power)
    material.set_shader_parameter("u_aperture", aperture)
    material.set_shader_parameter("u_contrast", contrast)
    material.set_shader_parameter("u_chroma", chroma)
    material.set_shader_parameter("u_handle", 0.34 if pointer_active else 0.16)


func _draw() -> void:
    pass


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "anchors": _anchors.duplicate(),
        "targets": _targets.duplicate(),
        "velocities": _velocities.duplicate(),
        "target_timer": _target_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("anchors", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 3: _anchors = (v as PackedVector2Array).duplicate()
    v = state.get("targets", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 3: _targets = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 3: _velocities = (v as PackedVector2Array).duplicate()
    _target_timer = float(state.get("target_timer", _target_timer))
    _event_counter = int(state.get("event_counter", _event_counter))
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "grabbed_anchor": _grabbed,
        "render_mode": "full_resolution_analytic_moire",
    }
