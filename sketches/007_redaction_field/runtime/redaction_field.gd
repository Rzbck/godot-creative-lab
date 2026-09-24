extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.945, 0.925, 0.875, 1.0)
const INK: Color = Color(0.055, 0.05, 0.045, 1.0)
const RED: Color = Color(0.82, 0.08, 0.06, 1.0)
const TEXT_LINES: Array[String] = ["EVERY EDIT", "CHANGES", "THE STORY"]
const BASELINES: Array[float] = [245.0, 402.0, 565.0]

@export_range(0.1, 0.95, 0.01) var censorship_bias: float = 0.58
@export_range(0.05, 1.4, 0.01) var scanner_speed: float = 0.34
@export_range(0.0, 1.0, 0.01) var leak_rate: float = 0.34
@export_range(0.0, 1.0, 0.01) var memory: float = 0.72
@export_range(0.2, 1.0, 0.01) var collapse: float = 0.84
@export_range(0.2, 1.0, 0.01) var ink_density: float = 0.9

var _levels: Array = []
var _locks: Array = []
var _press_age: float = 0.0
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
    super._ready()
    _ensure_state()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "censorship_bias", "label": "CENSORSHIP BIAS", "type": "float", "min": 0.1, "max": 0.95, "step": 0.01},
        {"id": "scanner_speed", "label": "INSTITUTIONAL DRIFT", "type": "float", "min": 0.05, "max": 1.4, "step": 0.01},
        {"id": "leak_rate", "label": "LEAK RATE", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "memory", "label": "MEMORY", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "collapse", "label": "LETTER COLLAPSE", "type": "float", "min": 0.2, "max": 1.0, "step": 0.01},
        {"id": "ink_density", "label": "INK DENSITY", "type": "float", "min": 0.2, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "censorship_bias": return censorship_bias
        "scanner_speed": return scanner_speed
        "leak_rate": return leak_rate
        "memory": return memory
        "collapse": return collapse
        "ink_density": return ink_density
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "censorship_bias": censorship_bias = clampf(float(value), 0.1, 0.95)
        "scanner_speed": scanner_speed = clampf(float(value), 0.05, 1.4)
        "leak_rate": leak_rate = clampf(float(value), 0.0, 1.0)
        "memory": memory = clampf(float(value), 0.0, 1.0)
        "collapse": collapse = clampf(float(value), 0.2, 1.0)
        "ink_density": ink_density = clampf(float(value), 0.2, 1.0)
        _: return
    queue_redraw()


func _ensure_state() -> void:
    if _levels.size() == TEXT_LINES.size():
        return
    _levels.clear()
    _locks.clear()
    for text: String in TEXT_LINES:
        var level_row: PackedFloat32Array = PackedFloat32Array()
        var lock_row: PackedFloat32Array = PackedFloat32Array()
        for char_index: int in range(text.length()):
            level_row.append(clampf(censorship_bias + (hash01(float(char_index) * 3.7) - 0.5) * 0.2, 0.0, 1.0))
            lock_row.append(0.0)
        _levels.append(level_row)
        _locks.append(lock_row)


func _update_source_simulation(delta: float) -> void:
    _ensure_state()
    var target_velocity: Vector2 = Vector2.ZERO
    if pointer_active:
        if _pointer_ready and delta > 0.0001:
            target_velocity = (pointer_position - _last_pointer) / delta
        _last_pointer = pointer_position
        _pointer_ready = true
    else:
        _pointer_ready = false
    _gesture_velocity = _gesture_velocity.lerp(target_velocity, clampf(delta * 10.0, 0.0, 1.0))

    var scan: float = fposmod(sketch_time * scanner_speed * 0.11, 1.0)
    for line_index: int in range(TEXT_LINES.size()):
        var row: PackedFloat32Array = _levels[line_index]
        var lock_row: PackedFloat32Array = _locks[line_index]
        for char_index: int in range(row.size()):
            var char_t: float = float(char_index) / maxf(1.0, float(row.size() - 1))
            var scan_distance: float = absf(char_t - scan)
            scan_distance = minf(scan_distance, 1.0 - scan_distance)
            var scanner_pressure: float = exp(-scan_distance * scan_distance * 100.0)
            var pulse: float = 0.5 + 0.5 * sin(sketch_time * (0.31 + float(line_index) * 0.03) + float(char_index) * 1.73)
            var leak: float = (pulse - 0.5) * leak_rate * 0.34
            var target: float = clampf(censorship_bias + scanner_pressure * 0.30 - leak, 0.02, 0.98)

            if lock_row[char_index] > 0.001:
                lock_row[char_index] = maxf(0.0, lock_row[char_index] - delta * lerpf(0.28, 0.035, memory))
            else:
                row[char_index] = lerpf(row[char_index], target, clampf(delta * (0.55 + scanner_speed), 0.0, 1.0))

        _levels[line_index] = row
        _locks[line_index] = lock_row

    if pointer_down:
        _press_age += delta
        _apply_pointer_edit(delta)
    else:
        _press_age = 0.0


func _apply_pointer_edit(delta: float) -> void:
    var line_index: int = _line_from_y(pointer_position.y)
    var text: String = TEXT_LINES[line_index]
    var row: PackedFloat32Array = _levels[line_index]
    var lock_row: PackedFloat32Array = _locks[line_index]
    var char_index: int = clampi(int(floor(pointer_position.x / DESIGN_SIZE.x * float(text.length()))), 0, text.length() - 1)
    var horizontal: float = clampf(_gesture_velocity.x / 850.0, -1.0, 1.0)
    var intent: float = -horizontal
    if absf(horizontal) < 0.08:
        intent = -0.18

    for offset: int in range(-2, 3):
        var index: int = char_index + offset
        if index < 0 or index >= row.size():
            continue
        var weight: float = exp(-float(offset * offset) * 0.55)
        row[index] = clampf(row[index] + intent * delta * 1.8 * weight, 0.0, 1.0)
        if _press_age > 0.75:
            lock_row[index] = maxf(lock_row[index], clampf((_press_age - 0.75) * 0.6 * weight, 0.0, 1.0))

    _levels[line_index] = row
    _locks[line_index] = lock_row


func _line_from_y(y: float) -> int:
    var best: int = 0
    var best_distance: float = INF
    for index: int in range(BASELINES.size()):
        var distance: float = absf(y - BASELINES[index])
        if distance < best_distance:
            best_distance = distance
            best = index
    return best


func _get_custom_live_sync_state() -> Dictionary:
    var levels_copy: Array = []
    var locks_copy: Array = []
    for row: PackedFloat32Array in _levels:
        levels_copy.append(row.duplicate())
    for row: PackedFloat32Array in _locks:
        locks_copy.append(row.duplicate())
    return {
        "levels": levels_copy,
        "locks": locks_copy,
        "press_age": _press_age,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
        "gesture_velocity": _gesture_velocity,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _ensure_state()
    var levels_variant: Variant = state.get("levels", [])
    if levels_variant is Array:
        var incoming: Array = levels_variant as Array
        for line_index: int in range(mini(incoming.size(), _levels.size())):
            if incoming[line_index] is PackedFloat32Array:
                _levels[line_index] = (incoming[line_index] as PackedFloat32Array).duplicate()
    var locks_variant: Variant = state.get("locks", [])
    if locks_variant is Array:
        var incoming_locks: Array = locks_variant as Array
        for line_index: int in range(mini(incoming_locks.size(), _locks.size())):
            if incoming_locks[line_index] is PackedFloat32Array:
                _locks[line_index] = (incoming_locks[line_index] as PackedFloat32Array).duplicate()
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
        "press_age": _press_age,
        "gesture_speed": _gesture_velocity.length(),
        "scanner": fposmod(sketch_time * scanner_speed * 0.11, 1.0),
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_paper_field()
    for line_index: int in range(TEXT_LINES.size()):
        _draw_mutating_line(font, line_index)
    end_design_draw()


func _draw_paper_field() -> void:
    for stripe: int in range(34):
        var y: float = float(stripe) / 33.0 * DESIGN_SIZE.y
        var drift: float = sin(sketch_time * 0.17 + float(stripe) * 0.61) * 7.0
        var c: Color = INK
        c.a = 0.012 + float(stripe % 4) * 0.002
        draw_line(Vector2(0.0, y + drift), Vector2(DESIGN_SIZE.x, y - drift * 0.4), c, 1.0)

    var scan_x: float = fposmod(sketch_time * scanner_speed * 0.11, 1.0) * DESIGN_SIZE.x
    var scan_color: Color = RED
    scan_color.a = 0.035
    draw_rect(Rect2(Vector2(scan_x - 40.0, 0.0), Vector2(80.0, DESIGN_SIZE.y)), scan_color, true)


func _draw_mutating_line(font: Font, line_index: int) -> void:
    var text: String = TEXT_LINES[line_index]
    var font_size: int = [108, 146, 108][line_index]
    var tracking: float = [12.0, 18.0, 12.0][line_index]
    var widths: Array[float] = []
    var total_width: float = 0.0
    for char_index: int in range(text.length()):
        var glyph: String = text.substr(char_index, 1)
        var width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
        widths.append(width)
        total_width += width
        if char_index < text.length() - 1:
            total_width += tracking

    var cursor_x: float = (DESIGN_SIZE.x - total_width) * 0.5
    var row: PackedFloat32Array = _levels[line_index]
    for char_index: int in range(text.length()):
        var glyph: String = text.substr(char_index, 1)
        var baseline: Vector2 = Vector2(cursor_x, BASELINES[line_index])
        var level: float = row[char_index] if char_index < row.size() else censorship_bias
        if glyph == " ":
            cursor_x += widths[char_index] + tracking
            continue

        var contours: Array[PackedVector2Array] = get_glyph_outline_contours(font, glyph, font_size, baseline, 7)
        if contours.is_empty():
            var fallback: Color = INK
            fallback.a = ink_density * (1.0 - level * 0.75)
            draw_string(font, baseline, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fallback)
            cursor_x += widths[char_index] + tracking
            continue

        var bounds: Rect2 = outline_bounds(contours)
        var center: Vector2 = bounds.get_center()
        var mutated: Array[PackedVector2Array] = []
        for contour_index: int in range(contours.size()):
            var mapped: PackedVector2Array = PackedVector2Array()
            var contour: PackedVector2Array = contours[contour_index]
            for point_index: int in range(contour.size()):
                var p: Vector2 = contour[point_index]
                var q: Vector2 = p
                var collapse_amount: float = level * collapse
                q.y = lerpf(q.y, center.y, collapse_amount * (0.74 + 0.12 * sin(float(point_index) * 0.37)))
                q.x += sin(q.y * 0.08 + sketch_time * 0.7 + float(char_index)) * level * 3.0
                mapped.append(q)
            mutated.append(mapped)

        var ghost: Color = RED
        ghost.a = (1.0 - level) * 0.08 + level * 0.12
        draw_outline_contours(mutated, ghost, 4.0 * level + 1.0, true)

        var ink: Color = INK
        ink.a = ink_density
        draw_outline_contours(mutated, ink, 2.0 + level * 5.0, true)

        if level > 0.55:
            var bar: Color = INK
            bar.a = (level - 0.55) / 0.45 * 0.72
            var bar_h: float = 5.0 + level * 15.0
            draw_rect(Rect2(Vector2(bounds.position.x - 3.0, center.y - bar_h * 0.5), Vector2(bounds.size.x + 6.0, bar_h)), bar, true)

        cursor_x += widths[char_index] + tracking
