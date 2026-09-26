extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 64
const ROWS := 36
const CELL_W := 1280.0 / float(COLS)
const CELL_H := 720.0 / float(ROWS)
const BG := Color(0.955, 0.935, 0.875, 1.0)
const DORMANT := Color(0.72, 0.79, 0.61, 1.0)
const ALIVE := Color(0.10, 0.52, 0.25, 1.0)
const HOT := Color(0.96, 0.23, 0.055, 1.0)
const SPORE := Color(0.055, 0.065, 0.055, 1.0)

@export_range(0.0, 1.8, 0.01) var coupling: float = 0.82
@export_range(0.08, 0.9, 0.01) var threshold: float = 0.43
@export_range(0.2, 3.0, 0.05) var refractory_time: float = 1.15
@export_range(0.0, 1.5, 0.01) var edge_feed: float = 0.64
@export_range(0.01, 0.8, 0.01) var decay: float = 0.16
@export_range(10.0, 150.0, 1.0) var spore_speed: float = 58.0
@export_range(0.0, 1.0, 0.01) var spore_split: float = 0.52
@export_range(0.0, 1.2, 0.01) var spore_deposit: float = 0.48
@export_range(1.0, 7.0, 1.0) var seed_radius: float = 3.0

var _charge := PackedFloat32Array()
var _refractory := PackedFloat32Array()
var _next_charge := PackedFloat32Array()
var _next_refractory := PackedFloat32Array()
var _spore_pos: Array[Vector2] = []
var _spore_vel: Array[Vector2] = []
var _accum := 0.0
var _split_accum := 0.0
var _field_image: Image
var _field_texture: ImageTexture


