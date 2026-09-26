extends "res://sketches/_shared/design_sketch_base.gd"

const GRID_X: int = 96
const GRID_Y: int = 54
const STEP_SECONDS: float = 1.0 / 24.0

@export_range(0.1, 2.6, 0.01) var growth_rate: float = 1.08
@export_range(0.0, 1.0, 0.01) var nutrient_diffusion: float = 0.34
@export_range(0.0, 1.0, 0.01) var phase_diffusion: float = 0.12
@export_range(0.0, 1.5, 0.01) var anisotropy: float = 0.78
@export_range(0.0, 1.4, 0.01) var undercooling: float = 0.64
@export_range(0.0, 0.35, 0.005) var remelt: float = 0.035
@export_range(0.0, 1.0, 0.01) var mineral_tint: float = 0.58
@export_range(0.2, 2.4, 0.01) var relief: float = 1.22
@export_range(0.0, 2.0, 0.01) var micro_detail: float = 1.08

var _phase := PackedFloat32Array()
var _nutrient := PackedFloat32Array()
var _age := PackedFloat32Array()
var _next_phase := PackedFloat32Array()
var _next_nutrient := PackedFloat32Array()
var _next_age := PackedFloat32Array()
var _accum: float = 0.0
var _step_index: int = 0
var _pointer_was_down: bool = false
var _state_image: Image
var _state_texture_a: ImageTexture
var _state_texture_b: ImageTexture
var _state_front: int = 0
var _state_dirty: bool = true

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    _allocate_state()
    _seed_initial_crystal()
    _build_textures()
    super._ready()
    _push_shader()


func _allocate_state() -> void:
    var count := GRID_X * GRID_Y
    _phase.resize(count)
    _nutrient.resize(count)
    _age.resize(count)
    _next_phase.resize(count)
    _next_nutrient.resize(count)
    _next_age.resize(count)
    for i: int in range(count):
        _phase[i] = 0.0
        _nutrient[i] = 0.84
        _age[i] = 0.0


func _seed_initial_crystal() -> void:
    _stamp_seed(Vector2i(37, 28), 3, 0.98)
    _stamp_seed(Vector2i(46, 23), 2, 0.82)
    _stamp_seed(Vector2i(31, 36), 2, 0.76)


func _stamp_seed(center: Vector2i, radius: int, amount: float) -> void:
    for oy: int in range(-radius, radius + 1):
        for ox: int in range(-radius, radius + 1):
            var x := clampi(center.x + ox, 1, GRID_X - 2)
            var y := clampi(center.y + oy, 1, GRID_Y - 2)
            if Vector2(float(ox), float(oy)).length() <= float(radius) + 0.25:
                var i := _idx(x, y)
                _phase[i] = maxf(_phase[i], amount)
                _nutrient[i] = minf(_nutrient[i], 0.34)


