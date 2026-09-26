extends "res://sketches/_shared/design_sketch_base.gd"

const BG := Color(0.018, 0.022, 0.028, 1.0)
const INK := Color(0.91, 0.94, 0.89, 1.0)
const SIGNAL := Color(1.0, 0.34, 0.12, 1.0)
const AGENT_COUNT := 72

@export_range(0.0, 2.0, 0.01) var cohesion: float = 0.72
@export_range(0.0, 2.0, 0.01) var separation: float = 1.08
@export_range(40.0, 220.0, 1.0) var link_radius: float = 118.0

var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _damage: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
    super._ready()
    _seed_agents()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"cohesion", "label":"COHESION", "type":"float", "min":0.0, "max":2.0, "step":0.01},
        {"id":"separation", "label":"SEPARATION", "type":"float", "min":0.0, "max":2.0, "step":0.01},
        {"id":"link_radius", "label":"LINK RANGE", "type":"float", "min":40.0, "max":220.0, "step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "cohesion": return cohesion
        "separation": return separation
        "link_radius": return link_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "cohesion": cohesion = clampf(float(value), 0.0, 2.0)
        "separation": separation = clampf(float(value), 0.0, 2.0)
        "link_radius": link_radius = clampf(float(value), 40.0, 220.0)
        _: return


func _seed_agents() -> void:
    if not _positions.is_empty():
        return
    for i: int in range(AGENT_COUNT):
        var px := 70.0 + hash01(float(i) * 11.7) * 1140.0
        var py := 60.0 + hash01(float(i) * 27.1 + 4.0) * 600.0
        var angle := hash01(float(i) * 41.3 + 8.0) * TAU
        _positions.append(Vector2(px, py))
        _velocities.append(Vector2.from_angle(angle) * (28.0 + hash01(float(i) * 3.1) * 38.0))
        _damage.append(0.0)


func _update_source_simulation(delta: float) -> void:
    _seed_agents()
    var centre := Vector2.ZERO
    for p: Vector2 in _positions:
        centre += p
    centre /= maxf(1.0, float(_positions.size()))

    var next_velocity: Array[Vector2] = _velocities.duplicate()
    for i: int in range(_positions.size()):
        var p := _positions[i]
        var v := _velocities[i]
        var force := (centre - p) * 0.010 * cohesion
        var local_count := 0
        var local_centre := Vector2.ZERO

        for j: int in range(_positions.size()):
            if i == j:
                continue
            var dvec := p - _positions[j]
            var d := dvec.length()
            if d < 64.0 and d > 0.001:
                force += dvec / d * (1.0 - d / 64.0) * 72.0 * separation
            if d < link_radius:
                local_centre += _positions[j]
                local_count += 1

        if local_count > 0:
            local_centre /= float(local_count)
            force += (local_centre - p) * 0.014 * cohesion

        var wander := Vector2(
            sin(sketch_time * 0.91 + float(i) * 1.73),
            cos(sketch_time * 0.73 + float(i) * 2.11)
        ) * 10.0
        force += wander

        if pointer_down:
            var away := p - pointer_position
            var dist := away.length()
            if dist < 170.0:
                var w := 1.0 - dist / 170.0
                if dist > 0.001:
                    force += away / dist * 280.0 * w
                _damage[i] = clampf(_damage[i] + delta * 2.6 * w, 0.0, 1.0)

        _damage[i] = maxf(0.0, _damage[i] - delta * 0.22)
        v += force * delta
        v = v.limit_length(118.0)
        next_velocity[i] = v

    _velocities = next_velocity
    for i: int in range(_positions.size()):
        var p := _positions[i] + _velocities[i] * delta
        if p.x < 24.0 or p.x > DESIGN_SIZE.x - 24.0:
            _velocities[i].x *= -1.0
        if p.y < 24.0 or p.y > DESIGN_SIZE.y - 24.0:
            _velocities[i].y *= -1.0
        p.x = clampf(p.x, 24.0, DESIGN_SIZE.x - 24.0)
        p.y = clampf(p.y, 24.0, DESIGN_SIZE.y - 24.0)
        _positions[i] = p


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "damage": _damage.duplicate(),
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var p: Variant = state.get("positions", [])
    if p is Array:
        _positions.assign(p)
    var v: Variant = state.get("velocities", [])
    if v is Array:
        _velocities.assign(v)
    var d: Variant = state.get("damage", PackedFloat32Array())
    if d is PackedFloat32Array:
        _damage = (d as PackedFloat32Array).duplicate()


func _get_custom_live_debug_state() -> Dictionary:
    return {"agents": _positions.size(), "mean_damage": _mean_damage()}


func _mean_damage() -> float:
    if _damage.is_empty():
        return 0.0
    var total := 0.0
    for value: float in _damage:
        total += value
    return total / float(_damage.size())


func _draw() -> void:
    begin_design_draw(BG)

    for i: int in range(_positions.size()):
        var nearest: Array[Dictionary] = []
        for j: int in range(_positions.size()):
            if i == j:
                continue
            var d := _positions[i].distance_to(_positions[j])
            if d <= link_radius:
                nearest.append({"j": j, "d": d})
        nearest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
        for k: int in range(mini(2, nearest.size())):
            var j := int(nearest[k]["j"])
            if j < i:
                continue
            var d := float(nearest[k]["d"])
            var health := 1.0 - maxf(_damage[i], _damage[j])
            if health <= 0.04:
                continue
            var c := INK
            c.a = (1.0 - d / link_radius) * 0.26 * health
            draw_line(_positions[i], _positions[j], c, 1.0)

    for i: int in range(_positions.size()):
        var c := INK.lerp(SIGNAL, _damage[i])
        c.a = 0.72 + _damage[i] * 0.28
        draw_circle(_positions[i], 2.2 + _damage[i] * 3.8, c)

    end_design_draw()
