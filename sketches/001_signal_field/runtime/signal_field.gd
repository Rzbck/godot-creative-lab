extends Node2D

const BG: Color = Color(0.015, 0.03, 0.06, 1.0)
const POINT: Color = Color(1.0, 0.72, 0.28, 0.92)
const POINT_FAINT: Color = Color(0.74, 0.78, 0.90, 0.45)
const LINE: Color = Color(1.0, 0.72, 0.28, 0.20)
const LINE_FAINT: Color = Color(0.64, 0.72, 0.92, 0.08)

# Every render surface uses the same logical coordinate system. Preview and live
# output can therefore have different physical resolutions without changing the
# generated composition, connection topology, line density or point sizes.
const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)

@export_range(8, 256, 1) var point_count: int = 72
@export_range(20.0, 320.0, 1.0) var connection_distance: float = 120.0
@export_range(2.0, 20.0, 0.1) var point_radius: float = 3.5
@export_range(0.0, 2.0, 0.01) var speed: float = 0.35
@export_range(0.0, 1.0, 0.01) var drift: float = 0.35
@export_range(0.0, 180.0, 1.0) var interaction_strength: float = 58.0
@export_range(40.0, 420.0, 1.0) var interaction_radius: float = 180.0
@export var show_center_ring: bool = true

var _time: float = 0.0
var _pointer_position: Vector2 = Vector2.ZERO
var _pointer_active: bool = false
var _pointer_down: bool = false
var _live_sync_follower: bool = false


func _ready() -> void:
    set_process(true)
    queue_redraw()


func _process(delta: float) -> void:
    if _live_sync_follower:
        return
    _time += delta * speed
    queue_redraw()


func _input(event: InputEvent) -> void:
    if _live_sync_follower:
        return

    if event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        _pointer_position = _viewport_to_design(motion.position)
        _pointer_active = true
        queue_redraw()
        return

    if event is InputEventMouseButton:
        var button: InputEventMouseButton = event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT:
            _pointer_position = _viewport_to_design(button.position)
            _pointer_active = true
            _pointer_down = button.pressed
            queue_redraw()


# Generic live-output synchronization contract. The workstation owns the source
# simulation state; any secondary renderer is a follower and never advances a
# second independent generative timeline.
func set_live_sync_follower(enabled: bool) -> void:
    _live_sync_follower = enabled
    set_process(not enabled)
    set_process_input(not enabled)
    queue_redraw()


func get_live_sync_state() -> Dictionary:
    return {
        "time": _time,
        "pointer_position": _pointer_position,
        "pointer_active": _pointer_active,
        "pointer_down": _pointer_down,
    }


func apply_live_sync_state(state: Dictionary) -> void:
    _time = float(state.get("time", _time))

    var pointer_variant: Variant = state.get("pointer_position", _pointer_position)
    if pointer_variant is Vector2:
        _pointer_position = pointer_variant as Vector2

    _pointer_active = bool(state.get("pointer_active", _pointer_active))
    _pointer_down = bool(state.get("pointer_down", _pointer_down))
    queue_redraw()


func get_live_sync_debug_state() -> Dictionary:
    return {
        "time": _time,
        "pointer_active": _pointer_active,
        "follower": _live_sync_follower,
        "design_size": [int(DESIGN_SIZE.x), int(DESIGN_SIZE.y)],
    }


func get_parameter_schema() -> Array[Dictionary]:
    var schema: Array[Dictionary] = [
        {"id": "point_count", "label": "POINT COUNT", "type": "int", "min": 8.0, "max": 256.0, "step": 1.0},
        {"id": "connection_distance", "label": "LINK DISTANCE", "type": "float", "min": 20.0, "max": 320.0, "step": 1.0},
        {"id": "point_radius", "label": "POINT SIZE", "type": "float", "min": 2.0, "max": 20.0, "step": 0.1},
        {"id": "speed", "label": "SPEED", "type": "float", "min": 0.0, "max": 2.0, "step": 0.01},
        {"id": "drift", "label": "DRIFT", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "interaction_strength", "label": "POINTER FORCE", "type": "float", "min": 0.0, "max": 180.0, "step": 1.0},
        {"id": "interaction_radius", "label": "POINTER RADIUS", "type": "float", "min": 40.0, "max": 420.0, "step": 1.0},
        {"id": "show_center_ring", "label": "CENTER RINGS", "type": "bool"}
    ]
    return schema


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "point_count":
            return point_count
        "connection_distance":
            return connection_distance
        "point_radius":
            return point_radius
        "speed":
            return speed
        "drift":
            return drift
        "interaction_strength":
            return interaction_strength
        "interaction_radius":
            return interaction_radius
        "show_center_ring":
            return show_center_ring
        _:
            return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "point_count":
            point_count = clampi(int(value), 8, 256)
        "connection_distance":
            connection_distance = clampf(float(value), 20.0, 320.0)
        "point_radius":
            point_radius = clampf(float(value), 2.0, 20.0)
        "speed":
            speed = clampf(float(value), 0.0, 2.0)
        "drift":
            drift = clampf(float(value), 0.0, 1.0)
        "interaction_strength":
            interaction_strength = clampf(float(value), 0.0, 180.0)
        "interaction_radius":
            interaction_radius = clampf(float(value), 40.0, 420.0)
        "show_center_ring":
            show_center_ring = bool(value)
        _:
            return

    queue_redraw()


