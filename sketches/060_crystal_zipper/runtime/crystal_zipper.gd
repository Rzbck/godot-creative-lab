extends "res://sketches/_shared/design_sketch_base.gd"

const COLS: int = 18
const ROWS: int = 10
const CELLS: int = COLS * ROWS
const SAFE := Rect2(64.0, 50.0, 1152.0, 620.0)

@export_range(0.35, 2.5, 0.01) var toughness: float = 1.08
@export_range(0.0, 3.0, 0.01) var propagation: float = 1.34
@export_range(0.0, 2.0, 0.01) var healing: float = 0.28
@export_range(0.0, 2.5, 0.01) var diffusion: float = 0.84
@export_range(-2.0, 2.0, 0.01) var shear: float = 0.34
@export_range(0.0, 1.5, 0.01) var relief: float = 0.78

var _stress := PackedFloat32Array()
var _crack := PackedFloat32Array()
var _direction := PackedVector2Array()
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _stress.clear()
    _crack.clear()
    _direction.clear()
    _pointer_was_down = false
    _last_pointer = DESIGN_SIZE * 0.5
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _stress.resize(CELLS)
    _crack.resize(CELLS)
    _direction.resize(CELLS)
    for i: int in range(CELLS):
        _stress[i] = _hash01i(i * 71 + 7) * 0.08
        _crack[i] = 0.0
        var angle := TAU * _hash01i(i * 109 + 13)
        _direction[i] = Vector2(cos(angle), sin(angle))


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"toughness","label":"FRACTURE TOUGHNESS","type":"float","min":0.35,"max":2.5,"step":0.01},
        {"id":"propagation","label":"CRACK PROPAGATION","type":"float","min":0.0,"max":3.0,"step":0.01},
        {"id":"healing","label":"SELF HEAL","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"diffusion","label":"STRESS DIFFUSION","type":"float","min":0.0,"max":2.5,"step":0.01},
        {"id":"shear","label":"SHEAR BIAS","type":"float","min":-2.0,"max":2.0,"step":0.01},
        {"id":"relief","label":"FACET RELIEF","type":"float","min":0.0,"max":1.5,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "toughness": return toughness
        "propagation": return propagation
        "healing": return healing
        "diffusion": return diffusion
        "shear": return shear
        "relief": return relief
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "toughness": toughness = clampf(float(value), 0.35, 2.5)
        "propagation": propagation = clampf(float(value), 0.0, 3.0)
        "healing": healing = clampf(float(value), 0.0, 2.0)
        "diffusion": diffusion = clampf(float(value), 0.0, 2.5)
        "shear": shear = clampf(float(value), -2.0, 2.0)
        "relief": relief = clampf(float(value), 0.0, 1.5)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down:
        var motion := pointer_position - _last_pointer
        var motion_dir := motion.normalized() if motion.length() > 0.5 else Vector2.RIGHT
        var brush := 102.0
        for row: int in range(ROWS):
            for col: int in range(COLS):
                var i := _idx(col, row)
                var center := _cell_center(col, row)
                var distance := center.distance_to(pointer_position)
                if distance >= brush:
                    continue
                var falloff := 1.0 - distance / brush
                _stress[i] = minf(3.0, _stress[i] + falloff * (0.16 + motion.length() * 0.008))
                _direction[i] = _direction[i].lerp(motion_dir, falloff * 0.34).normalized()
    _last_pointer = pointer_position
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    var next_stress := _stress.duplicate()
    var next_crack := _crack.duplicate()
    for row: int in range(ROWS):
        for col: int in range(COLS):
            var i := _idx(col, row)
            var neighbour_sum := 0.0
            var neighbour_crack := 0.0
            var neighbour_count := 0.0
            for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
                var x := col + offset.x
                var y := row + offset.y
                if x < 0 or x >= COLS or y < 0 or y >= ROWS:
                    continue
                var j := _idx(x, y)
                neighbour_sum += _stress[j]
                neighbour_crack += _crack[j]
                neighbour_count += 1.0
            if neighbour_count > 0.0:
                var mean_stress := neighbour_sum / neighbour_count
                next_stress[i] += (mean_stress - _stress[i]) * diffusion * delta
            var directional_bias := absf(_direction[i].dot(Vector2(1.0, shear).normalized()))
            var threshold := toughness * (1.10 - directional_bias * 0.24)
            if _stress[i] > threshold:
                var excess := (_stress[i] - threshold) / maxf(0.1, threshold)
                next_crack[i] = minf(1.0, _crack[i] + excess * propagation * delta * 1.8)
                next_stress[i] *= 1.0 - clampf(propagation * delta * 0.16, 0.0, 0.35)
            elif neighbour_count > 0.0 and neighbour_crack / neighbour_count > 0.18:
                var inherited := (neighbour_crack / neighbour_count) * propagation * delta * 0.20
                next_crack[i] = minf(1.0, _crack[i] + inherited * clampf(_stress[i] / maxf(0.2, toughness), 0.0, 1.0))
            next_crack[i] *= exp(-delta * healing * 0.42)
            next_stress[i] *= exp(-delta * (0.05 + healing * 0.025))
    _stress = next_stress
    _crack = next_crack
    queue_redraw()


func _cell_center(col: int, row: int) -> Vector2:
    var cell_w := SAFE.size.x / float(COLS)
    var cell_h := SAFE.size.y / float(ROWS)
    var i := _idx(col, row)
    var jitter := Vector2((_hash01i(i * 127 + 5) - 0.5) * cell_w * 0.26, (_hash01i(i * 151 + 17) - 0.5) * cell_h * 0.26)
    return SAFE.position + Vector2((float(col) + 0.5) * cell_w, (float(row) + 0.5) * cell_h) + jitter


func _draw() -> void:
    begin_design_draw(Color(0.105, 0.115, 0.12, 1.0))
    var cell_w := SAFE.size.x / float(COLS)
    var cell_h := SAFE.size.y / float(ROWS)
    for row: int in range(ROWS):
        for col: int in range(COLS):
            var i := _idx(col, row)
            var center := _cell_center(col, row)
            var half := Vector2(cell_w * 0.52, cell_h * 0.52)
            var relief_amount := relief * (0.12 + _stress[i] * 0.15)
            var shift := _direction[i] * minf(cell_w, cell_h) * relief_amount
            var p0 := center + Vector2(-half.x, -half.y) + shift * 0.24
            var p1 := center + Vector2(half.x, -half.y) - shift * 0.10
            var p2 := center + Vector2(half.x, half.y) + shift * 0.18
            var p3 := center + Vector2(-half.x, half.y) - shift * 0.16
            var stress_value := clampf(_stress[i] / maxf(0.35, toughness * 1.3), 0.0, 1.0)
            var crack_value := clampf(_crack[i], 0.0, 1.0)
            var base := Color(0.18, 0.22, 0.24, 0.96)
            base = base.lerp(Color(0.62, 0.40, 0.20, 0.98), stress_value * 0.76)
            var diagonal_a := ((col + row) % 2) == 0
            if diagonal_a:
                draw_colored_polygon(PackedVector2Array([p0, p1, p2]), base.lightened(relief_amount * 0.18))
                draw_colored_polygon(PackedVector2Array([p0, p2, p3]), base.darkened(relief_amount * 0.16))
                if crack_value > 0.03:
                    draw_line(p0, p2, Color(0.98, 0.48, 0.19, 0.22 + crack_value * 0.74), 0.8 + crack_value * 3.2, true)
            else:
                draw_colored_polygon(PackedVector2Array([p0, p1, p3]), base.lightened(relief_amount * 0.16))
                draw_colored_polygon(PackedVector2Array([p1, p2, p3]), base.darkened(relief_amount * 0.18))
                if crack_value > 0.03:
                    draw_line(p1, p3, Color(0.98, 0.48, 0.19, 0.22 + crack_value * 0.74), 0.8 + crack_value * 3.2, true)
    end_design_draw()


func _idx(col: int, row: int) -> int:
    return row * COLS + col


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {"stress": _stress.duplicate(), "crack": _crack.duplicate(), "direction": _direction.duplicate()}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("stress", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == CELLS:
        _stress = (value as PackedFloat32Array).duplicate()
    value = state.get("crack", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == CELLS:
        _crack = (value as PackedFloat32Array).duplicate()
    value = state.get("direction", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == CELLS:
        _direction = (value as PackedVector2Array).duplicate()


func _get_custom_live_debug_state() -> Dictionary:
    var cracked := 0
    for value: float in _crack:
        if value > 0.12:
            cracked += 1
    return {"cells": CELLS, "cracked_cells": cracked}
