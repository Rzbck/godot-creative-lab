extends "res://sketches/_shared/design_sketch_base.gd"

const WORDS: Array[String] = ["FORM", "PRESS", "TRACE"]
const FONT_SIZES: Array[int] = [104, 192, 112]
const BASELINES: Array[float] = [205.0, 410.0, 592.0]
const TRACKING_MULTIPLIERS: Array[float] = [1.0, 0.35, 1.2]
const SAFE_RECT: Rect2 = Rect2(86.0, 64.0, 1108.0, 592.0)
const ROW_COUNT: int = 3

const INK: Color = Color(0.035, 0.045, 0.065, 1.0)
const VERMILION: Color = Color(0.97, 0.16, 0.08, 1.0)
const CYAN: Color = Color(0.0, 0.55, 0.78, 1.0)
const VIOLET: Color = Color(0.42, 0.18, 0.76, 1.0)

@export_range(0.82, 1.18, 0.01) var type_scale: float = 1.0
@export_range(4.0, 28.0, 0.5) var tracking: float = 13.0
@export_range(0.4, 1.6, 0.01) var press_strength: float = 1.0
@export_range(4.0, 38.0, 0.5) var registration: float = 19.0
@export_range(0.35, 1.8, 0.01) var recovery: float = 0.92
@export_range(0.0, 1.0, 0.01) var grain: float = 0.28
@export_range(0.0, 1.0, 0.01) var grid_presence: float = 0.34
@export_range(0.0, 1.0, 0.01) var palette_mix: float = 0.08

@onready var _surface: ColorRect = $ShaderSurface
@onready var _shader_material: ShaderMaterial = $ShaderSurface.material as ShaderMaterial

var _row_energy: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var _row_spring_velocity: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var _row_anchor: PackedFloat32Array = PackedFloat32Array([0.5, 0.5, 0.5])
var _row_direction: Array[Vector2] = [
    Vector2(1.0, 0.0),
    Vector2(1.0, 0.0),
    Vector2(1.0, 0.0),
]
var _gesture_velocity: Vector2 = Vector2.ZERO
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_history_ready: bool = false
var _active_row: int = -1


