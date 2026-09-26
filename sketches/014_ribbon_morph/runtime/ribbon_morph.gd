extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 64
const ROWS := 36
const CW := 1280.0 / float(COLS)
const CH := 720.0 / float(ROWS)
const BG := Color(0.92, 0.9, 0.82, 1.0)
const INK := Color(0.05, 0.055, 0.06, 1.0)
const MATERIAL := Color(0.08, 0.42, 0.78, 1.0)

@export_range(4.0, 24.0, 0.5) var morph_rate: float = 10.0
@export_range(0.0, 1.0, 0.01) var persistence: float = 0.76
@export_range(0.5, 2.0, 0.01) var ribbon_gain: float = 1.0

var _cells: PackedByteArray = PackedByteArray()
var _next: PackedByteArray = PackedByteArray()
var _accumulator := 0.0
var _regime := 0
var _regime_age := 0.0
var _press_age := 0.0
var _toggle_armed := true


func _ready() -> void:
    super._ready()
    _seed()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"morph_rate", "label":"MORPH RATE", "type":"float", "min":4.0, "max":24.0, "step":0.5},
        {"id":"persistence", "label":"PERSISTENCE", "type":"float", "min":0.0, "max":1.0, "step":0.01},
        {"id":"ribbon_gain", "label":"RIBBON MASS", "type":"float", "min":0.5, "max":2.0, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "morph_rate": return morph_rate
        "persistence": return persistence
        "ribbon_gain": return ribbon_gain
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "morph_rate": morph_rate = clampf(float(value), 4.0, 24.0)
        "persistence": persistence = clampf(float(value), 0.0, 1.0)
        "ribbon_gain": ribbon_gain = clampf(float(value), 0.5, 2.0)
        _: return


func _idx(x: int, y: int) -> int:
    return posmod(y, ROWS) * COLS + posmod(x, COLS)


func _seed() -> void:
    if _cells.size() == COLS * ROWS:
        return
    _cells.resize(COLS * ROWS)
    _next.resize(COLS * ROWS)
    _cells.fill(0)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var wave := sin(float(x) * 0.31) + cos(float(y) * 0.47) + sin(float(x + y) * 0.19)
            var gate := hash01(float(_idx(x, y)) * 1.77)
            if wave + gate * 0.9 > 1.15:
                _cells[_idx(x, y)] = 1


func _neighbors(x: int, y: int) -> int:
    var count := 0
    for oy: int in range(-1, 2):
        for ox: int in range(-1, 2):
            if ox == 0 and oy == 0:
                continue
            count += int(_cells[_idx(x + ox, y + oy)])
    return count


func _update_source_simulation(delta: float) -> void:
    _seed()
    _regime_age += delta
    if _regime_age > 6.5:
        _regime_age = 0.0
        _regime = 1 - _regime

    if pointer_down:
        _press_age += delta
        _paint_seed(pointer_position)
        if _press_age > 0.72 and _toggle_armed:
            _regime = 1 - _regime
            _regime_age = 0.0
            _toggle_armed = false
    else:
        _press_age = 0.0
        _toggle_armed = true

    _accumulator += delta
    var step_time := 1.0 / morph_rate
    while _accumulator >= step_time:
        _accumulator -= step_time
        _step_morphology()


func _paint_seed(point: Vector2) -> void:
    var cx := clampi(int(point.x / CW), 0, COLS - 1)
    var cy := clampi(int(point.y / CH), 0, ROWS - 1)
    for oy: int in range(-2, 3):
        for ox: int in range(-3, 4):
            if float(ox * ox + oy * oy) > 10.0:
                continue
            _cells[_idx(cx + ox, cy + oy)] = 1


func _step_morphology() -> void:
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var current := int(_cells[i])
            var n := _neighbors(x, y)
            var result := current
            if _regime == 0:
                if n >= 3:
                    result = 1
                elif current == 1 and n <= 1 and hash01(float(i) + sketch_time) > persistence:
                    result = 0
            else:
                if current == 1 and n < 5:
                    result = 0
                elif current == 0 and n >= 6 and hash01(float(i) * 2.3 + sketch_time) < persistence * 0.35:
                    result = 1
            _next[i] = result
    var temp := _cells
    _cells = _next
    _next = temp


func _largest_run(y: int) -> Vector2:
    var best_start := -1
    var best_len := 0
    var run_start := -1
    for x: int in range(COLS + 1):
        var active := x < COLS and _cells[_idx(x, y)] == 1
        if active and run_start < 0:
            run_start = x
        elif not active and run_start >= 0:
            var length := x - run_start
            if length > best_len:
                best_len = length
                best_start = run_start
            run_start = -1
    if best_start < 0:
        return Vector2(-1.0, 0.0)
    return Vector2((float(best_start) + float(best_len) * 0.5) * CW, float(best_len) * CW)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "cells": _cells.duplicate(),
        "regime": _regime,
        "regime_age": _regime_age,
        "press_age": _press_age,
        "toggle_armed": _toggle_armed,
        "accumulator": _accumulator,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var c: Variant = state.get("cells", PackedByteArray())
    if c is PackedByteArray:
        _cells = (c as PackedByteArray).duplicate()
        _next.resize(_cells.size())
    _regime = int(state.get("regime", _regime))
    _regime_age = float(state.get("regime_age", _regime_age))
    _press_age = float(state.get("press_age", _press_age))
    _toggle_armed = bool(state.get("toggle_armed", _toggle_armed))
    _accumulator = float(state.get("accumulator", _accumulator))


func _get_custom_live_debug_state() -> Dictionary:
    var count := 0
    for v: int in _cells:
        count += v
    return {"regime": _regime, "active_cells": count}


func _draw() -> void:
    begin_design_draw(BG)

    for y: int in range(ROWS):
        for x: int in range(COLS):
            if _cells[_idx(x, y)] == 0:
                continue
            var c := INK if _regime == 0 else MATERIAL
            c.a = 0.24
            draw_rect(Rect2(Vector2(float(x) * CW, float(y) * CH), Vector2(CW + 0.4, CH + 0.4)), c, true)

    var previous := Vector2(-1.0, 0.0)
    var previous_y := 0.0
    var previous_width := 0.0
    for y: int in range(ROWS):
        var run := _largest_run(y)
        if run.x < 0.0:
            previous.x = -1.0
            continue
        var cy := (float(y) + 0.5) * CH
        var half := maxf(3.0, run.y * 0.16 * ribbon_gain)
        if previous.x >= 0.0:
            var prev_half := maxf(3.0, previous_width * 0.16 * ribbon_gain)
            var poly := PackedVector2Array([
                Vector2(previous.x - prev_half, previous_y),
                Vector2(previous.x + prev_half, previous_y),
                Vector2(run.x + half, cy),
                Vector2(run.x - half, cy),
            ])
            var ribbon := MATERIAL if _regime == 0 else INK
            ribbon.a = 0.62
            draw_colored_polygon(poly, ribbon)
        previous = run
        previous_y = cy
        previous_width = run.y

    end_design_draw()
