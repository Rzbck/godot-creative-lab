extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.010, 0.016, 0.030, 1.0)
const INK: Color = Color(0.90, 0.92, 0.88, 1.0)
const ACCENT: Color = Color(1.0, 0.72, 0.06, 1.0)
const COOL: Color = Color(0.20, 0.42, 0.72, 1.0)
const ROWS: int = 11
const CHORUS_TEXT: String = "I AM HERE / I AM HERE / I AM HERE"

@export_range(0.0, 2.0, 0.01) var cohesion: float = 0.82
@export_range(0.0, 1.5, 0.01) var unrest: float = 0.48
@export_range(0.2, 3.0, 0.01) var individuality: float = 1.0
@export_range(0.1, 2.0, 0.01) var reabsorb_speed: float = 0.58
@export_range(0.0, 2.0, 0.01) var touch_gravity: float = 1.0
@export_range(0.2, 1.0, 0.01) var contrast: float = 0.78

var _phases: PackedFloat32Array = PackedFloat32Array()
var _frequencies: PackedFloat32Array = PackedFloat32Array()
var _offsets: PackedFloat32Array = PackedFloat32Array()
var _velocities: PackedFloat32Array = PackedFloat32Array()
var _focus_row: int = 5
var _focus_energy: float = 0.0
var _gesture_velocity: Vector2 = Vector2.ZERO
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false


