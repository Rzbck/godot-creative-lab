extends "res://sketches/_shared/design_sketch_base.gd"

const GRID_X: int = 96
const GRID_Y: int = 54
const STEP_SECONDS: float = 1.0 / 24.0

@export_range(0.15, 0.95, 0.01) var threshold: float = 0.42
@export_range(0.3, 3.0, 0.01) var excitation_decay: float = 1.34
@export_range(0.2, 2.4, 0.01) var refractory_decay: float = 0.74
@export_range(0.1, 2.5, 0.01) var pacemaker_rate: float = 0.72
@export_range(0.0, 1.0, 0.01) var glass_tint: float = 0.36
@export_range(0.2, 2.2, 0.01) var relief: float = 1.12
@export_range(0.0, 2.0, 0.01) var caustic: float = 0.92

var _excite := PackedFloat32Array()
var _refractory := PackedFloat32Array()
var _age := PackedFloat32Array()
var _next_excite := PackedFloat32Array()
var _next_refractory := PackedFloat32Array()
var _next_age := PackedFloat32Array()
var _accum: float = 0.0
var _pacemaker_accum: float = 0.0
var _event_counter: int = 19
var _pointer_was_down: bool = false
var _paint_mode: int = 1
var _state_image: Image
var _front_texture: ImageTexture
var _back_texture: ImageTexture

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    _allocate_state()
    _stamp(Vector2i(24, 18), 3, 1)
    _stamp(Vector2i(69, 35), 4, 1)
    _build_textures()
    super._ready()
    _push_shader()


func _allocate_state() -> void:
    var count := GRID_X * GRID_Y
    _excite.resize(count)
    _refractory.resize(count)
    _age.resize(count)
    _next_excite.resize(count)
    _next_refractory.resize(count)
    _next_age.resize(count)