func _build_textures() -> void:
    _state_image = Image.create(GRID_X, GRID_Y, false, Image.FORMAT_RGBA8)
    _write_image()
    _state_texture_a = ImageTexture.create_from_image(_state_image)
    _state_texture_b = ImageTexture.create_from_image(_state_image)
    _state_front = 0
    _state_dirty = false


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"growth_rate","label":"GROWTH","type":"float","min":0.1,"max":2.6,"step":0.01},
        {"id":"nutrient_diffusion","label":"NUTRIENT FLOW","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"phase_diffusion","label":"INTERFACE SOFTNESS","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"anisotropy","label":"BRANCH ANISOTROPY","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"undercooling","label":"UNDERCOOLING","type":"float","min":0.0,"max":1.4,"step":0.01},
        {"id":"remelt","label":"REMELT","type":"float","min":0.0,"max":0.35,"step":0.005},
        {"id":"mineral_tint","label":"MINERAL TINT","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"relief","label":"RELIEF","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"micro_detail","label":"MICRO DETAIL","type":"float","min":0.0,"max":2.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "growth_rate": return growth_rate
        "nutrient_diffusion": return nutrient_diffusion
        "phase_diffusion": return phase_diffusion
        "anisotropy": return anisotropy
        "undercooling": return undercooling
        "remelt": return remelt
        "mineral_tint": return mineral_tint
        "relief": return relief
        "micro_detail": return micro_detail
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "growth_rate": growth_rate = clampf(float(value), 0.1, 2.6)
        "nutrient_diffusion": nutrient_diffusion = clampf(float(value), 0.0, 1.0)
        "phase_diffusion": phase_diffusion = clampf(float(value), 0.0, 1.0)
        "anisotropy": anisotropy = clampf(float(value), 0.0, 1.5)
        "undercooling": undercooling = clampf(float(value), 0.0, 1.4)
        "remelt": remelt = clampf(float(value), 0.0, 0.35)
        "mineral_tint": mineral_tint = clampf(float(value), 0.0, 1.0)
        "relief": relief = clampf(float(value), 0.2, 2.4)
        "micro_detail": micro_detail = clampf(float(value), 0.0, 2.0)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    if pointer_down:
        var gx := clampi(int(pointer_position.x / DESIGN_SIZE.x * float(GRID_X)), 2, GRID_X - 3)
        var gy := clampi(int(pointer_position.y / DESIGN_SIZE.y * float(GRID_Y)), 2, GRID_Y - 3)
        var radius := 2 if _pointer_was_down else 4
        for oy: int in range(-radius, radius + 1):
            for ox: int in range(-radius, radius + 1):
                var d := Vector2(float(ox), float(oy)).length()
                if d > float(radius) + 0.2:
                    continue
                var i := _idx(gx + ox, gy + oy)
                var falloff := 1.0 - d / (float(radius) + 0.5)
                _phase[i] = clampf(_phase[i] + falloff * 0.32, 0.0, 1.0)
                _nutrient[i] = clampf(_nutrient[i] + falloff * 0.18, 0.0, 1.0)
        _state_dirty = true
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _accum += delta
    var safety := 0
    while _accum >= STEP_SECONDS and safety < 2:
        _simulate_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        safety += 1
    if safety > 0:
        _state_dirty = true
    if _state_dirty:
        _commit_state_texture()


func _simulate_step(dt: float) -> void:
    _step_index += 1
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x, y)
            if x == 0 or y == 0 or x == GRID_X - 1 or y == GRID_Y - 1:
                _next_phase[i] = 0.0
                _next_nutrient[i] = 0.9
                _next_age[i] = 0.0
                continue

            var p := _phase[i]
            var n := _nutrient[i]
            var left := _phase[_idx(x - 1, y)]
            var right := _phase[_idx(x + 1, y)]
            var up := _phase[_idx(x, y - 1)]
            var down := _phase[_idx(x, y + 1)]
            var ul := _phase[_idx(x - 1, y - 1)]
            var ur := _phase[_idx(x + 1, y - 1)]
            var dl := _phase[_idx(x - 1, y + 1)]
            var dr := _phase[_idx(x + 1, y + 1)]
            var neighbour := (left + right + up + down) * 0.16 + (ul + ur + dl + dr) * 0.09
            var lap_p := left + right + up + down - 4.0 * p

            var nl := _nutrient[_idx(x - 1, y)]
            var nr := _nutrient[_idx(x + 1, y)]
            var nu := _nutrient[_idx(x, y - 1)]
            var nd := _nutrient[_idx(x, y + 1)]
            var lap_n := nl + nr + nu + nd - 4.0 * n

            var center := Vector2(37.0, 28.0)
            var q := Vector2(float(x), float(y)) - center
            var angle := atan2(q.y, q.x)
            var radial := q.length()
            var branch_bias := 0.55 + 0.45 * cos(angle * 6.0 + radial * 0.16)
            branch_bias = lerpf(1.0, branch_bias, clampf(anisotropy, 0.0, 1.0))

            var front := clampf(neighbour * 1.35 - p * 0.42, 0.0, 1.0)
            var drive := growth_rate * undercooling * n * front * branch_bias
            var dissolve := remelt * (0.22 + (1.0 - n) * 0.55)
            var next_p := p + dt * (drive + phase_diffusion * lap_p * 0.38 - dissolve * p)
            next_p = clampf(next_p, 0.0, 1.0)

            var consumed := maxf(0.0, next_p - p) * 0.92
            var next_n := n + dt * nutrient_diffusion * lap_n * 0.72 - consumed
            next_n += dt * 0.004 * (0.9 - n)
            next_n = clampf(next_n, 0.0, 1.0)

            var next_age := _age[i]
            if next_p > 0.18:
                next_age = minf(1.0, next_age + dt * (0.08 + next_p * 0.18))
            else:
                next_age = maxf(0.0, next_age - dt * 0.04)

            _next_phase[i] = next_p
            _next_nutrient[i] = next_n
            _next_age[i] = next_age

    var swap_p := _phase
    _phase = _next_phase
    _next_phase = swap_p
    var swap_n := _nutrient
    _nutrient = _next_nutrient
    _next_nutrient = swap_n
    var swap_a := _age
    _age = _next_age
    _next_age = swap_a


func _write_image() -> void:
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x, y)
            _state_image.set_pixel(x, y, Color(_phase[i], _nutrient[i], _age[i], 1.0))


func _commit_state_texture() -> void:
    if _state_texture_a == null or _state_texture_b == null:
        return
    _write_image()
    var next_front := 1 - _state_front
    var target := _state_texture_b if next_front == 1 else _state_texture_a
    target.update(_state_image)
    _state_front = next_front
    _state_dirty = false
    _push_shader()


func _active_state_texture() -> ImageTexture:
    return _state_texture_b if _state_front == 1 else _state_texture_a


func _push_shader() -> void:
    if not is_instance_valid(_surface) or _state_texture_a == null:
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_state", _active_state_texture())
    material.set_shader_parameter("u_texel", Vector2(1.0 / float(GRID_X), 1.0 / float(GRID_Y)))
    material.set_shader_parameter("u_tint", mineral_tint)
    material.set_shader_parameter("u_relief", relief)
    material.set_shader_parameter("u_micro", micro_detail)


func _idx(x: int, y: int) -> int:
    return y * GRID_X + x


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "phase": _phase.duplicate(),
        "nutrient": _nutrient.duplicate(),
        "age": _age.duplicate(),
        "step_index": _step_index,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("phase", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == GRID_X * GRID_Y:
        _phase = (v as PackedFloat32Array).duplicate()
    v = state.get("nutrient", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == GRID_X * GRID_Y:
        _nutrient = (v as PackedFloat32Array).duplicate()
    v = state.get("age", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == GRID_X * GRID_Y:
        _age = (v as PackedFloat32Array).duplicate()
    _step_index = int(state.get("step_index", _step_index))
    _state_dirty = true
    _commit_state_texture()


func _get_custom_live_debug_state() -> Dictionary:
    var occupied := 0
    for p: float in _phase:
        if p > 0.35:
            occupied += 1
    return {
        "occupied_cells": occupied,
        "render_mode": "phase_field_double_buffered_full_resolution",
        "state_front": _state_front,
    }


func _draw() -> void:
    pass
