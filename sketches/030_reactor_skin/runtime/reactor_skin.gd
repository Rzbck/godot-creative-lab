extends "res://sketches/_shared/design_sketch_base.gd"

const W := 52
const H := 30
const MW := 14
const MH := 9
const BG := Color(0.055, 0.052, 0.047, 1.0)
const PALE := Color(0.80, 0.79, 0.70, 1.0)
const DARK := Color(0.10, 0.12, 0.11, 1.0)
const RED := Color(0.74, 0.22, 0.15, 1.0)

@export_range(0.2, 1.5, 0.01) var diff_a: float = 0.92
@export_range(0.05, 0.8, 0.01) var diff_b: float = 0.38
@export_range(0.005, 0.09, 0.001) var feed: float = 0.036
@export_range(0.02, 0.09, 0.001) var kill: float = 0.061
@export_range(0.3, 2.0, 0.01) var chemistry_speed: float = 1.0
@export_range(0.0, 2.5, 0.01) var mesh_coupling: float = 0.88
@export_range(0.2, 2.5, 0.01) var fracture_threshold: float = 1.12
@export_range(0.05, 1.5, 0.01) var repair: float = 0.40
@export_range(0.2, 3.0, 0.01) var touch_gain: float = 1.24

var _a := PackedFloat32Array()
var _b := PackedFloat32Array()
var _next_a := PackedFloat32Array()
var _next_b := PackedFloat32Array()
var _stress := PackedFloat32Array()
var _mesh_stress := PackedFloat32Array()
var _broken_h := PackedFloat32Array()
var _broken_v := PackedFloat32Array()
var _image: Image
var _texture: ImageTexture
var _accum := 0.0
var _event_clock := 2.2
var _event_index := 0


