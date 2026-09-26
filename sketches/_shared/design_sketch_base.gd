extends Node2D

const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const GlyphContourTools = preload("res://sketches/_shared/glyph_contour_tools.gd")

var sketch_time: float = 0.0
var pointer_position: Vector2 = DESIGN_SIZE * 0.5
var pointer_active: bool = false
var pointer_down: bool = false
var live_sync_follower: bool = false


func _ready() -> void:
    set_process(true)
    set_process_input(true)
    queue_redraw()


func _process(delta: float) -> void:
    if live_sync_follower:
        return

    sketch_time += delta
    _update_source_simulation(delta)
    queue_redraw()


func _input(event: InputEvent) -> void:
    if live_sync_follower:
        return

    var viewport_size: Vector2 = get_viewport_rect().size

    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        apply_external_pointer(touch.position, viewport_size, touch.pressed, true)
        return

    if event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        apply_external_pointer(drag.position, viewport_size, true, true)
        return

    if event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        apply_external_pointer(motion.position, viewport_size, pointer_down, true)
        return

    if event is InputEventMouseButton:
        var button: InputEventMouseButton = event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT:
            apply_external_pointer(button.position, viewport_size, button.pressed, true)


# Public interaction contract used by the native LIVE OUT surface. The event is
# expressed in that surface's local pixel coordinates, then mapped through the
# same aspect-fit transform as the sketch rendering. This means a finger at the
# centre of a 1920x1080 output and a mouse at the centre of a 440x246 preview
# control the exact same logical point in the 1280x720 design space.
func apply_external_pointer(
    surface_position: Vector2,
    surface_size: Vector2,
    pressed: bool,
    active: bool = true
) -> void:
    pointer_position = surface_to_design(surface_position, surface_size)
    pointer_active = active
    pointer_down = pressed
    _on_pointer_changed()
    queue_redraw()


func surface_to_design(point: Vector2, surface_size: Vector2) -> Vector2:
    var transform_data: Dictionary = get_design_transform_for_size(surface_size)
    var scale_value: float = maxf(0.0001, float(transform_data["scale"]))
    var origin: Vector2 = transform_data["origin"] as Vector2
    return (point - origin) / scale_value


func _update_source_simulation(_delta: float) -> void:
    pass


func _on_pointer_changed() -> void:
    pass


func set_live_sync_follower(enabled: bool) -> void:
    live_sync_follower = enabled
    set_process(not enabled)
    set_process_input(not enabled)
    queue_redraw()


func get_live_sync_state() -> Dictionary:
    return {
        "time": sketch_time,
        "pointer_position": pointer_position,
        "pointer_active": pointer_active,
        "pointer_down": pointer_down,
        "custom": _get_custom_live_sync_state(),
    }


func apply_live_sync_state(state: Dictionary) -> void:
    sketch_time = float(state.get("time", sketch_time))

    var pointer_variant: Variant = state.get("pointer_position", pointer_position)
    if pointer_variant is Vector2:
        pointer_position = pointer_variant as Vector2

    pointer_active = bool(state.get("pointer_active", pointer_active))
    pointer_down = bool(state.get("pointer_down", pointer_down))

    var custom_variant: Variant = state.get("custom", {})
    if custom_variant is Dictionary:
        _apply_custom_live_sync_state(custom_variant as Dictionary)

    queue_redraw()


func _get_custom_live_sync_state() -> Dictionary:
    return {}


func _apply_custom_live_sync_state(_state: Dictionary) -> void:
    pass


func get_live_sync_debug_state() -> Dictionary:
    var state: Dictionary = {
        "time": sketch_time,
        "pointer_position": pointer_position,
        "pointer_active": pointer_active,
        "pointer_down": pointer_down,
        "follower": live_sync_follower,
        "design_size": [int(DESIGN_SIZE.x), int(DESIGN_SIZE.y)],
    }
    state.merge(_get_custom_live_debug_state(), true)
    return state


func _get_custom_live_debug_state() -> Dictionary:
    return {}


func viewport_to_design(point: Vector2) -> Vector2:
    return surface_to_design(point, get_viewport_rect().size)


