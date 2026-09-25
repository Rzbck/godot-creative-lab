extends "res://sketches/_shared/design_sketch_base.gd"

@export_range(0.0, 1.8, 0.01) var drive: float = 0.92
@export_range(0.4, 1.8, 0.01) var frequency: float = 1.0
@export_range(0.02, 0.95, 0.01) var damping: float = 0.34
@export_range(0.0, 1.5, 0.01) var capillarity: float = 0.72
@export_range(0.2, 1.5, 0.01) var depth: float = 0.76
@export_range(0.0, 1.5, 0.01) var mode_coupling: float = 0.68
@export_range(0.04, 0.55, 0.01) var resonance_width: float = 0.18
@export_range(0.0, 1.2, 0.01) var chirp: float = 0.22

var _amplitudes := PackedFloat32Array([0.12, 0.08, 0.04, 0.03])
var _phases := PackedFloat32Array([0.0, 1.1, 2.2, 0.4])
var _touch_impulse := 0.0
var _touch_pos := Vector2(640.0, 360.0)
var _forcing_phase := 0.0
var _chirp_offset := 0.0
var _chirp_target := 0.0
var _chirp_age := 0.0
var _chirp_duration := 9.0
var _chirp_index := 0

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _select_next_chirp_target()
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"drive","label":"DRIVE","type":"float","min":0.0,"max":1.8,"step":0.01},
        {"id":"frequency","label":"FREQUENCY","type":"float","min":0.4,"max":1.8,"step":0.01},
        {"id":"damping","label":"DAMPING","type":"float","min":0.02,"max":0.95,"step":0.01},
        {"id":"capillarity","label":"CAPILLARITY","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"depth","label":"DEPTH","type":"float","min":0.2,"max":1.5,"step":0.01},
        {"id":"mode_coupling","label":"MODE COUPLING","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"resonance_width","label":"RESONANCE WIDTH","type":"float","min":0.04,"max":0.55,"step":0.01},
        {"id":"chirp","label":"CHIRP","type":"float","min":0.0,"max":1.2,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "drive": return drive
        "frequency": return frequency
        "damping": return damping
        "capillarity": return capillarity
        "depth": return depth
        "mode_coupling": return mode_coupling
        "resonance_width": return resonance_width
        "chirp": return chirp
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "drive": drive = clampf(float(value), 0.0, 1.8)
        "frequency": frequency = clampf(float(value), 0.4, 1.8)
        "damping": damping = clampf(float(value), 0.02, 0.95)
        "capillarity": capillarity = clampf(float(value), 0.0, 1.5)
        "depth": depth = clampf(float(value), 0.2, 1.5)
        "mode_coupling": mode_coupling = clampf(float(value), 0.0, 1.5)
        "resonance_width": resonance_width = clampf(float(value), 0.04, 0.55)
        "chirp": chirp = clampf(float(value), 0.0, 1.2)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    if pointer_active:
        _touch_pos = pointer_position
    if pointer_down:
        _touch_impulse = minf(1.0, _touch_impulse + 0.16)


func _select_next_chirp_target() -> void:
    _chirp_index += 1
    var key := float(_chirp_index)
    _chirp_target = hash01(key * 19.37 + 5.1) * 2.0 - 1.0
    _chirp_duration = lerpf(6.0, 17.0, hash01(key * 7.41 + 12.8))
    _chirp_age = 0.0


func _update_source_simulation(delta: float) -> void:
    # TEMPORAL_INTENT: Faraday forcing is physically periodic. The periodic
    # phase drives competing modal state; the visible surface is reconstructed
    # from those modes rather than receiving decorative clock wobble.
    _chirp_age += delta
    if _chirp_age >= _chirp_duration:
        _select_next_chirp_target()
    _chirp_offset = lerpf(_chirp_offset, _chirp_target, clampf(delta * 0.22, 0.0, 1.0))
    var swept_frequency := frequency + _chirp_offset * chirp * 0.16
    _forcing_phase = fposmod(_forcing_phase + delta * swept_frequency * TAU, TAU)

    var mode_frequency := PackedFloat32Array([0.72, 0.96, 1.18, 1.42])
    var old := _amplitudes.duplicate()

    for i: int in range(4):
        var detune := (swept_frequency - mode_frequency[i]) / maxf(0.02, resonance_width)
        var resonance := exp(-detune * detune)
        var threshold := 0.28 + damping * 0.34 + float(i) * 0.035
        var forcing := maxf(0.0, drive * resonance - threshold)
        var neighbours := 0.0
        for j: int in range(4):
            if j != i:
                neighbours += old[j]
        neighbours /= 3.0
        var coupling_force := (neighbours - old[i]) * mode_coupling * 0.17
        var saturation := old[i] * old[i] * (0.45 + capillarity * 0.24)
        var da := forcing * 1.25 + coupling_force + _touch_impulse * (0.13 + float(i) * 0.025) - damping * old[i] * 0.88 - saturation
        _amplitudes[i] = clampf(old[i] + da * delta, 0.0, 1.35)
        _phases[i] = fposmod(_phases[i] + delta * mode_frequency[i] * TAU * 0.5 * (0.78 + depth * 0.22), TAU)

    _touch_impulse *= pow(lerpf(0.90, 0.975, damping), delta * 60.0)
    if pointer_down:
        _touch_impulse = minf(1.0, _touch_impulse + delta * 1.8)
    _push_shader()


func _push_shader() -> void:
    if not is_instance_valid(_surface):
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_amps", Vector4(_amplitudes[0], _amplitudes[1], _amplitudes[2], _amplitudes[3]))
    material.set_shader_parameter("u_phases", Vector4(_phases[0], _phases[1], _phases[2], _phases[3]))
    material.set_shader_parameter("u_drive", drive)
    material.set_shader_parameter("u_damping", damping)
    material.set_shader_parameter("u_capillarity", capillarity)
    material.set_shader_parameter("u_depth", depth)
    material.set_shader_parameter("u_mode_coupling", mode_coupling)
    material.set_shader_parameter("u_touch_pos", _touch_pos / DESIGN_SIZE)
    material.set_shader_parameter("u_touch_impulse", _touch_impulse)
    material.set_shader_parameter("u_forcing_phase", _forcing_phase)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "amplitudes": _amplitudes.duplicate(),
        "phases": _phases.duplicate(),
        "touch_impulse": _touch_impulse,
        "touch_pos": _touch_pos,
        "forcing_phase": _forcing_phase,
        "chirp_offset": _chirp_offset,
        "chirp_target": _chirp_target,
        "chirp_age": _chirp_age,
        "chirp_duration": _chirp_duration,
        "chirp_index": _chirp_index,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var av: Variant = state.get("amplitudes", PackedFloat32Array())
    if av is PackedFloat32Array and (av as PackedFloat32Array).size() == 4:
        _amplitudes = (av as PackedFloat32Array).duplicate()
    var pv: Variant = state.get("phases", PackedFloat32Array())
    if pv is PackedFloat32Array and (pv as PackedFloat32Array).size() == 4:
        _phases = (pv as PackedFloat32Array).duplicate()
    _touch_impulse = float(state.get("touch_impulse", _touch_impulse))
    var tp: Variant = state.get("touch_pos", _touch_pos)
    if tp is Vector2: _touch_pos = tp as Vector2
    _forcing_phase = float(state.get("forcing_phase", _forcing_phase))
    _chirp_offset = float(state.get("chirp_offset", _chirp_offset))
    _chirp_target = float(state.get("chirp_target", _chirp_target))
    _chirp_age = float(state.get("chirp_age", _chirp_age))
    _chirp_duration = float(state.get("chirp_duration", _chirp_duration))
    _chirp_index = int(state.get("chirp_index", _chirp_index))
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "modal_energy": _amplitudes[0] + _amplitudes[1] + _amplitudes[2] + _amplitudes[3],
        "touch_impulse": _touch_impulse,
        "chirp_offset": _chirp_offset,
        "render_mode":"single_shader_pass",
    }


func _draw() -> void:
    pass
