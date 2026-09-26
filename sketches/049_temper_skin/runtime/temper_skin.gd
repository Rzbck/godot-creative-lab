extends "res://sketches/_shared/design_sketch_base.gd"

const SPOT_COUNT: int = 6

@export_range(0.2, 2.0, 0.01) var torch_heat: float = 1.18
@export_range(0.04, 1.8, 0.01) var cooling: float = 0.34
@export_range(0.1, 1.5, 0.01) var conduction: float = 0.64
@export_range(0.0, 1.0, 0.01) var oxide_memory: float = 0.86
@export_range(0.0, 2.0, 0.01) var buckle: float = 0.72
@export_range(24.0, 190.0, 1.0) var torch_size: float = 104.0
@export_range(0.12, 1.25, 0.01) var quench_threshold: float = 0.68
@export_range(0.0, 1.5, 0.01) var furnace_drive: float = 0.52

var _positions := PackedVector2Array([
    Vector2(310.0, 238.0), Vector2(858.0, 202.0), Vector2(710.0, 504.0),
    Vector2(640.0, 360.0), Vector2(640.0, 360.0), Vector2(640.0, 360.0),
])
var _targets := PackedVector2Array([
    Vector2(270.0, 280.0), Vector2(930.0, 250.0), Vector2(650.0, 540.0),
    Vector2(640.0, 360.0), Vector2(640.0, 360.0), Vector2(640.0, 360.0),
])
var _heat := PackedFloat32Array([0.82, 0.64, 0.48, 0.0, 0.0, 0.0])
var _oxide := PackedFloat32Array([0.72, 0.46, 0.28, 0.0, 0.0, 0.0])
var _target_heat := PackedFloat32Array([0.82, 0.64, 0.48, 0.0, 0.0, 0.0])
var _active_spot: int = -1
var _quenching: bool = false
var _pointer_was_down: bool = false
var _event_counter: int = 59
var _target_timer: float = 2.4

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _push_shader()