func design_to_viewport(point: Vector2) -> Vector2:
    var transform_data: Dictionary = get_design_transform()
    return transform_data["origin"] as Vector2 + point * float(transform_data["scale"])


func get_design_transform() -> Dictionary:
    return get_design_transform_for_size(get_viewport_rect().size)


func get_design_transform_for_size(surface_size: Vector2) -> Dictionary:
    var safe_x: float = maxf(1.0, surface_size.x)
    var safe_y: float = maxf(1.0, surface_size.y)
    var scale_value: float = minf(safe_x / DESIGN_SIZE.x, safe_y / DESIGN_SIZE.y)
    var fitted_size: Vector2 = DESIGN_SIZE * scale_value
    return {
        "scale": scale_value,
        "origin": (surface_size - fitted_size) * 0.5,
        "viewport_size": surface_size,
    }


func begin_design_draw(background_color: Color) -> float:
    var transform_data: Dictionary = get_design_transform()
    var viewport_size: Vector2 = transform_data["viewport_size"] as Vector2
    var scale_value: float = float(transform_data["scale"])
    var origin: Vector2 = transform_data["origin"] as Vector2

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    draw_rect(Rect2(Vector2.ZERO, viewport_size), background_color, true)
    draw_set_transform(origin, 0.0, Vector2(scale_value, scale_value))
    return scale_value


func end_design_draw() -> void:
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Returns sampled real vector outlines for one glyph in design coordinates.
# The contour data returned by TextServer uses a font-style Y-up coordinate
# system, so Y is inverted here and translated from the supplied baseline.
func get_glyph_outline_contours(
    font: Font,
    glyph: String,
    font_size: int,
    baseline: Vector2,
    curve_steps: int = 6
) -> Array[PackedVector2Array]:
    var raw: Array[PackedVector2Array] = GlyphContourTools.get_sampled_contours(
        font,
        glyph,
        font_size,
        curve_steps
    )
    var transformed: Array[PackedVector2Array] = []
    for contour: PackedVector2Array in raw:
        var mapped: PackedVector2Array = PackedVector2Array()
        for point: Vector2 in contour:
            mapped.append(baseline + Vector2(point.x, -point.y))
        transformed.append(mapped)
    return transformed


func map_outline_contours(
    source: Array[PackedVector2Array],
    mapper: Callable
) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array] = []
    for contour_index: int in range(source.size()):
        var contour: PackedVector2Array = source[contour_index]
        var mapped: PackedVector2Array = PackedVector2Array()
        for point_index: int in range(contour.size()):
            var point: Vector2 = contour[point_index]
            if mapper.is_valid():
                var value: Variant = mapper.call(point, contour_index, point_index)
                if value is Vector2:
                    point = value as Vector2
            mapped.append(point)
        result.append(mapped)
    return result


func draw_outline_contours(
    contours: Array[PackedVector2Array],
    color: Color,
    width: float = 1.0,
    antialiased: bool = true
) -> void:
    for contour: PackedVector2Array in contours:
        if contour.size() >= 2:
            draw_polyline(contour, color, width, antialiased)


func outline_bounds(contours: Array[PackedVector2Array]) -> Rect2:
    var has_point: bool = false
    var min_point: Vector2 = Vector2.ZERO
    var max_point: Vector2 = Vector2.ZERO
    for contour: PackedVector2Array in contours:
        for point: Vector2 in contour:
            if not has_point:
                min_point = point
                max_point = point
                has_point = true
            else:
                min_point.x = minf(min_point.x, point.x)
                min_point.y = minf(min_point.y, point.y)
                max_point.x = maxf(max_point.x, point.x)
                max_point.y = maxf(max_point.y, point.y)
    if not has_point:
        return Rect2()
    return Rect2(min_point, max_point - min_point)


func palette_lerp(a: Color, b: Color, amount: float) -> Color:
    return a.lerp(b, clampf(amount, 0.0, 1.0))


func hash01(value: float) -> float:
    return fposmod(sin(value * 12.9898 + 78.233) * 43758.5453, 1.0)
