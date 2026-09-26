extends "res://sketches/_shared/design_sketch_base.gd"

const NODE_COUNT := 30
const FIELD_COLS := 40
const FIELD_ROWS := 23
const FIELD_W := 1280.0 / float(FIELD_COLS)
const FIELD_H := 720.0 / float(FIELD_ROWS)
const BG := Color(0.012, 0.022, 0.020, 1.0)
const LOW := Color(0.035, 0.125, 0.090, 1.0)
const HIGH := Color(0.72, 0.94, 0.38, 1.0)
const LINK := Color(0.78, 0.88, 0.68, 1.0)
const PRED := Color(1.0, 0.19, 0.32, 1.0)

@export_range(0.05, 1.5, 0.01) var growth: float = 0.46
@export_range(0.0, 1.6, 0.01) var diffusion: float = 0.82
@export_range(0.1, 2.5, 0.01) var predator_appetite: float = 1.05
@export_range(24.0, 180.0, 1.0) var predator_speed: float = 82.0
@export_range(90.0, 300.0, 1.0) var link_range: float = 205.0
@export_range(0.0, 1.0, 0.01) var hysteresis: float = 0.38
@export_range(0.0, 1.0, 0.01) var scar_memory: float = 0.74
@export_range(0.0, 1.5, 0.01) var field_cohesion: float = 0.68

var _node_pos: Array[Vector2] = []
var _node_vel: Array[Vector2] = []
var _energy: PackedFloat32Array = PackedFloat32Array()
var _scar: PackedFloat32Array = PackedFloat32Array()
var _active: PackedByteArray = PackedByteArray()

var _pred_pos: Array[Vector2] = []
var _pred_vel: Array[Vector2] = []
var _pred_age: PackedFloat32Array = PackedFloat32Array()

var _field: PackedFloat32Array = PackedFloat32Array()
var _field_next: PackedFloat32Array = PackedFloat32Array()
var _field_accum: float = 0.0
var _spawn_cooldown: float = 0.0


