extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.018, 0.019, 0.024, 1.0)
const PAPER: Color = Color(0.96, 0.94, 0.86, 1.0)
const ACCENT: Color = Color(0.96, 0.24, 0.11, 1.0)
const COOL: Color = Color(0.30, 0.58, 0.72, 1.0)
const LINES: Array[String] = ["BREATHE", "BETWEEN", "WORDS"]
const BASELINES: Array[float] = [235.0, 402.0, 574.0]

@export_range(2.8, 12.0, 0.1) var cycle_seconds: float = 6.6
@export_range(0.0, 1.0, 0.01) var autonomy: float = 0.78
@export_range(0.2, 2.4, 0.01) var elasticity: float = 1.15
@export_range(0.0, 2.0, 0.01) var touch_pressure: float = 1.0
@export_range(0.0, 1.0, 0.01) var contour_separation: float = 0.42
@export_range(0.2, 1.0, 0.01) var ink_density: float = 0.82

var _breath: float = 0.0
var _breath_velocity: float = 0.0
var _gesture_velocity: Vector2 = Vector2.ZERO
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _press_age: float = 0.0
var _impulse_energy: float = 0.0
var _impulse_center: Vector2 = DESIGN_SIZE * 0.5
var _active_line: int = 1


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "cycle_seconds", "label": "BREATH TEMPO", "type": "float", "min": 2.8, "max": 12.0, "step": 0.1},
        {"id": "autonomy", "label": "AUTONOMY", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "elasticity", "label": "ELASTICITY", "type": "float", "min": 0.2, "max": 2.4, "step": 0.01},
        {"id": "touch_pressure", "label": "TOUCH PRESSURE", "type": "float", "min": 0.0, "max": 2.0, "step": 0.01},
        {"id": "contour_separation", "label": "COUNTER TENSION", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "ink_density", "label": "INK DENSITY", "type": "float", "min": 0.2, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "cycle_seconds": return cycle_seconds
        "autonomy": return autonomy
        "elasticity": return elasticity
        "touch_pressure": return touch_pressure
        "contour_separation": return contour_separation
        "ink_density": return ink_density
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "cycle_seconds": cycle_seconds = clampf(float(value), 2.8, 12.0)
        "autonomy": autonomy = clampf(float(value), 0.0, 1.0)
        "elasticity": elasticity = clampf(float(value), 0.2, 2.4)
        "touch_pressure": touch_pressure = clampf(float(value), 0.0, 2.0)
        "contour_separation": contour_separation = clampf(float(value), 0.0, 1.0)
        "ink_density": ink_density = clampf(float(value), 0.2, 1.0)
        _: return
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    var phase: float = sketch_time / maxf(0.1, cycle_seconds) * TAU
    var inhale_wave: float = 0.5 + 0.5 * sin(phase - PI * 0.5)
    inhale_wave = smoothstep(0.04, 0.96, inhale_wave)
    var second_lung: float = 0.5 + 0.5 * sin(phase * 0.5 + 1.7)
    var autonomous_target: float = (inhale_wave * 0.82 + second_lung * 0.18) * autonomy

    var target_velocity: Vector2 = Vector2.ZERO
    if pointer_active:
        if _pointer_ready and delta > 0.0001:
            target_velocity = (pointer_position - _last_pointer) / delta
        _last_pointer = pointer_position
        _pointer_ready = true
    else:
        _pointer_ready = false
    _gesture_velocity = _gesture_velocity.lerp(target_velocity, clampf(delta * 8.0, 0.0, 1.0))

    var interaction_target: float = 0.0
    if pointer_down:
        _press_age += delta
        _impulse_center = pointer_position
        _active_line = clampi(roundi((pointer_position.y - BASELINES[0]) / (BASELINES[1] - BASELINES[0])), 0, 2)
        var dwell: float = 1.0 - exp(-_press_age * 1.4)
        var speed: float = clampf(_gesture_velocity.length() / 1300.0, 0.0, 1.0)
        interaction_target = (0.34 + dwell * 0.58 + speed * 0.34) * touch_pressure
        _impulse_energy = maxf(_impulse_energy, interaction_target)
    else:
        _press_age = 0.0
        _impulse_energy = maxf(0.0, _impulse_energy - delta * (0.32 + elasticity * 0.36))

    var target: float = autonomous_target + interaction_target * 0.62
    var spring: float = (target - _breath) * (2.6 + elasticity * 2.1)
    _breath_velocity += spring * delta
    _breath_velocity *= pow(0.18, delta)
    _breath += _breath_velocity * delta
    _breath = clampf(_breath, -0.12, 1.65)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "breath": _breath,
        "breath_velocity": _breath_velocity,
        "gesture_velocity": _gesture_velocity,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
        "press_age": _press_age,
        "impulse_energy": _impulse_energy,
        "impulse_center": _impulse_center,
        "active_line": _active_line,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _breath = float(state.get("breath", _breath))
    _breath_velocity = float(state.get("breath_velocity", _breath_velocity))
    var velocity_variant: Variant = state.get("gesture_velocity", _gesture_velocity)
    if velocity_variant is Vector2:
        _gesture_velocity = velocity_variant as Vector2
    var pointer_variant: Variant = state.get("last_pointer", _last_pointer)
    if pointer_variant is Vector2:
        _last_pointer = pointer_variant as Vector2
    _pointer_ready = bool(state.get("pointer_ready", _pointer_ready))
    _press_age = float(state.get("press_age", _press_age))
    _impulse_energy = float(state.get("impulse_energy", _impulse_energy))
    var impulse_variant: Variant = state.get("impulse_center", _impulse_center)
    if impulse_variant is Vector2:
        _impulse_center = impulse_variant as Vector2
    _active_line = int(state.get("active_line", _active_line))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "breath": _breath,
        "impulse_energy": _impulse_energy,
        "active_line": _active_line,
        "gesture_speed": _gesture_velocity.length(),
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_air_field()
    for line_index: int in range(LINES.size()):
        _draw_living_word(font, line_index)
    end_design_draw()


func _draw_air_field() -> void:
    # Full-canvas atmospheric field. It is part of the artwork, not a frame.
    for band: int in range(15):
        var y0: float = 34.0 + float(band) * 48.0
        var points: PackedVector2Array = PackedVector2Array()
        for step: int in range(33):
            var x: float = float(step) / 32.0 * DESIGN_SIZE.x
            var wave: float = sin(x * 0.008 + sketch_time * 0.34 + float(band) * 0.73)
            wave += sin(x * 0.0027 - sketch_time * 0.19 + float(band)) * 0.6
            var breathing: float = (_breath - 0.45) * 13.0 * sin(float(band) * 0.8 + x * 0.004)
            points.append(Vector2(x, y0 + wave * 5.0 + breathing))
        var c: Color = COOL.lerp(ACCENT, float(band % 5) / 5.0)
        c.a = 0.018 + autonomy * 0.018
        draw_polyline(points, c, 1.0, true)


func _draw_living_word(font: Font, line_index: int) -> void:
    var text: String = LINES[line_index]
    var font_size: int = [132, 96, 132][line_index]
    var tracking: float = [18.0, 22.0, 20.0][line_index]
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
    var line_phase: float = sketch_time * (0.42 + float(line_index) * 0.035) + float(line_index) * 1.8
    var line_breath: float = clampf(_breath * (0.78 + 0.12 * sin(line_phase)), 0.0, 1.5)

    for char_index: int in range(text.length()):
        var glyph: String = text.substr(char_index, 1)
        var baseline: Vector2 = Vector2(cursor_x, BASELINES[line_index])
        var contours: Array[PackedVector2Array] = get_glyph_outline_contours(font, glyph, font_size, baseline, 7)

        if contours.is_empty():
            var fallback_color: Color = PAPER
            fallback_color.a = ink_density
            draw_string(font, baseline, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fallback_color)
            cursor_x += widths[char_index] + tracking
            continue

        var bounds: Rect2 = outline_bounds(contours)
        var center: Vector2 = bounds.get_center()
        var glyph_phase: float = line_phase + float(char_index) * 0.61
        var active_bias: float = 1.0 if line_index == _active_line else 0.52
        var local_impulse: float = 0.0
        var glyph_center: Vector2 = Vector2(cursor_x + widths[char_index] * 0.5, BASELINES[line_index] - float(font_size) * 0.35)
        if _impulse_energy > 0.001:
            var distance: float = glyph_center.distance_to(_impulse_center)
            local_impulse = exp(-distance * distance / 72000.0) * _impulse_energy * active_bias

        var main_contours: Array[PackedVector2Array] = _deform_breath_contours(
            contours,
            center,
            line_breath,
            local_impulse,
            glyph_phase,
            1.0
        )
        var ghost_contours: Array[PackedVector2Array] = _deform_breath_contours(
            contours,
            center,
            line_breath,
            local_impulse,
            glyph_phase + 0.8,
            1.0 + contour_separation * 0.22
        )

        var ghost: Color = ACCENT.lerp(COOL, float(line_index) / 2.0)
        ghost.a = (0.10 + local_impulse * 0.20) * contour_separation
        draw_outline_contours(ghost_contours, ghost, 1.2 + contour_separation * 1.4, true)

        var ink: Color = PAPER.lerp(ACCENT, local_impulse * 0.24)
        ink.a = ink_density
        draw_outline_contours(main_contours, ink, 2.0 + ink_density * 1.2, true)

        # A restrained fill keeps the word readable while the actual contour
        # carries the deformation.
        var fill: Color = PAPER
        fill.a = 0.08 + ink_density * 0.08
        draw_string(font, baseline, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fill)
        cursor_x += widths[char_index] + tracking


func _deform_breath_contours(
    contours: Array[PackedVector2Array],
    center: Vector2,
    breath_amount: float,
    impulse: float,
    phase: float,
    layer_scale: float
) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array] = []
    var velocity_dir: Vector2 = _gesture_velocity.normalized() if _gesture_velocity.length() > 2.0 else Vector2.RIGHT

    for contour_index: int in range(contours.size()):
        var source: PackedVector2Array = contours[contour_index]
        var mapped: PackedVector2Array = PackedVector2Array()
        for point_index: int in range(source.size()):
            var point: Vector2 = source[point_index]
            var relative: Vector2 = point - center
            var radial_scale: float = 1.0 + breath_amount * 0.035 * layer_scale
            var q: Vector2 = center + relative * radial_scale

            # Different parts of one glyph breathe at slightly different
            # phases. This changes the outline itself instead of moving a whole
            # character as a rigid sprite.
            var anatomy_wave: float = sin(relative.y * 0.045 + phase + relative.x * 0.012)
            q.x += anatomy_wave * (2.2 + breath_amount * 5.8) * layer_scale
            q.y += sin(relative.x * 0.032 - phase * 0.83) * breath_amount * 3.8

            if impulse > 0.001:
                var to_point: Vector2 = q - _impulse_center
                var influence: float = exp(-to_point.length_squared() / 36000.0) * impulse
                var radial: Vector2 = to_point.normalized() if to_point.length() > 0.001 else Vector2.UP
                q += radial * influence * 18.0 * touch_pressure
                q += velocity_dir * influence * 9.0 * touch_pressure

            mapped.append(q)
        result.append(mapped)
    return result
