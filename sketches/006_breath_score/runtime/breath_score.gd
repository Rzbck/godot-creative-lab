extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.025, 0.026, 0.03, 1.0)
const PAPER: Color = Color(0.95, 0.93, 0.86, 1.0)
const ACCENT: Color = Color(0.93, 0.28, 0.14, 1.0)
const MUTED: Color = Color(0.55, 0.58, 0.62, 1.0)
const LINES: Array[String] = ["BREATHE", "BETWEEN", "WORDS"]
const BASELINES: Array[float] = [245.0, 390.0, 535.0]

@export_range(0.6, 1.8, 0.01) var breath_range: float = 1.18
@export_range(0.4, 2.4, 0.01) var hold_threshold: float = 1.05
@export_range(0.5, 5.0, 0.01) var recovery: float = 2.2
@export_range(4.0, 24.0, 0.1) var tracking: float = 11.0
@export_range(0.0, 1.0, 0.01) var accent_amount: float = 0.72
@export_range(0.0, 1.0, 0.01) var ambient_motion: float = 0.22

var _breath: float = 0.0
var _breath_velocity: float = 0.0
var _press_age: float = 0.0
var _release_energy: float = 0.0
var _active_line: int = 0
var _was_down: bool = false
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "breath_range", "label": "BREATH RANGE", "type": "float", "min": 0.6, "max": 1.8, "step": 0.01},
        {"id": "hold_threshold", "label": "HOLD TIME", "type": "float", "min": 0.4, "max": 2.4, "step": 0.01},
        {"id": "recovery", "label": "RECOVERY", "type": "float", "min": 0.5, "max": 5.0, "step": 0.01},
        {"id": "tracking", "label": "TRACKING", "type": "float", "min": 4.0, "max": 24.0, "step": 0.1},
        {"id": "accent_amount", "label": "ACCENT", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "ambient_motion", "label": "AMBIENT", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "breath_range": return breath_range
        "hold_threshold": return hold_threshold
        "recovery": return recovery
        "tracking": return tracking
        "accent_amount": return accent_amount
        "ambient_motion": return ambient_motion
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "breath_range": breath_range = clampf(float(value), 0.6, 1.8)
        "hold_threshold": hold_threshold = clampf(float(value), 0.4, 2.4)
        "recovery": recovery = clampf(float(value), 0.5, 5.0)
        "tracking": tracking = clampf(float(value), 4.0, 24.0)
        "accent_amount": accent_amount = clampf(float(value), 0.0, 1.0)
        "ambient_motion": ambient_motion = clampf(float(value), 0.0, 1.0)
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

    _gesture_velocity = _gesture_velocity.lerp(target_velocity, clampf(delta * 8.0, 0.0, 1.0))

    if pointer_down and not _was_down:
        _active_line = clampi(roundi((pointer_position.y - 245.0) / 145.0), 0, 2)
        _press_age = 0.0

    if pointer_down:
        _press_age += delta
        var inhale_target: float = clampf(0.18 + _press_age / maxf(0.01, hold_threshold), 0.0, 1.0)
        var speed_boost: float = clampf(_gesture_velocity.length() / 1200.0, 0.0, 0.28)
        var spring_force: float = (inhale_target + speed_boost - _breath) * (4.2 + breath_range * 1.6)
        _breath_velocity += spring_force * delta
        _breath_velocity *= pow(0.12, delta)
    else:
        if _was_down:
            _release_energy = clampf(_breath + _press_age / maxf(0.01, hold_threshold) * 0.24, 0.0, 1.45)
        _press_age = 0.0
        _breath_velocity += (-_breath * recovery * 3.4) * delta
        _breath_velocity *= pow(0.06, delta)

    _breath += _breath_velocity * delta
    _breath = clampf(_breath, -0.18, 1.3)
    _release_energy = maxf(0.0, _release_energy - delta * recovery * 0.35)
    _was_down = pointer_down


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "breath": _breath,
        "breath_velocity": _breath_velocity,
        "press_age": _press_age,
        "release_energy": _release_energy,
        "active_line": _active_line,
        "was_down": _was_down,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
        "gesture_velocity": _gesture_velocity,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _breath = float(state.get("breath", _breath))
    _breath_velocity = float(state.get("breath_velocity", _breath_velocity))
    _press_age = float(state.get("press_age", _press_age))
    _release_energy = float(state.get("release_energy", _release_energy))
    _active_line = int(state.get("active_line", _active_line))
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
        "breath": _breath,
        "press_age": _press_age,
        "release_energy": _release_energy,
        "active_line": _active_line,
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font

    _draw_structure()

    for line_index: int in range(LINES.size()):
        var active_weight: float = 1.0 if line_index == _active_line else 0.32
        var inhale: float = maxf(0.0, _breath) * active_weight
        var ambient: float = sin(sketch_time * 0.42 + float(line_index) * 1.7) * ambient_motion * 0.18
        var release_wave: float = sin(sketch_time * 4.8 - float(line_index) * 0.9) * _release_energy * (1.0 - float(line_index) * 0.13)
        var expansion: float = inhale * breath_range + ambient
        var local_tracking: float = tracking * (1.0 + expansion * 1.8)
        var font_size: int = [112, 88, 112][line_index]
        var y_offset: float = release_wave * 14.0 + expansion * (float(line_index) - 1.0) * 15.0
        var scale_hint: float = 1.0 + expansion * (0.05 if line_index == 1 else 0.09)

        _draw_tracked_word(
            font,
            LINES[line_index],
            BASELINES[line_index] + y_offset,
            font_size,
            local_tracking,
            scale_hint,
            line_index,
            inhale
        )

    _draw_breath_meter()
    end_design_draw()


func _draw_structure() -> void:
    var guide: Color = Color(0.95, 0.93, 0.86, 0.09)
    draw_line(Vector2(92.0, 128.0), Vector2(1188.0, 128.0), guide, 1.0)
    draw_line(Vector2(92.0, 592.0), Vector2(1188.0, 592.0), guide, 1.0)
    for column: int in range(7):
        var x: float = 92.0 + float(column) * (1096.0 / 6.0)
        var c: Color = guide
        c.a *= 0.42
        draw_line(Vector2(x, 128.0), Vector2(x, 592.0), c, 1.0)


func _draw_tracked_word(
    font: Font,
    text: String,
    baseline: float,
    font_size: int,
    local_tracking: float,
    scale_hint: float,
    line_index: int,
    inhale: float
) -> void:
    var widths: Array[float] = []
    var total_width: float = 0.0
    for index: int in range(text.length()):
        var glyph: String = text.substr(index, 1)
        var width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x * scale_hint
        widths.append(width)
        total_width += width
        if index < text.length() - 1:
            total_width += local_tracking

    var cursor_x: float = (DESIGN_SIZE.x - total_width) * 0.5
    var gesture_dir: float = clampf(_gesture_velocity.x / 1400.0, -1.0, 1.0)

    for index: int in range(text.length()):
        var glyph: String = text.substr(index, 1)
        var phase: float = float(index) / maxf(1.0, float(text.length() - 1))
        var local_lift: float = sin(phase * PI) * inhale * 12.0
        var directional: float = gesture_dir * inhale * (phase - 0.5) * 34.0
        var position: Vector2 = Vector2(cursor_x + directional, baseline - local_lift)

        if inhale > 0.08:
            var ghost: Color = ACCENT
            ghost.a = accent_amount * inhale * 0.28
            draw_string(font, position + Vector2(gesture_dir * 10.0, 2.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, ghost)

        var color: Color = PAPER
        color = color.lerp(ACCENT, inhale * accent_amount * (0.28 + float(line_index == 1) * 0.2))
        draw_string(font, position, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
        cursor_x += widths[index] + local_tracking


func _draw_breath_meter() -> void:
    var x: float = 1128.0
    var top: float = 170.0
    var height: float = 360.0
    var level: float = clampf(maxf(_breath, _release_energy * 0.65), 0.0, 1.0)
    var rail: Color = MUTED
    rail.a = 0.28
    draw_line(Vector2(x, top), Vector2(x, top + height), rail, 1.0)
    var fill: Color = ACCENT
    fill.a = 0.65
    draw_line(Vector2(x, top + height), Vector2(x, top + height * (1.0 - level)), fill, 3.0)
    for index: int in range(6):
        var y: float = top + float(index) * height / 5.0
        draw_line(Vector2(x - 9.0, y), Vector2(x + 9.0, y), rail, 1.0)
