extends "res://sketches/_shared/design_sketch_base.gd"

const GRAIN_COUNT := 54
const BG := Color(0.055, 0.050, 0.045, 1.0)
const GRAIN := Color(0.73, 0.68, 0.58, 1.0)
const GRAIN_HOT := Color(0.94, 0.43, 0.15, 1.0)
const CHAIN := Color(0.98, 0.82, 0.43, 1.0)
const WALL := Color(0.19, 0.17, 0.15, 1.0)
const CHAMBER := Rect2(92.0, 62.0, 1096.0, 610.0)

@export_range(0.65, 1.25, 0.01) var packing: float = 0.94
@export_range(0.0, 1.0, 0.01) var friction: float = 0.62
@export_range(0.0, 2.5, 0.01) var load: float = 1.08
@export_range(0.2, 2.5, 0.01) var stiffness: float = 1.20
@export_range(0.2, 2.5, 0.01) var force_chain_gain: float = 1.28
@export_range(0.0, 1.5, 0.01) var creep: float = 0.34
@export_range(0.0, 1.5, 0.01) var avalanche: float = 0.74
@export_range(0.0, 1.5, 0.01) var confinement: float = 0.72
@export_range(0.65, 1.35, 0.01) var grain_scale: float = 1.0

var _pos: Array[Vector2] = []
var _vel: Array[Vector2] = []
var _radius := PackedFloat32Array()
var _stress := PackedFloat32Array()
var _base_radius := PackedFloat32Array()
var _contact_pairs: Array[Vector2i] = []
var _contact_force := PackedFloat32Array()
var _accum := 0.0
var _load_memory := 0.0
var _avalanche_clock := 0.0