func _draw() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    var transform_data: Dictionary = _design_transform(viewport_size)
    var draw_scale: float = float(transform_data["scale"])
    var origin: Vector2 = transform_data["origin"] as Vector2
    var center: Vector2 = DESIGN_SIZE * 0.5

    draw_rect(Rect2(Vector2.ZERO, viewport_size), BG, true)

    var points: Array[Vector2] = []
    points.resize(point_count)

    var base_radius: float = minf(DESIGN_SIZE.x, DESIGN_SIZE.y) * 0.24
    var outer_radius: float = minf(DESIGN_SIZE.x, DESIGN_SIZE.y) * 0.37

    for i: int in point_count:
        var t: float = float(i) / float(point_count)
        var a: float = t * TAU
        var orbit_a: float = a + _time * (0.45 + t * 0.65)
        var orbit_b: float = -a * 1.7 + _time * (0.85 + t * 0.35)
        var radius_mix: float = 0.5 + 0.5 * sin(_time * 0.9 + a * 3.0)
        var radius: float = lerpf(base_radius, outer_radius, radius_mix)
        var x: float = cos(orbit_a) * radius
        var y: float = sin(orbit_b) * radius * 0.72

        x += cos(_time * 2.1 + a * 7.0) * (28.0 + 48.0 * drift)
        y += sin(_time * 1.7 + a * 5.0) * (24.0 + 44.0 * drift)

        var point_position: Vector2 = center + Vector2(x, y)

        if _pointer_active and interaction_strength > 0.0:
            var pointer_offset: Vector2 = point_position - _pointer_position
            var pointer_distance: float = pointer_offset.length()
            if pointer_distance > 0.001 and pointer_distance < interaction_radius:
                var pointer_amount: float = 1.0 - (pointer_distance / interaction_radius)
                var pointer_multiplier: float = 1.8 if _pointer_down else 1.0
                point_position += (pointer_offset / pointer_distance) * interaction_strength * pointer_amount * pointer_multiplier

        points[i] = point_position

    if show_center_ring:
        draw_arc(
            _design_to_viewport(center, origin, draw_scale),
            base_radius * 1.06 * draw_scale,
            0.0,
            TAU,
            128,
            Color(1, 1, 1, 0.05),
            maxf(1.0, draw_scale),
            true
        )
        draw_arc(
            _design_to_viewport(center, origin, draw_scale),
            outer_radius * 0.98 * draw_scale,
            0.0,
            TAU,
            128,
            Color(1, 0.72, 0.28, 0.08),
            maxf(1.0, draw_scale),
            true
        )

    for i: int in point_count:
        for j: int in range(i + 1, point_count):
            var p1: Vector2 = points[i]
            var p2: Vector2 = points[j]
            var distance: float = p1.distance_to(p2)

            if distance <= connection_distance:
                var alpha: float = 1.0 - (distance / connection_distance)
                var color: Color = LINE.lerp(LINE_FAINT, clampf(1.0 - alpha, 0.0, 1.0))
                color.a = lerpf(0.04, 0.28, alpha)
                draw_line(
                    _design_to_viewport(p1, origin, draw_scale),
                    _design_to_viewport(p2, origin, draw_scale),
                    color,
                    maxf(1.0, alpha * 2.2 * draw_scale),
                    true
                )

    for i: int in point_count:
        var pulse: float = 0.5 + 0.5 * sin(_time * 2.8 + float(i) * 0.37)
        var radius: float = point_radius + pulse * 1.4
        var color: Color = POINT.lerp(POINT_FAINT, clampf(1.0 - pulse, 0.0, 1.0))
        color.a = lerpf(0.45, 0.95, pulse)
        draw_circle(
            _design_to_viewport(points[i], origin, draw_scale),
            maxf(0.75, radius * draw_scale),
            color
        )


func _design_transform(viewport_size: Vector2) -> Dictionary:
    var safe_x: float = maxf(1.0, viewport_size.x)
    var safe_y: float = maxf(1.0, viewport_size.y)
    var scale_value: float = minf(safe_x / DESIGN_SIZE.x, safe_y / DESIGN_SIZE.y)
    var fitted_size: Vector2 = DESIGN_SIZE * scale_value
    var origin: Vector2 = (viewport_size - fitted_size) * 0.5
    return {
        "scale": scale_value,
        "origin": origin,
    }


func _design_to_viewport(point: Vector2, origin: Vector2, scale_value: float) -> Vector2:
    return origin + point * scale_value


func _viewport_to_design(point: Vector2) -> Vector2:
    var viewport_size: Vector2 = get_viewport_rect().size
    var transform_data: Dictionary = _design_transform(viewport_size)
    var scale_value: float = maxf(0.0001, float(transform_data["scale"]))
    var origin: Vector2 = transform_data["origin"] as Vector2
    return (point - origin) / scale_value
