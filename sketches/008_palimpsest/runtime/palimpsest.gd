extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.085, 0.075, 0.065, 1.0)
const PAPER: Color = Color(0.92, 0.86, 0.73, 1.0)
const OLD_INK: Color = Color(0.16, 0.42, 0.38, 1.0)
const DEEP_INK: Color = Color(0.72, 0.18, 0.12, 1.0)
const CURRENT: Array[String] = ["WE WRITE", "OVER WHAT", "WE KEEP"]
const OLDER: Array[String] = ["NOTHING", "VANISHES", "CLEANLY"]
const DEEPEST: Array[String] = ["THE PAGE", "REMEMBERS", "TOUCH"]
const BASELINES: Array[float] = [245.0, 390.0, 535.0]
const MAX_MARKS: int = 14

@export_range(70.0, 260.0, 1.0) var scratch_radius: float = 145.0
@export_range(0.1, 2.0, 0.01) var reveal_strength: float = 1.0
@export_range(250.0, 1400.0, 10.0) var tear_threshold: float = 720.0
@export_range(0.05, 1.2, 0.01) var recovery: float = 0.24
@export_range(0.3, 2.5, 0.01) var hold_memory: float = 1.0
@export_range(0.0, 1.0, 0.01) var abrasion: float = 0.62