func _ready() -> void:
    super._ready()
    _ensure_population()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "cohesion", "label": "COHESION", "type": "float", "min": 0.0, "max": 2.0, "step": 0.01},
        {"id": "unrest", "label": "UNREST", "type": "float", "min": 0.0, "max": 1.5, "step": 0.01},
        {"id": "individuality", "label": "INDIVIDUALITY", "type": "float", "min": 0.2, "max": 3.0, "step": 0.01},
        {"id": "reabsorb_speed", "label": "REABSORPTION", "type": "float", "min": 0.1, "max": 2.0, "step": 0.01},
        {"id": "touch_gravity", "label": "TOUCH GRAVITY", "type": "float", "min": 0.0, "max": 2.0, "step": 0.01},
        {"id": "contrast", "label": "CONTRAST", "type": "float", "min": 0.2, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "cohesion": return cohesion
        "unrest": return unrest
        "individuality": return individuality
        "reabsorb_speed": return reabsorb_speed
        "touch_gravity": return touch_gravity
        "contrast": return contrast
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "cohesion": cohesion = clampf(float(value), 0.0, 2.0)
        "unrest": unrest = clampf(float(value), 0.0, 1.5)
        "individuality": individuality = clampf(float(value), 0.2, 3.0)
        "reabsorb_speed": reabsorb_speed = clampf(float(value), 0.1, 2.0)
        "touch_gravity": touch_gravity = clampf(float(value), 0.0, 2.0)
        "contrast": contrast = clampf(float(value), 0.2, 1.0)
        _: return
    queue_redraw()


func _ensure_population() -> void:
    if _phases.size() == ROWS:
        return
    _phases.resize(ROWS)
    _frequencies.resize(ROWS)
    _offsets.resize(ROWS)
    _velocities.resize(ROWS)
    for row: int in range(ROWS):
        _phases[row] = hash01(float(row) * 9.7) * TAU
        _frequencies[row] = 0.32 + hash01(float(row) * 4.1 + 8.0) * 0.16
        _offsets[row] = (hash01(float(row) * 7.1 + 2.0) - 0.5) * 40.0
        _velocities[row] = 0.0


func _update_source_simulation(delta: float) -> void:
    _ensure_population()
    var mean_sin: float = 0.0
    var mean_cos: float = 0.0
    for phase: float in _phases:
        mean_sin += sin(phase)
        mean_cos += cos(phase)
    var mean_phase: float = atan2(mean_sin, mean_cos)

    for row: int in range(ROWS):
        var phase_pull: float = sin(mean_phase - _phases[row]) * cohesion * 0.32
        var autonomous_noise: float = sin(sketch_time * 0.19 + float(row) * 1.47) * unrest * 0.08
        _phases[row] += (_frequencies[row] + phase_pull + autonomous_noise) * delta

        var home: float = sin(_phases[row] * 0.73 + float(row) * 0.6) * 28.0 * unrest
        _velocities[row] += (home - _offsets[row]) * delta * (0.6 + cohesion * 0.5)
        _velocities[row] *= pow(0.11, delta)
        _offsets[row] += _velocities[row] * delta

    var target_velocity: Vector2 = Vector2.ZERO
    if pointer_active:
        if _pointer_ready and delta > 0.0001:
            target_velocity = (pointer_position - _last_pointer) / delta
        _last_pointer = pointer_position
        _pointer_ready = true
    else:
        _pointer_ready = false
    _gesture_velocity = _gesture_velocity.lerp(target_velocity, clampf(delta * 10.0, 0.0, 1.0))

    if pointer_down:
        _focus_row = clampi(int(floor(pointer_position.y / DESIGN_SIZE.y * float(ROWS))), 0, ROWS - 1)
        var speed: float = clampf(_gesture_velocity.length() / 1200.0, 0.0, 1.0)
        _focus_energy = lerpf(_focus_energy, clampf((0.55 + speed * 0.65) * individuality, 0.0, 1.6), clampf(delta * 5.5, 0.0, 1.0))
        _velocities[_focus_row] += _gesture_velocity.x * delta * 0.14 * touch_gravity
        _phases[_focus_row] += _gesture_velocity.y * delta * 0.0015 * touch_gravity
        for row: int in range(ROWS):
            if row == _focus_row:
                continue
            var distance: float = absf(float(row - _focus_row))
            var push: float = signf(float(row - _focus_row)) * exp(-distance * 0.45) * _focus_energy * 24.0
            _velocities[row] += push * delta * touch_gravity
    else:
        _focus_energy = lerpf(_focus_energy, 0.0, clampf(delta * reabsorb_speed * 1.8, 0.0, 1.0))


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "phases": _phases.duplicate(),
        "offsets": _offsets.duplicate(),
        "velocities": _velocities.duplicate(),
        "focus_row": _focus_row,
        "focus_energy": _focus_energy,
        "gesture_velocity": _gesture_velocity,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _ensure_population()
    var phases_variant: Variant = state.get("phases", _phases)
    if phases_variant is PackedFloat32Array:
        _phases = (phases_variant as PackedFloat32Array).duplicate()
    var offsets_variant: Variant = state.get("offsets", _offsets)
    if offsets_variant is PackedFloat32Array:
        _offsets = (offsets_variant as PackedFloat32Array).duplicate()
    var velocities_variant: Variant = state.get("velocities", _velocities)
    if velocities_variant is PackedFloat32Array:
        _velocities = (velocities_variant as PackedFloat32Array).duplicate()
    _focus_row = int(state.get("focus_row", _focus_row))
    _focus_energy = float(state.get("focus_energy", _focus_energy))
    var velocity_variant: Variant = state.get("gesture_velocity", _gesture_velocity)
    if velocity_variant is Vector2:
        _gesture_velocity = velocity_variant as Vector2
    var pointer_variant: Variant = state.get("last_pointer", _last_pointer)
    if pointer_variant is Vector2:
        _last_pointer = pointer_variant as Vector2
    _pointer_ready = bool(state.get("pointer_ready", _pointer_ready))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "focus_row": _focus_row,
        "focus_energy": _focus_energy,
        "mean_offset": _mean_abs_offset(),
    }


func _mean_abs_offset() -> float:
    if _offsets.is_empty():
        return 0.0
    var total: float = 0.0
    for value: float in _offsets:
        total += absf(value)
    return total / float(_offsets.size())


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_resonance_field()
    _draw_chorus(font)
    end_design_draw()