func _ready() -> void:
    super._ready()
    _seed_system()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"packing","label":"PACKING","type":"float","min":0.65,"max":1.25,"step":0.01},
        {"id":"friction","label":"FRICTION","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"load","label":"LOAD","type":"float","min":0.0,"max":2.5,"step":0.01},
        {"id":"stiffness","label":"STIFFNESS","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"force_chain_gain","label":"FORCE CHAINS","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"creep","label":"CREEP","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"avalanche","label":"AVALANCHE","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"confinement","label":"CONFINEMENT","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"grain_scale","label":"GRAIN SIZE","type":"float","min":0.65,"max":1.35,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "packing": return packing
        "friction": return friction
        "load": return load
        "stiffness": return stiffness
        "force_chain_gain": return force_chain_gain
        "creep": return creep
        "avalanche": return avalanche
        "confinement": return confinement
        "grain_scale": return grain_scale
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "packing": packing = clampf(float(value), 0.65, 1.25)
        "friction": friction = clampf(float(value), 0.0, 1.0)
        "load": load = clampf(float(value), 0.0, 2.5)
        "stiffness": stiffness = clampf(float(value), 0.2, 2.5)
        "force_chain_gain": force_chain_gain = clampf(float(value), 0.2, 2.5)
        "creep": creep = clampf(float(value), 0.0, 1.5)
        "avalanche": avalanche = clampf(float(value), 0.0, 1.5)
        "confinement": confinement = clampf(float(value), 0.0, 1.5)
        "grain_scale": grain_scale = clampf(float(value), 0.65, 1.35)
        _: return


func _seed_system() -> void:
    if not _pos.is_empty():
        return
    _radius.resize(GRAIN_COUNT)
    _base_radius.resize(GRAIN_COUNT)
    _stress.resize(GRAIN_COUNT)
    var cols := 9
    for i: int in range(GRAIN_COUNT):
        var row := i / cols
        var col := i % cols
        var base := 24.0 + hash01(float(i) * 13.7) * 10.0
        _base_radius[i] = base
        _radius[i] = base * grain_scale
        var p := Vector2(
            CHAMBER.position.x + 82.0 + float(col) * 112.0 + (float(row % 2) * 36.0),
            CHAMBER.position.y + 150.0 + float(row) * 78.0
        )
        p += Vector2(hash01(float(i) * 7.1) - 0.5, hash01(float(i) * 17.9) - 0.5) * 20.0
        _pos.append(p)
        _vel.append(Vector2.ZERO)
        _stress[i] = 0.0


func _update_source_simulation(delta: float) -> void:
    _seed_system()
    _load_memory = lerpf(_load_memory, 1.0 if pointer_down else 0.0, clampf(delta * (3.2 if pointer_down else 0.62), 0.0, 1.0))
    _accum += delta
    while _accum >= 1.0 / 45.0:
        _accum -= 1.0 / 45.0
        _step_grains(1.0 / 45.0)


func _step_grains(dt: float) -> void:
    _contact_pairs.clear()
    _contact_force = PackedFloat32Array()
    for i: int in range(GRAIN_COUNT):
        _radius[i] = lerpf(_radius[i], _base_radius[i] * grain_scale * packing, clampf(dt * 1.5, 0.0, 1.0))
        _stress[i] *= pow(0.96, dt * 45.0)

        var v := _vel[i]
        v.y += (22.0 + load * 18.0) * dt
        v *= pow(lerpf(0.995, 0.91, friction), dt * 45.0)

        var center_pull := Vector2(640.0, 420.0) - _pos[i]
        v += center_pull * confinement * 0.0009 * dt * 45.0

        if pointer_down:
            var dvec := _pos[i] - pointer_position
            var d := dvec.length()
            if d < 220.0:
                var w := 1.0 - d / 220.0
                var load_dir := Vector2(0.0, 1.0) + (dvec.normalized() if d > 0.001 else Vector2.ZERO) * 0.32
                v += load_dir * load * w * 185.0 * dt
                _stress[i] += load * w * 0.12

        var creep_dir := sin(float(i) * 2.17 + sketch_time * 0.51)
        v.x += creep_dir * creep * (0.6 + _stress[i]) * dt * 11.0
        _vel[i] = v

    for i: int in range(GRAIN_COUNT):
        for j: int in range(i + 1, GRAIN_COUNT):
            var dvec := _pos[j] - _pos[i]
            var d := dvec.length()
            var min_d := _radius[i] + _radius[j]
            if d >= min_d or d <= 0.0001:
                continue
            var normal := dvec / d
            var overlap := min_d - d
            var force := overlap * stiffness * 0.085
            var correction := normal * overlap * clampf(0.24 + stiffness * 0.12, 0.20, 0.62)
            _pos[i] -= correction * 0.5
            _pos[j] += correction * 0.5

            var rel := _vel[j] - _vel[i]
            var normal_speed := rel.dot(normal)
            var impulse := normal * (-normal_speed * 0.34 + force * 0.54)
            _vel[i] -= impulse * 0.5
            _vel[j] += impulse * 0.5

            var tangent := Vector2(-normal.y, normal.x)
            var slip := rel.dot(tangent)
            var friction_impulse := tangent * slip * friction * 0.12
            _vel[i] += friction_impulse
            _vel[j] -= friction_impulse

            var stress_gain := clampf(force * force_chain_gain, 0.0, 2.0)
            _stress[i] += stress_gain * 0.025
            _stress[j] += stress_gain * 0.025
            _contact_pairs.append(Vector2i(i, j))
            _contact_force.append(stress_gain)

    _avalanche_clock += dt
    if _avalanche_clock >= 0.18:
        _avalanche_clock = 0.0
        var mean_stress := 0.0
        for s: float in _stress:
            mean_stress += s
        mean_stress /= float(GRAIN_COUNT)
        var trigger := lerpf(1.25, 0.28, clampf(avalanche / 1.5, 0.0, 1.0))
        if mean_stress + _load_memory * load * 0.25 > trigger:
            for i: int in range(GRAIN_COUNT):
                var slip_bias := hash01(float(i) * 31.1 + floor(sketch_time * 5.0)) - 0.5
                _vel[i].x += slip_bias * avalanche * (18.0 + _stress[i] * 34.0)
                _vel[i].y += absf(slip_bias) * avalanche * 7.0
                _stress[i] *= 0.62

    for i: int in range(GRAIN_COUNT):
        var p := _pos[i] + _vel[i] * dt
        var r := _radius[i]
        var min_x := CHAMBER.position.x + r
        var max_x := CHAMBER.end.x - r
        var min_y := CHAMBER.position.y + r
        var max_y := CHAMBER.end.y - r
        if p.x < min_x:
            p.x = min_x
            _vel[i].x = absf(_vel[i].x) * (0.30 + (1.0 - friction) * 0.30)
        elif p.x > max_x:
            p.x = max_x
            _vel[i].x = -absf(_vel[i].x) * (0.30 + (1.0 - friction) * 0.30)
        if p.y < min_y:
            p.y = min_y
            _vel[i].y = absf(_vel[i].y) * 0.30
        elif p.y > max_y:
            p.y = max_y
            _vel[i].y = -absf(_vel[i].y) * (0.18 + (1.0 - friction) * 0.25)
            _vel[i].x *= 1.0 - friction * 0.08
        _pos[i] = p


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "pos": _pos.duplicate(), "vel": _vel.duplicate(),
        "radius": _radius.duplicate(), "stress": _stress.duplicate(),
        "load_memory": _load_memory, "accum": _accum, "avalanche_clock": _avalanche_clock,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var pv: Variant = state.get("pos", [])
    if pv is Array: _pos.assign(pv)
    var vv: Variant = state.get("vel", [])
    if vv is Array: _vel.assign(vv)
    var rv: Variant = state.get("radius", PackedFloat32Array())
    if rv is PackedFloat32Array: _radius = (rv as PackedFloat32Array).duplicate()
    var sv: Variant = state.get("stress", PackedFloat32Array())
    if sv is PackedFloat32Array: _stress = (sv as PackedFloat32Array).duplicate()
    _load_memory = float(state.get("load_memory", _load_memory))
    _accum = float(state.get("accum", _accum))
    _avalanche_clock = float(state.get("avalanche_clock", _avalanche_clock))
    _rebuild_contacts_for_draw()


func _rebuild_contacts_for_draw() -> void:
    _contact_pairs.clear()
    _contact_force = PackedFloat32Array()
    for i: int in range(_pos.size()):
        for j: int in range(i + 1, _pos.size()):
            var d := _pos[i].distance_to(_pos[j])
            var min_d := _radius[i] + _radius[j]
            if d < min_d * 1.05:
                _contact_pairs.append(Vector2i(i, j))
                _contact_force.append(clampf((min_d - d + min_d * 0.05) * stiffness * 0.05 * force_chain_gain, 0.0, 2.0))


func _get_custom_live_debug_state() -> Dictionary:
    var mean_stress := 0.0
    for s: float in _stress: mean_stress += s
    return {"grains": GRAIN_COUNT, "contacts": _contact_pairs.size(), "mean_stress": mean_stress / float(GRAIN_COUNT)}


func _draw() -> void:
    begin_design_draw(BG)
    draw_rect(CHAMBER, WALL, false, 2.0)

    for i: int in range(_contact_pairs.size()):
        var pair := _contact_pairs[i]
        var force := _contact_force[i] if i < _contact_force.size() else 0.0
        if force < 0.08:
            continue
        var c := CHAIN
        c.a = clampf(force * 0.46, 0.06, 0.78)
        draw_line(_pos[pair.x], _pos[pair.y], c, 0.8 + force * 2.2, true)

    for i: int in range(_pos.size()):
        var stress_value := clampf(_stress[i] * 0.55, 0.0, 1.0)
        var c := GRAIN.lerp(GRAIN_HOT, stress_value)
        draw_circle(_pos[i], _radius[i], c)
        var edge := Color(0.13, 0.12, 0.11, 0.54)
        draw_arc(_pos[i], _radius[i], 0.0, TAU, 24, edge, 1.0)

    if _load_memory > 0.02:
        var c := CHAIN
        c.a = _load_memory * 0.12
        draw_circle(pointer_position, 70.0 + load * 32.0, c, false, 1.2)

    end_design_draw()
