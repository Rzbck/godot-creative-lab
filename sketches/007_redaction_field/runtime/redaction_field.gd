extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.945, 0.925, 0.875, 1.0)
const INK: Color = Color(0.055, 0.05, 0.045, 1.0)
const RED: Color = Color(0.82, 0.08, 0.06, 1.0)
const TEXT_LINES: Array[String] = ["EVERY EDIT", "CHANGES", "THE STORY"]
const BASELINES: Array[float] = [250.0, 392.0, 534.0]

@export_range(0.15, 0.95, 0.01) var base_redaction: float = 0.62
@export_range(0.2, 2.5, 0.01) var reveal_speed: float = 1.0
@export_range(0.2, 2.5, 0.01) var redact_speed: float = 1.0
@export_range(0.4, 3.0, 0.01) var memory_hold: float = 1.25
@export_range(0.05, 1.5, 0.01) var recovery: float = 0.28
@export_range(0.0, 1.0, 0.01) var accent_amount: float = 0.68

var _redaction: Array[float] = [0.62, 0.62, 0.62]
var _lock: Array[float] = [0.0, 0.0, 0.0]
var _active_line: int = 0
var _was_down: bool = false
var _press_age: float = 0.0
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "base_redaction", "label": "BASE REDACTION", "type": "float", "min": 0.15, "max": 0.95, "step": 0.01},
        {"id": "reveal_speed", "label": "REVEAL", "type": "float", "min": 0.2, "max": 2.5, "step": 0.01},
        {"id": "redact_speed", "label": "REDACT", "type": "float", "min": 0.2, "max": 2.5, "step": 0.01},
        {"id": "memory_hold", "label": "MEMORY HOLD", "type": "float", "min": 0.4, "max": 3.0, "step": 0.01},
        {"id": "recovery", "label": "RECOVERY", "type": "float", "min": 0.05, "max": 1.5, "step": 0.01},
        {"id": "accent_amount", "label": "ACCENT", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "base_redaction": return base_redaction
        "reveal_speed": return reveal_speed
        "redact_speed": return redact_speed
        "memory_hold": return memory_hold
        "recovery": return recovery
        "accent_amount": return accent_amount
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "base_redaction": base_redaction = clampf(float(value), 0.15, 0.95)
        "reveal_speed": reveal_speed = clampf(float(value), 0.2, 2.5)
        "redact_speed": redact_speed = clampf(float(value), 0.2, 2.5)
        "memory_hold": memory_hold = clampf(float(value), 0.4, 3.0)
        "recovery": recovery = clampf(float(value), 0.05, 1.5)
        "accent_amount": accent_amount = clampf(float(value), 0.0, 1.0)
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

    _gesture_velocity = _gesture_velocity.lerp(target_velocity, clampf(delta * 12.0, 0.0, 1.0))

    if pointer_down and not _was_down:
        _active_line = clampi(roundi((pointer_position.y - 250.0) / 142.0), 0, 2)
        _press_age = 0.0

    if pointer_down:
        _press_age += delta
        var horizontal: float = _gesture_velocity.x / 950.0
        if horizontal > 0.04:
            _redaction[_active_line] -= horizontal * reveal_speed * delta
        elif horizontal < -0.04:
            _redaction[_active_line] += -horizontal * redact_speed * delta
        _redaction[_active_line] = clampf(_redaction[_active_line], 0.04, 0.98)

        if _press_age >= memory_hold:
            _lock[_active_line] = 1.0
    else:
        _press_age = 0.0
        for index: int in range(3):
            if _lock[index] > 0.0:
                _lock[index] = maxf(0.0, _lock[index] - delta * 0.12)
            else:
                _redaction[index] = lerpf(_redaction[index], base_redaction, clampf(delta * recovery, 0.0, 1.0))

    _was_down = pointer_down


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "redaction": _redaction.duplicate(),
        "lock": _lock.duplicate(),
        "active_line": _active_line,
        "was_down": _was_down,
        "press_age": _press_age,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
        "gesture_velocity": _gesture_velocity,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var redaction_variant: Variant = state.get("redaction", _redaction)
    if redaction_variant is Array:
        var arr: Array = redaction_variant as Array
        for index: int in range(mini(arr.size(), 3)):
            _redaction[index] = float(arr[index])
    var lock_variant: Variant = state.get("lock", _lock)
    if lock_variant is Array:
        var lock_arr: Array = lock_variant as Array
        for index: int in range(mini(lock_arr.size(), 3)):
            _lock[index] = float(lock_arr[index])
    _active_line = int(state.get("active_line", _active_line))
    _was_down = bool(state.get("was_down", _was_down))
    _press_age = float(state.get("press_age", _press_age))
    var pointer_variant: Variant = state.get("last_pointer", _last_pointer)
    if pointer_variant is Vector2:
        _last_pointer = pointer_variant as Vector2
    _pointer_ready = bool(state.get("pointer_ready", _pointer_ready))
    var velocity_variant: Variant = state.get("gesture_velocity", _gesture_velocity)
    if velocity_variant is Vector2:
        _gesture_velocity = velocity_variant as Vector2


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "active_line": _active_line,
        "redaction": _redaction.duplicate(),
        "lock": _lock.duplicate(),
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_editorial_frame(font)

    for line_index: int in range(TEXT_LINES.size()):
        _draw_line_system(font, line_index)

    end_design_draw()


func _draw_editorial_frame(font: Font) -> void:
    var rule: Color = INK
    rule.a = 0.24
    draw_line(Vector2(92.0, 110.0), Vector2(1188.0, 110.0), rule, 1.0)
    draw_line(Vector2(92.0, 610.0), Vector2(1188.0, 610.0), rule, 1.0)
    draw_string(font, Vector2(92.0, 88.0), "DOCUMENT / REVISION / VISIBILITY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.055, 0.05, 0.045, 0.46))
    draw_string(font, Vector2(1002.0, 88.0), "07", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, RED)


func _draw_line_system(font: Font, line_index: int) -> void:
    var text: String = TEXT_LINES[line_index]
    var font_size: int = [92, 122, 92][line_index]
    var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
    var x: float = 120.0 if line_index != 1 else 220.0
    var baseline: float = BASELINES[line_index]

    var ghost: Color = RED
    ghost.a = accent_amount * (0.08 + (1.0 - _redaction[line_index]) * 0.22)
    draw_string(font, Vector2(x + 5.0, baseline + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, ghost)
    draw_string(font, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)

    var coverage: float = clampf(_redaction[line_index], 0.0, 1.0)
    var total_width: float = minf(text_size.x, 980.0)
    var block_count: int = 5 + line_index
    var covered_width: float = total_width * coverage
    var cursor: float = x

    for block_index: int in range(block_count):
        var seed: float = float(line_index * 37 + block_index * 11)
        var weight: float = 0.12 + hash01(seed + 1.0) * 0.18
        var block_w: float = maxf(28.0, covered_width * weight)
        if cursor + block_w > x + covered_width:
            block_w = maxf(0.0, x + covered_width - cursor)
        if block_w <= 1.0:
            break
        var jitter_y: float = (hash01(seed + 4.0) - 0.5) * 5.0
        draw_rect(Rect2(Vector2(cursor, baseline - float(font_size) * 0.78 + jitter_y), Vector2(block_w, float(font_size) * 0.48)), INK, true)
        cursor += block_w + 8.0 + hash01(seed + 8.0) * 16.0

    if _lock[line_index] > 0.0:
        var lock_color: Color = RED
        lock_color.a = _lock[line_index] * 0.72
        draw_line(Vector2(x, baseline + 18.0), Vector2(x + total_width * (1.0 - coverage), baseline + 18.0), lock_color, 3.0)

    if line_index == _active_line and pointer_down:
        var marker: Color = RED
        marker.a = 0.55
        draw_circle(Vector2(clampf(pointer_position.x, 92.0, 1188.0), baseline + 28.0), 5.0, marker)
