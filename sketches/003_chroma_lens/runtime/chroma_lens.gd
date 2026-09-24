extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.012, 0.015, 0.026, 1.0)
const BASE_INK: Color = Color(0.78, 0.81, 0.88, 0.58)
const RED: Color = Color(1.0, 0.15, 0.22, 1.0)
const CYAN: Color = Color(0.0, 0.82, 1.0, 1.0)
const BLUE: Color = Color(0.22, 0.36, 1.0, 1.0)
const ACCENT: Color = Color(1.0, 0.68, 0.18, 1.0)
const GLYPH_STREAM: String = "CHROMA//TYPE//SIGNAL//LENS//RGB//"

# The typography lives inside one fixed, centred safe area. GRID DENSITY only
# changes how many cells are fitted inside it; it never changes the outer margins.
const TYPE_SAFE_RECT: Rect2 = Rect2(80.0, 96.0, 1120.0, 528.0)
const TYPE_EDGE_GAP: float = 5.0

@export_range(80.0, 360.0, 1.0) var lens_size: float = 210.0
@export_range(0.0, 2.0, 0.01) var distortion: float = 0.72
@export_range(0.0, 24.0, 0.1) var chroma_amount: float = 7.0
@export_range(1.0, 2.2, 0.01) var zoom_factor: float = 1.24
@export_range(0.0, 1.0, 0.01) var edge_softness: float = 0.5
@export_range(5, 18, 1) var grid_density: int = 11
@export_range(0.0, 2.0, 0.01) var motion_speed: float = 0.35
@export_range(0.3, 1.5, 0.01) var contrast: float = 0.95
@export_range(0.0, 1.0, 0.01) var palette_mix: float = 0.1


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "lens_size", "label": "LENS SIZE", "type": "float", "min": 80.0, "max": 360.0, "step": 1.0},
        {"id": "distortion", "label": "DISTORTION", "type": "float", "min": 0.0, "max": 2.0, "step": 0.01},
        {"id": "chroma_amount", "label": "CHROMA", "type": "float", "min": 0.0, "max": 24.0, "step": 0.1},
        {"id": "zoom_factor", "label": "ZOOM", "type": "float", "min": 1.0, "max": 2.2, "step": 0.01},
        {"id": "edge_softness", "label": "EDGE SOFT", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "grid_density", "label": "GRID DENSITY", "type": "int", "min": 5.0, "max": 18.0, "step": 1.0},
        {"id": "motion_speed", "label": "MOTION", "type": "float", "min": 0.0, "max": 2.0, "step": 0.01},
        {"id": "contrast", "label": "CONTRAST", "type": "float", "min": 0.3, "max": 1.5, "step": 0.01},
        {"id": "palette_mix", "label": "PALETTE", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "lens_size": return lens_size
        "distortion": return distortion
        "chroma_amount": return chroma_amount
        "zoom_factor": return zoom_factor
        "edge_softness": return edge_softness
        "grid_density": return grid_density
        "motion_speed": return motion_speed
        "contrast": return contrast
        "palette_mix": return palette_mix
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "lens_size": lens_size = clampf(float(value), 80.0, 360.0)
        "distortion": distortion = clampf(float(value), 0.0, 2.0)
        "chroma_amount": chroma_amount = clampf(float(value), 0.0, 24.0)
        "zoom_factor": zoom_factor = clampf(float(value), 1.0, 2.2)
        "edge_softness": edge_softness = clampf(float(value), 0.0, 1.0)
        "grid_density": grid_density = clampi(int(value), 5, 18)
        "motion_speed": motion_speed = clampf(float(value), 0.0, 2.0)
        "contrast": contrast = clampf(float(value), 0.3, 1.5)
        "palette_mix": palette_mix = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _draw() -> void:
    begin_design_draw(BG)

    var font: Font = ThemeDB.fallback_font
    var lens_center: Vector2 = pointer_position
    if not pointer_active:
        lens_center = Vector2(
            640.0 + sin(sketch_time * motion_speed * 1.35) * 260.0,
            360.0 + cos(sketch_time * motion_speed * 1.07) * 150.0
        )

    _draw_background_grid(lens_center)

    var cols: int = grid_density
    var rows: int = maxi(4, roundi(float(grid_density) * 0.56))

    # Use cell centres instead of using the first/last glyph as the grid bounds.
    # This keeps the complete composition centred for every density value.
    var cell_width: float = TYPE_SAFE_RECT.size.x / float(cols)
    var cell_height: float = TYPE_SAFE_RECT.size.y / float(rows)
    var font_size: int = maxi(
        18,
        mini(
            roundi(cell_width * 0.56),
            roundi(cell_height * 0.58)
        )
    )

    var red_color: Color = palette_lerp(RED, ACCENT, palette_mix)
    var cyan_color: Color = palette_lerp(CYAN, BLUE, palette_mix)

    var glyph_index: int = 0
    for row: int in range(rows):
        for col: int in range(cols):
            var phase: float = sketch_time * motion_speed + float(row) * 0.47 + float(col) * 0.31
            var cell_center: Vector2 = Vector2(
                TYPE_SAFE_RECT.position.x + (float(col) + 0.5) * cell_width,
                TYPE_SAFE_RECT.position.y + (float(row) + 0.5) * cell_height
            )
            var base_position: Vector2 = cell_center + Vector2(
                sin(phase * 1.7) * minf(5.0, cell_width * 0.07),
                cos(phase * 1.25) * minf(5.0, cell_height * 0.07)
            )

            var glyph: String = GLYPH_STREAM.substr(glyph_index % GLYPH_STREAM.length(), 1)
            glyph_index += 1
            if glyph == " ":
                continue

            var to_cell: Vector2 = base_position - lens_center
            var distance: float = to_cell.length()
            var normalized: float = clampf(distance / lens_size, 0.0, 1.0)
            var inside: bool = distance < lens_size

            if not inside:
                var outside_alpha: float = 0.24 + contrast * 0.22
                var outside_color: Color = BASE_INK
                outside_color.a = outside_alpha
                var safe_base: Vector2 = _clamp_glyph_center(base_position, font, glyph, font_size, 0.0)
                _draw_centered_glyph(font, safe_base, glyph, font_size, outside_color)
                continue

            var lens_amount: float = 1.0 - normalized
            var smooth_amount: float = pow(lens_amount, lerpf(0.55, 2.1, edge_softness))
            var radial: Vector2 = Vector2.ZERO
            if distance > 0.001:
                radial = to_cell / distance
            var tangent: Vector2 = Vector2(-radial.y, radial.x)

            var zoomed: Vector2 = lens_center + to_cell * lerpf(1.0, zoom_factor, smooth_amount)
            var wobble: Vector2 = tangent * sin(phase * 3.0 + distance * 0.025) * distortion * 18.0 * smooth_amount
            var target: Vector2 = zoomed + wobble
            var split: Vector2 = (radial + tangent * 0.35).normalized() * chroma_amount * smooth_amount
            var pressed_boost: float = 1.35 if pointer_down else 1.0
            target += radial * distortion * 13.0 * smooth_amount * pressed_boost

            # The lens may distort a glyph, but it may not break the typography
            # safe area. Account for the RGB split as well as the glyph itself.
            target = _clamp_glyph_center(
                target,
                font,
                glyph,
                font_size,
                split.length()
            )

            var shadow_red: Color = red_color
            shadow_red.a = 0.42 + 0.42 * smooth_amount
            var shadow_cyan: Color = cyan_color
            shadow_cyan.a = 0.42 + 0.42 * smooth_amount
            var core: Color = Color(0.98, 0.98, 0.96, 0.72 + 0.28 * smooth_amount)

            _draw_centered_glyph(font, target - split, glyph, font_size, shadow_cyan)
            _draw_centered_glyph(font, target + split, glyph, font_size, shadow_red)
            _draw_centered_glyph(font, target, glyph, font_size, core)

    _draw_lens_overlay(lens_center, red_color, cyan_color)
    end_design_draw()


func _draw_centered_glyph(
    font: Font,
    center: Vector2,
    glyph: String,
    font_size: int,
    color: Color
) -> void:
    var glyph_size: Vector2 = font.get_string_size(
        glyph,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        font_size
    )
    var ascent: float = font.get_ascent(font_size)
    var descent: float = font.get_descent(font_size)
    var baseline: Vector2 = Vector2(
        center.x - glyph_size.x * 0.5,
        center.y + (ascent - descent) * 0.5
    )
    draw_string(
        font,
        baseline,
        glyph,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        font_size,
        color
    )


func _clamp_glyph_center(
    center: Vector2,
    font: Font,
    glyph: String,
    font_size: int,
    extra_radius: float
) -> Vector2:
    var glyph_size: Vector2 = font.get_string_size(
        glyph,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        font_size
    )
    var glyph_height: float = font.get_height(font_size)
    var pad_x: float = glyph_size.x * 0.5 + extra_radius + TYPE_EDGE_GAP
    var pad_y: float = glyph_height * 0.5 + extra_radius + TYPE_EDGE_GAP

    var min_x: float = TYPE_SAFE_RECT.position.x + pad_x
    var max_x: float = TYPE_SAFE_RECT.end.x - pad_x
    var min_y: float = TYPE_SAFE_RECT.position.y + pad_y
    var max_y: float = TYPE_SAFE_RECT.end.y - pad_y

    return Vector2(
        clampf(center.x, min_x, max_x),
        clampf(center.y, min_y, max_y)
    )


func _draw_background_grid(lens_center: Vector2) -> void:
    for x_index: int in range(17):
        var x: float = 48.0 + float(x_index) * 74.0
        draw_line(Vector2(x, 70.0), Vector2(x, 650.0), Color(0.7, 0.8, 1.0, 0.022), 1.0)
    for y_index: int in range(9):
        var y: float = 74.0 + float(y_index) * 72.0
        draw_line(Vector2(48.0, y), Vector2(1232.0, y), Color(0.7, 0.8, 1.0, 0.022), 1.0)

    var halo: Color = ACCENT
    halo.a = 0.025
    draw_circle(lens_center, lens_size * 1.18, halo)


func _draw_lens_overlay(lens_center: Vector2, red_color: Color, cyan_color: Color) -> void:
    var border_a: Color = cyan_color
    border_a.a = 0.28
    var border_b: Color = red_color
    border_b.a = 0.22
    draw_arc(lens_center - Vector2(chroma_amount * 0.22, 0.0), lens_size, 0.0, TAU, 160, border_a, 1.5, true)
    draw_arc(lens_center + Vector2(chroma_amount * 0.22, 0.0), lens_size, 0.0, TAU, 160, border_b, 1.5, true)
    draw_arc(lens_center, lens_size, 0.0, TAU, 160, Color(1.0, 1.0, 1.0, 0.16), 1.0, true)
    draw_line(lens_center - Vector2(14.0, 0.0), lens_center + Vector2(14.0, 0.0), Color(1, 1, 1, 0.18), 1.0)
    draw_line(lens_center - Vector2(0.0, 14.0), lens_center + Vector2(0.0, 14.0), Color(1, 1, 1, 0.18), 1.0)
