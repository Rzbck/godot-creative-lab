extends Node2D

const BG := Color(0.015, 0.03, 0.06, 1.0)
const POINT := Color(1.0, 0.72, 0.28, 0.92)
const POINT_FAINT := Color(0.74, 0.78, 0.90, 0.45)
const LINE := Color(1.0, 0.72, 0.28, 0.20)
const LINE_FAINT := Color(0.64, 0.72, 0.92, 0.08)

@export_range(8, 256, 1) var point_count: int = 72
@export_range(20.0, 320.0, 1.0) var connection_distance: float = 120.0
@export_range(2.0, 20.0, 0.1) var point_radius: float = 3.5
@export_range(0.0, 2.0, 0.01) var speed: float = 0.35
@export_range(0.0, 1.0, 0.01) var drift: float = 0.35
@export var show_center_ring: bool = true

var _time: float = 0.0


func _ready() -> void:
    set_process(true)
    queue_redraw()


func _process(delta: float) -> void:
    _time += delta * speed
    queue_redraw()


func _draw() -> void:
    var rect: Rect2 = get_viewport_rect()
    var size: Vector2 = rect.size
    var center: Vector2 = size * 0.5

    draw_rect(Rect2(Vector2.ZERO, size), BG, true)

    var points: Array[Vector2] = []
    points.resize(point_count)

    var min_dimension: float = minf(size.x, size.y)
    var base_radius: float = min_dimension * 0.24
    var outer_radius: float = min_dimension * 0.37

    for i in point_count:
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

        points[i] = center + Vector2(x, y)

    if show_center_ring:
        draw_arc(center, base_radius * 1.06, 0.0, TAU, 128, Color(1, 1, 1, 0.05), 1.0, true)
        draw_arc(center, outer_radius * 0.98, 0.0, TAU, 128, Color(1, 0.72, 0.28, 0.08), 1.0, true)

    for i in point_count:
        for j in range(i + 1, point_count):
            var p1: Vector2 = points[i]
            var p2: Vector2 = points[j]
            var distance: float = p1.distance_to(p2)

            if distance <= connection_distance:
                var alpha: float = 1.0 - (distance / connection_distance)
                var color: Color = LINE.lerp(LINE_FAINT, clampf(1.0 - alpha, 0.0, 1.0))
                color.a = lerpf(0.04, 0.28, alpha)
                draw_line(p1, p2, color, maxf(1.0, alpha * 2.2), true)

    for i in point_count:
        var pulse: float = 0.5 + 0.5 * sin(_time * 2.8 + float(i) * 0.37)
        var radius: float = point_radius + pulse * 1.4
        var color: Color = POINT.lerp(POINT_FAINT, clampf(1.0 - pulse, 0.0, 1.0))
        color.a = lerpf(0.45, 0.95, pulse)
        draw_circle(points[i], radius, color)

    draw_string(
        ThemeDB.fallback_font,
        Vector2(20, size.y - 20),
        "001_SIGNAL_FIELD  |  points=%d  dist=%.0f  speed=%.2f" % [point_count, connection_distance, speed],
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        14,
        Color(0.62, 0.68, 0.80, 0.70)
    )