var _marks: Array[Dictionary] = []
var _mark_accumulator: float = 0.0
var _press_age: float = 0.0
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "scratch_radius", "label": "SCRATCH RADIUS", "type": "float", "min": 70.0, "max": 260.0, "step": 1.0},
        {"id": "reveal_strength", "label": "REVEAL", "type": "float", "min": 0.1, "max": 2.0, "step": 0.01},
        {"id": "tear_threshold", "label": "TEAR SPEED", "type": "float", "min": 250.0, "max": 1400.0, "step": 10.0},
        {"id": "recovery", "label": "REWRITE", "type": "float", "min": 0.05, "max": 1.2, "step": 0.01},
        {"id": "hold_memory", "label": "HOLD MEMORY", "type": "float", "min": 0.3, "max": 2.5, "step": 0.01},
        {"id": "abrasion", "label": "ABRASION", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "scratch_radius": return scratch_radius
        "reveal_strength": return reveal_strength
        "tear_threshold": return tear_threshold
        "recovery": return recovery
        "hold_memory": return hold_memory
        "abrasion": return abrasion
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "scratch_radius": scratch_radius = clampf(float(value), 70.0, 260.0)
        "reveal_strength": reveal_strength = clampf(float(value), 0.1, 2.0)
        "tear_threshold": tear_threshold = clampf(float(value), 250.0, 1400.0)
        "recovery": recovery = clampf(float(value), 0.05, 1.2)
        "hold_memory": hold_memory = clampf(float(value), 0.3, 2.5)
        "abrasion": abrasion = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    for mark_index: int in range(_marks.size() - 1, -1, -1):
        var mark: Dictionary = _marks[mark_index]
        var lock_bonus: float = float(mark.get("locked", 0.0))
        var energy: float = float(mark.get("energy", 0.0)) - recovery * delta * (0.24 if lock_bonus > 0.5 else 1.0)
        if energy <= 0.0:
            _marks.remove_at(mark_index)
            continue
        mark["energy"] = energy
        mark["age"] = float(mark.get("age", 0.0)) + delta
        _marks[mark_index] = mark

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
        _press_age += delta
        _mark_accumulator += delta
        if _mark_accumulator >= 0.052:
            _mark_accumulator = fmod(_mark_accumulator, 0.052)
            var speed: float = _gesture_velocity.length()
            var depth: int = 2 if speed >= tear_threshold else 1
            var energy: float = clampf((0.48 + speed / 1400.0) * reveal_strength, 0.0, 1.5)
            var locked: float = 1.0 if _press_age >= hold_memory else 0.0
            _marks.append({
                "position": pointer_position,
                "energy": energy,
                "depth": depth,
                "direction": _gesture_velocity.normalized() if speed > 0.001 else Vector2.RIGHT,
                "locked": locked,
                "age": 0.0,
            })
            while _marks.size() > MAX_MARKS:
                _marks.remove_at(0)
    else:
        _press_age = 0.0
        _mark_accumulator = 0.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "marks": _marks.duplicate(true),
        "mark_accumulator": _mark_accumulator,
        "press_age": _press_age,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
        "gesture_velocity": _gesture_velocity,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _marks.clear()
    var marks_variant: Variant = state.get("marks", [])
    if marks_variant is Array:
        for item: Variant in marks_variant as Array:
            if item is Dictionary:
                _marks.append((item as Dictionary).duplicate(true))
    _mark_accumulator = float(state.get("mark_accumulator", _mark_accumulator))
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
        "mark_count": _marks.size(),
        "press_age": _press_age,
        "gesture_speed": _gesture_velocity.length(),
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_archive_frame(font)

    for line_index: int in range(3):
        _draw_layered_line(font, line_index)

    _draw_trace_marks()
    end_design_draw()


func _draw_archive_frame(font: Font) -> void:
    var rule: Color = PAPER
    rule.a = 0.14
    draw_rect(Rect2(Vector2(82.0, 98.0), Vector2(1116.0, 520.0)), Color(0.02, 0.018, 0.016, 0.24), true)
    draw_rect(Rect2(Vector2(82.0, 98.0), Vector2(1116.0, 520.0)), rule, false, 1.0)
    draw_string(font, Vector2(96.0, 82.0), "ARCHIVE / LAYER 03 / TOUCH TO EXCAVATE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(PAPER.r, PAPER.g, PAPER.b, 0.46))


func _draw_layered_line(font: Font, line_index: int) -> void:
    var current: String = CURRENT[line_index]
    var older: String = OLDER[line_index]
    var deepest: String = DEEPEST[line_index]
    var max_len: int = maxi(current.length(), maxi(older.length(), deepest.length()))
    var cell_w: float = 1020.0 / float(maxi(1, max_len))
    var start_x: float = 130.0
    var baseline: float = BASELINES[line_index]
    var font_size: int = 78 if line_index != 1 else 94

    for index: int in range(max_len):
        var center: Vector2 = Vector2(start_x + (float(index) + 0.5) * cell_w, baseline - float(font_size) * 0.35)
        var influence: Dictionary = _influence_at(center)
        var surface: float = clampf(float(influence.get("surface", 0.0)), 0.0, 1.0)
        var deep: float = clampf(float(influence.get("deep", 0.0)), 0.0, 1.0)
        var direction_variant: Variant = influence.get("direction", Vector2.ZERO)
        var direction: Vector2 = direction_variant as Vector2 if direction_variant is Vector2 else Vector2.ZERO

        var current_glyph: String = current.substr(index, 1) if index < current.length() else " "
        var old_glyph: String = older.substr(index, 1) if index < older.length() else " "
        var deep_glyph: String = deepest.substr(index, 1) if index < deepest.length() else " "

        if deep_glyph != " " and deep > 0.03:
            var deep_color: Color = DEEP_INK
            deep_color.a = deep * 0.88
            _draw_centered_glyph(font, center + direction * 18.0 * deep, deep_glyph, font_size, deep_color)

        if old_glyph != " " and surface > 0.03:
            var old_color: Color = OLD_INK
            old_color.a = surface * (1.0 - deep * 0.45)
            _draw_centered_glyph(font, center - direction * 8.0 * surface, old_glyph, font_size, old_color)

        if current_glyph != " ":
            var current_color: Color = PAPER
            current_color.a = 1.0 - maxf(surface * 0.82, deep * 0.94)
            _draw_centered_glyph(font, center, current_glyph, font_size, current_color)

        if abrasion > 0.0 and surface > 0.08:
            var abrasion_color: Color = PAPER
            abrasion_color.a = abrasion * surface * 0.14
            var dash: float = cell_w * 0.36
            draw_line(center - Vector2(dash * 0.5, 4.0), center + Vector2(dash * 0.5, 4.0), abrasion_color, 1.0)


func _draw_centered_glyph(font: Font, center: Vector2, glyph: String, font_size: int, color: Color) -> void:
    var size: Vector2 = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
    var ascent: float = font.get_ascent(font_size)
    var descent: float = font.get_descent(font_size)
    var baseline: Vector2 = Vector2(center.x - size.x * 0.5, center.y + (ascent - descent) * 0.5)
    draw_string(font, baseline, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _influence_at(point: Vector2) -> Dictionary:
    var surface: float = 0.0
    var deep: float = 0.0
    var direction: Vector2 = Vector2.ZERO
    var direction_weight: float = 0.0
    for mark: Dictionary in _marks:
        var pos_variant: Variant = mark.get("position", Vector2.ZERO)
        if not pos_variant is Vector2:
            continue
        var pos: Vector2 = pos_variant as Vector2
        var distance: float = point.distance_to(pos)
        if distance >= scratch_radius:
            continue
        var radial: float = 1.0 - distance / scratch_radius
        var energy: float = float(mark.get("energy", 0.0))
        var amount: float = radial * energy
        if int(mark.get("depth", 1)) >= 2:
            deep = maxf(deep, amount)
        else:
            surface = maxf(surface, amount)
        var dir_variant: Variant = mark.get("direction", Vector2.ZERO)
        if dir_variant is Vector2:
            direction += (dir_variant as Vector2) * amount
            direction_weight += amount
    if direction_weight > 0.001:
        direction /= direction_weight
    return {"surface": surface, "deep": deep, "direction": direction}


func _draw_trace_marks() -> void:
    for mark: Dictionary in _marks:
        var pos_variant: Variant = mark.get("position", Vector2.ZERO)
        if not pos_variant is Vector2:
            continue
        var pos: Vector2 = pos_variant as Vector2
        var energy: float = clampf(float(mark.get("energy", 0.0)), 0.0, 1.0)
        var color: Color = DEEP_INK if int(mark.get("depth", 1)) >= 2 else OLD_INK
        color.a = 0.025 + energy * 0.06
        draw_circle(pos, scratch_radius * (0.18 + energy * 0.18), color)
