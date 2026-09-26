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
# Visual phases are deliberately unwrapped. The old implementation wrapped the
# forcing phase and then multiplied that wrapped value by fractional factors in
# the shader, producing a visible cut every cycle. Unwrapped modal phases keep
# every rendered harmonic continuous indefinitely.
var _phases := PackedFloat32Array([0.0, 1.1, 2.2, 0.4])
var _touch_energy := 0.0
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
        # Interaction now enters the physical modal state only. There is no
        # direct click-shaped height patch in the shader, so press/release cannot
        # reveal a compositing seam or pop an unrelated radial effect on screen.
        _touch_energy = minf(1.0, _touch_energy + 0.12)


func _select_next_chirp_target() -> void:
    _chirp_index += 1
    var key := float(_chirp_index)
    _chirp_target = hash01(key * 19.37 + 5.1) * 2.0 - 1.0
    _chirp_duration = lerpf(6.0, 17.0, hash01(key * 7.41 + 12.8))
    _chirp_age = 0.0


func _touch_mode_weight(index: int) -> float:
    var p := (_touch_pos / DESIGN_SIZE - Vector2(0.5, 0.5)) * 2.0
    match index:
        0:
            return 0.42 + absf(p.x) * 0.58
        1:
            return 0.42 + absf(p.y) * 0.58
        2:
            return 0.42 + absf((p.x + p.y) * 0.7071) * 0.58
        _:
            return 0.42 + absf((p.x - p.y * 0.618) * 0.85) * 0.58


func _update_source_simulation(delta: float) -> void:
    # TEMPORAL_INTENT: Faraday excitation is a genuinely periodic physical pump.
    # The pump changes modal energy in this state integrator. The shader never
    # receives the wrapped forcing phase, so no visible geometry can jump when
    # this internal phase crosses 2π.
    _chirp_age += delta
    if _chirp_age >= _chirp_duration:
        _select_next_chirp_target()
    _chirp_offset = lerpf(_chirp_offset, _chirp_target, clampf(delta * 0.22, 0.0, 1.0))
    var swept_frequency := frequency + _chirp_offset * chirp * 0.16
    _forcing_phase = fposmod(_forcing_phase + delta * swept_frequency * TAU, TAU)
    var pump := 0.5 + 0.5 * sin(_forcing_phase)

    var mode_frequency := PackedFloat32Array([0.72, 0.96, 1.18, 1.42])
    var old := _amplitudes.duplicate()

    for i: int in range(4):
        var detune := (swept_frequency - mode_frequency[i]) / maxf(0.02, resonance_width)
        var resonance := exp(-detune * detune)
        var threshold := 0.23 + damping * 0.30 + float(i) * 0.028
        var physical_drive := drive * resonance * (0.22 + pump * 0.78)
        var forcing := maxf(0.0, physical_drive - threshold)

        var neighbours := 0.0
        for j: int in range(4):
            if j != i:
                neighbours += old[j]
        neighbours /= 3.0

        var coupling_force := (neighbours - old[i]) * mode_coupling * 0.17
        var saturation := old[i] * old[i] * (0.45 + capillarity * 0.24)
        var touch_drive := _touch_energy * _touch_mode_weight(i) * (0.12 + float(i) * 0.018)
        var da := forcing * 1.18 + coupling_force + touch_drive - damping * old[i] * 0.88 - saturation
        _amplitudes[i] = clampf(old[i] + da * delta, 0.0, 1.35)

        # Keep visual phase continuous; do not fposmod() this value. Multiple
        # non-integer harmonics in the material can therefore remain continuous.
        var modal_speed := mode_frequency[i] * TAU * 0.5 * (0.78 + depth * 0.22)
        var touch_detune := _touch_energy * (_touch_mode_weight(i) - 0.68) * 0.24
        _phases[i] += delta * (modal_speed + touch_detune)

    var release_rate := lerpf(1.8, 0.48, clampf(damping / 0.95, 0.0, 1.0))
    _touch_energy = maxf(0.0, _touch_energy - delta * release_rate)
    if pointer_down:
        _touch_energy = minf(1.0, _touch_energy + delta * 1.35)
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
    material.set_shader_parameter("u_touch_energy", _touch_energy)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "amplitudes": _amplitudes.duplicate(),
        "phases": _phases.duplicate(),
        "touch_energy": _touch_energy,
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
    _touch_energy = float(state.get("touch_energy", _touch_energy))
    var tp: Variant = state.get("touch_pos", _touch_pos)
    if tp is Vector2:
        _touch_pos = tp as Vector2
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
        "touch_energy": _touch_energy,
        "chirp_offset": _chirp_offset,
        "render_mode": "continuous_modal_surface",
    }


func _draw() -> void:
    pass
