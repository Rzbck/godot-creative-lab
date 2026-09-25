extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 56
const ROWS := 32
const CELL_W := 1280.0 / float(COLS)
const CELL_H := 720.0 / float(ROWS)
const BG := Color(0.035, 0.032, 0.028, 1.0)
const PHASE_A := Color(0.92, 0.82, 0.58, 1.0)
const PHASE_B := Color(0.10, 0.18, 0.20, 1.0)
const INTERFACE := Color(0.91, 0.25, 0.12, 1.0)
const COOL := Color(0.16, 0.48, 0.72, 1.0)

@export_range(0.2, 2.0, 0.01) var quench_depth: float = 1.08
@export_range(0.05, 2.0, 0.01) var mobility: float = 0.72
@export_range(0.02, 0.6, 0.01) var interface_energy: float = 0.20
@export_range(0.2, 2.0, 0.01) var coarsening: float = 0.86
@export_range(-0.45, 0.45, 0.01) var mass_bias: float = -0.04
@export_range(0.0, 2.0, 0.01) var advection: float = 0.58
@export_range(0.0, 1.0, 0.01) var thermal_memory: float = 0.72
@export_range(0.0, 2.0, 0.01) var surface_tension: float = 0.92
@export_range(1.0, 9.0, 1.0) var quench_radius: float = 4.0

var _phi := PackedFloat32Array()
var _mu := PackedFloat32Array()
var _next_phi := PackedFloat32Array()
var _thermal := PackedFloat32Array()
var _next_thermal := PackedFloat32Array()
var _accum := 0.0
var _field_image: Image
var _field_texture: ImageTexture


