extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.012, 0.018, 0.032, 1.0)
const INK: Color = Color(0.9, 0.92, 0.88, 1.0)
const ACCENT: Color = Color(1.0, 0.74, 0.08, 1.0)
const MUTED: Color = Color(0.26, 0.34, 0.5, 1.0)
const ROWS: int = 11
const CHORUS_TEXT: String = "I AM HERE / I AM HERE / I AM HERE"

@export_range(0.2, 2.5, 0.01) var isolation_gain: float = 1.0
@export_range(0.2, 3.0, 0.01) var hold_gain: float = 1.1
@export_range(0.2, 2.5, 0.01) var drift_gain: float = 1.0
@export_range(0.1, 2.0, 0.01) var reabsorb_speed: float = 0.62
@export_range(0.0, 1.0, 0.01) var crowd_motion: float = 0.32
@export_range(0.0, 1.0, 0.01) var contrast: float = 0.78

var _focus_row: int = 5
var _focus_energy: float = 0.0
var _hold_age: float = 0.0
var _drift: float = 0.0
var _drift_velocity: float = 0.0
var _was_down: bool = false
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "isolation_gain", "label": "ISOLATION", "type": "float", "min": 0.2, "max": 2.5, "step": 0.01},
        {"id": "hold_gain", "label": "PRESENCE", "type": "float", "min": 0.2, "max": 3.0, "step": 0.01},
        {"id": "drift_gain", "label": "DRIFT", "type": "float", "min": 0.2, "max": 2.5, "step": 0.01},
        {"id": "reabsorb_speed", "label": "REABSORB", "type": "float", "min": 0.1, "max": 2.0, "step": 0.01},
        {"id": "crowd_motion", "label": "CROWD MOTION", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "contrast", "label": "CONTRAST", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "isolation_gain": return isolation_gain
        "hold_gain": return hold_gain
        "drift_gain": return drift_gain
        "reabsorb_speed": return reabsorb_speed
        "crowd_motion": return crowd_motion
        "contrast": return contrast
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "isolation_gain": isolation_gain = clampf(float(value), 0.2, 2.5)
        "hold_gain": hold_gain = clampf(float(value), 0.2, 3.0)
        "drift_gain": drift_gain = clampf(float(value), 0.2, 2.5)
        "reabsorb_speed": reabsorb_speed = clampf(float(value), 0.1, 2.0)
        "crowd_motion": crowd_motion = clampf(float(value), 0.0, 1.0)
        "contrast": contrast = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    var target_velocity: Vector2 = Vector2.ZERO
    if pointer_active:
        if _pointer_ready and delta > 0.0001:
            target_velocity = (pointer_position - _last_pointer) / delta
        _last_pointer = pointer_position
        _pointer_ready = true
    else:
        _pointer_ready = false
    _gesture_velocity = _gesture_velocity.lerp(target_velocity, clampf(delta * 10.0, 0.0, 1.0))

    if pointer_down and not _was_down:
        _focus_row = clampi(int(floor((pointer_position.y - 108.0) / 46.0)), 0, ROWS - 1)
        _hold_age = 0.0

    if pointer_down:
        _hold_age += delta
        var target_energy: float = clampf((0.28 + _hold_age * 0.72) * isolation_gain * hold_gain, 0.0, 1.5)
        _focus_energy = lerpf(_focus_energy, target_energy, clampf(delta * 6.0, 0.0, 1.0))
        _drift_velocity = lerpf(_drift_velocity, _gesture_velocity.x * 0.045 * drift_gain, clampf(delta * 8.0, 0.0, 1.0))
        _drift += _drift_velocity * delta
        _drift = clampf(_drift, -260.0, 260.0)
    else:
        _hold_age = 0.0
        _focus_energy = lerpf(_focus_energy, 0.0, clampf(delta * reabsorb_speed * 2.0, 0.0, 1.0))
        _drift_velocity += (-_drift * reabsorb_speed * 2.8) * delta
        _drift_velocity *= pow(0.08, delta)
        _drift += _drift_velocity * delta

    _was_down = pointer_down


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "focus_row": _focus_row,
        "focus_energy": _focus_energy,
        "hold_age": _hold_age,
        "drift": _drift,
        "drift_velocity": _drift_velocity,
        "was_down": _was_down,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
        "gesture_velocity": _gesture_velocity,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _focus_row = int(state.get("focus_row", _focus_row))
    _focus_energy = float(state.get("focus_energy", _focus_energy))
    _hold_age = float(state.get("hold_age", _hold_age))
    _drift = float(state.get("drift", _drift))
    _drift_velocity = float(state.get("drift_velocity", _drift_velocity))
    _was_down = bool(state.get("was_down", _was_down))
    var pointer_variant: Variant = state.get("last_pointer", _last_pointer)
    if pointer_variant is Vector2:
        _last_pointer = pointer_variant as Vector2
    _pointer_ready = bool(state.get("pointer_ready", _pointer_ready))
    var velocity_variant: Variant = state.get("gesture_velocity", _gesture_velocity)
    if velocity_variant is Vector2:
        _gesture_velocity = velocity_variant as Vector2


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "focus_row": _focus_row,
        "focus_energy": _focus_energy,
        "drift": _drift,
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_frame(font)
    _draw_chorus(font)
    _draw_statement(font)
    end_design_draw()


func _draw_frame(font: Font) -> void:
    var guide: Color = MUTED
    guide.a = 0.24
    draw_rect(Rect2(Vector2(72.0, 76.0), Vector2(1136.0, 568.0)), guide, false, 1.0)
    draw_string(font, Vector2(82.0, 62.0), "VOICE / CROWD / ABSORPTION", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.9, 0.92, 0.88, 0.42))


func _draw_chorus(font: Font) -> void:
    var row_spacing: float = 46.0
    var base_y: float = 132.0
    var font_size: int = 32

    for row: int in range(ROWS):
        var y: float = base_y + float(row) * row_spacing
        var row_phase: float = sin(sketch_time * 0.38 + float(row) * 0.73) * 16.0 * crowd_motion
        var distance_from_focus: float = absf(float(row - _focus_row))
        var push: float = 0.0
        if _focus_energy > 0.01:
            var direction: float = -1.0 if row < _focus_row else 1.0
            if row == _focus_row:
                direction = 0.0
            push = direction * _focus_energy * maxf(0.0, 82.0 - distance_from_focus * 14.0)

        var x: float = 110.0 + row_phase + push
        var row_alpha: float = 0.22 + contrast * 0.26
        var row_color: Color = INK
        row_color.a = row_alpha * (1.0 - _focus_energy * 0.55)

        if row == _focus_row:
            var focus_color: Color = ACCENT
            focus_color.a = 0.34 + _focus_energy * 0.6
            var focus_x: float = x + _drift
            for echo_index: int in range(3):
                var echo_t: float = float(echo_index + 1) / 3.0
                var echo_color: Color = focus_color
                echo_color.a *= 0.18 * (1.0 - echo_t * 0.5)
                draw_string(font, Vector2(focus_x - _drift_velocity * 0.018 * echo_t, y), CHORUS_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, echo_color)
            draw_string(font, Vector2(focus_x, y), CHORUS_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, focus_color)
        else:
            draw_string(font, Vector2(x, y), CHORUS_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, row_color)


func _draw_statement(font: Font) -> void:
    var title_color: Color = INK
    title_color.a = 0.9
    draw_string(font, Vector2(102.0, 330.0), "ONE VOICE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 88, title_color)
    var accent_color: Color = ACCENT
    accent_color.a = 0.9
    draw_string(font, Vector2(612.0, 425.0), "BECOMES MANY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 66, accent_color)