func _ready() -> void:
    super._ready()
    _surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _update_surface_layout()
    _update_shader_uniforms()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "type_scale", "label": "TYPE SCALE", "type": "float", "min": 0.82, "max": 1.18, "step": 0.01},
        {"id": "tracking", "label": "TRACKING", "type": "float", "min": 4.0, "max": 28.0, "step": 0.5},
        {"id": "press_strength", "label": "PRESSURE", "type": "float", "min": 0.4, "max": 1.6, "step": 0.01},
        {"id": "registration", "label": "REGISTRATION", "type": "float", "min": 4.0, "max": 38.0, "step": 0.5},
        {"id": "recovery", "label": "RECOVERY", "type": "float", "min": 0.35, "max": 1.8, "step": 0.01},
        {"id": "grain", "label": "PRINT GRAIN", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "grid_presence", "label": "GRID", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "palette_mix", "label": "INK PALETTE", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "type_scale": return type_scale
        "tracking": return tracking
        "press_strength": return press_strength
        "registration": return registration
        "recovery": return recovery
        "grain": return grain
        "grid_presence": return grid_presence
        "palette_mix": return palette_mix
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "type_scale": type_scale = clampf(float(value), 0.82, 1.18)
        "tracking": tracking = clampf(float(value), 4.0, 28.0)
        "press_strength": press_strength = clampf(float(value), 0.4, 1.6)
        "registration": registration = clampf(float(value), 4.0, 38.0)
        "recovery": recovery = clampf(float(value), 0.35, 1.8)
        "grain": grain = clampf(float(value), 0.0, 1.0)
        "grid_presence": grid_presence = clampf(float(value), 0.0, 1.0)
        "palette_mix": palette_mix = clampf(float(value), 0.0, 1.0)
        _: return
    _update_shader_uniforms()
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    var target_velocity: Vector2 = Vector2.ZERO
    if pointer_active:
        if _pointer_history_ready and delta > 0.0001:
            target_velocity = (pointer_position - _last_pointer) / delta
        _last_pointer = pointer_position
        _pointer_history_ready = true
    else:
        _pointer_history_ready = false

    _gesture_velocity = _gesture_velocity.lerp(
        target_velocity,
        clampf(delta * 11.0, 0.0, 1.0)
    )

    _active_row = _row_from_point(pointer_position) if pointer_active and pointer_down else -1
    var speed_ratio: float = clampf(_gesture_velocity.length() / 1100.0, 0.0, 1.0)

    if _active_row >= 0:
        _row_anchor[_active_row] = lerpf(
            _row_anchor[_active_row],
            clampf(pointer_position.x / DESIGN_SIZE.x, 0.08, 0.92),
            clampf(delta * 18.0, 0.0, 1.0)
        )

        if _gesture_velocity.length() > 24.0:
            var direction: Vector2 = _gesture_velocity.normalized()
            _row_direction[_active_row] = _row_direction[_active_row].lerp(
                direction,
                clampf(delta * 14.0, 0.0, 1.0)
            ).normalized()

    var spring_strength: float = 17.0 + recovery * 11.0
    var damping: float = 7.5 + recovery * 4.5

    for row_index: int in range(ROW_COUNT):
        var target_energy: float = 0.0
        if row_index == _active_row:
            target_energy = clampf(
                (0.68 + speed_ratio * 0.48) * press_strength,
                0.0,
                1.25
            )

        var acceleration: float = (
            (target_energy - _row_energy[row_index]) * spring_strength
            - _row_spring_velocity[row_index] * damping
        )
        _row_spring_velocity[row_index] += acceleration * delta
        _row_energy[row_index] += _row_spring_velocity[row_index] * delta

        if _row_energy[row_index] < 0.0:
            _row_energy[row_index] = 0.0
            if _row_spring_velocity[row_index] < 0.0:
                _row_spring_velocity[row_index] = 0.0
        elif _row_energy[row_index] > 1.3:
            _row_energy[row_index] = 1.3

    _update_shader_uniforms()


func _row_from_point(point: Vector2) -> int:
    if not SAFE_RECT.has_point(point):
        return -1

    var best_row: int = -1
    var best_distance: float = INF
    for row_index: int in range(ROW_COUNT):
        var visual_center_y: float = BASELINES[row_index] - float(FONT_SIZES[row_index]) * type_scale * 0.34
        var distance: float = absf(point.y - visual_center_y)
        if distance < best_distance:
            best_distance = distance
            best_row = row_index

    return best_row if best_distance <= 105.0 else -1


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "row0_energy": _row_energy[0],
        "row1_energy": _row_energy[1],
        "row2_energy": _row_energy[2],
        "row0_velocity": _row_spring_velocity[0],
        "row1_velocity": _row_spring_velocity[1],
        "row2_velocity": _row_spring_velocity[2],
        "row0_anchor": _row_anchor[0],
        "row1_anchor": _row_anchor[1],
        "row2_anchor": _row_anchor[2],
        "row0_direction": _row_direction[0],
        "row1_direction": _row_direction[1],
        "row2_direction": _row_direction[2],
        "gesture_velocity": _gesture_velocity,
        "last_pointer": _last_pointer,
        "pointer_history_ready": _pointer_history_ready,
        "active_row": _active_row,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    for row_index: int in range(ROW_COUNT):
        _row_energy[row_index] = float(state.get("row%d_energy" % row_index, _row_energy[row_index]))
        _row_spring_velocity[row_index] = float(state.get("row%d_velocity" % row_index, _row_spring_velocity[row_index]))
        _row_anchor[row_index] = float(state.get("row%d_anchor" % row_index, _row_anchor[row_index]))
        var direction_variant: Variant = state.get("row%d_direction" % row_index, _row_direction[row_index])
        if direction_variant is Vector2:
            _row_direction[row_index] = direction_variant as Vector2

    var gesture_variant: Variant = state.get("gesture_velocity", _gesture_velocity)
    if gesture_variant is Vector2:
        _gesture_velocity = gesture_variant as Vector2

    var pointer_variant: Variant = state.get("last_pointer", _last_pointer)
    if pointer_variant is Vector2:
        _last_pointer = pointer_variant as Vector2

    _pointer_history_ready = bool(state.get("pointer_history_ready", _pointer_history_ready))
    _active_row = int(state.get("active_row", _active_row))
    _update_shader_uniforms()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "active_row": _active_row,
        "gesture_speed": _gesture_velocity.length(),
        "row_energy": [_row_energy[0], _row_energy[1], _row_energy[2]],
    }


