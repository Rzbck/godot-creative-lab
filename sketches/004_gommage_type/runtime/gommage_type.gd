extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.015, 0.012, 0.02, 1.0)
const PAPER: Color = Color(0.96, 0.93, 0.84, 1.0)
const ORANGE: Color = Color(1.0, 0.46, 0.12, 1.0)
const PINK: Color = Color(1.0, 0.12, 0.42, 1.0)
const BLUE: Color = Color(0.1, 0.62, 1.0, 1.0)
const LINES: Array[String] = ["ERASE", "REBUILD"]

@export_range(60.0, 320.0, 1.0) var dissolve_radius: float = 155.0
@export_range(0.1, 2.0, 0.01) var dissolve_strength: float = 1.0
@export_range(0, 22, 1) var dust_amount: int = 9
@export_range(0.05, 1.5, 0.01) var rebuild_speed: float = 0.38
@export_range(2, 24, 1) var trail_length: int = 12
@export_range(0.1, 3.0, 0.01) var noise_scale: float = 1.0
@export_range(0.0, 1.0, 0.01) var edge_glow: float = 0.65
@export_range(0.2, 2.5, 0.01) var pointer_force: float = 1.0
@export_range(0.0, 1.0, 0.01) var palette_mix: float = 0.15

var _marks: Array[Dictionary] = []
var _mark_accumulator: float = 0.0


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "dissolve_radius", "label": "DISSOLVE RADIUS", "type": "float", "min": 60.0, "max": 320.0, "step": 1.0},
        {"id": "dissolve_strength", "label": "DISSOLVE", "type": "float", "min": 0.1, "max": 2.0, "step": 0.01},
        {"id": "dust_amount", "label": "DUST", "type": "int", "min": 0.0, "max": 22.0, "step": 1.0},
        {"id": "rebuild_speed", "label": "REBUILD SPEED", "type": "float", "min": 0.05, "max": 1.5, "step": 0.01},
        {"id": "trail_length", "label": "TRAIL", "type": "int", "min": 2.0, "max": 24.0, "step": 1.0},
        {"id": "noise_scale", "label": "NOISE", "type": "float", "min": 0.1, "max": 3.0, "step": 0.01},
        {"id": "edge_glow", "label": "EDGE GLOW", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "pointer_force", "label": "POINTER FORCE", "type": "float", "min": 0.2, "max": 2.5, "step": 0.01},
        {"id": "palette_mix", "label": "PALETTE", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "dissolve_radius": return dissolve_radius
        "dissolve_strength": return dissolve_strength
        "dust_amount": return dust_amount
        "rebuild_speed": return rebuild_speed
        "trail_length": return trail_length
        "noise_scale": return noise_scale
        "edge_glow": return edge_glow
        "pointer_force": return pointer_force
        "palette_mix": return palette_mix
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "dissolve_radius": dissolve_radius = clampf(float(value), 60.0, 320.0)
        "dissolve_strength": dissolve_strength = clampf(float(value), 0.1, 2.0)
        "dust_amount": dust_amount = clampi(int(value), 0, 22)
        "rebuild_speed": rebuild_speed = clampf(float(value), 0.05, 1.5)
        "trail_length": trail_length = clampi(int(value), 2, 24)
        "noise_scale": noise_scale = clampf(float(value), 0.1, 3.0)
        "edge_glow": edge_glow = clampf(float(value), 0.0, 1.0)
        "pointer_force": pointer_force = clampf(float(value), 0.2, 2.5)
        "palette_mix": palette_mix = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    for mark_index: int in range(_marks.size() - 1, -1, -1):
        var mark: Dictionary = _marks[mark_index]
        var energy: float = float(mark.get("energy", 0.0)) - rebuild_speed * delta
        if energy <= 0.0:
            _marks.remove_at(mark_index)
            continue
        mark["energy"] = energy
        _marks[mark_index] = mark

    _mark_accumulator += delta
    var interval: float = 0.055
    if _mark_accumulator < interval:
        return
    _mark_accumulator = fmod(_mark_accumulator, interval)

    var mark_position: Vector2
    var mark_energy: float
    if pointer_active:
        mark_position = pointer_position
        mark_energy = (1.0 if pointer_down else 0.58) * pointer_force
    else:
        mark_position = Vector2(
            640.0 + sin(sketch_time * 0.58) * 280.0,
            360.0 + cos(sketch_time * 0.43) * 150.0
        )
        mark_energy = 0.42 * pointer_force

    _marks.append({
        "position": mark_position,
        "energy": mark_energy,
        "birth": sketch_time,
    })

    while _marks.size() > trail_length:
        _marks.remove_at(0)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "marks": _marks.duplicate(true),
        "mark_accumulator": _mark_accumulator,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _marks.clear()
    var marks_variant: Variant = state.get("marks", [])
    if marks_variant is Array:
        for item: Variant in marks_variant as Array:
            if item is Dictionary:
                _marks.append((item as Dictionary).duplicate(true))
    _mark_accumulator = float(state.get("mark_accumulator", _mark_accumulator))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "mark_count": _marks.size(),
    }