func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _seed()
    _refresh_texture()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"diff_a", "label":"DIFFUSION A", "type":"float", "min":0.2, "max":1.5, "step":0.01},
        {"id":"diff_b", "label":"DIFFUSION B", "type":"float", "min":0.05, "max":0.8, "step":0.01},
        {"id":"feed", "label":"FEED RATE", "type":"float", "min":0.005, "max":0.09, "step":0.001},
        {"id":"kill", "label":"KILL RATE", "type":"float", "min":0.02, "max":0.09, "step":0.001},
        {"id":"chemistry_speed", "label":"CHEMISTRY SPEED", "type":"float", "min":0.3, "max":2.0, "step":0.01},
        {"id":"mesh_coupling", "label":"MESH COUPLING", "type":"float", "min":0.0, "max":2.5, "step":0.01},
        {"id":"fracture_threshold", "label":"FRACTURE THRESHOLD", "type":"float", "min":0.2, "max":2.5, "step":0.01},
        {"id":"repair", "label":"REPAIR", "type":"float", "min":0.05, "max":1.5, "step":0.01},
        {"id":"touch_gain", "label":"INJECTION ENERGY", "type":"float", "min":0.2, "max":3.0, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "diff_a": return diff_a
        "diff_b": return diff_b
        "feed": return feed
        "kill": return kill
        "chemistry_speed": return chemistry_speed
        "mesh_coupling": return mesh_coupling
        "fracture_threshold": return fracture_threshold
        "repair": return repair
        "touch_gain": return touch_gain
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "diff_a": diff_a = clampf(float(value), 0.2, 1.5)
        "diff_b": diff_b = clampf(float(value), 0.05, 0.8)
        "feed": feed = clampf(float(value), 0.005, 0.09)
        "kill": kill = clampf(float(value), 0.02, 0.09)
        "chemistry_speed": chemistry_speed = clampf(float(value), 0.3, 2.0)
        "mesh_coupling": mesh_coupling = clampf(float(value), 0.0, 2.5)
        "fracture_threshold": fracture_threshold = clampf(float(value), 0.2, 2.5)
        "repair": repair = clampf(float(value), 0.05, 1.5)
        "touch_gain": touch_gain = clampf(float(value), 0.2, 3.0)
        _: return


func _idx(x: int, y: int) -> int:
    return posmod(y, H) * W + posmod(x, W)


func _midx(x: int, y: int) -> int:
    return y * MW + x


func _seed() -> void:
    if _a.size() == W * H:
        return
    var count := W * H
    _a.resize(count)
    _b.resize(count)
    _next_a.resize(count)
    _next_b.resize(count)
    _stress.resize(count)
    _a.fill(1.0)
    _b.fill(0.0)
    _next_a.fill(1.0)
    _next_b.fill(0.0)
    _stress.fill(0.0)
    _mesh_stress.resize(MW * MH)
    _mesh_stress.fill(0.0)
    _broken_h.resize((MW - 1) * MH)
    _broken_v.resize(MW * (MH - 1))
    _broken_h.fill(0.0)
    _broken_v.fill(0.0)
    _seed_patch(16, 11, 4, 0.92)
    _seed_patch(35, 19, 3, 0.78)
    _image = Image.create(W, H, false, Image.FORMAT_RGBA8)
    _texture = ImageTexture.create_from_image(_image)


func _update_source_simulation(delta: float) -> void:
    _seed()
    if pointer_down:
        _inject(pointer_position, touch_gain)

    _event_clock -= delta
    if _event_clock <= 0.0:
        var x := 5 + int(_hash01(_event_index * 31 + 3) * float(W - 10))
        var y := 4 + int(_hash01(_event_index * 43 + 7) * float(H - 8))
        _seed_patch(x, y, 2 + (_event_index % 3), 0.45 + _hash01(_event_index * 59 + 11) * 0.45)
        var mx := clampi(int(float(x) / float(W) * float(MW)), 0, MW - 1)
        var my := clampi(int(float(y) / float(H) * float(MH)), 0, MH - 1)
        _mesh_stress[_midx(mx, my)] = minf(2.5, _mesh_stress[_midx(mx, my)] + 0.65)
        _event_clock = 1.6 + _hash01(_event_index * 71 + 17) * 5.0
        _event_index += 1

    var stepped := false
    _accum += delta
    var step_dt := 1.0 / 30.0
    while _accum >= step_dt:
        _accum -= step_dt
        _step_chemistry(step_dt * chemistry_speed)
        _step_mesh(step_dt)
        stepped = true
    if stepped:
        _refresh_texture()


func _lap(field: PackedFloat32Array, x: int, y: int) -> float:
    var center := field[_idx(x, y)]
    var sum := field[_idx(x - 1, y)] + field[_idx(x + 1, y)] + field[_idx(x, y - 1)] + field[_idx(x, y + 1)]
    sum += (field[_idx(x - 1, y - 1)] + field[_idx(x + 1, y - 1)] + field[_idx(x - 1, y + 1)] + field[_idx(x + 1, y + 1)]) * 0.5
    return sum * (1.0 / 6.0) - center


func _step_chemistry(dt: float) -> void:
    for y: int in range(H):
        for x: int in range(W):
            var i := _idx(x, y)
            var av := _a[i]
            var bv := _b[i]
            var reaction := av * bv * bv
            var na := av + (diff_a * _lap(_a, x, y) - reaction + feed * (1.0 - av)) * dt * 10.0
            var nb := bv + (diff_b * _lap(_b, x, y) + reaction - (kill + feed) * bv) * dt * 10.0
            _next_a[i] = clampf(na, 0.0, 1.2)
            _next_b[i] = clampf(nb, 0.0, 1.2)
            var grad := absf(_b[_idx(x + 1, y)] - _b[_idx(x - 1, y)]) + absf(_b[_idx(x, y + 1)] - _b[_idx(x, y - 1)])
            _stress[i] = lerpf(_stress[i], clampf(grad * 2.6 + bv * 0.22, 0.0, 2.0), 0.22)
    var temp := _a
    _a = _next_a
    _next_a = temp
    temp = _b
    _b = _next_b
    _next_b = temp


func _step_mesh(dt: float) -> void:
    for my: int in range(MH):
        for mx: int in range(MW):
            var sx := clampi(int(float(mx) / float(MW - 1) * float(W - 1)), 0, W - 1)
            var sy := clampi(int(float(my) / float(MH - 1) * float(H - 1)), 0, H - 1)
            var target := _stress[_idx(sx, sy)] * mesh_coupling
            var mi := _midx(mx, my)
            _mesh_stress[mi] = lerpf(_mesh_stress[mi], target, 0.18)

    for i: int in range(_broken_h.size()):
        _broken_h[i] = maxf(0.0, _broken_h[i] - dt * repair)
    for i: int in range(_broken_v.size()):
        _broken_v[i] = maxf(0.0, _broken_v[i] - dt * repair)

    for my: int in range(MH):
        for mx: int in range(MW - 1):
            var a := _midx(mx, my)
            var b := _midx(mx + 1, my)
            var edge_i := my * (MW - 1) + mx
            if _broken_h[edge_i] <= 0.0 and maxf(_mesh_stress[a], _mesh_stress[b]) > fracture_threshold:
                if _hash01(_event_index * 101 + edge_i * 7 + 3) > 0.74:
                    _broken_h[edge_i] = 0.55 + _mesh_stress[a] * 0.35
        if my >= MH - 1:
            continue
        for mx: int in range(MW):
            var a := _midx(mx, my)
            var b := _midx(mx, my + 1)
            var edge_i := my * MW + mx
            if _broken_v[edge_i] <= 0.0 and maxf(_mesh_stress[a], _mesh_stress[b]) > fracture_threshold:
                if _hash01(_event_index * 109 + edge_i * 11 + 5) > 0.76:
                    _broken_v[edge_i] = 0.55 + _mesh_stress[a] * 0.35


func _seed_patch(cx: int, cy: int, radius: int, strength: float) -> void:
    for oy: int in range(-radius, radius + 1):
        for ox: int in range(-radius, radius + 1):
            var d := Vector2(float(ox), float(oy)).length()
            if d > float(radius):
                continue
            var i := _idx(cx + ox, cy + oy)
            _b[i] = maxf(_b[i], strength * (1.0 - d / float(radius + 1)))
            _a[i] = minf(_a[i], 0.58)


func _inject(point: Vector2, gain: float) -> void:
    var cx := clampi(int(point.x / DESIGN_SIZE.x * float(W)), 0, W - 1)
    var cy := clampi(int(point.y / DESIGN_SIZE.y * float(H)), 0, H - 1)
    _seed_patch(cx, cy, 3 + int(round(gain)), clampf(0.46 + gain * 0.22, 0.0, 1.15))
    var mx := clampi(int(point.x / DESIGN_SIZE.x * float(MW)), 0, MW - 1)
    var my := clampi(int(point.y / DESIGN_SIZE.y * float(MH)), 0, MH - 1)
    var mi := _midx(mx, my)
    _mesh_stress[mi] = minf(3.0, _mesh_stress[mi] + gain * 0.42)


func _mesh_point(mx: int, my: int) -> Vector2:
    var base := Vector2(float(mx) / float(MW - 1) * DESIGN_SIZE.x, float(my) / float(MH - 1) * DESIGN_SIZE.y)
    var mi := _midx(mx, my)
    var s := _mesh_stress[mi]
    var dx := 0.0
    var dy := 0.0
    if mx > 0 and mx < MW - 1:
        dx = _mesh_stress[_midx(mx + 1, my)] - _mesh_stress[_midx(mx - 1, my)]
    if my > 0 and my < MH - 1:
        dy = _mesh_stress[_midx(mx, my + 1)] - _mesh_stress[_midx(mx, my - 1)]
    return base + Vector2(dx, dy) * 34.0 * mesh_coupling + Vector2(0.0, s * 8.0)


func _refresh_texture() -> void:
    for y: int in range(H):
        for x: int in range(W):
            var i := _idx(x, y)
            var bv := clampf(_b[i], 0.0, 1.0)
            var edge := clampf(_stress[i] / 1.4, 0.0, 1.0)
            var c := PALE.lerp(DARK, smoothstep(0.18, 0.72, bv))
            c = c.lerp(RED, edge * 0.42)
            _image.set_pixel(x, y, c)
    _texture.update(_image)


func _draw() -> void:
    begin_design_draw(BG)
    if _texture != null:
        draw_texture_rect(_texture, Rect2(Vector2.ZERO, DESIGN_SIZE), false)

    for my: int in range(MH):
        for mx: int in range(MW - 1):
            var edge_i := my * (MW - 1) + mx
            var a := _mesh_point(mx, my)
            var b := _mesh_point(mx + 1, my)
            if _broken_h[edge_i] > 0.0:
                draw_line(a, a.lerp(b, 0.38), Color(0.74, 0.22, 0.15, 0.55), 1.2)
                draw_line(b, b.lerp(a, 0.38), Color(0.74, 0.22, 0.15, 0.55), 1.2)
            else:
                draw_line(a, b, Color(0.12, 0.13, 0.12, 0.30), 1.0)
    for my: int in range(MH - 1):
        for mx: int in range(MW):
            var edge_i := my * MW + mx
            var a := _mesh_point(mx, my)
            var b := _mesh_point(mx, my + 1)
            if _broken_v[edge_i] <= 0.0:
                draw_line(a, b, Color(0.12, 0.13, 0.12, 0.24), 1.0)
    end_design_draw()


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "a": _a.duplicate(), "b": _b.duplicate(), "stress": _stress.duplicate(),
        "mesh_stress": _mesh_stress.duplicate(), "broken_h": _broken_h.duplicate(), "broken_v": _broken_v.duplicate(),
        "event_clock": _event_clock, "event_index": _event_index, "accum": _accum,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("a", PackedFloat32Array())
    if v is PackedFloat32Array: _a = (v as PackedFloat32Array).duplicate()
    v = state.get("b", PackedFloat32Array())
    if v is PackedFloat32Array: _b = (v as PackedFloat32Array).duplicate()
    v = state.get("stress", PackedFloat32Array())
    if v is PackedFloat32Array: _stress = (v as PackedFloat32Array).duplicate()
    v = state.get("mesh_stress", PackedFloat32Array())
    if v is PackedFloat32Array: _mesh_stress = (v as PackedFloat32Array).duplicate()
    v = state.get("broken_h", PackedFloat32Array())
    if v is PackedFloat32Array: _broken_h = (v as PackedFloat32Array).duplicate()
    v = state.get("broken_v", PackedFloat32Array())
    if v is PackedFloat32Array: _broken_v = (v as PackedFloat32Array).duplicate()
    _event_clock = float(state.get("event_clock", _event_clock))
    _event_index = int(state.get("event_index", _event_index))
    _accum = float(state.get("accum", _accum))
    _next_a.resize(_a.size())
    _next_b.resize(_b.size())
    _refresh_texture()