func reset_state() -> void:
    _positions = PackedVector2Array([
        Vector2(310.0, 238.0), Vector2(858.0, 202.0), Vector2(710.0, 504.0),
        Vector2(640.0, 360.0), Vector2(640.0, 360.0), Vector2(640.0, 360.0),
    ])
    _targets = PackedVector2Array([
        Vector2(270.0, 280.0), Vector2(930.0, 250.0), Vector2(650.0, 540.0),
        Vector2(640.0, 360.0), Vector2(640.0, 360.0), Vector2(640.0, 360.0),
    ])
    _heat = PackedFloat32Array([0.82, 0.64, 0.48, 0.0, 0.0, 0.0])
    _oxide = PackedFloat32Array([0.72, 0.46, 0.28, 0.0, 0.0, 0.0])
    _target_heat = PackedFloat32Array([0.82, 0.64, 0.48, 0.0, 0.0, 0.0])
    _active_spot = -1
    _quenching = false
    _event_counter = 59
    _target_timer = 2.4
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"torch_heat","label":"TORCH HEAT","type":"float","min":0.2,"max":2.0,"step":0.01},
        {"id":"cooling","label":"COOLING","type":"float","min":0.04,"max":1.8,"step":0.01},
        {"id":"conduction","label":"CONDUCTION","type":"float","min":0.1,"max":1.5,"step":0.01},
        {"id":"oxide_memory","label":"OXIDE MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"buckle","label":"THERMAL BUCKLE","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"torch_size","label":"TORCH SIZE","type":"float","min":24.0,"max":190.0,"step":1.0},
        {"id":"quench_threshold","label":"QUENCH THRESHOLD","type":"float","min":0.12,"max":1.25,"step":0.01},
        {"id":"furnace_drive","label":"FURNACE DRIVE","type":"float","min":0.0,"max":1.5,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "torch_heat": return torch_heat
        "cooling": return cooling
        "conduction": return conduction
        "oxide_memory": return oxide_memory
        "buckle": return buckle
        "torch_size": return torch_size
        "quench_threshold": return quench_threshold
        "furnace_drive": return furnace_drive
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "torch_heat": torch_heat = clampf(float(value), 0.2, 2.0)
        "cooling": cooling = clampf(float(value), 0.04, 1.8)
        "conduction": conduction = clampf(float(value), 0.1, 1.5)
        "oxide_memory": oxide_memory = clampf(float(value), 0.0, 1.0)
        "buckle": buckle = clampf(float(value), 0.0, 2.0)
        "torch_size": torch_size = clampf(float(value), 24.0, 190.0)
        "quench_threshold": quench_threshold = clampf(float(value), 0.12, 1.25)
        "furnace_drive": furnace_drive = clampf(float(value), 0.0, 1.5)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    if pointer_down and not _pointer_was_down:
        _quenching = _sample_heat(pointer_position) >= quench_threshold
        if _quenching:
            _quench_at(pointer_position, 0.24)
            _active_spot = -1
        else:
            _active_spot = 3 + (_event_counter % 3)
            _positions[_active_spot] = pointer_position
            _targets[_active_spot] = pointer_position
            _heat[_active_spot] = maxf(_heat[_active_spot], torch_heat)
            _oxide[_active_spot] = maxf(_oxide[_active_spot], 0.22)
    elif pointer_down:
        if _quenching:
            _quench_at(pointer_position, 0.48)
        elif _active_spot >= 0:
            _positions[_active_spot] = pointer_position
            _targets[_active_spot] = pointer_position
            _heat[_active_spot] = maxf(_heat[_active_spot], torch_heat)
            _oxide[_active_spot] = clampf(_oxide[_active_spot] + 0.018, 0.0, 1.6)
    elif _pointer_was_down:
        _active_spot = -1
        _quenching = false
    _pointer_was_down = pointer_down
    _push_shader()


func _sample_heat(position: Vector2) -> float:
    var total := 0.0
    var radius := maxf(20.0, torch_size * (0.72 + conduction * 0.42))
    for i: int in range(SPOT_COUNT):
        var distance := position.distance_to(_positions[i])
        total += _heat[i] * exp(-distance * distance / (radius * radius))
    return total


func _quench_at(position: Vector2, strength: float) -> void:
    var radius := torch_size * 1.65
    for i: int in range(SPOT_COUNT):
        var distance := position.distance_to(_positions[i])
        if distance >= radius:
            continue
        var falloff := 1.0 - distance / radius
        _heat[i] *= maxf(0.04, 1.0 - strength * falloff * 1.6)
        _oxide[i] *= maxf(0.72, 1.0 - strength * falloff * 0.22)


func _update_source_simulation(delta: float) -> void:
    _target_timer -= delta
    if _target_timer <= 0.0:
        _event_counter += 1
        _target_timer = 1.8 + _hash01i(_event_counter * 61 + 7) * 4.2
        var index := _event_counter % 3
        _targets[index] = Vector2(
            lerpf(180.0, 1090.0, _hash01i(_event_counter * 79 + 13)),
            lerpf(120.0, 600.0, _hash01i(_event_counter * 101 + 17))
        )
        _target_heat[index] = lerpf(0.32, 1.0, _hash01i(_event_counter * 127 + 29))

    for i: int in range(3):
        _positions[i] = _positions[i].lerp(_targets[i], clampf(delta * (0.05 + furnace_drive * 0.10), 0.0, 0.15))
        var desired_heat := _target_heat[i] * furnace_drive
        _heat[i] = lerpf(_heat[i], desired_heat, clampf(delta * (0.12 + furnace_drive * 0.18), 0.0, 0.18))

    var next_heat := _heat.duplicate()
    var conduction_radius := torch_size * (1.1 + conduction * 1.2)
    for i: int in range(SPOT_COUNT):
        for j: int in range(i + 1, SPOT_COUNT):
            var distance := _positions[i].distance_to(_positions[j])
            if distance > conduction_radius:
                continue
            var coupling := (1.0 - distance / conduction_radius) * conduction * delta * 0.42
            var transfer := (_heat[i] - _heat[j]) * coupling
            next_heat[i] -= transfer
            next_heat[j] += transfer

    var oxide_decay := lerpf(0.48, 0.004, oxide_memory)
    for i: int in range(SPOT_COUNT):
        _heat[i] = maxf(0.0, next_heat[i] * exp(-delta * cooling * (0.28 if i < 3 else 0.72)))
        _oxide[i] = clampf(_oxide[i] + _heat[i] * delta * 0.045 - delta * oxide_decay, 0.0, 1.8)

    _push_shader()


func _push_shader() -> void:
    if not is_instance_valid(_surface):
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    for i: int in range(SPOT_COUNT):
        var packed := Vector4(
            _positions[i].x / DESIGN_SIZE.x,
            _positions[i].y / DESIGN_SIZE.y,
            _heat[i],
            _oxide[i]
        )
        material.set_shader_parameter("u_spot%d" % i, packed)
    material.set_shader_parameter("u_radius", torch_size / DESIGN_SIZE.y)
    material.set_shader_parameter("u_conduction", conduction)
    material.set_shader_parameter("u_buckle", buckle)
    material.set_shader_parameter("u_oxide", lerpf(0.25, 1.2, oxide_memory))
    material.set_shader_parameter("u_furnace", furnace_drive)


func _draw() -> void:
    pass


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "targets": _targets.duplicate(),
        "heat": _heat.duplicate(),
        "oxide": _oxide.duplicate(),
        "target_heat": _target_heat.duplicate(),
        "event_counter": _event_counter,
        "target_timer": _target_timer,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == SPOT_COUNT: _positions = (v as PackedVector2Array).duplicate()
    v = state.get("targets", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == SPOT_COUNT: _targets = (v as PackedVector2Array).duplicate()
    v = state.get("heat", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == SPOT_COUNT: _heat = (v as PackedFloat32Array).duplicate()
    v = state.get("oxide", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == SPOT_COUNT: _oxide = (v as PackedFloat32Array).duplicate()
    v = state.get("target_heat", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == SPOT_COUNT: _target_heat = (v as PackedFloat32Array).duplicate()
    _event_counter = int(state.get("event_counter", _event_counter))
    _target_timer = float(state.get("target_timer", _target_timer))
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "sample_heat_at_pointer": _sample_heat(pointer_position),
        "quenching": _quenching,
        "render_mode": "analytic_temper_metal",
    }
