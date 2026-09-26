extends "res://sketches/_shared/design_sketch_base.gd"

const MAX_TIPS: int = 72
const STEP_SECONDS: float = 1.0 / 24.0

@export_range(12.0, 80.0, 0.5) var growth_speed: float = 38.0
@export_range(0.1, 2.4, 0.01) var chemotaxis: float = 1.12
@export_range(0.0, 2.0, 0.01) var branch_rate: float = 0.72
@export_range(0.0, 1.5, 0.01) var wander: float = 0.42
@export_range(0.0, 1.5, 0.01) var phosphor: float = 0.88
@export_range(0.0, 1.0, 0.01) var persistence: float = 0.92

var _agent_positions := PackedVector2Array()
var _agent_directions := PackedVector2Array()
var _agent_energy := PackedFloat32Array()
var _trails: Array = []
var _nutrients := PackedVector2Array()
var _nutrient_targets := PackedVector2Array()
var _painted_nutrients := PackedVector2Array()
var _accum: float = 0.0
var _nutrient_timer: float = 0.4
var _event_counter: int = 23
var _pointer_was_down: bool = false
var _last_paint := Vector2(-1000.0, -1000.0)


func _ready() -> void:
    _seed_ecology()
    super._ready()


func _seed_ecology() -> void:
    _nutrients = PackedVector2Array([
        Vector2(210.0, 180.0), Vector2(550.0, 520.0), Vector2(920.0, 210.0), Vector2(1080.0, 535.0), Vector2(700.0, 330.0)
    ])
    _nutrient_targets = _nutrients.duplicate()

    var seeds := [Vector2(150.0, 400.0), Vector2(430.0, 260.0), Vector2(820.0, 520.0)]
    for s: int in range(seeds.size()):
        for i: int in range(4):
            var angle := (_hash01i(s * 101 + i * 37 + 9) - 0.5) * 2.6
            _spawn_agent(seeds[s], Vector2.RIGHT.rotated(angle), 0.78 + float(i) * 0.05)


