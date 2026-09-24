extends "res://sketches/_shared/design_sketch_base.gd"

const MESH_COLS := 13
const MESH_ROWS := 8
const AGENT_COUNT := 42
const BG := Color(0.955, 0.945, 0.905, 1.0)
const INK := Color(0.045, 0.048, 0.043, 1.0)

@export_range(0.1, 1.4, 0.01) var mesh_tension: float = 0.74
@export_range(0.82, 0.999, 0.001) var mesh_damping: float = 0.982
@export_range(0.0, 1.5, 0.01) var flock_cohesion: float = 0.54
@export_range(0.0, 1.5, 0.01) var flock_alignment: float = 0.62
@export_range(0.0, 1.8, 0.01) var flock_separation: float = 0.92
@export_range(0.0, 1.5, 0.01) var agent_pressure: float = 0.72
@export_range(0.0, 1.5, 0.01) var erosion_rate: float = 0.58
@export_range(0.0, 1.0, 0.01) var repair_rate: float = 0.26
@export_range(40.0, 220.0, 1.0) var obstacle_radius: float = 112.0

var _mesh_pos: Array[Vector2] = []
var _mesh_prev: Array[Vector2] = []
var _mesh_rest: Array[Vector2] = []
var _edges: Array[Vector2i] = []
var _edge_rest: PackedFloat32Array = PackedFloat32Array()
var _edge_health: PackedFloat32Array = PackedFloat32Array()

var _agent_pos: Array[Vector2] = []
var _agent_vel: Array[Vector2] = []
var _obstacle_pos: Vector2 = Vector2(640.0, 360.0)
var _obstacle_strength: float = 0.0


