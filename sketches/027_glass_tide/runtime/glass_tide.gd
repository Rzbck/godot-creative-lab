extends "res://sketches/_shared/design_sketch_base.gd"

const LENS_COUNT := 4

@export_range(0.2, 3.0, 0.01) var lens_tension: float = 1.08
@export_range(0.1, 0.98, 0.01) var damping: float = 0.80
@export_range(0.2, 3.0, 0.01) var displacement: float = 1.16
@export_range(0.05, 0.95, 0.01) var threshold: float = 0.42
@export_range(0.2, 2.5, 0.01) var refraction: float = 1.05
@export_range(0.0, 1.0, 0.01) var topology_bias: float = 0.58
@export_range(0.05, 1.5, 0.01) var memory: float = 0.64
@export_range(0.3, 3.0, 0.01) var touch_gain: float = 1.22

@onready var _surface: ColorRect = $ShaderSurface
@onready var _material: ShaderMaterial = _surface.material as ShaderMaterial

var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _targets: Array[Vector2] = []
var _radii := PackedFloat32Array()
var _activity := PackedFloat32Array()
var _wave_radius := PackedFloat32Array()
var _wave_amp := PackedFloat32Array()
var _event_clock := 1.2
var _event_index := 0
var _regime := 0.25
var _regime_target := 0.25
var _optical_memory := 0.0
var _press_latch := false


