extends "res://sketches/_shared/design_sketch_base.gd"

const DROPLETS: int = 84
const MAX_WET_SPOTS: int = 12
const SAFE := Rect2(58.0, 48.0, 1164.0, 624.0)

@export_range(0.2, 2.4, 0.01) var surface_tension: float = 1.15
@export_range(0.0, 1.0, 0.01) var wetting: float = 0.62
@export_range(0.0, 1.5, 0.01) var evaporation: float = 0.34
@export_range(28.0, 130.0, 1.0) var bridge_reach: float = 74.0
@export_range(0.0, 2.0, 0.01) var feed_rate: float = 0.72
@export_range(0.2, 2.2, 0.01) var inertia: float = 0.88

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _radii := PackedFloat32Array()
var _life := PackedFloat32Array()
var _wet_spots: Array[Dictionary] = []
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _gesture_velocity := Vector2.ZERO
var _feed_timer: float = 0.0
var _event_counter: int = 51


func _ready() -> void:
    _seed_droplets()
    super._ready()


func reset_state() -> void:
    _positions.clear()
    _velocities.clear()
    _radii.clear()
    _life.clear()
    _wet_spots.clear()
    _pointer_was_down = false
    _feed_timer = 0.0
    _event_counter = 51
    _seed_droplets()
    queue_redraw()


func _seed_droplets() -> void:
    _positions.resize(DROPLETS)
    _velocities.resize(DROPLETS)
    _radii.resize(DROPLETS)
    _life.resize(DROPLETS)
    for i: int in range(DROPLETS):
        var column := i % 7
        var row := int(i / 7)
        _positions[i] = Vector2(
            165.0 + float(column) * 150.0 + (_hash01i(i * 47 + 3) - 0.5) * 42.0,
            92.0 + float(row) * 48.0 + (_hash01i(i * 73 + 9) - 0.5) * 26.0
        )
        _velocities[i] = Vector2((_hash01i(i * 19 + 5) - 0.5) * 8.0, 4.0 + _hash01i(i * 31 + 7) * 8.0)
        _radii[i] = 5.0 + _hash01i(i * 61 + 11) * 8.0
        _life[i] = 0.65 + _hash01i(i * 97 + 13) * 0.35


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"surface_tension","label":"SURFACE TENSION","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"wetting","label":"WETTING","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"evaporation","label":"EVAPORATION","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"bridge_reach","label":"BRIDGE REACH","type":"float","min":28.0,"max":130.0,"step":1.0},
        {"id":"feed_rate","label":"FEED RATE","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"inertia","label":"INERTIA","type":"float","min":0.2,"max":2.2,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "surface_tension": return surface_tension
        "wetting": return wetting
        "evaporation": return evaporation
        "bridge_reach": return bridge_reach
        "feed_rate": return feed_rate
        "inertia": return inertia
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "surface_tension": surface_tension = clampf(float(value), 0.2, 2.4)
        "wetting": wetting = clampf(float(value), 0.0, 1.0)
        "evaporation": evaporation = clampf(float(value), 0.0, 1.5)
        "bridge_reach": bridge_reach = clampf(float(value), 28.0, 130.0)
        "feed_rate": feed_rate = clampf(float(value), 0.0, 2.0)
        "inertia": inertia = clampf(float(value), 0.2, 2.2)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    var delta_pointer := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pointer, 0.48)
    _last_pointer = pointer_position
    if pointer_down:
        if not _pointer_was_down or delta_pointer.length() > 12.0:
            _add_wet_spot(pointer_position, 1.0)
    elif _pointer_was_down:
        _add_wet_spot(pointer_position, 1.25)
    _pointer_was_down = pointer_down


func _add_wet_spot(position: Vector2, strength: float) -> void:
    _wet_spots.append({
        "position": position.clamp(SAFE.position, SAFE.end),
        "strength": strength,
        "velocity": _gesture_velocity * 5.0,
    })
    while _wet_spots.size() > MAX_WET_SPOTS:
        _wet_spots.pop_front()


