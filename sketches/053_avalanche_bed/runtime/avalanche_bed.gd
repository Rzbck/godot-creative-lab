extends "res://sketches/_shared/design_sketch_base.gd"

const COLUMNS: int = 96
const SAFE := Rect2(56.0, 52.0, 1168.0, 616.0)
const BASE_Y: float = 640.0

@export_range(12.0, 42.0, 0.5) var repose_angle: float = 27.0
@export_range(0.0, 1.0, 0.01) var cohesion: float = 0.28
@export_range(0.0, 2.0, 0.01) var grain_feed: float = 0.44
@export_range(-2.0, 2.0, 0.01) var drift: float = 0.18
@export_range(18.0, 150.0, 1.0) var tool_radius: float = 74.0
@export_range(0.0, 1.0, 0.01) var compaction: float = 0.42

var _height := PackedFloat32Array()
var _velocity := PackedFloat32Array()
var _compacted := PackedFloat32Array()
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _event_counter: int = 23
var _feed_timer: float = 0.0


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _height.clear()
    _velocity.clear()
    _compacted.clear()
    _event_counter = 23
    _feed_timer = 0.0
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _height.resize(COLUMNS)
    _velocity.resize(COLUMNS)
    _compacted.resize(COLUMNS)
    for i: int in range(COLUMNS):
        var u := float(i) / float(COLUMNS - 1)
        _height[i] = 74.0 + sin(u * PI) * 42.0 + sin(u * 12.0) * 8.0
        _velocity[i] = 0.0
        _compacted[i] = 0.08 + _hash01i(i * 71 + 3) * 0.12


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"repose_angle","label":"REPOSE ANGLE","type":"float","min":12.0,"max":42.0,"step":0.5},
        {"id":"cohesion","label":"COHESION","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"grain_feed","label":"GRAIN FEED","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"drift","label":"WIND / DRIFT","type":"float","min":-2.0,"max":2.0,"step":0.01},
        {"id":"tool_radius","label":"TOOL RADIUS","type":"float","min":18.0,"max":150.0,"step":1.0},
        {"id":"compaction","label":"COMPACTION","type":"float","min":0.0,"max":1.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "repose_angle": return repose_angle
        "cohesion": return cohesion
        "grain_feed": return grain_feed
        "drift": return drift
        "tool_radius": return tool_radius
        "compaction": return compaction
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "repose_angle": repose_angle = clampf(float(value), 12.0, 42.0)
        "cohesion": cohesion = clampf(float(value), 0.0, 1.0)
        "grain_feed": grain_feed = clampf(float(value), 0.0, 2.0)
        "drift": drift = clampf(float(value), -2.0, 2.0)
        "tool_radius": tool_radius = clampf(float(value), 18.0, 150.0)
        "compaction": compaction = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down:
        var x_step := SAFE.size.x / float(COLUMNS - 1)
        var center := int(round((pointer_position.x - SAFE.position.x) / x_step))
        var radius_columns := maxi(1, int(ceil(tool_radius / x_step)))
        var surface_y := _surface_y(clampi(center, 0, COLUMNS - 1))
        var adding := pointer_position.y < surface_y - 8.0
        for dx: int in range(-radius_columns, radius_columns + 1):
            var i := center + dx
            if i < 0 or i >= COLUMNS:
                continue
            var falloff := 1.0 - absf(float(dx)) / float(radius_columns + 1)
            if adding:
                _height[i] += 8.0 * falloff
                _velocity[i] += 12.0 * falloff
            else:
                _height[i] = maxf(12.0, _height[i] - 10.0 * falloff)
                _velocity[i] -= 8.0 * falloff
            _compacted[i] = clampf(_compacted[i] + 0.08 * falloff * compaction, 0.0, 1.0)
    elif _pointer_was_down:
        _event_counter += 1
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _feed_timer -= delta * grain_feed
    if _feed_timer <= 0.0 and grain_feed > 0.01:
        _feed_timer = 0.55
        _event_counter += 1
        var center := int(lerpf(12.0, float(COLUMNS - 13), _hash01i(_event_counter * 67 + 5)))
        for dx: int in range(-3, 4):
            var i := clampi(center + dx, 0, COLUMNS - 1)
            var amount := (1.0 - absf(float(dx)) / 4.0) * grain_feed * 5.2
            _height[i] += amount
            _velocity[i] += amount * 0.9

    var x_step := SAFE.size.x / float(COLUMNS - 1)
    var allowed_slope := tan(deg_to_rad(repose_angle)) * x_step * lerpf(0.78, 1.32, cohesion)
    var transfers := PackedFloat32Array()
    transfers.resize(COLUMNS)

    for i: int in range(COLUMNS - 1):
        var diff := _height[i] - _height[i + 1]
        var compact_guard := 1.0 + (_compacted[i] + _compacted[i + 1]) * 0.65 * compaction
        var threshold := allowed_slope * compact_guard
        if absf(diff) > threshold:
            var excess := (absf(diff) - threshold) * 0.18 * (1.0 - cohesion * 0.52)
            if diff > 0.0:
                transfers[i] -= excess
                transfers[i + 1] += excess
            else:
                transfers[i] += excess
                transfers[i + 1] -= excess

    for i: int in range(COLUMNS):
        var wind := drift * delta * 2.2
        if absf(wind) > 0.0001:
            var j := clampi(i + (1 if wind > 0.0 else -1), 0, COLUMNS - 1)
            var moved := minf(_height[i] * 0.0012 * absf(drift), 0.38) * delta * 60.0
            transfers[i] -= moved
            transfers[j] += moved

    for i: int in range(COLUMNS):
        _velocity[i] += transfers[i] * 7.0
        _velocity[i] *= exp(-delta * (3.2 + cohesion * 2.0))
        _height[i] = clampf(_height[i] + transfers[i] + _velocity[i] * delta * 0.14, 10.0, 500.0)
        _compacted[i] *= exp(-delta * lerpf(0.05, 0.008, compaction))

    queue_redraw()


func _surface_y(index: int) -> float:
    return BASE_Y - _height[index]


func _draw() -> void:
    begin_design_draw(Color(0.89, 0.84, 0.72, 1.0))
    draw_rect(SAFE, Color(0.16, 0.11, 0.07, 0.045), true)

    var x_step := SAFE.size.x / float(COLUMNS - 1)
    var polygon := PackedVector2Array()
    polygon.append(Vector2(SAFE.position.x, BASE_Y))
    for i: int in range(COLUMNS):
        polygon.append(Vector2(SAFE.position.x + float(i) * x_step, _surface_y(i)))
    polygon.append(Vector2(SAFE.end.x, BASE_Y))
    draw_colored_polygon(polygon, Color(0.45, 0.29, 0.14, 0.94))

    var ridge := PackedVector2Array()
    for i: int in range(COLUMNS):
        ridge.append(Vector2(SAFE.position.x + float(i) * x_step, _surface_y(i)))
    draw_polyline(ridge, Color(0.97, 0.81, 0.49, 0.84), 2.0, true)

    for i: int in range(0, COLUMNS, 3):
        var x := SAFE.position.x + float(i) * x_step
        var top := _surface_y(i)
        var depth := minf(98.0, _height[i] * 0.55)
        var compacted := _compacted[i]
        draw_line(Vector2(x, top + 4.0), Vector2(x + drift * 5.0, top + depth), Color(0.19, 0.11, 0.06, 0.05 + compacted * 0.17), 1.0, true)

    if pointer_down:
        var center := int(round((pointer_position.x - SAFE.position.x) / x_step))
        center = clampi(center, 0, COLUMNS - 1)
        var adding := pointer_position.y < _surface_y(center) - 8.0
        var color := Color(0.93, 0.73, 0.36, 0.42) if adding else Color(0.34, 0.18, 0.10, 0.42)
        draw_arc(pointer_position, tool_radius, 0.0, TAU, 48, color, 1.5, true)

    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "height": _height.duplicate(),
        "velocity": _velocity.duplicate(),
        "compacted": _compacted.duplicate(),
        "event_counter": _event_counter,
        "feed_timer": _feed_timer,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("height", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == COLUMNS:
        _height = (value as PackedFloat32Array).duplicate()
    value = state.get("velocity", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == COLUMNS:
        _velocity = (value as PackedFloat32Array).duplicate()
    value = state.get("compacted", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == COLUMNS:
        _compacted = (value as PackedFloat32Array).duplicate()
    _event_counter = int(state.get("event_counter", _event_counter))
    _feed_timer = float(state.get("feed_timer", _feed_timer))


func _get_custom_live_debug_state() -> Dictionary:
    return {"columns": COLUMNS, "mass": _total_mass()}


func _total_mass() -> float:
    var total := 0.0
    for value: float in _height:
        total += value
    return total