func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _seed_system()
    _refresh_texture()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"quench_depth","label":"QUENCH DEPTH","type":"float","min":0.2,"max":2.0,"step":0.01},
        {"id":"mobility","label":"MOBILITY","type":"float","min":0.05,"max":2.0,"step":0.01},
        {"id":"interface_energy","label":"INTERFACE ENERGY","type":"float","min":0.02,"max":0.6,"step":0.01},
        {"id":"coarsening","label":"COARSENING","type":"float","min":0.2,"max":2.0,"step":0.01},
        {"id":"mass_bias","label":"MASS BIAS","type":"float","min":-0.45,"max":0.45,"step":0.01},
        {"id":"advection","label":"ADVECTION","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"thermal_memory","label":"THERMAL MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"surface_tension","label":"SURFACE TENSION","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"quench_radius","label":"QUENCH RADIUS","type":"float","min":1.0,"max":9.0,"step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "quench_depth": return quench_depth
        "mobility": return mobility
        "interface_energy": return interface_energy
        "coarsening": return coarsening
        "mass_bias": return mass_bias
        "advection": return advection
        "thermal_memory": return thermal_memory
        "surface_tension": return surface_tension
        "quench_radius": return quench_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "quench_depth": quench_depth = clampf(float(value), 0.2, 2.0)
        "mobility": mobility = clampf(float(value), 0.05, 2.0)
        "interface_energy": interface_energy = clampf(float(value), 0.02, 0.6)
        "coarsening": coarsening = clampf(float(value), 0.2, 2.0)
        "mass_bias": mass_bias = clampf(float(value), -0.45, 0.45)
        "advection": advection = clampf(float(value), 0.0, 2.0)
        "thermal_memory": thermal_memory = clampf(float(value), 0.0, 1.0)
        "surface_tension": surface_tension = clampf(float(value), 0.0, 2.0)
        "quench_radius": quench_radius = clampf(float(value), 1.0, 9.0)
        _: return


func _idx(x: int, y: int) -> int:
    return posmod(y, ROWS) * COLS + posmod(x, COLS)


func _seed_system() -> void:
    if _phi.size() == COLS * ROWS:
        return
    var count := COLS * ROWS
    _phi.resize(count)
    _mu.resize(count)
    _next_phi.resize(count)
    _thermal.resize(count)
    _next_thermal.resize(count)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var n := (hash01(float(i) * 17.17 + 4.3) - 0.5) * 0.18
            var band := sin(float(x) * 0.21 + sin(float(y) * 0.17)) * 0.025
            _phi[i] = clampf(mass_bias + n + band, -0.95, 0.95)
            _thermal[i] = 0.0
            _mu[i] = 0.0
            _next_phi[i] = _phi[i]
            _next_thermal[i] = 0.0
    _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    _field_texture = ImageTexture.create_from_image(_field_image)


func _update_source_simulation(delta: float) -> void:
    _seed_system()
    if pointer_down:
        _quench_at(pointer_position)

    var stepped := false
    _accum += delta
    while _accum >= 1.0 / 22.0:
        _accum -= 1.0 / 22.0
        _step_phase(1.0 / 22.0)
        stepped = true
    if stepped:
        _refresh_texture()


func _quench_at(point: Vector2) -> void:
    var cx := clampi(int(point.x / CELL_W), 0, COLS - 1)
    var cy := clampi(int(point.y / CELL_H), 0, ROWS - 1)
    var radius := int(round(quench_radius))
    for oy: int in range(-radius, radius + 1):
        for ox: int in range(-radius, radius + 1):
            var d := Vector2(float(ox), float(oy)).length()
            if d > float(radius) + 0.25:
                continue
            var w := 1.0 - d / maxf(1.0, float(radius + 1))
            var i := _idx(cx + ox, cy + oy)
            _thermal[i] = clampf(_thermal[i] + w * 0.24 * quench_depth, 0.0, 1.5)


func _lap(field: PackedFloat32Array, x: int, y: int) -> float:
    var c := field[_idx(x, y)]
    return (
        field[_idx(x - 1, y)] + field[_idx(x + 1, y)] +
        field[_idx(x, y - 1)] + field[_idx(x, y + 1)] - c * 4.0
    )


func _step_phase(dt: float) -> void:
    # Chemical potential: double-well phase energy + interface penalty + local thermal quench.
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var p := _phi[i]
            _mu[i] = p * p * p - p - interface_energy * _lap(_phi, x, y) - _thermal[i] * quench_depth * 0.16

    var previous_mean := _mean_phi()
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var p := _phi[i]
            var conserved_drive := _lap(_mu, x, y) * mobility * coarsening

            var gx_t := (_thermal[_idx(x + 1, y)] - _thermal[_idx(x - 1, y)]) * 0.5
            var gy_t := (_thermal[_idx(x, y + 1)] - _thermal[_idx(x, y - 1)]) * 0.5
            var gx_p := (_phi[_idx(x + 1, y)] - _phi[_idx(x - 1, y)]) * 0.5
            var gy_p := (_phi[_idx(x, y + 1)] - _phi[_idx(x, y - 1)]) * 0.5
            var marangoni := -(gx_t * gx_p + gy_t * gy_p) * surface_tension * advection

            _next_phi[i] = clampf(p + (conserved_drive * 0.12 + marangoni * 0.10) * dt * 22.0, -1.15, 1.15)

            var thermal_lap := _lap(_thermal, x, y)
            var memory_decay := lerpf(0.92, 0.995, thermal_memory)
            _next_thermal[i] = clampf((_thermal[i] + thermal_lap * 0.055) * memory_decay, 0.0, 1.5)

    var next_mean := 0.0
    for value: float in _next_phi:
        next_mean += value
    next_mean /= float(_next_phi.size())
    var correction := previous_mean - next_mean
    var target_drift := (mass_bias - previous_mean) * 0.0025
    for i: int in range(_next_phi.size()):
        _next_phi[i] = clampf(_next_phi[i] + correction + target_drift, -1.15, 1.15)

    var temp_phi := _phi
    _phi = _next_phi
    _next_phi = temp_phi
    var temp_t := _thermal
    _thermal = _next_thermal
    _next_thermal = temp_t


func _mean_phi() -> float:
    if _phi.is_empty():
        return 0.0
    var total := 0.0
    for value: float in _phi:
        total += value
    return total / float(_phi.size())


func _refresh_texture() -> void:
    if _field_image == null:
        _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var phase := clampf(_phi[i] * 0.5 + 0.5, 0.0, 1.0)
            var interface_amount := 1.0 - smoothstep(0.0, 0.30, absf(_phi[i]))
            var c := PHASE_B.lerp(PHASE_A, phase)
            c = c.lerp(INTERFACE, interface_amount * 0.42)
            c = c.lerp(COOL, clampf(_thermal[i], 0.0, 1.0) * 0.34)
            _field_image.set_pixel(x, y, c)
    if _field_texture == null:
        _field_texture = ImageTexture.create_from_image(_field_image)
    else:
        _field_texture.update(_field_image)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "phi": _phi.duplicate(),
        "thermal": _thermal.duplicate(),
        "accum": _accum,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var pv: Variant = state.get("phi", PackedFloat32Array())
    if pv is PackedFloat32Array:
        _phi = (pv as PackedFloat32Array).duplicate()
        _mu.resize(_phi.size())
        _next_phi.resize(_phi.size())
    var tv: Variant = state.get("thermal", PackedFloat32Array())
    if tv is PackedFloat32Array:
        _thermal = (tv as PackedFloat32Array).duplicate()
        _next_thermal.resize(_thermal.size())
    _accum = float(state.get("accum", _accum))
    _refresh_texture()


func _get_custom_live_debug_state() -> Dictionary:
    return {"phase_mean": _mean_phi(), "cells": COLS * ROWS, "render_mode":"field_texture"}


func _draw() -> void:
    begin_design_draw(BG)
    if _field_texture != null:
        draw_texture_rect(_field_texture, Rect2(Vector2.ZERO, DESIGN_SIZE), false)
    end_design_draw()