func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _seed_system()
    _refresh_field_texture()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"coupling", "label":"CELL COUPLING", "type":"float", "min":0.0, "max":1.8, "step":0.01},
        {"id":"threshold", "label":"EXCITATION THRESHOLD", "type":"float", "min":0.08, "max":0.9, "step":0.01},
        {"id":"refractory_time", "label":"REFRACTORY TIME", "type":"float", "min":0.2, "max":3.0, "step":0.05},
        {"id":"edge_feed", "label":"EDGE FEED", "type":"float", "min":0.0, "max":1.5, "step":0.01},
        {"id":"decay", "label":"DECAY", "type":"float", "min":0.01, "max":0.8, "step":0.01},
        {"id":"spore_speed", "label":"SPORE SPEED", "type":"float", "min":10.0, "max":150.0, "step":1.0},
        {"id":"spore_split", "label":"SPORE SPLIT", "type":"float", "min":0.0, "max":1.0, "step":0.01},
        {"id":"spore_deposit", "label":"SPORE DEPOSIT", "type":"float", "min":0.0, "max":1.2, "step":0.01},
        {"id":"seed_radius", "label":"SEED RADIUS", "type":"float", "min":1.0, "max":7.0, "step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "coupling": return coupling
        "threshold": return threshold
        "refractory_time": return refractory_time
        "edge_feed": return edge_feed
        "decay": return decay
        "spore_speed": return spore_speed
        "spore_split": return spore_split
        "spore_deposit": return spore_deposit
        "seed_radius": return seed_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "coupling": coupling = clampf(float(value), 0.0, 1.8)
        "threshold": threshold = clampf(float(value), 0.08, 0.9)
        "refractory_time": refractory_time = clampf(float(value), 0.2, 3.0)
        "edge_feed": edge_feed = clampf(float(value), 0.0, 1.5)
        "decay": decay = clampf(float(value), 0.01, 0.8)
        "spore_speed": spore_speed = clampf(float(value), 10.0, 150.0)
        "spore_split": spore_split = clampf(float(value), 0.0, 1.0)
        "spore_deposit": spore_deposit = clampf(float(value), 0.0, 1.2)
        "seed_radius": seed_radius = clampf(float(value), 1.0, 7.0)
        _: return


func _idx(x: int, y: int) -> int:
    return posmod(y, ROWS) * COLS + posmod(x, COLS)


func _seed_system() -> void:
    if _charge.size() == COLS * ROWS:
        return
    var count := COLS * ROWS
    _charge.resize(count)
    _refractory.resize(count)
    _next_charge.resize(count)
    _next_refractory.resize(count)
    _charge.fill(0.0)
    _refractory.fill(0.0)
    _next_charge.fill(0.0)
    _next_refractory.fill(0.0)

    for y: int in range(ROWS):
        for x: int in range(COLS):
            var edge_distance := mini(mini(x, COLS - 1 - x), mini(y, ROWS - 1 - y))
            if edge_distance <= 1 and hash01(float(x * 37 + y * 71)) > 0.44:
                _charge[_idx(x, y)] = 0.45 + hash01(float(x * 13 + y * 19)) * 0.45

    for i: int in range(18):
        var side := i % 4
        var t := (float(i) + 0.5) / 18.0
        var p := Vector2.ZERO
        match side:
            0: p = Vector2(18.0, 60.0 + t * 600.0)
            1: p = Vector2(1262.0, 60.0 + t * 600.0)
            2: p = Vector2(90.0 + t * 1100.0, 18.0)
            _: p = Vector2(90.0 + t * 1100.0, 702.0)
        _spore_pos.append(p)
        _spore_vel.append(Vector2.from_angle(hash01(float(i) * 9.7) * TAU) * spore_speed * 0.55)

    _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    _field_texture = ImageTexture.create_from_image(_field_image)


func _update_source_simulation(delta: float) -> void:
    _seed_system()
    if pointer_down:
        _seed_at(pointer_position, int(round(seed_radius)))

    var stepped := false
    _accum += delta
    while _accum >= 1.0 / 30.0:
        _accum -= 1.0 / 30.0
        _step_cells(1.0 / 30.0)
        stepped = true

    _update_spores(delta)
    _split_accum += delta
    if _split_accum >= 0.5:
        _split_accum = 0.0
        _try_split_spores()

    if stepped:
        _refresh_field_texture()


func _seed_at(point: Vector2, radius_cells: int) -> void:
    var cx := clampi(int(point.x / CELL_W), 0, COLS - 1)
    var cy := clampi(int(point.y / CELL_H), 0, ROWS - 1)
    for oy: int in range(-radius_cells, radius_cells + 1):
        for ox: int in range(-radius_cells, radius_cells + 1):
            var d := Vector2(float(ox), float(oy)).length()
            if d > float(radius_cells) + 0.2:
                continue
            var i := _idx(cx + ox, cy + oy)
            _charge[i] = maxf(_charge[i], 1.0 - d / maxf(1.0, float(radius_cells + 1)) * 0.35)
            _refractory[i] = 0.0


func _neighbour_average(x: int, y: int) -> float:
    return (
        _charge[_idx(x - 1, y - 1)] + _charge[_idx(x, y - 1)] + _charge[_idx(x + 1, y - 1)] +
        _charge[_idx(x - 1, y)] + _charge[_idx(x + 1, y)] +
        _charge[_idx(x - 1, y + 1)] + _charge[_idx(x, y + 1)] + _charge[_idx(x + 1, y + 1)]
    ) * 0.125


func _step_cells(dt: float) -> void:
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var current := _charge[i]
            var ref := _refractory[i]
            var neighbour := _neighbour_average(x, y)
            var edge_distance := mini(mini(x, COLS - 1 - x), mini(y, ROWS - 1 - y))
            var edge_source := edge_feed * 0.22 if edge_distance <= 1 else 0.0

            if ref > 0.0:
                _next_refractory[i] = maxf(0.0, ref - dt)
                _next_charge[i] = maxf(0.0, current - decay * dt * 2.8)
            else:
                var drive := neighbour * coupling + edge_source
                if current > 0.78:
                    _next_charge[i] = maxf(0.0, current - decay * dt * 6.0 - 0.055)
                    _next_refractory[i] = refractory_time
                elif drive > threshold:
                    _next_charge[i] = clampf(current + 0.19 + (drive - threshold) * 0.72, 0.0, 1.0)
                    _next_refractory[i] = 0.0
                else:
                    _next_charge[i] = clampf(current * (1.0 - decay * dt * 1.6) + neighbour * coupling * 0.018, 0.0, 1.0)
                    _next_refractory[i] = 0.0

    var temp_c := _charge
    _charge = _next_charge
    _next_charge = temp_c
    var temp_r := _refractory
    _refractory = _next_refractory
    _next_refractory = temp_r


func _sample_charge(point: Vector2) -> float:
    return _charge[_idx(int(point.x / CELL_W), int(point.y / CELL_H))]


func _sample_gradient(point: Vector2) -> Vector2:
    var x := clampi(int(point.x / CELL_W), 0, COLS - 1)
    var y := clampi(int(point.y / CELL_H), 0, ROWS - 1)
    return Vector2(
        _charge[_idx(x + 1, y)] - _charge[_idx(x - 1, y)],
        _charge[_idx(x, y + 1)] - _charge[_idx(x, y - 1)]
    )


func _update_spores(delta: float) -> void:
    for i: int in range(_spore_pos.size()):
        var p := _spore_pos[i]
        var gradient := _sample_gradient(p)
        var tangent := Vector2(-gradient.y, gradient.x)
        var desired := gradient * 0.78 + tangent * (0.22 + 0.18 * sin(sketch_time + float(i)))
        if desired.length_squared() < 0.001:
            desired = Vector2.from_angle(hash01(float(i) * 11.3 + floor(sketch_time)) * TAU)
        else:
            desired = desired.normalized()
        var v := _spore_vel[i].lerp(desired * spore_speed, clampf(delta * 1.8, 0.0, 1.0))
        p += v * delta
        if p.x < 8.0: p.x = 1272.0
        if p.x > 1272.0: p.x = 8.0
        if p.y < 8.0: p.y = 712.0
        if p.y > 712.0: p.y = 8.0
        _spore_pos[i] = p
        _spore_vel[i] = v
        var index := _idx(int(p.x / CELL_W), int(p.y / CELL_H))
        _charge[index] = clampf(_charge[index] + spore_deposit * delta * 0.8, 0.0, 1.0)


func _try_split_spores() -> void:
    if _spore_pos.size() >= 72:
        return
    var original_count := _spore_pos.size()
    for i: int in range(original_count):
        if _spore_pos.size() >= 72:
            break
        if _sample_charge(_spore_pos[i]) < 0.58:
            continue
        var chance := hash01(float(i) * 23.9 + floor(sketch_time * 2.0))
        if chance > spore_split * 0.28:
            continue
        var offset := Vector2.from_angle(hash01(float(i) * 5.7 + sketch_time) * TAU) * 12.0
        _spore_pos.append(_spore_pos[i] + offset)
        _spore_vel.append(_spore_vel[i].rotated(0.9 + chance * 0.7) * 0.92)


func _refresh_field_texture() -> void:
    if _field_image == null:
        _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var value := _charge[i]
            var ref := _refractory[i]
            if value < 0.012 and ref <= 0.0:
                _field_image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
                continue
            var t := smoothstep(0.02, 0.92, value)
            var c := DORMANT.lerp(ALIVE, t).lerp(HOT, smoothstep(0.68, 1.0, value))
            if ref > 0.0:
                c = c.lerp(BG, clampf(ref / maxf(0.01, refractory_time), 0.0, 1.0) * 0.72)
            c.a = 0.20 + t * 0.80
            _field_image.set_pixel(x, y, c)
    if _field_texture == null:
        _field_texture = ImageTexture.create_from_image(_field_image)
    else:
        _field_texture.update(_field_image)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "charge": _charge.duplicate(), "refractory": _refractory.duplicate(),
        "spore_pos": _spore_pos.duplicate(), "spore_vel": _spore_vel.duplicate(),
        "accum": _accum, "split_accum": _split_accum,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var cv: Variant = state.get("charge", PackedFloat32Array())
    if cv is PackedFloat32Array:
        _charge = (cv as PackedFloat32Array).duplicate()
        _next_charge.resize(_charge.size())
    var rv: Variant = state.get("refractory", PackedFloat32Array())
    if rv is PackedFloat32Array:
        _refractory = (rv as PackedFloat32Array).duplicate()
        _next_refractory.resize(_refractory.size())
    var sp: Variant = state.get("spore_pos", [])
    if sp is Array: _spore_pos.assign(sp)
    var sv: Variant = state.get("spore_vel", [])
    if sv is Array: _spore_vel.assign(sv)
    _accum = float(state.get("accum", _accum))
    _split_accum = float(state.get("split_accum", _split_accum))
    _refresh_field_texture()


func _get_custom_live_debug_state() -> Dictionary:
    var mass := 0.0
    for value: float in _charge: mass += value
    return {"cell_mass": mass, "spores": _spore_pos.size(), "render_mode":"field_texture"}


func _draw() -> void:
    begin_design_draw(BG)
    if _field_texture != null:
        draw_texture_rect(_field_texture, Rect2(Vector2.ZERO, DESIGN_SIZE), false)
    for i: int in range(_spore_pos.size()):
        var p := _spore_pos[i]
        var v := _spore_vel[i].normalized()
        draw_circle(p, 2.3, SPORE)
        draw_line(p, p - v * 9.0, Color(SPORE.r, SPORE.g, SPORE.b, 0.42), 1.0, true)
    end_design_draw()