func _draw() -> void:
    _update_surface_layout()
    _update_shader_uniforms()

    var transform_data: Dictionary = get_design_transform()
    var scale_value: float = float(transform_data["scale"])
    var origin: Vector2 = transform_data["origin"] as Vector2
    draw_set_transform(origin, 0.0, Vector2(scale_value, scale_value))

    _draw_editorial_guides()
    _draw_typography()
    _draw_registration_targets()

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_editorial_guides() -> void:
    var ink_muted: Color = INK
    ink_muted.a = 0.10 + grid_presence * 0.10

    draw_line(Vector2(SAFE_RECT.position.x, 82.0), Vector2(SAFE_RECT.end.x, 82.0), ink_muted, 1.0)
    draw_line(Vector2(SAFE_RECT.position.x, 640.0), Vector2(SAFE_RECT.end.x, 640.0), ink_muted, 1.0)

    var micro_font: Font = ThemeDB.fallback_font
    var micro_color: Color = INK
    micro_color.a = 0.46
    draw_string(micro_font, Vector2(88.0, 104.0), "INK / PRESS / TRACE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, micro_color)

    var right_label: String = "FORM → FORCE → MEMORY"
    var label_width: float = micro_font.get_string_size(right_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
    draw_string(
        micro_font,
        Vector2(SAFE_RECT.end.x - label_width, 104.0),
        right_label,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        18,
        micro_color
    )


func _draw_typography() -> void:
    var font: Font = ThemeDB.fallback_font
    var accent_a: Color = palette_lerp(VERMILION, VIOLET, palette_mix)
    var accent_b: Color = palette_lerp(CYAN, VERMILION, palette_mix)

    for row_index: int in range(ROW_COUNT):
        var word: String = WORDS[row_index]
        var font_size: int = maxi(24, roundi(float(FONT_SIZES[row_index]) * type_scale))
        var row_tracking: float = tracking * TRACKING_MULTIPLIERS[row_index] * type_scale
        var widths: Array[float] = []
        var total_width: float = 0.0

        for char_index: int in range(word.length()):
            var glyph: String = word.substr(char_index, 1)
            var glyph_width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
            widths.append(glyph_width)
            total_width += glyph_width
            if char_index < word.length() - 1:
                total_width += row_tracking

        var cursor_x: float
        match row_index:
            0:
                cursor_x = SAFE_RECT.position.x + 4.0
            1:
                cursor_x = (DESIGN_SIZE.x - total_width) * 0.5
            _:
                cursor_x = SAFE_RECT.end.x - total_width - 4.0

        var baseline: float = BASELINES[row_index]
        var row_energy: float = _row_energy[row_index]
        var anchor_x: float = _row_anchor[row_index] * DESIGN_SIZE.x
        var direction: Vector2 = _row_direction[row_index]
        var influence_radius: float = 255.0 if row_index == 1 else 210.0

        for char_index: int in range(word.length()):
            var glyph: String = word.substr(char_index, 1)
            var glyph_width: float = widths[char_index]
            var glyph_center_x: float = cursor_x + glyph_width * 0.5
            var dx: float = (glyph_center_x - anchor_x) / influence_radius
            var local_weight: float = exp(-dx * dx * 2.15)
            var local_energy: float = row_energy * local_weight

            var compression: float = 0.115 * local_energy
            var compressed_center_x: float = anchor_x + (glyph_center_x - anchor_x) * (1.0 - compression)
            var core_x: float = compressed_center_x - glyph_width * 0.5
            var core_position: Vector2 = Vector2(core_x, baseline + 7.0 * local_energy)

            var register_vector: Vector2 = direction * registration * local_energy
            register_vector.y *= 0.62

            if local_energy > 0.012:
                var color_a: Color = accent_a
                color_a.a = clampf(0.18 + local_energy * 0.66, 0.0, 0.84)
                var color_b: Color = accent_b
                color_b.a = clampf(0.14 + local_energy * 0.58, 0.0, 0.76)
                _draw_glyph(font, glyph, core_position - register_vector, font_size, color_b)
                _draw_glyph(font, glyph, core_position + register_vector * 0.78, font_size, color_a)

            var core_color: Color = INK
            core_color.a = 0.96
            _draw_glyph(font, glyph, core_position, font_size, core_color)

            cursor_x += glyph_width + row_tracking


func _draw_glyph(
    font: Font,
    glyph: String,
    baseline_position: Vector2,
    font_size: int,
    color: Color
) -> void:
    draw_string(font, baseline_position, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_registration_targets() -> void:
    var accent: Color = palette_lerp(VERMILION, VIOLET, palette_mix)
    for row_index: int in range(ROW_COUNT):
        var energy: float = _row_energy[row_index]
        if energy < 0.025:
            continue

        var center: Vector2 = Vector2(
            _row_anchor[row_index] * DESIGN_SIZE.x,
            BASELINES[row_index] - float(FONT_SIZES[row_index]) * type_scale * 0.34
        )
        var target_color: Color = accent
        target_color.a = clampf(energy * 0.26, 0.0, 0.28)
        var radius: float = 9.0 + energy * 7.0
        draw_arc(center, radius, 0.0, TAU, 48, target_color, 1.0, true)
        draw_line(center - Vector2(radius + 7.0, 0.0), center + Vector2(radius + 7.0, 0.0), target_color, 1.0)
        draw_line(center - Vector2(0.0, radius + 7.0), center + Vector2(0.0, radius + 7.0), target_color, 1.0)


func _update_surface_layout() -> void:
    if not is_instance_valid(_surface):
        return
    var transform_data: Dictionary = get_design_transform()
    _surface.position = transform_data["origin"] as Vector2
    var scale_value: float = float(transform_data["scale"])
    _surface.scale = Vector2(scale_value, scale_value)
    _surface.size = DESIGN_SIZE


func _update_shader_uniforms() -> void:
    if not is_instance_valid(_shader_material):
        return

    _shader_material.set_shader_parameter("u_time", sketch_time)
    _shader_material.set_shader_parameter("u_grain", grain)
    _shader_material.set_shader_parameter("u_grid_presence", grid_presence)
    _shader_material.set_shader_parameter("u_registration", registration / 38.0)
    _shader_material.set_shader_parameter("u_palette_mix", palette_mix)

    for row_index: int in range(ROW_COUNT):
        var direction: Vector2 = _row_direction[row_index]
        var encoded: Vector4 = Vector4(
            _row_anchor[row_index],
            direction.x,
            direction.y,
            _row_energy[row_index]
        )
        _shader_material.set_shader_parameter("u_row%d" % row_index, encoded)