func _build_textures() -> void:
    _state_image = Image.create(GRID_X, GRID_Y, false, Image.FORMAT_RGBA8)
    _write_image()
    _front_texture = ImageTexture.create_from_image(_state_image)
    _back_texture = ImageTexture.create_from_image(_state_image)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"threshold","label":"TRIGGER THRESHOLD","type":"float","min":0.15,"max":0.95,"step":0.01},
        {"id":"excitation_decay","label":"EXCITATION DECAY","type":"float","min":0.3,"max":3.0,"step":0.01},
        {"id":"refractory_decay","label":"REFRACTORY DECAY","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"pacemaker_rate","label":"PACEMAKER RATE","type":"float","min":0.1,"max":2.5,"step":0.01},
        {"id":"glass_tint","label":"GLASS TINT","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"relief","label":"RELIEF","type":"float","min":0.2,"max":2.2,"step":0.01},
        {"id":"caustic","label":"CAUSTIC","type":"float","min":0.0,"max":2.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "threshold": return threshold
        "excitation_decay": return excitation_decay
        "refractory_decay": return refractory_decay
        "pacemaker_rate": return pacemaker_rate
        "glass_tint": return glass_tint
        "relief": return relief
        "caustic": return caustic
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "threshold": threshold = clampf(float(value), 0.15, 0.95)
        "excitation_decay": excitation_decay = clampf(float(value), 0.3, 3.0)
        "refractory_decay": refractory_decay = clampf(float(value), 0.2, 2.4)
        "pacemaker_rate": pacemaker_rate = clampf(float(value), 0.1, 2.5)
        "glass_tint": glass_tint = clampf(float(value), 0.0, 1.0)
        "relief": relief = clampf(float(value), 0.2, 2.2)
        "caustic": caustic = clampf(float(value), 0.0, 2.0)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    var gx := clampi(int(pointer_position.x / DESIGN_SIZE.x * float(GRID_X)), 0, GRID_X - 1)
    var gy := clampi(int(pointer_position.y / DESIGN_SIZE.y * float(GRID_Y)), 0, GRID_Y - 1)
    if pointer_down and not _pointer_was_down:
        var i := _idx(gx, gy)
        _paint_mode = -1 if _excite[i] > 0.22 or _refractory[i] > 0.24 else 1

    if pointer_down:
        _stamp(Vector2i(gx, gy), 3 if _pointer_was_down else 5, _paint_mode)
        _publish_state()
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _accum += delta
    var steps := 0
    while _accum >= STEP_SECONDS and steps < 2:
        _simulate_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        steps += 1
    if steps > 0:
        _publish_state()


func _simulate_step(dt: float) -> void:
    _pacemaker_accum += dt
    var pulse_interval := 1.0 / maxf(0.05, pacemaker_rate)
    if _pacemaker_accum >= pulse_interval:
        _pacemaker_accum -= pulse_interval
        _event_counter += 1
        var centers := [Vector2i(19, 15), Vector2i(52, 38), Vector2i(79, 21)]
        var center: Vector2i = centers[_event_counter % centers.size()]
        center.x = wrapi(center.x + int(round((_hash01i(_event_counter * 61) - 0.5) * 14.0)), 0, GRID_X)
        center.y = wrapi(center.y + int(round((_hash01i(_event_counter * 83) - 0.5) * 10.0)), 0, GRID_Y)
        _stamp(center, 2 + (_event_counter % 2), 1)

    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x, y)
            var e := _excite[i]
            var r := _refractory[i]
            var a := _age[i]

            var left := _excite[_idx(wrapi(x - 1, 0, GRID_X), y)]
            var right := _excite[_idx(wrapi(x + 1, 0, GRID_X), y)]
            var up := _excite[_idx(x, wrapi(y - 1, 0, GRID_Y))]
            var down := _excite[_idx(x, wrapi(y + 1, 0, GRID_Y))]
            var neighbour := maxf(maxf(left, right), maxf(up, down))

            var next_e := maxf(0.0, e - dt * excitation_decay)
            var next_r := maxf(0.0, r - dt * refractory_decay)
            var next_a := maxf(0.0, a - dt * 0.045)

            if e < 0.055 and r < 0.09 and neighbour > threshold:
                next_e = 1.0
                next_r = 1.0
                next_a = 1.0
            elif e > 0.26:
                next_r = maxf(next_r, e * 0.94)
                next_a = minf(1.0, next_a + dt * 0.22)

            _next_excite[i] = next_e
            _next_refractory[i] = next_r
            _next_age[i] = next_a

    var te := _excite; _excite = _next_excite; _next_excite = te
    var tr := _refractory; _refractory = _next_refractory; _next_refractory = tr
    var ta := _age; _age = _next_age; _next_age = ta


func _stamp(center: Vector2i, radius: int, mode: int) -> void:
    for oy: int in range(-radius, radius + 1):
        for ox: int in range(-radius, radius + 1):
            var d := Vector2(float(ox), float(oy)).length()
            if d > float(radius) + 0.25:
                continue
            var x := wrapi(center.x + ox, 0, GRID_X)
            var y := wrapi(center.y + oy, 0, GRID_Y)
            var i := _idx(x, y)
            var falloff := 1.0 - d / (float(radius) + 0.5)
            if mode > 0:
                _excite[i] = maxf(_excite[i], falloff)
                _refractory[i] = minf(_refractory[i], 0.08)
                _age[i] = maxf(_age[i], falloff * 0.8)
            else:
                _excite[i] = 0.0
                _refractory[i] = maxf(_refractory[i], falloff)


func _write_image() -> void:
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x, y)
            _state_image.set_pixel(x, y, Color(_excite[i], _refractory[i], _age[i], 1.0))


func _publish_state() -> void:
    if _state_image == null or _back_texture == null:
        return
    _write_image()
    _back_texture.update(_state_image)
    var material := _surface.material as ShaderMaterial
    if material != null:
        material.set_shader_parameter("u_state", _back_texture)
    var temp := _front_texture
    _front_texture = _back_texture
    _back_texture = temp
    _push_shader()


func _push_shader() -> void:
    if not is_instance_valid(_surface) or _front_texture == null:
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_state", _front_texture)
    material.set_shader_parameter("u_texel", Vector2(1.0 / float(GRID_X), 1.0 / float(GRID_Y)))
    material.set_shader_parameter("u_tint", glass_tint)
    material.set_shader_parameter("u_relief", relief)
    material.set_shader_parameter("u_caustic", caustic)


func _idx(x: int, y: int) -> int:
    return y * GRID_X + x


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "excite": _excite.duplicate(),
        "refractory": _refractory.duplicate(),
        "age": _age.duplicate(),
        "pacemaker_accum": _pacemaker_accum,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("excite", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == GRID_X * GRID_Y: _excite = (v as PackedFloat32Array).duplicate()
    v = state.get("refractory", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == GRID_X * GRID_Y: _refractory = (v as PackedFloat32Array).duplicate()
    v = state.get("age", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == GRID_X * GRID_Y: _age = (v as PackedFloat32Array).duplicate()
    _pacemaker_accum = float(state.get("pacemaker_accum", _pacemaker_accum))
    _event_counter = int(state.get("event_counter", _event_counter))
    _publish_state()


func _get_custom_live_debug_state() -> Dictionary:
    var active := 0
    for e: float in _excite:
        if e > 0.15: active += 1
    return {
        "active_cells": active,
        "render_mode": "excitable_grid_to_full_resolution_glass",
    }


func _draw() -> void:
    pass