func _ready() -> void:
    super._ready()
    _seed_lenses()
    _apply_shader_state()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"lens_tension", "label":"LENS TENSION", "type":"float", "min":0.2, "max":3.0, "step":0.01},
        {"id":"damping", "label":"DAMPING", "type":"float", "min":0.1, "max":0.98, "step":0.01},
        {"id":"displacement", "label":"WAVE DISPLACEMENT", "type":"float", "min":0.2, "max":3.0, "step":0.01},
        {"id":"threshold", "label":"GLASS THRESHOLD", "type":"float", "min":0.05, "max":0.95, "step":0.01},
        {"id":"refraction", "label":"REFRACTION", "type":"float", "min":0.2, "max":2.5, "step":0.01},
        {"id":"topology_bias", "label":"TOPOLOGY BIAS", "type":"float", "min":0.0, "max":1.0, "step":0.01},
        {"id":"memory", "label":"OPTICAL MEMORY", "type":"float", "min":0.05, "max":1.5, "step":0.01},
        {"id":"touch_gain", "label":"TOUCH GAIN", "type":"float", "min":0.3, "max":3.0, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "lens_tension": return lens_tension
        "damping": return damping
        "displacement": return displacement
        "threshold": return threshold
        "refraction": return refraction
        "topology_bias": return topology_bias
        "memory": return memory
        "touch_gain": return touch_gain
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "lens_tension": lens_tension = clampf(float(value), 0.2, 3.0)
        "damping": damping = clampf(float(value), 0.1, 0.98)
        "displacement": displacement = clampf(float(value), 0.2, 3.0)
        "threshold": threshold = clampf(float(value), 0.05, 0.95)
        "refraction": refraction = clampf(float(value), 0.2, 2.5)
        "topology_bias": topology_bias = clampf(float(value), 0.0, 1.0)
        "memory": memory = clampf(float(value), 0.05, 1.5)
        "touch_gain": touch_gain = clampf(float(value), 0.3, 3.0)
        _: return
    _apply_shader_state()


func _seed_lenses() -> void:
    if not _positions.is_empty():
        return
    _radii.resize(LENS_COUNT)
    _activity.resize(LENS_COUNT)
    _wave_radius.resize(LENS_COUNT)
    _wave_amp.resize(LENS_COUNT)
    for i: int in range(LENS_COUNT):
        var p := Vector2(
            220.0 + float(i % 2) * 700.0 + _hash01(i * 13 + 2) * 120.0,
            190.0 + float(i / 2) * 330.0 + _hash01(i * 23 + 4) * 90.0
        )
        _positions.append(p)
        _targets.append(p + Vector2((_hash01(i * 31 + 7) - 0.5) * 180.0, (_hash01(i * 41 + 8) - 0.5) * 120.0))
        _velocities.append(Vector2.ZERO)
        _radii[i] = 105.0 + _hash01(i * 19 + 5) * 92.0
        _activity[i] = 1.0 if i < 3 else 0.0
        _wave_radius[i] = 0.0
        _wave_amp[i] = 0.0


func _update_source_simulation(delta: float) -> void:
    _seed_lenses()
    var dt := minf(delta, 1.0 / 30.0)

    if pointer_down and not _press_latch:
        _alter_topology_at(pointer_position)
    _press_latch = pointer_down

    _event_clock -= delta
    if _event_clock <= 0.0:
        var index := int(_hash01(_event_index * 47 + 3) * float(LENS_COUNT)) % LENS_COUNT
        _targets[index] = Vector2(
            140.0 + _hash01(_event_index * 59 + 11) * 1000.0,
            100.0 + _hash01(_event_index * 67 + 17) * 520.0
        )
        if _hash01(_event_index * 71 + 19) < 0.34 + topology_bias * 0.38:
            _activity[index] = 1.0 - _activity[index]
        _wave_radius[index] = 0.0
        _wave_amp[index] = 0.42 + _hash01(_event_index * 79 + 23) * 0.45
        _regime_target = _hash01(_event_index * 83 + 29)
        _event_clock = 1.7 + _hash01(_event_index * 97 + 31) * 4.4
        _event_index += 1

    var total_activity := 0.0
    for i: int in range(LENS_COUNT):
        var force := (_targets[i] - _positions[i]) * (0.32 + lens_tension * 0.42)
        for j: int in range(LENS_COUNT):
            if i == j:
                continue
            var delta_p := _positions[i] - _positions[j]
            var distance := maxf(1.0, delta_p.length())
            if distance < 260.0:
                force += delta_p / distance * (260.0 - distance) * 0.28
        _velocities[i] = (_velocities[i] + force * dt) * pow(damping, dt * 60.0)
        _positions[i] += _velocities[i] * dt
        _positions[i].x = clampf(_positions[i].x, 80.0, 1200.0)
        _positions[i].y = clampf(_positions[i].y, 70.0, 650.0)

        _wave_radius[i] += dt * (110.0 + displacement * 85.0)
        _wave_amp[i] = maxf(0.0, _wave_amp[i] - dt * (0.16 + 0.22 / maxf(memory, 0.05)))
        if _wave_radius[i] > 860.0:
            _wave_amp[i] = 0.0
        total_activity += _activity[i] * (0.4 + _wave_amp[i] * 0.6)

    _regime = lerpf(_regime, _regime_target, clampf(dt * (0.45 + memory * 0.35), 0.0, 1.0))
    _optical_memory = lerpf(_optical_memory, total_activity / float(LENS_COUNT), clampf(dt * memory, 0.0, 1.0))
    _apply_shader_state()


func _alter_topology_at(point: Vector2) -> void:
    var nearest := 0
    var nearest_d := INF
    for i: int in range(LENS_COUNT):
        var d := point.distance_squared_to(_positions[i])
        if d < nearest_d:
            nearest_d = d
            nearest = i
    _activity[nearest] = 1.0 - _activity[nearest]
    _targets[nearest] = point
    _wave_radius[nearest] = 0.0
    _wave_amp[nearest] = clampf(0.62 * touch_gain, 0.0, 1.6)
    _velocities[nearest] += (point - DESIGN_SIZE * 0.5).normalized() * touch_gain * 90.0
    _regime_target = clampf(_regime_target + (0.22 if _activity[nearest] > 0.5 else -0.18), 0.0, 1.0)


func _apply_shader_state() -> void:
    if not is_instance_valid(_material) or _positions.size() < LENS_COUNT:
        return
    for i: int in range(LENS_COUNT):
        var lens := Vector4(
            _positions[i].x / DESIGN_SIZE.x,
            _positions[i].y / DESIGN_SIZE.y,
            _radii[i] / DESIGN_SIZE.x,
            _activity[i]
        )
        var wave := Vector4(
            _positions[i].x / DESIGN_SIZE.x,
            _positions[i].y / DESIGN_SIZE.y,
            _wave_radius[i] / DESIGN_SIZE.x,
            _wave_amp[i]
        )
        _material.set_shader_parameter("u_lens%d" % i, lens)
        _material.set_shader_parameter("u_wave%d" % i, wave)
    _material.set_shader_parameter("u_threshold", threshold)
    _material.set_shader_parameter("u_displacement", displacement)
    _material.set_shader_parameter("u_refraction", refraction)
    _material.set_shader_parameter("u_regime", _regime)
    _material.set_shader_parameter("u_memory", _optical_memory)


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(), "velocities": _velocities.duplicate(), "targets": _targets.duplicate(),
        "activity": _activity.duplicate(), "wave_radius": _wave_radius.duplicate(), "wave_amp": _wave_amp.duplicate(),
        "event_clock": _event_clock, "event_index": _event_index,
        "regime": _regime, "regime_target": _regime_target, "optical_memory": _optical_memory,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", [])
    if v is Array: _positions.assign(v as Array)
    v = state.get("velocities", [])
    if v is Array: _velocities.assign(v as Array)
    v = state.get("targets", [])
    if v is Array: _targets.assign(v as Array)
    v = state.get("activity", PackedFloat32Array())
    if v is PackedFloat32Array: _activity = (v as PackedFloat32Array).duplicate()
    v = state.get("wave_radius", PackedFloat32Array())
    if v is PackedFloat32Array: _wave_radius = (v as PackedFloat32Array).duplicate()
    v = state.get("wave_amp", PackedFloat32Array())
    if v is PackedFloat32Array: _wave_amp = (v as PackedFloat32Array).duplicate()
    _event_clock = float(state.get("event_clock", _event_clock))
    _event_index = int(state.get("event_index", _event_index))
    _regime = float(state.get("regime", _regime))
    _regime_target = float(state.get("regime_target", _regime_target))
    _optical_memory = float(state.get("optical_memory", _optical_memory))
    _apply_shader_state()