func _draw() -> void:
    begin_design_draw(BG)

    var font: Font = ThemeDB.fallback_font
    var accent: Color = palette_lerp(ORANGE, PINK, palette_mix)
    var secondary: Color = palette_lerp(BLUE, ORANGE, palette_mix)

    _draw_background(accent)

    var line_font_size: int = 142
    var line_y: Array[float] = [310.0, 468.0]
    var glyph_global_index: int = 0

    for line_index: int in range(LINES.size()):
        var text: String = LINES[line_index]
        var tracking: float = 13.0
        var widths: Array[float] = []
        var total_width: float = 0.0

        for char_index: int in range(text.length()):
            var glyph: String = text.substr(char_index, 1)
            var width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, line_font_size).x
            widths.append(width)
            total_width += width
            if char_index < text.length() - 1:
                total_width += tracking

        var cursor_x: float = (DESIGN_SIZE.x - total_width) * 0.5
        var baseline: float = line_y[line_index]

        for char_index: int in range(text.length()):
            var glyph: String = text.substr(char_index, 1)
            var glyph_width: float = widths[char_index]
            var glyph_center: Vector2 = Vector2(
                cursor_x + glyph_width * 0.5,
                baseline - float(line_font_size) * 0.34
            )

            var influence: float = _dissolve_influence(glyph_center)
            var noise: float = 0.5 + 0.5 * sin(
                float(glyph_global_index) * 2.73 * noise_scale
                + sketch_time * 2.1
                + glyph_center.x * 0.004 * noise_scale
            )
            var erase: float = clampf(influence * dissolve_strength * lerpf(0.58, 1.24, noise), 0.0, 1.0)
            var alpha: float = 1.0 - erase

            if alpha > 0.015:
                var edge_color: Color = accent
                edge_color.a = edge_glow * erase * 0.75
                var edge_offset: float = 1.0 + 5.0 * erase
                draw_string(
                    font,
                    Vector2(cursor_x + edge_offset, baseline),
                    glyph,
                    HORIZONTAL_ALIGNMENT_LEFT,
                    -1.0,
                    line_font_size,
                    edge_color
                )

                var glyph_color: Color = PAPER
                glyph_color.a = alpha
                draw_string(
                    font,
                    Vector2(cursor_x, baseline),
                    glyph,
                    HORIZONTAL_ALIGNMENT_LEFT,
                    -1.0,
                    line_font_size,
                    glyph_color
                )

            if erase > 0.03 and dust_amount > 0:
                _draw_dust(glyph_center, glyph_global_index, erase, accent, secondary)

            cursor_x += glyph_width + tracking
            glyph_global_index += 1

    _draw_eraser_marks(accent)
    draw_string(font, Vector2(78.0, 82.0), "004 / GOMMAGE TYPE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, accent)
    draw_string(font, Vector2(78.0, 656.0), "ERASE / DUST / MEMORY / RECONSTRUCTION", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.82, 0.8, 0.86, 0.46))

    end_design_draw()


func _dissolve_influence(point: Vector2) -> float:
    var influence: float = 0.0
    for mark: Dictionary in _marks:
        var position_variant: Variant = mark.get("position", Vector2.ZERO)
        if not position_variant is Vector2:
            continue
        var position: Vector2 = position_variant as Vector2
        var distance: float = point.distance_to(position)
        if distance >= dissolve_radius:
            continue
        var radial: float = 1.0 - distance / dissolve_radius
        var energy: float = float(mark.get("energy", 0.0))
        influence = maxf(influence, radial * energy)
    return clampf(influence, 0.0, 1.5)


func _draw_dust(
    center: Vector2,
    glyph_index: int,
    erase: float,
    accent: Color,
    secondary: Color
) -> void:
    for particle_index: int in range(dust_amount):
        var seed: float = float(glyph_index * 37 + particle_index * 13)
        var angle: float = hash01(seed + 1.7) * TAU
        var radial: float = 18.0 + hash01(seed + 5.3) * dissolve_radius * 0.34
        var drift: float = 18.0 + hash01(seed + 11.1) * 68.0
        var motion: Vector2 = Vector2(
            cos(angle + sketch_time * (0.25 + hash01(seed + 2.2) * 0.55)),
            sin(angle * 1.17 + sketch_time * (0.18 + hash01(seed + 3.4) * 0.45))
        )
        var position: Vector2 = center + Vector2(cos(angle), sin(angle)) * radial + motion * drift * erase
        var radius: float = 0.8 + hash01(seed + 9.8) * 3.2
        var color: Color = accent.lerp(secondary, hash01(seed + 6.6))
        color.a = erase * (0.16 + hash01(seed + 7.7) * 0.52)
        draw_circle(position, radius, color)


func _draw_eraser_marks(accent: Color) -> void:
    for mark: Dictionary in _marks:
        var position_variant: Variant = mark.get("position", Vector2.ZERO)
        if not position_variant is Vector2:
            continue
        var position: Vector2 = position_variant as Vector2
        var energy: float = clampf(float(mark.get("energy", 0.0)), 0.0, 1.0)
        var ring_color: Color = accent
        ring_color.a = 0.02 + edge_glow * energy * 0.035
        draw_arc(position, dissolve_radius * (0.38 + energy * 0.48), 0.0, TAU, 96, ring_color, 1.0, true)


func _draw_background(accent: Color) -> void:
    for index: int in range(10):
        var x: float = 70.0 + float(index) * 126.0
        var color: Color = accent
        color.a = 0.012 + float(index % 3) * 0.004
        draw_line(Vector2(x, 118.0), Vector2(x, 610.0), color, 1.0)