func _ready() -> void:
    super._ready()
    _seed_system()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"mesh_tension", "label":"MESH TENSION", "type":"float", "min":0.1, "max":1.4, "step":0.01},
        {"id":"mesh_damping", "label":"MESH DAMPING", "type":"float", "min":0.82, "max":0.999, "step":0.001},
        {"id":"flock_cohesion", "label":"FLOCK COHESION", "type":"float", "min":0.0, "max":1.5, "step":0.01},
        {"id":"flock_alignment", "label":"FLOCK ALIGNMENT", "type":"float", "min":0.0, "max":1.5, "step":0.01},
        {"id":"flock_separation", "label":"FLOCK SEPARATION", "type":"float", "min":0.0, "max":1.8, "step":0.01},
        {"id":"agent_pressure", "label":"AGENT PRESSURE", "type":"float", "min":0.0, "max":1.5, "step":0.01},
        {"id":"erosion_rate", "label":"LINK EROSION", "type":"float", "min":0.0, "max":1.5, "step":0.01},
        {"id":"repair_rate", "label":"LINK REPAIR", "type":"float", "min":0.0, "max":1.0, "step":0.01},
        {"id":"obstacle_radius", "label":"OBSTACLE RADIUS", "type":"float", "min":40.0, "max":220.0, "step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "mesh_tension": return mesh_tension
        "mesh_damping": return mesh_damping
        "flock_cohesion": return flock_cohesion
        "flock_alignment": return flock_alignment
        "flock_separation": return flock_separation
        "agent_pressure": return agent_pressure
        "erosion_rate": return erosion_rate
        "repair_rate": return repair_rate
        "obstacle_radius": return obstacle_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "mesh_tension": mesh_tension = clampf(float(value), 0.1, 1.4)
        "mesh_damping": mesh_damping = clampf(float(value), 0.82, 0.999)
        "flock_cohesion": flock_cohesion = clampf(float(value), 0.0, 1.5)
        "flock_alignment": flock_alignment = clampf(float(value), 0.0, 1.5)
        "flock_separation": flock_separation = clampf(float(value), 0.0, 1.8)
        "agent_pressure": agent_pressure = clampf(float(value), 0.0, 1.5)
        "erosion_rate": erosion_rate = clampf(float(value), 0.0, 1.5)
        "repair_rate": repair_rate = clampf(float(value), 0.0, 1.0)
        "obstacle_radius": obstacle_radius = clampf(float(value), 40.0, 220.0)
        _: return


func _mesh_index(x: int, y: int) -> int:
    return clampi(y, 0, MESH_ROWS - 1) * MESH_COLS + clampi(x, 0, MESH_COLS - 1)


func _is_anchor(index: int) -> bool:
    return index == _mesh_index(0, 0) or index == _mesh_index(MESH_COLS - 1, 0) or index == _mesh_index(0, MESH_ROWS - 1) or index == _mesh_index(MESH_COLS - 1, MESH_ROWS - 1)


func _seed_system() -> void:
    if not _mesh_pos.is_empty():
        return

    for y: int in range(MESH_ROWS):
        for x: int in range(MESH_COLS):
            var fx := float(x) / float(MESH_COLS - 1)
            var fy := float(y) / float(MESH_ROWS - 1)
            var p := Vector2(95.0 + fx * 1090.0, 105.0 + fy * 510.0)
            p.y += sin(fx * PI * 2.0 + fy * PI) * 16.0
            _mesh_pos.append(p)
            _mesh_prev.append(p)
            _mesh_rest.append(p)

    for y: int in range(MESH_ROWS):
        for x: int in range(MESH_COLS):
            if x < MESH_COLS - 1:
                _add_edge(_mesh_index(x, y), _mesh_index(x + 1, y))
            if y < MESH_ROWS - 1:
                _add_edge(_mesh_index(x, y), _mesh_index(x, y + 1))
            if x < MESH_COLS - 1 and y < MESH_ROWS - 1 and (x + y) % 2 == 0:
                _add_edge(_mesh_index(x, y), _mesh_index(x + 1, y + 1))

    for i: int in range(AGENT_COUNT):
        var p := Vector2(
            180.0 + hash01(float(i) * 13.1) * 920.0,
            150.0 + hash01(float(i) * 29.7 + 2.0) * 420.0
        )
        var angle := hash01(float(i) * 5.3 + 7.0) * TAU
        _agent_pos.append(p)
        _agent_vel.append(Vector2.from_angle(angle) * (34.0 + hash01(float(i) * 17.0) * 46.0))


func _add_edge(a: int, b: int) -> void:
    _edges.append(Vector2i(a, b))
    _edge_rest.append(_mesh_rest[a].distance_to(_mesh_rest[b]))
    _edge_health.append(1.0)


func _update_source_simulation(delta: float) -> void:
    _seed_system()

    if pointer_down:
        _obstacle_pos = pointer_position
        _obstacle_strength = 1.0
    else:
        _obstacle_strength = maxf(0.0, _obstacle_strength - delta * (0.05 + repair_rate * 0.08))

    _update_agents(delta)
    _integrate_mesh(delta)
    _solve_constraints()
    _erode_links(delta)


func _update_agents(delta: float) -> void:
    var next_vel: Array[Vector2] = _agent_vel.duplicate()

    for i: int in range(_agent_pos.size()):
        var p := _agent_pos[i]
        var centre := Vector2.ZERO
        var align := Vector2.ZERO
        var separate := Vector2.ZERO
        var neighbours := 0

        for j: int in range(_agent_pos.size()):
            if i == j:
                continue
            var dvec := _agent_pos[j] - p
            var d := dvec.length()
            if d < 145.0:
                centre += _agent_pos[j]
                align += _agent_vel[j]
                neighbours += 1
            if d < 48.0 and d > 0.001:
                separate -= dvec / d * (1.0 - d / 48.0)

        var force := Vector2.ZERO
        if neighbours > 0:
            centre /= float(neighbours)
            align /= float(neighbours)
            force += (centre - p).normalized() * flock_cohesion * 22.0
            force += (align - _agent_vel[i]) * flock_alignment * 0.18
        force += separate * flock_separation * 92.0

        var nearest := 0
        var nearest_d := INF
        for n: int in range(_mesh_pos.size()):
            var d := p.distance_to(_mesh_pos[n])
            if d < nearest_d:
                nearest_d = d
                nearest = n
        if nearest_d < 150.0:
            var to_mesh := _mesh_pos[nearest] - p
            force += to_mesh * 0.06
            force += Vector2(-to_mesh.y, to_mesh.x).normalized() * 9.0 * sin(sketch_time * 0.7 + float(i))

        if _obstacle_strength > 0.0:
            var away := p - _obstacle_pos
            var d := away.length()
            var radius := obstacle_radius * (0.55 + _obstacle_strength * 0.45)
            if d < radius and d > 0.001:
                force += away / d * (1.0 - d / radius) * 240.0 * _obstacle_strength

        var v := _agent_vel[i] + force * delta
        v = v.limit_length(122.0)
        next_vel[i] = v

    _agent_vel = next_vel

    for i: int in range(_agent_pos.size()):
        var p := _agent_pos[i] + _agent_vel[i] * delta
        if p.x < 28.0 or p.x > 1252.0:
            _agent_vel[i].x *= -1.0
        if p.y < 28.0 or p.y > 692.0:
            _agent_vel[i].y *= -1.0
        p.x = clampf(p.x, 28.0, 1252.0)
        p.y = clampf(p.y, 28.0, 692.0)
        _agent_pos[i] = p


func _integrate_mesh(delta: float) -> void:
    for i: int in range(_mesh_pos.size()):
        if _is_anchor(i):
            _mesh_prev[i] = _mesh_pos[i]
            _mesh_pos[i] = _mesh_rest[i]
            continue

        var pos := _mesh_pos[i]
        var velocity := (pos - _mesh_prev[i]) * mesh_damping
        var force := (_mesh_rest[i] - pos) * 0.0018
        force.y += sin(sketch_time * 0.75 + float(i) * 0.31) * 0.012

        for a: int in range(_agent_pos.size()):
            var away := pos - _agent_pos[a]
            var d := away.length()
            if d < 76.0 and d > 0.001:
                force += away / d * (1.0 - d / 76.0) * agent_pressure * 0.52

        if _obstacle_strength > 0.0:
            var obstacle_away := pos - _obstacle_pos
            var od := obstacle_away.length()
            var radius := obstacle_radius * (0.65 + _obstacle_strength * 0.35)
            if od < radius and od > 0.001:
                force += obstacle_away / od * (1.0 - od / radius) * _obstacle_strength * 1.15

        _mesh_prev[i] = pos
        _mesh_pos[i] = pos + velocity + force * delta * 60.0


func _solve_constraints() -> void:
    for _iteration: int in range(3):
        for e: int in range(_edges.size()):
            var health := _edge_health[e]
            if health <= 0.02:
                continue
            var edge := _edges[e]
            var a := edge.x
            var b := edge.y
            var delta_pos := _mesh_pos[b] - _mesh_pos[a]
            var dist := delta_pos.length()
            if dist <= 0.001:
                continue
            var rest := _edge_rest[e]
            var correction := delta_pos * ((dist - rest) / dist) * 0.5 * mesh_tension * health
            if not _is_anchor(a):
                _mesh_pos[a] += correction
            if not _is_anchor(b):
                _mesh_pos[b] -= correction

        for i: int in range(_mesh_pos.size()):
            if _is_anchor(i):
                _mesh_pos[i] = _mesh_rest[i]


func _erode_links(delta: float) -> void:
    for e: int in range(_edges.size()):
        var edge := _edges[e]
        var midpoint := (_mesh_pos[edge.x] + _mesh_pos[edge.y]) * 0.5
        var wear := 0.0
        for p: Vector2 in _agent_pos:
            var d := midpoint.distance_to(p)
            if d < 26.0:
                wear += (1.0 - d / 26.0) * erosion_rate * delta * 0.52
        _edge_health[e] = clampf(_edge_health[e] - wear + repair_rate * delta * 0.055, 0.0, 1.0)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "mesh_pos": _mesh_pos.duplicate(),
        "mesh_prev": _mesh_prev.duplicate(),
        "edge_health": _edge_health.duplicate(),
        "agent_pos": _agent_pos.duplicate(),
        "agent_vel": _agent_vel.duplicate(),
        "obstacle_pos": _obstacle_pos,
        "obstacle_strength": _obstacle_strength,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var mp: Variant = state.get("mesh_pos", [])
    if mp is Array: _mesh_pos.assign(mp)
    var mv: Variant = state.get("mesh_prev", [])
    if mv is Array: _mesh_prev.assign(mv)
    var eh: Variant = state.get("edge_health", PackedFloat32Array())
    if eh is PackedFloat32Array: _edge_health = (eh as PackedFloat32Array).duplicate()
    var ap: Variant = state.get("agent_pos", [])
    if ap is Array: _agent_pos.assign(ap)
    var av: Variant = state.get("agent_vel", [])
    if av is Array: _agent_vel.assign(av)
    var op: Variant = state.get("obstacle_pos", _obstacle_pos)
    if op is Vector2: _obstacle_pos = op as Vector2
    _obstacle_strength = float(state.get("obstacle_strength", _obstacle_strength))


func _get_custom_live_debug_state() -> Dictionary:
    var health := 0.0
    for value: float in _edge_health:
        health += value
    return {"mesh_health": health, "agents": _agent_pos.size(), "obstacle": _obstacle_strength}


func _draw() -> void:
    begin_design_draw(BG)

    for e: int in range(_edges.size()):
        var health := _edge_health[e]
        if health <= 0.02:
            continue
        var edge := _edges[e]
        var c := INK
        c.a = 0.07 + health * 0.42
        draw_line(_mesh_pos[edge.x], _mesh_pos[edge.y], c, 0.5 + health * 1.25, true)

    for i: int in range(_agent_pos.size()):
        var p := _agent_pos[i]
        var v := _agent_vel[i].normalized()
        draw_circle(p, 2.7, INK)
        draw_line(p, p - v * 8.0, INK, 1.0, true)

    if _obstacle_strength > 0.01:
        var c := INK
        c.a = 0.08 + _obstacle_strength * 0.22
        draw_arc(_obstacle_pos, obstacle_radius * (0.65 + _obstacle_strength * 0.35), 0.0, TAU, 64, c, 1.2, true)

    end_design_draw()
