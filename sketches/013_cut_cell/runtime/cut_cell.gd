extends "res://sketches/_shared/design_sketch_base.gd"

const BG := Color(0.035, 0.03, 0.055, 1.0)
const SITE_COUNT := 18
const GRID_X := 36
const GRID_Y := 20
const CELL_W := 1280.0 / float(GRID_X)
const CELL_H := 720.0 / float(GRID_Y)
const PALETTE := [
    Color(0.18, 0.78, 0.84, 1.0),
    Color(0.98, 0.36, 0.18, 1.0),
    Color(0.75, 0.68, 0.98, 1.0),
    Color(0.92, 0.86, 0.52, 1.0),
]

@export_range(0.2, 2.0, 0.01) var site_speed: float = 0.82
@export_range(0.02, 1.0, 0.01) var heal_rate: float = 0.16
@export_range(70.0, 240.0, 1.0) var connection_range: float = 155.0

var _sites: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _cut_links: Dictionary = {}


func _ready() -> void:
    super._ready()
    _seed_sites()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"site_speed", "label":"DRIFT", "type":"float", "min":0.2, "max":2.0, "step":0.01},
        {"id":"heal_rate", "label":"HEAL", "type":"float", "min":0.02, "max":1.0, "step":0.01},
        {"id":"connection_range", "label":"NETWORK RANGE", "type":"float", "min":70.0, "max":240.0, "step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "site_speed": return site_speed
        "heal_rate": return heal_rate
        "connection_range": return connection_range
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "site_speed": site_speed = clampf(float(value), 0.2, 2.0)
        "heal_rate": heal_rate = clampf(float(value), 0.02, 1.0)
        "connection_range": connection_range = clampf(float(value), 70.0, 240.0)
        _: return


func _seed_sites() -> void:
    if not _sites.is_empty():
        return
    for i: int in range(SITE_COUNT):
        var x := 90.0 + hash01(float(i) * 4.31) * 1100.0
        var y := 70.0 + hash01(float(i) * 9.77 + 2.0) * 580.0
        var a := hash01(float(i) * 17.7) * TAU
        _sites.append(Vector2(x, y))
        _velocities.append(Vector2.from_angle(a) * (12.0 + hash01(float(i) * 31.0) * 28.0))


func _link_key(a: int, b: int) -> String:
    if a > b:
        var t := a
        a = b
        b = t
    return "%d:%d" % [a, b]


func _links() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for i: int in range(_sites.size()):
        var nearest_j := -1
        var nearest_d := INF
        var second_j := -1
        var second_d := INF
        for j: int in range(_sites.size()):
            if i == j:
                continue
            var d := _sites[i].distance_to(_sites[j])
            if d < nearest_d:
                second_d = nearest_d
                second_j = nearest_j
                nearest_d = d
                nearest_j = j
            elif d < second_d:
                second_d = d
                second_j = j
        for j: int in [nearest_j, second_j]:
            if j < 0:
                continue
            if _sites[i].distance_to(_sites[j]) > connection_range:
                continue
            var edge := Vector2i(mini(i, j), maxi(i, j))
            if not result.has(edge):
                result.append(edge)
    return result


func _update_source_simulation(delta: float) -> void:
    _seed_sites()
    for key: Variant in _cut_links.keys():
        var remaining := float(_cut_links[key]) - delta * heal_rate
        if remaining <= 0.0:
            _cut_links.erase(key)
        else:
            _cut_links[key] = remaining

    var attract_y := 360.0 + sin(sketch_time * 0.23) * 90.0
    for i: int in range(_sites.size()):
        var p := _sites[i]
        var v := _velocities[i]
        var force := Vector2(0.0, (attract_y - p.y) * 0.012)
        force.x += sin(sketch_time * 0.41 + float(i) * 1.37) * 8.0
        force.y += cos(sketch_time * 0.33 + float(i) * 2.03) * 7.0
        if pointer_down:
            var away := p - pointer_position
            var d := away.length()
            if d < 150.0 and d > 0.001:
                force += away / d * (1.0 - d / 150.0) * 90.0
        v += force * delta
        v = v.limit_length(72.0 * site_speed)
        p += v * delta * site_speed
        if p.x < 30.0 or p.x > 1250.0:
            v.x *= -1.0
        if p.y < 30.0 or p.y > 690.0:
            v.y *= -1.0
        p.x = clampf(p.x, 30.0, 1250.0)
        p.y = clampf(p.y, 30.0, 690.0)
        _sites[i] = p
        _velocities[i] = v

    if pointer_down:
        for edge: Vector2i in _links():
            var midpoint := (_sites[edge.x] + _sites[edge.y]) * 0.5
            if midpoint.distance_to(pointer_position) < 92.0:
                _cut_links[_link_key(edge.x, edge.y)] = 1.0


func _nearest_site(point: Vector2) -> int:
    var best := 0
    var best_d := INF
    for i: int in range(_sites.size()):
        var d := point.distance_squared_to(_sites[i])
        if d < best_d:
            best_d = d
            best = i
    return best


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "sites": _sites.duplicate(),
        "velocities": _velocities.duplicate(),
        "cut_links": _cut_links.duplicate(true),
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var s: Variant = state.get("sites", [])
    if s is Array:
        _sites.assign(s)
    var v: Variant = state.get("velocities", [])
    if v is Array:
        _velocities.assign(v)
    var cuts: Variant = state.get("cut_links", {})
    if cuts is Dictionary:
        _cut_links = (cuts as Dictionary).duplicate(true)


func _get_custom_live_debug_state() -> Dictionary:
    return {"sites": _sites.size(), "cut_links": _cut_links.size()}


func _draw() -> void:
    begin_design_draw(BG)

    for gy: int in range(GRID_Y):
        for gx: int in range(GRID_X):
            var center := Vector2((float(gx) + 0.5) * CELL_W, (float(gy) + 0.5) * CELL_H)
            var site := _nearest_site(center)
            var c: Color = PALETTE[site % PALETTE.size()]
            c.a = 0.10 + 0.07 * float((site % 3) + 1)
            draw_rect(Rect2(Vector2(float(gx) * CELL_W, float(gy) * CELL_H), Vector2(CELL_W + 0.5, CELL_H + 0.5)), c, true)

    for edge: Vector2i in _links():
        var key := _link_key(edge.x, edge.y)
        var cut := clampf(float(_cut_links.get(key, 0.0)), 0.0, 1.0)
        var c := Color(0.94, 0.96, 0.9, 0.34 * (1.0 - cut))
        if cut > 0.0:
            c = Color(1.0, 0.18, 0.08, 0.12 + cut * 0.35)
        draw_line(_sites[edge.x], _sites[edge.y], c, 1.2 + cut * 2.4)

    for i: int in range(_sites.size()):
        var c: Color = PALETTE[i % PALETTE.size()]
        draw_circle(_sites[i], 4.0, c)
        draw_circle(_sites[i], 10.0, Color(c.r, c.g, c.b, 0.12), false, 1.0)

    end_design_draw()