func _draw_resonance_field() -> void:
    for row: int in range(ROWS):
        var y: float = (float(row) + 0.5) / float(ROWS) * DESIGN_SIZE.y
        var c: Color = COOL.lerp(ACCENT, 0.5 + 0.5 * sin(_phases[row]))
        c.a = 0.015 + absf(sin(_phases[row])) * 0.02
        var x_shift: float = _offsets[row] * 0.7
        draw_line(Vector2(0.0, y), Vector2(DESIGN_SIZE.x, y + x_shift * 0.03), c, 1.0)


func _draw_chorus(font: Font) -> void:
    var row_spacing: float = DESIGN_SIZE.y / float(ROWS + 1)
    var font_size: int = 34
    var text_width: float = font.get_string_size(CHORUS_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x

    for row: int in range(ROWS):
        var y: float = row_spacing * float(row + 1) + 10.0
        var energy: float = 0.5 + 0.5 * sin(_phases[row])
        var auto_voice: float = pow(energy, 4.0) * individuality * 0.55
        var focus: float = _focus_energy if row == _focus_row else 0.0
        var voice: float = clampf(maxf(auto_voice, focus), 0.0, 1.5)
        var x: float = (DESIGN_SIZE.x - text_width) * 0.5 + _offsets[row]

        if voice > 0.26:
            _draw_voice_contours(font, row, Vector2(x, y), font_size, voice)
        else:
            var row_color: Color = INK.lerp(COOL, 0.28 + energy * 0.18)
            row_color.a = (0.16 + contrast * 0.28) * (0.85 - voice * 0.2)
            draw_string(font, Vector2(x, y), CHORUS_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, row_color)


func _draw_voice_contours(font: Font, row: int, origin: Vector2, font_size: int, voice: float) -> void:
    var tracking: float = 1.5
    var cursor_x: float = origin.x
    var velocity_norm: float = clampf(absf(_velocities[row]) / 90.0, 0.0, 1.0)

    for char_index: int in range(CHORUS_TEXT.length()):
        var glyph: String = CHORUS_TEXT.substr(char_index, 1)
        var width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
        if glyph == " ":
            cursor_x += width + tracking
            continue
        var baseline: Vector2 = Vector2(cursor_x, origin.y)
        var contours: Array[PackedVector2Array] = get_glyph_outline_contours(font, glyph, font_size, baseline, 5)
        if contours.is_empty():
            var fallback: Color = ACCENT
            fallback.a = clampf(voice, 0.0, 1.0)
            draw_string(font, baseline, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fallback)
            cursor_x += width + tracking
            continue

        var bounds: Rect2 = outline_bounds(contours)
        var center: Vector2 = bounds.get_center()
        var deformed: Array[PackedVector2Array] = []
        for contour_index: int in range(contours.size()):
            var mapped: PackedVector2Array = PackedVector2Array()
            for point_index: int in range(contours[contour_index].size()):
                var p: Vector2 = contours[contour_index][point_index]
                var relative: Vector2 = p - center
                var q: Vector2 = p
                var local_phase: float = _phases[row] + relative.y * 0.055 + float(char_index) * 0.29
                q.x += sin(local_phase) * voice * (2.5 + velocity_norm * 5.0)
                q.y += cos(local_phase * 0.7 + relative.x * 0.04) * voice * 2.8
                q += relative.normalized() * voice * 0.8
                mapped.append(q)
            deformed.append(mapped)

        var echo: Color = COOL
        echo.a = voice * 0.18
        var echo_offset: Vector2 = Vector2(-_velocities[row] * 0.025, 0.0)
        var echo_set: Array[PackedVector2Array] = []
        for contour: PackedVector2Array in deformed:
            var shifted: PackedVector2Array = PackedVector2Array()
            for point: Vector2 in contour:
                shifted.append(point + echo_offset)
            echo_set.append(shifted)
        draw_outline_contours(echo_set, echo, 1.0, true)

        var color: Color = ACCENT.lerp(INK, clampf(1.0 - voice * 0.55, 0.0, 1.0))
        color.a = 0.52 + clampf(voice, 0.0, 1.0) * 0.46
        draw_outline_contours(deformed, color, 1.4 + voice * 1.6, true)
        cursor_x += width + tracking