func _ready() -> void:
    super._ready()
    _seed_system()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"growth", "label":"REGROWTH", "type":"float", "min":0.05, "max":1.5, "step":0.01},
        {"id":"diffusion", "label":"RESOURCE FLOW", "type":"float", "min":0.0, "max":1.6, "step":0.01},
        {"id":"predator_appetite", "label":"APPETITE", "type":"float", "min":0.1, "max":2.5, "step":0.01},
        {"id":"predator_speed", "label":"PREDATOR SPEED", "type":"float", "min":24.0, "max":180.0, "step":1.0},
        {"id":"link_range", "label":"NETWORK RANGE", "type":"float", "min":90.0, "max":300.0, "step":1.0},
        {"id":"hysteresis", "label":"HYSTERESIS", "type":"float", "min":0.0, "max":1.0, "step":0.01},
        {"id":"scar_memory", "label":"SCAR MEMORY", "type":"float", "min":0.0, "max":1.0, "step":0.01},
        {"id":"field_cohesion", "label":"FIELD COHESION", "type":"float", "min":0.0, "max":1.5, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "growth": return growth
        "diffusion": return diffusion
        "predator_appetite": return predator_appetite
        "predator_speed": return predator_speed
        "link_range": return link_range
        "hysteresis": return hysteresis
        "scar_memory": return scar_memory
        "field_cohesion": return field_cohesion
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "growth": growth = clampf(float(value), 0.05, 1.5)
        "diffusion": diffusion = clampf(float(value), 0.0, 1.6)
        "predator_appetite": predator_appetite = clampf(float(value), 0.1, 2.5)
        "predator_speed": predator_speed = clampf(float(value), 24.0, 180.0)
        "link_range": link_range = clampf(float(value), 90.0, 300.0)
        "hysteresis": hysteresis = clampf(float(value), 0.0, 1.0)
        "scar_memory": scar_memory = clampf(float(value), 0.0, 1.0)
        "field_cohesion": field_cohesion = clampf(float(value), 0.0, 1.5)
        _: return


func _seed_system() -> void:
    if not _node_pos.is_empty():
        return

    _energy.resize(NODE_COUNT)
    _scar.resize(NODE_COUNT)
    _active.resize(NODE_COUNT)

    for i: int in range(NODE_COUNT):
        var ring := float(i % 10) / 10.0 * TAU
        var band := float(i / 10)
        var centre := Vector2(640.0 + (band - 1.0) * 170.0, 360.0)
        var radius := 160.0 + 72.0 * sin(float(i) * 1.71)
        var p := centre + Vector2(cos(ring), sin(ring)) * radius
        p += Vector2(hash01(float(i) * 17.3) - 0.5, hash01(float(i) * 29.1 + 4.0) - 0.5) * 92.0
        p.x = clampf(p.x, 64.0, 1216.0)
        p.y = clampf(p.y, 58.0, 662.0)
        _node_pos.append(p)
        _node_vel.append(Vector2.ZERO)
        _energy[i] = 0.48 + hash01(float(i) * 13.7) * 0.46
        _scar[i] = 0.0
        _active[i] = 1 if _energy[i] > 0.52 else 0

    _field.resize(FIELD_COLS * FIELD_ROWS)
    _field_next.resize(FIELD_COLS * FIELD_ROWS)
    _field.fill(0.0)
    _field_next.fill(0.0)
    _step_field()

    _spawn_predator(Vector2(332.0, 238.0))
    _spawn_predator(Vector2(948.0, 486.0))


func _field_idx(x: int, y: int) -> int:
    return clampi(y, 0, FIELD_ROWS - 1) * FIELD_COLS + clampi(x, 0, FIELD_COLS - 1)


func _update_source_simulation(delta: float) -> void:
    _seed_system()
    _spawn_cooldown = maxf(0.0, _spawn_cooldown - delta)

    if pointer_down and _spawn_cooldown <= 0.0:
        _spawn_predator(pointer_position)
        _spawn_cooldown = 0.32

    _update_nodes(delta)
    _update_predators(delta)

    _field_accum += delta
    while _field_accum >= 1.0 / 18.0:
        _field_accum -= 1.0 / 18.0
        _step_field()


func _update_nodes(delta: float) -> void:
    var next_energy := _energy.duplicate()
    var next_vel: Array[Vector2] = _node_vel.duplicate()
    var scar_decay := lerpf(0.42, 0.035, scar_memory)

    for i: int in range(NODE_COUNT):
        var p := _node_pos[i]
        var neighbour_energy := 0.0
        var neighbour_count := 0
        var local_centre := Vector2.ZERO

        for j: int in range(NODE_COUNT):
            if i == j:
                continue
            var d := p.distance_to(_node_pos[j])
            if d < link_range:
                var w := 1.0 - d / link_range
                neighbour_energy += _energy[j] * w
                local_centre += _node_pos[j] * w
                neighbour_count += 1

        var avg := _energy[i]
        if neighbour_count > 0:
            avg = neighbour_energy / float(neighbour_count)

        var value := _energy[i]
        value += (1.0 - value) * growth * delta * (0.32 + 0.68 * (1.0 - _scar[i]))
        value += (avg - value) * diffusion * delta * 0.38
        value -= _scar[i] * delta * 0.18
        next_energy[i] = clampf(value, 0.0, 1.0)

        _scar[i] = maxf(0.0, _scar[i] - scar_decay * delta)

        var high := 0.48 + hysteresis * 0.16
        var low := 0.40 - hysteresis * 0.14
        if _active[i] == 0 and next_energy[i] > high:
            _active[i] = 1
        elif _active[i] == 1 and next_energy[i] < low:
            _active[i] = 0

        var drift := Vector2(
            sin(sketch_time * 0.31 + float(i) * 1.31),
            cos(sketch_time * 0.27 + float(i) * 1.77)
        ) * 2.4
        var centre_force := (Vector2(640.0, 360.0) - p) * 0.0007
        var v := (_node_vel[i] + (drift + centre_force) * delta * 60.0) * pow(0.985, delta * 60.0)
        next_vel[i] = v.limit_length(8.0)

    _energy = next_energy
    _node_vel = next_vel

    for i: int in range(NODE_COUNT):
        var p := _node_pos[i] + _node_vel[i] * delta
        if p.x < 44.0 or p.x > 1236.0:
            _node_vel[i].x *= -1.0
        if p.y < 42.0 or p.y > 678.0:
            _node_vel[i].y *= -1.0
        p.x = clampf(p.x, 44.0, 1236.0)
        p.y = clampf(p.y, 42.0, 678.0)
        _node_pos[i] = p


func _spawn_predator(point: Vector2) -> void:
    if _pred_pos.size() >= 9:
        _pred_pos.remove_at(0)
        _pred_vel.remove_at(0)
        var ages := PackedFloat32Array()
        for i: int in range(1, _pred_age.size()):
            ages.append(_pred_age[i])
        _pred_age = ages

    _pred_pos.append(Vector2(clampf(point.x, 24.0, 1256.0), clampf(point.y, 24.0, 696.0)))
    var angle := hash01(float(_pred_pos.size()) * 19.7 + sketch_time) * TAU
    _pred_vel.append(Vector2.from_angle(angle) * predator_speed * 0.45)
    _pred_age.append(0.0)


func _update_predators(delta: float) -> void:
    for pidx: int in range(_pred_pos.size()):
        var p := _pred_pos[pidx]
        var best_score := -1.0
        var target := Vector2(640.0, 360.0)

        for i: int in range(NODE_COUNT):
            var d := p.distance_to(_node_pos[i])
            var score := _energy[i] * (1.0 - _scar[i] * 0.7) / (44.0 + d)
            if score > best_score:
                best_score = score
                target = _node_pos[i]

        var desired := (target - p).normalized() * predator_speed
        var v := _pred_vel[pidx].lerp(desired, clampf(delta * 1.9, 0.0, 1.0))
        v += Vector2(sin(sketch_time * 1.3 + float(pidx) * 2.1), cos(sketch_time * 1.1 + float(pidx) * 1.7)) * 8.0
        v = v.limit_length(predator_speed * 1.25)
        p += v * delta

        if p.x < 18.0 or p.x > 1262.0:
            v.x *= -1.0
        if p.y < 18.0 or p.y > 702.0:
            v.y *= -1.0
        p.x = clampf(p.x, 18.0, 1262.0)
        p.y = clampf(p.y, 18.0, 702.0)

        _pred_pos[pidx] = p
        _pred_vel[pidx] = v
        _pred_age[pidx] += delta

        for i: int in range(NODE_COUNT):
            var d := p.distance_to(_node_pos[i])
            if d < 82.0:
                var w := 1.0 - d / 82.0
                _energy[i] = maxf(0.0, _energy[i] - predator_appetite * delta * 0.42 * w)
                _scar[i] = clampf(_scar[i] + predator_appetite * delta * 0.34 * w, 0.0, 1.0)


func _step_field() -> void:
    if _field.size() != FIELD_COLS * FIELD_ROWS:
        return

    for y: int in range(FIELD_ROWS):
        for x: int in range(FIELD_COLS):
            var i := _field_idx(x, y)
            var centre := Vector2((float(x) + 0.5) * FIELD_W, (float(y) + 0.5) * FIELD_H)
            var source := 0.0
            var scar_value := 0.0

            for n: int in range(NODE_COUNT):
                var d2 := centre.distance_squared_to(_node_pos[n])
                var influence := exp(-d2 / 19000.0)
                source += _energy[n] * influence * 0.24
                scar_value += _scar[n] * influence * 0.18

            source = clampf(source - scar_value, 0.0, 1.0)
            var neighbour := (
                _field[_field_idx(x - 1, y)] +
                _field[_field_idx(x + 1, y)] +
                _field[_field_idx(x, y - 1)] +
                _field[_field_idx(x, y + 1)]
            ) * 0.25
            var current := _field[i]
            var mixed := lerpf(current, source, 0.12 + field_cohesion * 0.08)
            mixed += (neighbour - current) * field_cohesion * 0.16
            _field_next[i] = clampf(mixed, 0.0, 1.0)

    var temp := _field
    _field = _field_next
    _field_next = temp


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "node_pos": _node_pos.duplicate(),
        "node_vel": _node_vel.duplicate(),
        "energy": _energy.duplicate(),
        "scar": _scar.duplicate(),
        "active": _active.duplicate(),
        "pred_pos": _pred_pos.duplicate(),
        "pred_vel": _pred_vel.duplicate(),
        "pred_age": _pred_age.duplicate(),
        "field": _field.duplicate(),
        "field_accum": _field_accum,
        "spawn_cooldown": _spawn_cooldown,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var np: Variant = state.get("node_pos", [])
    if np is Array: _node_pos.assign(np)
    var nv: Variant = state.get("node_vel", [])
    if nv is Array: _node_vel.assign(nv)
    var ev: Variant = state.get("energy", PackedFloat32Array())
    if ev is PackedFloat32Array: _energy = (ev as PackedFloat32Array).duplicate()
    var sv: Variant = state.get("scar", PackedFloat32Array())
    if sv is PackedFloat32Array: _scar = (sv as PackedFloat32Array).duplicate()
    var av: Variant = state.get("active", PackedByteArray())
    if av is PackedByteArray: _active = (av as PackedByteArray).duplicate()
    var pp: Variant = state.get("pred_pos", [])
    if pp is Array: _pred_pos.assign(pp)
    var pv: Variant = state.get("pred_vel", [])
    if pv is Array: _pred_vel.assign(pv)
    var pa: Variant = state.get("pred_age", PackedFloat32Array())
    if pa is PackedFloat32Array: _pred_age = (pa as PackedFloat32Array).duplicate()
    var fv: Variant = state.get("field", PackedFloat32Array())
    if fv is PackedFloat32Array:
        _field = (fv as PackedFloat32Array).duplicate()
        _field_next.resize(_field.size())
    _field_accum = float(state.get("field_accum", _field_accum))
    _spawn_cooldown = float(state.get("spawn_cooldown", _spawn_cooldown))


func _get_custom_live_debug_state() -> Dictionary:
    var total := 0.0
    for value: float in _energy:
        total += value
    return {"network_energy": total, "predators": _pred_pos.size()}


func _draw() -> void:
    begin_design_draw(BG)

    if _field.size() == FIELD_COLS * FIELD_ROWS:
        for y: int in range(FIELD_ROWS):
            for x: int in range(FIELD_COLS):
                var value := _field[_field_idx(x, y)]
                if value < 0.035:
                    continue
                var t := smoothstep(0.03, 0.72, value)
                var c := LOW.lerp(HIGH, t)
                c.a = 0.12 + t * 0.62
                var centre := Vector2((float(x) + 0.5) * FIELD_W, (float(y) + 0.5) * FIELD_H)
                var radius := minf(FIELD_W, FIELD_H) * (0.16 + t * 0.34)
                draw_circle(centre, radius, c)

    for i: int in range(NODE_COUNT):
        if _active[i] == 0:
            continue
        for j: int in range(i + 1, NODE_COUNT):
            if _active[j] == 0:
                continue
            var d := _node_pos[i].distance_to(_node_pos[j])
            if d > link_range:
                continue
            var strength := (1.0 - d / link_range) * minf(_energy[i], _energy[j])
            if strength < 0.08:
                continue
            var c := LINK
            c.a = 0.06 + strength * 0.34
            draw_line(_node_pos[i], _node_pos[j], c, 0.8 + strength * 1.6, true)

    for i: int in range(NODE_COUNT):
        var e := _energy[i]
        var c := LOW.lerp(HIGH, e)
        c.a = 0.38 + e * 0.62
        draw_circle(_node_pos[i], 2.0 + e * 4.6, c)
        if _scar[i] > 0.05:
            var s := PRED
            s.a = _scar[i] * 0.52
            draw_arc(_node_pos[i], 7.0 + _scar[i] * 8.0, 0.0, TAU, 22, s, 1.2)

    for p: Vector2 in _pred_pos:
        draw_circle(p, 5.0, PRED)
        draw_circle(p, 10.0, Color(PRED.r, PRED.g, PRED.b, 0.12), false, 1.0)

    end_design_draw()
