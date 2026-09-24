extends Node2D

const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)

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

    if event is InputEventMouseMotion:
        pointer_position = viewport_to_design((event as InputEventMouseMotion).position)
        pointer_active = true
        _on_pointer_changed()
        queue_redraw()
        return

    if event is InputEventMouseButton:
        var button: InputEventMouseButton = event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT:
            pointer_position = viewport_to_design(button.position)
            pointer_active = true
            pointer_down = button.pressed
            _on_pointer_changed()
            queue_redraw()


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
    var transform_data: Dictionary = get_design_transform()
    var scale_value: float = maxf(0.0001, float(transform_data["scale"]))
    var origin: Vector2 = transform_data["origin"] as Vector2
    return (point - origin) / scale_value


func design_to_viewport(point: Vector2) -> Vector2:
    var transform_data: Dictionary = get_design_transform()
    return transform_data["origin"] as Vector2 + point * float(transform_data["scale"])


func get_design_transform() -> Dictionary:
    var viewport_size: Vector2 = get_viewport_rect().size
    var safe_x: float = maxf(1.0, viewport_size.x)
    var safe_y: float = maxf(1.0, viewport_size.y)
    var scale_value: float = minf(safe_x / DESIGN_SIZE.x, safe_y / DESIGN_SIZE.y)
    var fitted_size: Vector2 = DESIGN_SIZE * scale_value
    return {
        "scale": scale_value,
        "origin": (viewport_size - fitted_size) * 0.5,
        "viewport_size": viewport_size,
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


func palette_lerp(a: Color, b: Color, amount: float) -> Color:
    return a.lerp(b, clampf(amount, 0.0, 1.0))


func hash01(value: float) -> float:
    return fposmod(sin(value * 12.9898 + 78.233) * 43758.5453, 1.0)