func _update_source_simulation(delta: float) -> void:
    _feed_timer -= delta * feed_rate
    if _feed_timer <= 0.0 and feed_rate > 0.01:
        _feed_timer = 0.7
        _event_counter += 1
        var i := _event_counter % DROPLETS
        _positions[i] = Vector2(
            lerpf(160.0, 1120.0, _hash01i(_event_counter * 67 + 3)),
            72.0 + _hash01i(_event_counter * 41 + 5) * 52.0
        )
        _velocities[i] = Vector2((_hash01i(_event_counter * 89 + 7) - 0.5) * 16.0, 16.0 + feed_rate * 18.0)
        _life[i] = 1.0

    for s: int in range(_wet_spots.size() - 1, -1, -1):
        var spot: Dictionary = _wet_spots[s]
        var strength := float(spot["strength"])
        strength -= delta * (0.08 + evaporation * 0.19)
        if strength <= 0.0:
            _wet_spots.remove_at(s)
            continue
        var velocity: Vector2 = spot["velocity"] as Vector2
        velocity *= exp(-delta * 2.4)
        spot["velocity"] = velocity
        spot["strength"] = strength
        _wet_spots[s] = spot

    for i: int in range(DROPLETS):
        var pos := _positions[i]
        var vel := _velocities[i]
        var force := Vector2(0.0, 12.0 + feed_rate * 7.0)
        for spot_variant: Dictionary in _wet_spots:
            var spot_pos: Vector2 = spot_variant["position"] as Vector2
            var d := spot_pos - pos
            var distance := maxf(8.0, d.length())
            if distance < 250.0:
                var falloff := 1.0 - distance / 250.0
                force += d / distance * falloff * falloff * wetting * float(spot_variant["strength"]) * 160.0
                force += (spot_variant["velocity"] as Vector2) * falloff * 0.12 * wetting

        for offset: int in range(1, 5):
            var j := (i + offset * 11) % DROPLETS
            var d := _positions[j] - pos
            var distance := d.length()
            if distance > 0.001 and distance < bridge_reach:
                var pull := (1.0 - distance / bridge_reach) * surface_tension * 34.0
                force += d / distance * pull

        vel += force * delta
        vel *= exp(-delta * lerpf(2.5, 0.55, inertia / 2.2))
        if vel.length() > 220.0:
            vel = vel.normalized() * 220.0
        pos += vel * delta

        if pos.x < SAFE.position.x or pos.x > SAFE.end.x:
            vel.x *= -0.66
            pos.x = clampf(pos.x, SAFE.position.x, SAFE.end.x)
        if pos.y > SAFE.end.y:
            pos.y = SAFE.position.y + _hash01i(i * 113 + _event_counter) * 70.0
            vel.y = -absf(vel.y) * 0.18
        if pos.y < SAFE.position.y:
            pos.y = SAFE.position.y
            vel.y = absf(vel.y) * 0.5

        _life[i] = clampf(_life[i] - delta * evaporation * 0.014 + delta * feed_rate * 0.003, 0.22, 1.0)
        _positions[i] = pos
        _velocities[i] = vel

    queue_redraw()


func _draw() -> void:
    begin_design_draw(Color(0.965, 0.948, 0.900, 1.0))

    draw_rect(Rect2(58.0, 48.0, 1164.0, 624.0), Color(0.82, 0.86, 0.83, 0.10), true)
    for spot_variant: Dictionary in _wet_spots:
        var spot_pos: Vector2 = spot_variant["position"] as Vector2
        var strength := float(spot_variant["strength"])
        draw_circle(spot_pos, 24.0 + wetting * 36.0, Color(0.20, 0.37, 0.34, 0.028 * strength), true)

    var bridge_limit := minf(bridge_reach, 112.0)
    for i: int in range(DROPLETS):
        for offset: int in range(1, 4):
            var j := (i + offset * 11) % DROPLETS
            var distance := _positions[i].distance_to(_positions[j])
            if distance < bridge_limit:
                var amount := 1.0 - distance / bridge_limit
                var width := 0.7 + amount * surface_tension * 2.8
                draw_line(_positions[i], _positions[j], Color(0.08, 0.24, 0.22, 0.05 + amount * 0.20), width, true)

    for i: int in range(DROPLETS):
        var radius := _radii[i] * lerpf(0.78, 1.32, surface_tension / 2.4)
        var life := _life[i]
        draw_circle(_positions[i] + Vector2(1.8, 2.6), radius * 1.08, Color(0.04, 0.08, 0.07, 0.08 * life), true)
        draw_circle(_positions[i], radius, Color(0.055, 0.24, 0.20, 0.42 + life * 0.40), true)
        draw_circle(_positions[i] - Vector2(radius * 0.24, radius * 0.24), maxf(1.2, radius * 0.22), Color(0.86, 0.96, 0.91, 0.58), true)

    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "life": _life.duplicate(),
        "wet_spots": _wet_spots.duplicate(true),
        "feed_timer": _feed_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("positions", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == DROPLETS:
        _positions = (value as PackedVector2Array).duplicate()
    value = state.get("velocities", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == DROPLETS:
        _velocities = (value as PackedVector2Array).duplicate()
    value = state.get("life", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == DROPLETS:
        _life = (value as PackedFloat32Array).duplicate()
    value = state.get("wet_spots", [])
    if value is Array:
        _wet_spots.clear()
        for item: Variant in value as Array:
            if item is Dictionary:
                _wet_spots.append((item as Dictionary).duplicate(true))
    _feed_timer = float(state.get("feed_timer", _feed_timer))
    _event_counter = int(state.get("event_counter", _event_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {"wet_spots": _wet_spots.size(), "droplets": DROPLETS}
