extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 48
const ROWS := 27
const CELL_W := 1280.0 / float(COLS)
const CELL_H := 720.0 / float(ROWS)
const BG := Color(0.965, 0.94, 0.84, 1.0)
const A_COLOR := Color(0.07, 0.08, 0.075, 1.0)
const B_COLOR := Color(0.86, 0.13, 0.06, 1.0)

@export_range(0.01, 0.09, 0.001) var feed: float = 0.036
@export_range(0.03, 0.08, 0.001) var kill: float = 0.061
@export_range(0.2, 1.4, 0.01) var diffusion: float = 0.86

var _a: PackedFloat32Array = PackedFloat32Array()
var _b: PackedFloat32Array = PackedFloat32Array()
var _next_a: PackedFloat32Array = PackedFloat32Array()
var _next_b: PackedFloat32Array = PackedFloat32Array()
var _accumulator := 0.0


func _ready() -> void:
    super._ready()
    _seed_field()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"feed", "label":"FEED", "type":"float", "min":0.01, "max":0.09, "step":0.001},
        {"id":"kill", "label":"KILL", "type":"float", "min":0.03, "max":0.08, "step":0.001},
        {"id":"diffusion", "label":"DIFFUSION", "type":"float", "min":0.2, "max":1.4, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "feed": return feed
        "kill": return kill
        "diffusion": return diffusion
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "feed": feed = clampf(float(value), 0.01, 0.09)
        "kill": kill = clampf(float(value), 0.03, 0.08)
        "diffusion": diffusion = clampf(float(value), 0.2, 1.4)
        _: return


func _idx(x: int, y: int) -> int:
    return posmod(y, ROWS) * COLS + posmod(x, COLS)


func _seed_field() -> void:
    if _a.size() == COLS * ROWS:
        return
    _a.resize(COLS * ROWS)
    _b.resize(COLS * ROWS)
    _next_a.resize(COLS * ROWS)
    _next_b.resize(COLS * ROWS)
    _a.fill(1.0)
    _b.fill(0.0)
    for sy: int in range(10, 17):
        for sx: int in range(20, 28):
            var i := _idx(sx, sy)
            _b[i] = 0.82 + hash01(float(i) * 2.7) * 0.18
            _a[i] = 0.18
    for sy: int in range(3, 7):
        for sx: int in range(5, 10):
            _b[_idx(sx, sy)] = 0.75
            _a[_idx(sx, sy)] = 0.24


func _lap(field: PackedFloat32Array, x: int, y: int) -> float:
    var c := field[_idx(x, y)] * -1.0
    c += field[_idx(x - 1, y)] * 0.2
    c += field[_idx(x + 1, y)] * 0.2
    c += field[_idx(x, y - 1)] * 0.2
    c += field[_idx(x, y + 1)] * 0.2
    c += field[_idx(x - 1, y - 1)] * 0.05
    c += field[_idx(x + 1, y - 1)] * 0.05
    c += field[_idx(x - 1, y + 1)] * 0.05
    c += field[_idx(x + 1, y + 1)] * 0.05
    return c


func _update_source_simulation(delta: float) -> void:
    _seed_field()
    if pointer_down:
        _seed_at(pointer_position)

    _accumulator += delta
    while _accumulator >= 1.0 / 30.0:
        _accumulator -= 1.0 / 30.0
        _step_field()


func _seed_at(point: Vector2) -> void:
    var cx := clampi(int(point.x / CELL_W), 0, COLS - 1)
    var cy := clampi(int(point.y / CELL_H), 0, ROWS - 1)
    for oy: int in range(-2, 3):
        for ox: int in range(-2, 3):
            if Vector2(float(ox), float(oy)).length() > 2.5:
                continue
            var i := _idx(cx + ox, cy + oy)
            _b[i] = 1.0
            _a[i] = 0.08


func _step_field() -> void:
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var a := _a[i]
            var b := _b[i]
            var reaction := a * b * b
            var da := diffusion
            var db := diffusion * 0.48
            var na := a + (da * _lap(_a, x, y) - reaction + feed * (1.0 - a)) * 0.82
            var nb := b + (db * _lap(_b, x, y) + reaction - (kill + feed) * b) * 0.82
            _next_a[i] = clampf(na, 0.0, 1.0)
            _next_b[i] = clampf(nb, 0.0, 1.0)
    var temp_a := _a
    _a = _next_a
    _next_a = temp_a
    var temp_b := _b
    _b = _next_b
    _next_b = temp_b


func _get_custom_live_sync_state() -> Dictionary:
    return {"a": _a.duplicate(), "b": _b.duplicate(), "accumulator": _accumulator}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var av: Variant = state.get("a", PackedFloat32Array())
    if av is PackedFloat32Array:
        _a = (av as PackedFloat32Array).duplicate()
        _next_a.resize(_a.size())
    var bv: Variant = state.get("b", PackedFloat32Array())
    if bv is PackedFloat32Array:
        _b = (bv as PackedFloat32Array).duplicate()
        _next_b.resize(_b.size())
    _accumulator = float(state.get("accumulator", _accumulator))


func _get_custom_live_debug_state() -> Dictionary:
    var mass := 0.0
    for value: float in _b:
        mass += value
    return {"chemical_mass": mass}


func _draw() -> void:
    begin_design_draw(BG)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var b := _b[_idx(x, y)] if _b.size() == COLS * ROWS else 0.0
            var threshold := smoothstep(0.08, 0.72, b)
            var color := BG.lerp(A_COLOR, threshold)
            color = color.lerp(B_COLOR, smoothstep(0.45, 0.95, b) * 0.72)
            var pad := 0.8 + (1.0 - threshold) * 1.8
            draw_rect(
                Rect2(Vector2(float(x) * CELL_W + pad, float(y) * CELL_H + pad), Vector2(CELL_W - pad * 2.0, CELL_H - pad * 2.0)),
                color,
                true
            )
    end_design_draw()
