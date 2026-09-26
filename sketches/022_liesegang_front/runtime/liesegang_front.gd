extends "res://sketches/_shared/design_sketch_base.gd"

const BG := Color(0.93, 0.90, 0.81, 1.0)
const GEL := Color(0.77, 0.73, 0.62, 1.0)
const PRECIP := Color(0.075, 0.085, 0.095, 1.0)
const ACTIVE := Color(0.82, 0.20, 0.08, 1.0)
const MAX_RESERVOIRS := 4
const MAX_BANDS := 42

@export_range(0.1, 2.0, 0.01) var diffusion: float = 0.92
@export_range(0.1, 1.8, 0.01) var supersaturation: float = 0.86
@export_range(0.05, 1.5, 0.01) var nucleation: float = 0.72
@export_range(0.0, 1.5, 0.01) var depletion: float = 0.68
@export_range(0.0, 1.0, 0.01) var dissolution: float = 0.18
@export_range(8.0, 120.0, 1.0) var front_speed: float = 42.0
@export_range(0.0, 1.0, 0.01) var band_memory: float = 0.84
@export_range(0.0, 1.5, 0.01) var field_bias: float = 0.36

var _reservoir_pos: Array[Vector2] = []
var _front_radius := PackedFloat32Array()
var _next_band_radius := PackedFloat32Array()
var _reservoir_phase := PackedFloat32Array()
var _reservoir_charge := PackedFloat32Array()
var _reservoir_rest := PackedFloat32Array()
var _reservoir_generation := PackedInt32Array()

var _band_center: Array[Vector2] = []
var _band_radius := PackedFloat32Array()
var _band_strength := PackedFloat32Array()
var _band_phase := PackedFloat32Array()
var _band_width := PackedFloat32Array()

var _spawn_cooldown := 0.0