func _spawn_agent(position: Vector2, direction: Vector2, energy: float) -> void:
    if _agent_positions.size() >= MAX_TIPS:
        return
    _agent_positions.append(position)
    _agent_directions.append(direction.normalized())
    _agent_energy.append(energy)
    var trail := PackedVector2Array()
    trail.append(position)
    _trails.append(trail)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"growth_speed","label":"GROWTH SPEED","type":"float","min":12.0,"max":80.0,"step":0.5},
        {"id":"chemotaxis","label":"CHEMOTAXIS","type":"float","min":0.1,"max":2.4,"step":0.01},
        {"id":"branch_rate","label":"BRANCH RATE","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"wander","label":"MICRO WANDER","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"phosphor","label":"PHOSPHOR","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"persistence","label":"PATH MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "growth_speed": return growth_speed
        "chemotaxis": return chemotaxis
        "branch_rate": return branch_rate
        "wander": return wander
        "phosphor": return phosphor
        "persistence": return persistence
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "growth_speed": growth_speed = clampf(float(value), 12.0, 80.0)
        "chemotaxis": chemotaxis = clampf(float(value), 0.1, 2.4)
        "branch_rate": branch_rate = clampf(float(value), 0.0, 2.0)
        "wander": wander = clampf(float(value), 0.0, 1.5)
        "phosphor": phosphor = clampf(float(value), 0.0, 1.5)
        "persistence": persistence = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down:
        if not _pointer_was_down or pointer_position.distance_to(_last_paint) > 18.0:
            _painted_nutrients.append(pointer_position.clamp(Vector2(28.0, 28.0), DESIGN_SIZE - Vector2(28.0, 28.0)))
            _last_paint = pointer_position
            while _painted_nutrients.size() > 26:
                _painted_nutrients.remove_at(0)
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _accum += delta
    var steps := 0
    while _accum >= STEP_SECONDS and steps < 2:
        _simulate_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        steps += 1


func _simulate_step(dt: float) -> void:
    _event_counter += 1
    _nutrient_timer -= dt
    if _nutrient_timer <= 0.0:
        _nutrient_timer = 2.1 + _hash01i(_event_counter * 31) * 2.8
        var index := _event_counter % _nutrient_targets.size()
        _nutrient_targets[index] = Vector2(
            lerpf(100.0, 1180.0, _hash01i(_event_counter * 61 + 7)),
            lerpf(90.0, 630.0, _hash01i(_event_counter * 83 + 13))
        )

    for i: int in range(_nutrients.size()):
        _nutrients[i] = _nutrients[i].lerp(_nutrient_targets[i], clampf(dt * 0.16, 0.0, 1.0))

    var agent_count := _agent_positions.size()
    for i: int in range(agent_count):
        var position := _agent_positions[i]
        var direction := _agent_directions[i]
        var desired := _nutrient_direction(position)

        var jitter_angle := (_hash01i(_event_counter * 173 + i * 29) - 0.5) * wander * 0.34
        desired = desired.rotated(jitter_angle)
        direction = direction.lerp(desired, clampf(dt * (0.8 + chemotaxis * 0.55), 0.0, 0.34)).normalized()

        if position.x < 55.0: direction.x += 0.28
        if position.x > DESIGN_SIZE.x - 55.0: direction.x -= 0.28
        if position.y < 55.0: direction.y += 0.28
        if position.y > DESIGN_SIZE.y - 55.0: direction.y -= 0.28
        direction = direction.normalized()

        var energy := _agent_energy[i]
        var speed := growth_speed * lerpf(0.55, 1.18, clampf(energy, 0.0, 1.0))
        var next_position := (position + direction * speed * dt).clamp(Vector2(20.0, 20.0), DESIGN_SIZE - Vector2(20.0, 20.0))

        _agent_positions[i] = next_position
        _agent_directions[i] = direction

        var near_food := _nearest_nutrient_distance(next_position)
        energy += dt * (0.16 if near_food < 95.0 else -0.018)
        energy = clampf(energy, 0.18, 1.15)
        _agent_energy[i] = energy

        var trail: PackedVector2Array = _trails[i]
        if trail.is_empty() or trail[trail.size() - 1].distance_to(next_position) > 4.8:
            trail.append(next_position)
        while trail.size() > int(lerpf(46.0, 116.0, persistence)):
            trail.remove_at(0)
        _trails[i] = trail

        var branch_chance := branch_rate * dt * 0.18 * energy
        if _agent_positions.size() < MAX_TIPS and trail.size() > 10 and _hash01i(_event_counter * 211 + i * 43) < branch_chance:
            var turn := lerpf(0.24, 0.82, _hash01i(_event_counter * 227 + i * 59))
            if _hash01i(_event_counter * 239 + i * 17) < 0.5:
                turn = -turn
            _spawn_agent(next_position, direction.rotated(turn), energy * 0.72)
            _agent_energy[i] *= 0.88


func _nutrient_direction(position: Vector2) -> Vector2:
    var force := Vector2.ZERO
    for nutrient: Vector2 in _nutrients:
        var delta := nutrient - position
        var distance := maxf(28.0, delta.length())
        force += delta / distance * (120.0 / distance)
    for nutrient: Vector2 in _painted_nutrients:
        var delta := nutrient - position
        var distance := maxf(18.0, delta.length())
        force += delta / distance * (190.0 / distance)
    if force.length() < 0.0001:
        return Vector2.RIGHT
    return force.normalized()


func _nearest_nutrient_distance(position: Vector2) -> float:
    var result := INF
    for nutrient: Vector2 in _nutrients:
        result = minf(result, position.distance_to(nutrient))
    for nutrient: Vector2 in _painted_nutrients:
        result = minf(result, position.distance_to(nutrient))
    return result


func _draw() -> void:
    begin_design_draw(Color(0.006, 0.012, 0.010, 1.0))

    for nutrient: Vector2 in _nutrients:
        draw_circle(nutrient, 30.0, Color(0.31, 0.95, 0.58, 0.018 + phosphor * 0.018), true)
        draw_circle(nutrient, 3.0, Color(0.62, 1.0, 0.74, 0.50), true)
    for nutrient: Vector2 in _painted_nutrients:
        draw_circle(nutrient, 17.0, Color(0.22, 1.0, 0.58, 0.035 + phosphor * 0.022), true)

    for i: int in range(_trails.size()):
        var trail_variant: Variant = _trails[i]
        if not trail_variant is PackedVector2Array:
            continue
        var trail := trail_variant as PackedVector2Array
        if trail.size() < 2:
            continue
        var energy := _agent_energy[i] if i < _agent_energy.size() else 0.5
        var core := Color(0.42, 0.96, 0.69, 0.38 + energy * 0.42)
        var warm := Color(0.92, 0.76, 0.44, 0.72)
        core = core.lerp(warm, clampf((1.0 - energy) * 0.34, 0.0, 0.34))
        if phosphor > 0.01:
            draw_polyline(trail, Color(core.r, core.g, core.b, 0.035 * phosphor), 6.0 + phosphor * 2.2, true)
        draw_polyline(trail, core, 0.95 + energy * 0.65, true)

    for i: int in range(_agent_positions.size()):
        var p := _agent_positions[i]
        var e := _agent_energy[i]
        draw_circle(p, 2.0 + e * 1.3, Color(0.76, 1.0, 0.83, 0.68), true)
        if e > 0.78:
            draw_circle(p, 7.0, Color(0.58, 1.0, 0.72, 0.035 * phosphor), true)

    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    var trails_copy: Array = []
    for trail_variant: Variant in _trails:
        if trail_variant is PackedVector2Array:
            trails_copy.append((trail_variant as PackedVector2Array).duplicate())
    return {
        "agent_positions": _agent_positions.duplicate(),
        "agent_directions": _agent_directions.duplicate(),
        "agent_energy": _agent_energy.duplicate(),
        "trails": trails_copy,
        "nutrients": _nutrients.duplicate(),
        "nutrient_targets": _nutrient_targets.duplicate(),
        "painted_nutrients": _painted_nutrients.duplicate(),
        "nutrient_timer": _nutrient_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("agent_positions", PackedVector2Array())
    if v is PackedVector2Array: _agent_positions = (v as PackedVector2Array).duplicate()
    v = state.get("agent_directions", PackedVector2Array())
    if v is PackedVector2Array: _agent_directions = (v as PackedVector2Array).duplicate()
    v = state.get("agent_energy", PackedFloat32Array())
    if v is PackedFloat32Array: _agent_energy = (v as PackedFloat32Array).duplicate()
    v = state.get("nutrients", PackedVector2Array())
    if v is PackedVector2Array: _nutrients = (v as PackedVector2Array).duplicate()
    v = state.get("nutrient_targets", PackedVector2Array())
    if v is PackedVector2Array: _nutrient_targets = (v as PackedVector2Array).duplicate()
    v = state.get("painted_nutrients", PackedVector2Array())
    if v is PackedVector2Array: _painted_nutrients = (v as PackedVector2Array).duplicate()
    v = state.get("trails", [])
    if v is Array:
        _trails.clear()
        for trail_variant: Variant in v as Array:
            if trail_variant is PackedVector2Array:
                _trails.append((trail_variant as PackedVector2Array).duplicate())
    _nutrient_timer = float(state.get("nutrient_timer", _nutrient_timer))
    _event_counter = int(state.get("event_counter", _event_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "active_tips": _agent_positions.size(),
        "painted_nutrients": _painted_nutrients.size(),
        "render_mode": "persistent_agent_graph",
    }
