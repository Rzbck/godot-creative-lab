extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.072, 0.062, 0.054, 1.0)
const PAPER: Color = Color(0.92, 0.86, 0.73, 1.0)
const OLD_INK: Color = Color(0.12, 0.52, 0.44, 1.0)
const DEEP_INK: Color = Color(0.86, 0.20, 0.10, 1.0)
const CURRENT: Array[String] = ["WE WRITE", "OVER WHAT", "WE KEEP"]
const OLDER: Array[String] = ["NOTHING", "VANISHES", "CLEANLY"]
const DEEPEST: Array[String] = ["THE PAGE", "REMEMBERS", "TOUCH"]
const BASELINES: Array[float] = [232.0, 402.0, 574.0]
const MAX_MARKS: int = 18

@export_range(0.0, 1.0, 0.01) var sediment_flow: float = 0.62
@export_range(0.2, 2.0, 0.01) var excavation_gain: float = 1.0
@export_range(250.0, 1400.0, 10.0) var depth_threshold: float = 700.0
@export_range(0.02, 0.8, 0.01) var rewrite_rate: float = 0.18
@export_range(0.0, 1.0, 0.01) var memory: float = 0.82
@export_range(0.0, 1.0, 0.01) var layer_drift: float = 0.46

var _marks: Array[Dictionary] = []
var _mark_accumulator: float = 0.0
var _press_age: float = 0.0
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "sediment_flow", "label": "SEDIMENT FLOW", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "excavation_gain", "label": "EXCAVATION", "type": "float", "min": 0.2, "max": 2.0, "step": 0.01},
        {"id": "depth_threshold", "label": "DEPTH THRESHOLD", "type": "float", "min": 250.0, "max": 1400.0, "step": 10.0},
        {"id": "rewrite_rate", "label": "REWRITE RATE", "type": "float", "min": 0.02, "max": 0.8, "step": 0.01},
        {"id": "memory", "label": "MEMORY", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "layer_drift", "label": "LAYER DRIFT", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "sediment_flow": return sediment_flow
        "excavation_gain": return excavation_gain
        "depth_threshold": return depth_threshold
        "rewrite_rate": return rewrite_rate
        "memory": return memory
        "layer_drift": return layer_drift
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "sediment_flow": sediment_flow = clampf(float(value), 0.0, 1.0)
        "excavation_gain": excavation_gain = clampf(float(value), 0.2, 2.0)
        "depth_threshold": depth_threshold = clampf(float(value), 250.0, 1400.0)
        "rewrite_rate": rewrite_rate = clampf(float(value), 0.02, 0.8)
        "memory": memory = clampf(float(value), 0.0, 1.0)
        "layer_drift": layer_drift = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    for mark_index: int in range(_marks.size() - 1, -1, -1):
        var mark: Dictionary = _marks[mark_index]
        var persistent: float = float(mark.get("persistent", 0.0))
        var decay: float = rewrite_rate * lerpf(1.0, 0.12, persistent * memory)
        var energy: float = float(mark.get("energy", 0.0)) - delta * decay
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
        if _mark_accumulator >= 0.05:
            _mark_accumulator = fmod(_mark_accumulator, 0.05)
            var speed: float = _gesture_velocity.length()
            var depth: int = 2 if speed >= depth_threshold else 1
            var energy: float = clampf((0.45 + speed / 1500.0) * excavation_gain, 0.0, 1.6)
            _marks.append({
                "position": pointer_position,
                "energy": energy,
                "depth": depth,
                "direction": _gesture_velocity.normalized() if speed > 2.0 else Vector2.RIGHT,
                "persistent": clampf((_press_age - 0.35) * 0.55, 0.0, 1.0),
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
        "gesture_speed": _gesture_velocity.length(),
        "press_age": _press_age,
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_sediment()
    for line_index: int in range(3):
        _draw_memory_line(font, line_index)
    end_design_draw()


func _draw_sediment() -> void:
    for band: int in range(22):
        var y: float = float(band) / 21.0 * DESIGN_SIZE.y
        var points: PackedVector2Array = PackedVector2Array()
        for step: int in range(25):
            var x: float = float(step) / 24.0 * DESIGN_SIZE.x
            var offset: float = sin(x * 0.006 + sketch_time * 0.15 + float(band) * 0.8) * 7.0 * sediment_flow
            offset += sin(x * 0.002 - sketch_time * 0.09 + float(band) * 1.4) * 4.0
            points.append(Vector2(x, y + offset))
        var c: Color = PAPER.lerp(OLD_INK, float(band % 5) / 4.0)
        c.a = 0.014 + sediment_flow * 0.018
        draw_polyline(points, c, 1.0, true)


func _draw_memory_line(font: Font, line_index: int) -> void:
    var current: String = CURRENT[line_index]
    var older: String = OLDER[line_index]
    var deepest: String = DEEPEST[line_index]
    var max_len: int = maxi(current.length(), maxi(older.length(), deepest.length()))
    var cell_w: float = 1080.0 / float(maxi(1, max_len))
    var start_x: float = (DESIGN_SIZE.x - cell_w * float(max_len)) * 0.5
    var baseline_y: float = BASELINES[line_index]
    var font_size: int = [92, 112, 94][line_index]

    for char_index: int in range(max_len):
        var current_glyph: String = current.substr(char_index, 1) if char_index < current.length() else " "
        var old_glyph: String = older.substr(char_index, 1) if char_index < older.length() else " "
        var deep_glyph: String = deepest.substr(char_index, 1) if char_index < deepest.length() else " "
        var baseline: Vector2 = Vector2(start_x + float(char_index) * cell_w, baseline_y)
        var center: Vector2 = baseline + Vector2(cell_w * 0.48, -float(font_size) * 0.34)
        var influence: Dictionary = _influence_at(center)
        var surface: float = float(influence.get("surface", 0.0))
        var deep: float = float(influence.get("deep", 0.0))
        var direction_variant: Variant = influence.get("direction", Vector2.ZERO)
        var direction: Vector2 = direction_variant as Vector2 if direction_variant is Vector2 else Vector2.ZERO

        var auto_phase: float = sketch_time * 0.23 + float(char_index) * 0.77 + float(line_index) * 1.9
        var auto_surface: float = maxf(0.0, sin(auto_phase)) * sediment_flow * 0.22
        var auto_deep: float = maxf(0.0, sin(auto_phase * 0.63 - 1.1)) * sediment_flow * 0.11
        surface = clampf(maxf(surface, auto_surface), 0.0, 1.0)
        deep = clampf(maxf(deep, auto_deep), 0.0, 1.0)

        if deep_glyph != " " and deep > 0.015:
            _draw_layer_glyph(font, deep_glyph, font_size, baseline, DEEP_INK, deep, direction, 2, char_index)
        if old_glyph != " " and surface > 0.015:
            _draw_layer_glyph(font, old_glyph, font_size, baseline, OLD_INK, surface * (1.0 - deep * 0.35), -direction, 1, char_index)
        if current_glyph != " ":
            var current_alpha: float = clampf(0.96 - surface * 0.68 - deep * 0.78, 0.08, 1.0)
            _draw_layer_glyph(font, current_glyph, font_size, baseline, PAPER, current_alpha, Vector2.ZERO, 0, char_index)


func _draw_layer_glyph(
    font: Font,
    glyph: String,
    font_size: int,
    baseline: Vector2,
    color: Color,
    amount: float,
    direction: Vector2,
    layer: int,
    char_index: int
) -> void:
    var contours: Array[PackedVector2Array] = get_glyph_outline_contours(font, glyph, font_size, baseline, 7)
    if contours.is_empty():
        var fallback: Color = color
        fallback.a *= amount
        draw_string(font, baseline, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fallback)
        return

    var bounds: Rect2 = outline_bounds(contours)
    var center: Vector2 = bounds.get_center()
    var mapped_set: Array[PackedVector2Array] = []
    for contour_index: int in range(contours.size()):
        var mapped: PackedVector2Array = PackedVector2Array()
        for point_index: int in range(contours[contour_index].size()):
            var p: Vector2 = contours[contour_index][point_index]
            var relative: Vector2 = p - center
            var phase: float = sketch_time * (0.18 + float(layer) * 0.07) + float(char_index) * 0.53 + relative.y * 0.025
            var q: Vector2 = p
            q += direction * amount * (8.0 + float(layer) * 9.0)
            q.x += sin(phase) * amount * layer_drift * (3.0 + float(layer) * 4.0)
            q.y += cos(phase * 0.81 + relative.x * 0.02) * amount * layer_drift * 4.0
            if layer > 0:
                q += relative.normalized() * amount * float(layer) * 1.8
            mapped.append(q)
        mapped_set.append(mapped)

    var ink: Color = color
    ink.a *= clampf(amount, 0.0, 1.0)
    draw_outline_contours(mapped_set, ink, 1.4 + float(layer) * 0.8, true)


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
        var radius: float = 118.0 + float(mark.get("energy", 0.0)) * 58.0
        if distance >= radius:
            continue
        var radial: float = 1.0 - distance / radius
        var amount: float = radial * float(mark.get("energy", 0.0))
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
