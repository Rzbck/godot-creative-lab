extends "res://sketches/_shared/design_sketch_base.gd"

const TEXT_VALUE: String = "LIQUID TYPE"
const BG_A: Color = Color(0.018, 0.024, 0.04, 1.0)
const BG_B: Color = Color(0.035, 0.018, 0.05, 1.0)
const INK: Color = Color(0.96, 0.93, 0.84, 1.0)
const AMBER: Color = Color(1.0, 0.55, 0.16, 1.0)
const CYAN: Color = Color(0.1, 0.78, 0.95, 1.0)
const MAGENTA: Color = Color(1.0, 0.16, 0.52, 1.0)

@export_range(0.55, 1.35, 0.01) var type_scale: float = 1.0
@export_range(0.0, 140.0, 1.0) var warp_strength: float = 72.0
@export_range(0.0, 70.0, 1.0) var wave_amount: float = 22.0
@export_range(0.0, 3.0, 0.01) var wave_speed: float = 0.95
@export_range(0.0, 1.0, 0.01) var elasticity: float = 0.72
@export_range(40.0, 420.0, 1.0) var pointer_radius: float = 210.0
@export_range(0.0, 2.5, 0.01) var pointer_force: float = 1.0
@export_range(0.0, 22.0, 0.1) var chroma_split: float = 7.0
@export_range(0.0, 1.0, 0.01) var glow_amount: float = 0.35
@export_range(0.0, 1.0, 0.01) var palette_mix: float = 0.2


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "type_scale", "label": "TYPE SCALE", "type": "float", "min": 0.55, "max": 1.35, "step": 0.01},
        {"id": "warp_strength", "label": "WARP", "type": "float", "min": 0.0, "max": 140.0, "step": 1.0},
        {"id": "wave_amount", "label": "WAVE", "type": "float", "min": 0.0, "max": 70.0, "step": 1.0},
        {"id": "wave_speed", "label": "WAVE SPEED", "type": "float", "min": 0.0, "max": 3.0, "step": 0.01},
        {"id": "elasticity", "label": "ELASTICITY", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "pointer_radius", "label": "FIELD RADIUS", "type": "float", "min": 40.0, "max": 420.0, "step": 1.0},
        {"id": "pointer_force", "label": "FIELD FORCE", "type": "float", "min": 0.0, "max": 2.5, "step": 0.01},
        {"id": "chroma_split", "label": "RGB SPLIT", "type": "float", "min": 0.0, "max": 22.0, "step": 0.1},
        {"id": "glow_amount", "label": "GLOW", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "palette_mix", "label": "PALETTE", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "type_scale": return type_scale
        "warp_strength": return warp_strength
        "wave_amount": return wave_amount
        "wave_speed": return wave_speed
        "elasticity": return elasticity
        "pointer_radius": return pointer_radius
        "pointer_force": return pointer_force
        "chroma_split": return chroma_split
        "glow_amount": return glow_amount
        "palette_mix": return palette_mix
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "type_scale": type_scale = clampf(float(value), 0.55, 1.35)
        "warp_strength": warp_strength = clampf(float(value), 0.0, 140.0)
        "wave_amount": wave_amount = clampf(float(value), 0.0, 70.0)
        "wave_speed": wave_speed = clampf(float(value), 0.0, 3.0)
        "elasticity": elasticity = clampf(float(value), 0.0, 1.0)
        "pointer_radius": pointer_radius = clampf(float(value), 40.0, 420.0)
        "pointer_force": pointer_force = clampf(float(value), 0.0, 2.5)
        "chroma_split": chroma_split = clampf(float(value), 0.0, 22.0)
        "glow_amount": glow_amount = clampf(float(value), 0.0, 1.0)
        "palette_mix": palette_mix = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _draw() -> void:
    begin_design_draw(palette_lerp(BG_A, BG_B, palette_mix))

    var font: Font = ThemeDB.fallback_font
    var font_size: int = maxi(18, roundi(126.0 * type_scale))
    var tracking: float = 9.0 * type_scale
    var widths: Array[float] = []
    var total_width: float = 0.0

    for index: int in range(TEXT_VALUE.length()):
        var glyph: String = TEXT_VALUE.substr(index, 1)
        var glyph_width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
        widths.append(glyph_width)
        total_width += glyph_width
        if index < TEXT_VALUE.length() - 1:
            total_width += tracking

    var focus: Vector2 = pointer_position
    if not pointer_active:
        focus = Vector2(
            640.0 + sin(sketch_time * 0.48) * 250.0,
            360.0 + cos(sketch_time * 0.61) * 120.0
        )

    _draw_background_field(focus)

    var cursor_x: float = (DESIGN_SIZE.x - total_width) * 0.5
    var baseline: float = DESIGN_SIZE.y * 0.56
    var accent: Color = palette_lerp(AMBER, MAGENTA, palette_mix)
    var secondary: Color = palette_lerp(CYAN, AMBER, palette_mix)

    for index: int in range(TEXT_VALUE.length()):
        var glyph: String = TEXT_VALUE.substr(index, 1)
        var glyph_width: float = widths[index]
        var glyph_center: Vector2 = Vector2(cursor_x + glyph_width * 0.5, baseline - float(font_size) * 0.35)
        var wave: float = sin(sketch_time * wave_speed * 2.0 + float(index) * 0.72) * wave_amount
        var sideways: float = cos(sketch_time * wave_speed * 1.35 + float(index) * 0.51) * wave_amount * 0.28

        var field_offset: Vector2 = Vector2.ZERO
        var to_glyph: Vector2 = glyph_center - focus
        var distance: float = to_glyph.length()
        if distance < pointer_radius and distance > 0.001:
            var field_amount: float = 1.0 - distance / pointer_radius
            var pressed_boost: float = 1.65 if pointer_down else 1.0
            var direction: Vector2 = to_glyph / distance
            var tangent: Vector2 = Vector2(-direction.y, direction.x)
            field_offset = (
                direction * warp_strength * field_amount * pointer_force * pressed_boost
                + tangent * warp_strength * 0.34 * field_amount * sin(sketch_time * 2.4 + float(index))
            )

        var elastic_wave: float = sin(sketch_time * 3.2 - float(index) * 0.9) * wave_amount * elasticity * 0.32
        var position: Vector2 = Vector2(cursor_x + sideways, baseline + wave + elastic_wave) + field_offset

        if glyph != " ":
            var split_direction: Vector2 = Vector2(
                cos(sketch_time * 0.8 + float(index)),
                sin(sketch_time * 0.9 + float(index) * 0.7)
            )
            var split: Vector2 = split_direction * chroma_split

            var cyan_color: Color = secondary
            cyan_color.a = 0.18 + glow_amount * 0.22
            draw_string(font, position - split, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, cyan_color)

            var magenta_color: Color = accent
            magenta_color.a = 0.18 + glow_amount * 0.22
            draw_string(font, position + split, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, magenta_color)

            for smear_index: int in range(4):
                var smear_t: float = float(smear_index + 1) / 4.0
                var smear_offset: Vector2 = Vector2(
                    -field_offset.x * smear_t * 0.22,
                    -wave * smear_t * 0.16
                )
                var smear_color: Color = accent
                smear_color.a = glow_amount * (0.11 - smear_t * 0.018)
                draw_string(font, position + smear_offset, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, smear_color)

            draw_string(font, position, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)

        cursor_x += glyph_width + tracking

    var caption_color: Color = accent
    caption_color.a = 0.72
    draw_string(font, Vector2(76.0, 92.0), "002 / LIQUID TYPE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, caption_color)
    draw_string(font, Vector2(76.0, 656.0), "POINTER FIELD / ELASTIC LETTERFORM / LIVE SYNC", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.78, 0.8, 0.86, 0.48))

    end_design_draw()


func _draw_background_field(focus: Vector2) -> void:
    var accent: Color = palette_lerp(AMBER, MAGENTA, palette_mix)
    for ring_index: int in range(5):
        var radius: float = pointer_radius * (0.35 + float(ring_index) * 0.18)
        var ring_color: Color = accent
        ring_color.a = 0.025 + glow_amount * 0.012
        draw_arc(focus, radius, 0.0, TAU, 96, ring_color, 1.0, true)

    for line_index: int in range(7):
        var y: float = 142.0 + float(line_index) * 72.0
        var line_color: Color = Color(0.8, 0.85, 0.95, 0.018 + float(line_index % 2) * 0.01)
        draw_line(Vector2(56.0, y), Vector2(1224.0, y), line_color, 1.0, true)