func _ready() -> void:
    super._ready()
    _spawn_reservoir(Vector2(420.0, 360.0))


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"diffusion","label":"DIFFUSION","type":"float","min":0.1,"max":2.0,"step":0.01},
        {"id":"supersaturation","label":"SUPERSATURATION","type":"float","min":0.1,"max":1.8,"step":0.01},
        {"id":"nucleation","label":"NUCLEATION","type":"float","min":0.05,"max":1.5,"step":0.01},
        {"id":"depletion","label":"DEPLETION","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"dissolution","label":"DISSOLUTION","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"front_speed","label":"FRONT SPEED","type":"float","min":8.0,"max":120.0,"step":1.0},
        {"id":"band_memory","label":"BAND MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"field_bias","label":"FIELD BIAS","type":"float","min":0.0,"max":1.5,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "diffusion": return diffusion
        "supersaturation": return supersaturation
        "nucleation": return nucleation
        "depletion": return depletion
        "dissolution": return dissolution
        "front_speed": return front_speed
        "band_memory": return band_memory
        "field_bias": return field_bias
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "diffusion": diffusion = clampf(float(value), 0.1, 2.0)
        "supersaturation": supersaturation = clampf(float(value), 0.1, 1.8)
        "nucleation": nucleation = clampf(float(value), 0.05, 1.5)
        "depletion": depletion = clampf(float(value), 0.0, 1.5)
        "dissolution": dissolution = clampf(float(value), 0.0, 1.0)
        "front_speed": front_speed = clampf(float(value), 8.0, 120.0)
        "band_memory": band_memory = clampf(float(value), 0.0, 1.0)
        "field_bias": field_bias = clampf(float(value), 0.0, 1.5)
        _: return


func _spawn_reservoir(point: Vector2) -> void:
    if _reservoir_pos.size() >= MAX_RESERVOIRS:
        return
    var p := Vector2(clampf(point.x, 80.0, 1200.0), clampf(point.y, 70.0, 650.0))
    _reservoir_pos.append(p)
    _front_radius.append(8.0)
    _next_band_radius.append(32.0)
    _reservoir_phase.append(hash01(float(_reservoir_pos.size()) * 17.3 + sketch_time) * TAU)
    _reservoir_charge.append(1.0)
    _reservoir_rest.append(0.0)
    _reservoir_generation.append(0)


func _update_source_simulation(delta: float) -> void:
    _spawn_cooldown = maxf(0.0, _spawn_cooldown - delta)
    if pointer_down:
        if _spawn_cooldown <= 0.0 and _reservoir_pos.size() < MAX_RESERVOIRS:
            _spawn_reservoir(pointer_position)
            _spawn_cooldown = 0.7
        elif not _reservoir_pos.is_empty():
            var idx := _reservoir_pos.size() - 1
            _reservoir_pos[idx] = _reservoir_pos[idx].lerp(pointer_position, clampf(delta * 1.6, 0.0, 1.0))

    for i: int in range(_reservoir_pos.size()):
        var local_boost := 1.0
        if pointer_down:
            var d := pointer_position.distance_to(_reservoir_pos[i])
            if d < 220.0:
                local_boost += (1.0 - d / 220.0) * 0.8

        if _reservoir_charge[i] > 0.08:
            var charge_scale := smoothstep(0.05, 0.55, _reservoir_charge[i])
            _front_radius[i] += front_speed * diffusion * delta * local_boost * charge_scale
            var depletion_rate := 0.008 + depletion * 0.014 + diffusion * 0.004
            _reservoir_charge[i] = maxf(0.0, _reservoir_charge[i] - depletion_rate * delta * local_boost)

            if _front_radius[i] >= _next_band_radius[i]:
                _precipitate_band(i)
                var spacing := 18.0 + depletion * 24.0 + _front_radius[i] * (0.018 + 0.018 * depletion)
                spacing /= maxf(0.25, supersaturation * (0.65 + nucleation * 0.35))
                _next_band_radius[i] += clampf(spacing, 12.0, 90.0)

            if _front_radius[i] > 860.0 or _reservoir_charge[i] <= 0.08:
                _reservoir_charge[i] = 0.0
                var generation_key := float(_reservoir_generation[i] + 1) + float(i) * 17.0
                _reservoir_rest[i] = lerpf(2.8, 8.4, hash01(generation_key * 11.3 + 4.7))
        elif _reservoir_rest[i] > 0.0:
            var previous_rest := _reservoir_rest[i]
            _reservoir_rest[i] = maxf(0.0, previous_rest - delta)
            if previous_rest > 0.0 and _reservoir_rest[i] <= 0.0:
                _reservoir_generation[i] += 1
                var generation_key := float(_reservoir_generation[i]) + float(i) * 23.0
                _front_radius[i] = 8.0
                _next_band_radius[i] = 28.0 + hash01(generation_key * 7.9) * 24.0
                _reservoir_phase[i] += 0.47 + hash01(generation_key * 3.7) * 0.82
        else:
            var recharge_rate := 0.055 + supersaturation * 0.035 + nucleation * 0.018
            _reservoir_charge[i] = minf(1.0, _reservoir_charge[i] + recharge_rate * delta)

    var fade_rate := dissolution * lerpf(0.18, 0.018, band_memory)
    for i: int in range(_band_strength.size()):
        _band_strength[i] = maxf(0.0, _band_strength[i] - fade_rate * delta)

    _remove_dead_bands()


func _precipitate_band(owner: int) -> void:
    if _band_radius.size() >= MAX_BANDS:
        _remove_band_at(0)
    _band_center.append(_reservoir_pos[owner])
    _band_radius.append(_front_radius[owner])
    _band_strength.append(clampf((0.48 + supersaturation * 0.35 + nucleation * 0.18) * _reservoir_charge[owner], 0.0, 1.0))
    _band_phase.append(_reservoir_phase[owner] + _front_radius[owner] * 0.009)
    _band_width.append(0.9 + supersaturation * 1.7 + hash01(_front_radius[owner]) * 1.3)


func _remove_dead_bands() -> void:
    var i := _band_strength.size() - 1
    while i >= 0:
        if _band_strength[i] <= 0.01:
            _remove_band_at(i)
        i -= 1


func _remove_band_at(index: int) -> void:
    _band_center.remove_at(index)
    _band_radius.remove_at(index)
    _band_strength.remove_at(index)
    _band_phase.remove_at(index)
    _band_width.remove_at(index)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "reservoir_pos": _reservoir_pos.duplicate(),
        "front_radius": _front_radius.duplicate(),
        "next_band_radius": _next_band_radius.duplicate(),
        "reservoir_phase": _reservoir_phase.duplicate(),
        "reservoir_charge": _reservoir_charge.duplicate(),
        "reservoir_rest": _reservoir_rest.duplicate(),
        "reservoir_generation": _reservoir_generation.duplicate(),
        "band_center": _band_center.duplicate(),
        "band_radius": _band_radius.duplicate(),
        "band_strength": _band_strength.duplicate(),
        "band_phase": _band_phase.duplicate(),
        "band_width": _band_width.duplicate(),
        "spawn_cooldown": _spawn_cooldown,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var rp: Variant = state.get("reservoir_pos", [])
    if rp is Array: _reservoir_pos.assign(rp)
    var fr: Variant = state.get("front_radius", PackedFloat32Array())
    if fr is PackedFloat32Array: _front_radius = (fr as PackedFloat32Array).duplicate()
    var nb: Variant = state.get("next_band_radius", PackedFloat32Array())
    if nb is PackedFloat32Array: _next_band_radius = (nb as PackedFloat32Array).duplicate()
    var ph: Variant = state.get("reservoir_phase", PackedFloat32Array())
    if ph is PackedFloat32Array: _reservoir_phase = (ph as PackedFloat32Array).duplicate()
    var rc: Variant = state.get("reservoir_charge", PackedFloat32Array())
    if rc is PackedFloat32Array: _reservoir_charge = (rc as PackedFloat32Array).duplicate()
    var rr: Variant = state.get("reservoir_rest", PackedFloat32Array())
    if rr is PackedFloat32Array: _reservoir_rest = (rr as PackedFloat32Array).duplicate()
    var rg: Variant = state.get("reservoir_generation", PackedInt32Array())
    if rg is PackedInt32Array: _reservoir_generation = (rg as PackedInt32Array).duplicate()
    var bc: Variant = state.get("band_center", [])
    if bc is Array: _band_center.assign(bc)
    var br: Variant = state.get("band_radius", PackedFloat32Array())
    if br is PackedFloat32Array: _band_radius = (br as PackedFloat32Array).duplicate()
    var bs: Variant = state.get("band_strength", PackedFloat32Array())
    if bs is PackedFloat32Array: _band_strength = (bs as PackedFloat32Array).duplicate()
    var bp: Variant = state.get("band_phase", PackedFloat32Array())
    if bp is PackedFloat32Array: _band_phase = (bp as PackedFloat32Array).duplicate()
    var bw: Variant = state.get("band_width", PackedFloat32Array())
    if bw is PackedFloat32Array: _band_width = (bw as PackedFloat32Array).duplicate()
    _spawn_cooldown = float(state.get("spawn_cooldown", _spawn_cooldown))


func _get_custom_live_debug_state() -> Dictionary:
    var charge_total := 0.0
    for charge: float in _reservoir_charge:
        charge_total += charge
    return {
        "reservoirs": _reservoir_pos.size(),
        "bands": _band_radius.size(),
        "reservoir_charge": charge_total,
    }


func _draw() -> void:
    begin_design_draw(BG)

    for r: int in range(_reservoir_pos.size()):
        var charge := _reservoir_charge[r] if r < _reservoir_charge.size() else 1.0
        var source_color := ACTIVE
        source_color.a = 0.025 + charge * (0.055 + (0.06 if pointer_down else 0.0))
        draw_circle(_reservoir_pos[r], 18.0 + supersaturation * 8.0, source_color)
        if charge > 0.015:
            var front_color := GEL
            front_color.a = 0.025 + charge * 0.085
            draw_arc(_reservoir_pos[r], _front_radius[r], 0.0, TAU, 96, front_color, 1.0)

    for i: int in range(_band_radius.size()):
        var points := PackedVector2Array()
        var segments := 72
        var phase := _band_phase[i]
        var base_radius := _band_radius[i]
        for s: int in range(segments + 1):
            var a := float(s) / float(segments) * TAU
            var anisotropy := sin(a * 2.0 + phase) * field_bias * base_radius * 0.032
            anisotropy += sin(a * 5.0 - phase * 0.7) * field_bias * 2.2
            var rr := base_radius + anisotropy
            points.append(_band_center[i] + Vector2(cos(a), sin(a)) * rr)
        var c := PRECIP.lerp(ACTIVE, clampf((1.0 - _band_strength[i]) * dissolution * 0.8, 0.0, 0.32))
        c.a = 0.08 + _band_strength[i] * 0.72
        draw_polyline(points, c, _band_width[i], true)

    end_design_draw()
