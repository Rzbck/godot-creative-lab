extends "res://sketches/_shared/design_sketch_base.gd"

const COLS: int = 16
const ROWS: int = 9
const CELLS: int = COLS * ROWS
const SAFE := Rect2(66.0, 56.0, 1148.0, 608.0)

@export_range(0.2, 3.0, 0.01) var barrier: float = 1.24
@export_range(0.0, 3.0, 0.01) var coupling: float = 1.10
@export_range(0.1, 5.0, 0.01) var damping: float = 1.52
@export_range(-1.0, 1.0, 0.01) var bias: float = -0.08
@export_range(0.0, 1.8, 0.01) var spontaneous: float = 0.28
@export_range(0.0, 1.0, 0.01) var relief: float = 0.72

var _state := PackedFloat32Array()
var _velocity := PackedFloat32Array()
var _heat := PackedFloat32Array()
var _pointer_was_down: bool = false
var _event_timer: float = 1.6
var _event_counter: int = 37


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _state.clear()
    _velocity.clear()
    _heat.clear()
    _event_timer = 1.6
    _event_counter = 37
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _state.resize(CELLS)
    _velocity.resize(CELLS)
    _heat.resize(CELLS)
    for row: int in range(ROWS):
        for col: int in range(COLS):
            var i := _idx(col, row)
            var seed := -1.0 if ((col + row * 2) % 5) < 3 else 1.0
            _state[i] = seed * (0.78 + _hash01i(i * 59 + 7) * 0.18)
            _velocity[i] = 0.0
            _heat[i] = 0.0


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"barrier","label":"SNAP BARRIER","type":"float","min":0.2,"max":3.0,"step":0.01},
        {"id":"coupling","label":"NEIGHBOUR COUPLING","type":"float","min":0.0,"max":3.0,"step":0.01},
        {"id":"damping","label":"HINGE DAMPING","type":"float","min":0.1,"max":5.0,"step":0.01},
        {"id":"bias","label":"STATE BIAS","type":"float","min":-1.0,"max":1.0,"step":0.01},
        {"id":"spontaneous","label":"SPONTANEOUS SNAPS","type":"float","min":0.0,"max":1.8,"step":0.01},
        {"id":"relief","label":"FACET RELIEF","type":"float","min":0.0,"max":1.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "barrier": return barrier
        "coupling": return coupling
        "damping": return damping
        "bias": return bias
        "spontaneous": return spontaneous
        "relief": return relief
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "barrier": barrier = clampf(float(value), 0.2, 3.0)
        "coupling": coupling = clampf(float(value), 0.0, 3.0)
        "damping": damping = clampf(float(value), 0.1, 5.0)
        "bias": bias = clampf(float(value), -1.0, 1.0)
        "spontaneous": spontaneous = clampf(float(value), 0.0, 1.8)
        "relief": relief = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down:
        var cell := _cell_at(pointer_position)
        if cell >= 0:
            var row := int(cell / COLS)
            var col := cell % COLS
            var target := -1.0 if _state[cell] > 0.0 else 1.0
            for oy: int in range(-1, 2):
                for ox: int in range(-1, 2):
                    var x := col + ox
                    var y := row + oy
                    if x < 0 or x >= COLS or y < 0 or y >= ROWS:
                        continue
                    var i := _idx(x, y)
                    var falloff := 1.0 if ox == 0 and oy == 0 else 0.48
                    _velocity[i] += (target - _state[i]) * (4.8 * falloff)
                    _heat[i] = minf(1.0, _heat[i] + 0.78 * falloff)
    elif _pointer_was_down:
        _event_counter += 1
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _event_timer -= delta * maxf(0.08, spontaneous)
    if _event_timer <= 0.0 and spontaneous > 0.01:
        _event_counter += 1
        _event_timer = 0.9 + _hash01i(_event_counter * 83 + 5) * 4.1
        var i := int(_hash01i(_event_counter * 101 + 9) * float(CELLS - 1))
        var target := -1.0 if _state[i] > 0.0 else 1.0
        _velocity[i] += (target - _state[i]) * spontaneous * 1.7
        _heat[i] = 1.0

    var next_velocity := _velocity.duplicate()
    for row: int in range(ROWS):
        for col: int in range(COLS):
            var i := _idx(col, row)
            var s := _state[i]

            var force := barrier * (s - s * s * s) + bias * 0.85
            var neighbour_sum := 0.0
            var neighbour_count := 0.0
            if col > 0:
                neighbour_sum += _state[_idx(col - 1, row)]
                neighbour_count += 1.0
            if col + 1 < COLS:
                neighbour_sum += _state[_idx(col + 1, row)]
                neighbour_count += 1.0
            if row > 0:
                neighbour_sum += _state[_idx(col, row - 1)]
                neighbour_count += 1.0
            if row + 1 < ROWS:
                neighbour_sum += _state[_idx(col, row + 1)]
                neighbour_count += 1.0
            if neighbour_count > 0.0:
                force += ((neighbour_sum / neighbour_count) - s) * coupling * 1.7

            var velocity := _velocity[i] + force * delta * 3.0
            velocity *= exp(-delta * damping)
            next_velocity[i] = clampf(velocity, -4.0, 4.0)
            _heat[i] *= exp(-delta * 1.05)

    _velocity = next_velocity
    for i: int in range(CELLS):
        _state[i] = clampf(_state[i] + _velocity[i] * delta, -1.24, 1.24)

    queue_redraw()


func _cell_at(point: Vector2) -> int:
    if not SAFE.has_point(point):
        return -1
    var cell_w := SAFE.size.x / float(COLS)
    var cell_h := SAFE.size.y / float(ROWS)
    var col := clampi(int((point.x - SAFE.position.x) / cell_w), 0, COLS - 1)
    var row := clampi(int((point.y - SAFE.position.y) / cell_h), 0, ROWS - 1)
    return _idx(col, row)


func _cell_center(col: int, row: int) -> Vector2:
    var cell_w := SAFE.size.x / float(COLS)
    var cell_h := SAFE.size.y / float(ROWS)
    return SAFE.position + Vector2((float(col) + 0.5) * cell_w, (float(row) + 0.5) * cell_h)


func _draw() -> void:
    begin_design_draw(Color(0.073, 0.076, 0.078, 1.0))

    var cell_w := SAFE.size.x / float(COLS)
    var cell_h := SAFE.size.y / float(ROWS)
    for row: int in range(ROWS):
        for col: int in range(COLS):
            var i := _idx(col, row)
            var center := _cell_center(col, row)
            var inset := 4.5
            var half_w := cell_w * 0.5 - inset
            var half_h := cell_h * 0.5 - inset
            var lift := _state[i] * relief * minf(half_w, half_h) * 0.42
            var heat := _heat[i]

            var top := center + Vector2(0.0, -half_h - lift * 0.18)
            var right := center + Vector2(half_w + lift * 0.18, 0.0)
            var bottom := center + Vector2(0.0, half_h + lift * 0.18)
            var left := center + Vector2(-half_w - lift * 0.18, 0.0)
            var ridge_a := center + Vector2(lift * 0.42, -lift * 0.24)
            var ridge_b := center - Vector2(lift * 0.42, -lift * 0.24)

            var cold := Color(0.20, 0.23, 0.23, 0.94)
            var warm := Color(0.72, 0.35, 0.16, 0.96)
            var base := cold.lerp(Color(0.60, 0.61, 0.55, 0.96), (_state[i] + 1.0) * 0.5)
            base = base.lerp(warm, heat * 0.55)

            draw_colored_polygon(PackedVector2Array([top, right, ridge_a, left]), base.lightened(0.08 * relief))
            draw_colored_polygon(PackedVector2Array([right, bottom, left, ridge_a]), base.darkened(0.10 * relief))
            draw_line(top, bottom, Color(0.88, 0.86, 0.75, 0.07 + absf(_state[i]) * 0.10), 0.8, true)
            draw_line(left, right, Color(0.01, 0.01, 0.01, 0.16), 0.8, true)
            if heat > 0.05:
                draw_circle(ridge_b, 2.0 + heat * 3.0, Color(0.96, 0.52, 0.20, heat * 0.50), true)

    end_design_draw()


func _idx(col: int, row: int) -> int:
    return row * COLS + col


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "state": _state.duplicate(),
        "velocity": _velocity.duplicate(),
        "heat": _heat.duplicate(),
        "event_timer": _event_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(sync: Dictionary) -> void:
    var value: Variant = sync.get("state", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == CELLS:
        _state = (value as PackedFloat32Array).duplicate()
    value = sync.get("velocity", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == CELLS:
        _velocity = (value as PackedFloat32Array).duplicate()
    value = sync.get("heat", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == CELLS:
        _heat = (value as PackedFloat32Array).duplicate()
    _event_timer = float(sync.get("event_timer", _event_timer))
    _event_counter = int(sync.get("event_counter", _event_counter))


func _get_custom_live_debug_state() -> Dictionary:
    var positive := 0
    for value: float in _state:
        if value > 0.0:
            positive += 1
    return {"cells": CELLS, "positive_state_cells": positive}
