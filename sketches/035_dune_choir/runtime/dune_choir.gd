extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 72
const ROWS := 38
const SAFE_TOP := 54.0
const SAFE_BOTTOM := 674.0
const BG := Color(0.006, 0.008, 0.015, 1.0)
const DEEP := Color(0.030, 0.075, 0.115, 1.0)
const MID := Color(0.12, 0.48, 0.55, 1.0)
const HIGH := Color(0.90, 0.76, 0.43, 1.0)

@export_range(0.2, 2.5, 0.01) var wave_speed: float = 1.08
@export_range(0.02, 0.9, 0.01) var damping: float = 0.17
@export_range(0.2, 2.5, 0.01) var coupling: float = 1.16
@export_range(0.2, 2.5, 0.01) var relief: float = 1.18
@export_range(0.2, 1.6, 0.01) var perspective: float = 0.82
@export_range(12.0, 38.0, 1.0) var line_density: float = 38.0
@export_range(0.0, 1.0, 0.01) var point_light: float = 0.46
@export_range(0.1, 3.0, 0.01) var touch_force: float = 1.55
@export_range(20.0, 190.0, 1.0) var touch_radius: float = 92.0

var _height := PackedFloat32Array()
var _velocity := PackedFloat32Array()
var _next_height := PackedFloat32Array()
var _next_velocity := PackedFloat32Array()
var _accum := 0.0
var _auto_armed := true
var _auto_index := 0
var _energy := 0.0
var _last_pointer := Vector2(640.0, 360.0)
var _gesture_velocity := Vector2.ZERO


func _ready() -> void:
    super._ready()
    _ensure_field()
    _inject_impulse(Vector2(388.0, 312.0), 110.0, 0.84)
    _inject_impulse(Vector2(882.0, 458.0), 146.0, -0.56)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"wave_speed","label":"WAVE SPEED","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"damping","label":"DAMPING","type":"float","min":0.02,"max":0.9,"step":0.01},
        {"id":"coupling","label":"NEIGHBOUR TENSION","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"relief","label":"RELIEF","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"perspective","label":"PERSPECTIVE","type":"float","min":0.2,"max":1.6,"step":0.01},
        {"id":"line_density","label":"LINE DENSITY","type":"int","min":12,"max":38,"step":1},
        {"id":"point_light","label":"PEAK LIGHT","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"touch_force","label":"IMPACT FORCE","type":"float","min":0.1,"max":3.0,"step":0.01},
        {"id":"touch_radius","label":"IMPACT RADIUS","type":"float","min":20.0,"max":190.0,"step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "wave_speed": return wave_speed
        "damping": return damping
        "coupling": return coupling
        "relief": return relief
        "perspective": return perspective
        "line_density": return int(round(line_density))
        "point_light": return point_light
        "touch_force": return touch_force
        "touch_radius": return touch_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "wave_speed": wave_speed = clampf(float(value), 0.2, 2.5)
        "damping": damping = clampf(float(value), 0.02, 0.9)
        "coupling": coupling = clampf(float(value), 0.2, 2.5)
        "relief": relief = clampf(float(value), 0.2, 2.5)
        "perspective": perspective = clampf(float(value), 0.2, 1.6)
        "line_density": line_density = clampf(float(value), 12.0, 38.0)
        "point_light": point_light = clampf(float(value), 0.0, 1.0)
        "touch_force": touch_force = clampf(float(value), 0.1, 3.0)
        "touch_radius": touch_radius = clampf(float(value), 20.0, 190.0)
        _: return


func _idx(x: int, y: int) -> int:
    return clampi(y, 0, ROWS - 1) * COLS + clampi(x, 0, COLS - 1)


func _ensure_field() -> void:
    var count := COLS * ROWS
    if _height.size() == count:
        return
    _height.resize(count)
    _velocity.resize(count)
    _next_height.resize(count)
    _next_velocity.resize(count)
    _height.fill(0.0)
    _velocity.fill(0.0)
    _next_height.fill(0.0)
    _next_velocity.fill(0.0)


func _on_pointer_changed() -> void:
    var delta_pos := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pos, 0.40)
    _last_pointer = pointer_position
    if pointer_down:
        var signed_force := touch_force * (0.56 + clampf(_gesture_velocity.length() / 38.0, 0.0, 1.0) * 0.72)
        if _gesture_velocity.y > 0.0:
            signed_force *= -1.0
        _inject_impulse(pointer_position, touch_radius, signed_force * 0.16)


func _inject_impulse(point: Vector2, radius: float, amount: float) -> void:
    _ensure_field()
    var cx := int(point.x / DESIGN_SIZE.x * float(COLS - 1))
    var cy := int(point.y / DESIGN_SIZE.y * float(ROWS - 1))
    var rx := maxi(1, int(radius / DESIGN_SIZE.x * float(COLS)))
    var ry := maxi(1, int(radius / DESIGN_SIZE.y * float(ROWS)))
    for oy: int in range(-ry, ry + 1):
        for ox: int in range(-rx, rx + 1):
            var x := cx + ox
            var y := cy + oy
            if x < 0 or x >= COLS or y < 0 or y >= ROWS:
                continue
            var n := Vector2(float(ox) / float(maxi(1, rx)), float(oy) / float(maxi(1, ry)))
            var d := n.length()
            if d > 1.0:
                continue
            var w := 1.0 - d
            w = w * w * (3.0 - 2.0 * w)
            var i := _idx(x, y)
            _velocity[i] += amount * w
            _height[i] += amount * w * 0.05


func _update_source_simulation(delta: float) -> void:
    _ensure_field()
    _accum += delta
    while _accum >= 1.0 / 30.0:
        _accum -= 1.0 / 30.0
        _step_wave(1.0 / 30.0)
    _gesture_velocity *= exp(-delta * 6.4)


func _step_wave(dt: float) -> void:
    var energy_sum := 0.0
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var h := _height[i]
            var v := _velocity[i]
            var neighbour := (
                _height[_idx(x - 1, y)] + _height[_idx(x + 1, y)] +
                _height[_idx(x, y - 1)] + _height[_idx(x, y + 1)]
            ) * 0.25
            var lap := neighbour - h
            var boundary := 1.0
            if x == 0 or x == COLS - 1 or y == 0 or y == ROWS - 1:
                boundary = 0.32
            v += lap * coupling * wave_speed * 15.0 * dt
            v -= h * 0.16 * dt
            v *= exp(-dt * (0.55 + damping * 4.0)) * boundary
            var next_h := clampf(h + v * dt, -1.6, 1.6)
            _next_height[i] = next_h
            _next_velocity[i] = v
            energy_sum += absf(next_h) + absf(v) * 0.14

    var temp := _height
    _height = _next_height
    _next_height = temp
    temp = _velocity
    _velocity = _next_velocity
    _next_velocity = temp

    _energy = energy_sum / float(COLS * ROWS)
    # Hysteretic autonomous excitation: a new impulse is allowed only after the
    # previous field has genuinely decayed below the quiet threshold.
    if _energy < 0.018 and _auto_armed:
        _auto_index += 1
        var p := Vector2(
            128.0 + _hash01(_auto_index * 41 + 7) * 1024.0,
            92.0 + _hash01(_auto_index * 67 + 17) * 536.0
        )
        var sign_value := -1.0 if _hash01(_auto_index * 79 + 23) < 0.46 else 1.0
        _inject_impulse(p, 70.0 + _hash01(_auto_index * 97 + 31) * 124.0, sign_value * (0.72 + _hash01(_auto_index * 107 + 5) * 0.66))
        _auto_armed = false
    elif _energy > 0.055:
        _auto_armed = true


func _project(x: int, y: int) -> Vector2:
    var fx := float(x) / float(COLS - 1)
    var fy := float(y) / float(ROWS - 1)
    var depth_scale := lerpf(0.54, 1.08, pow(fy, 0.72 + perspective * 0.28))
    var px := 640.0 + (fx - 0.5) * 1160.0 * depth_scale
    var base_y := lerpf(SAFE_TOP, SAFE_BOTTOM, fy)
    var h := _height[_idx(x, y)]
    var py := base_y - h * relief * lerpf(38.0, 102.0, fy)
    px += h * relief * 11.0 * (fy - 0.45)
    return Vector2(px, py)


func _draw() -> void:
    begin_design_draw(BG)

    # Layered atmospheric base, still vector-resolution independent.
    for band: int in range(18):
        var t := float(band) / 17.0
        var c := Color(0.006 + t * 0.010, 0.010 + t * 0.020, 0.020 + t * 0.030, 1.0)
        draw_rect(Rect2(0.0, t * DESIGN_SIZE.y, DESIGN_SIZE.x, DESIGN_SIZE.y / 17.0 + 1.0), c, true)

    var desired_rows := clampi(int(round(line_density)), 12, ROWS)
    var row_stride := maxi(1, int(floor(float(ROWS) / float(desired_rows))))
    for y: int in range(0, ROWS, row_stride):
        var points := PackedVector2Array()
        var local_energy := 0.0
        for x: int in range(COLS):
            points.append(_project(x, y))
            local_energy += absf(_height[_idx(x, y)])
        local_energy /= float(COLS)
        var fy := float(y) / float(ROWS - 1)
        var color := DEEP.lerp(MID, fy).lerp(HIGH, clampf(local_energy * 1.8 + fy * point_light * 0.18, 0.0, 0.72))
        var alpha := 0.22 + fy * 0.48
        color.a = alpha
        draw_polyline(points, Color(0.0, 0.0, 0.0, 0.34), 3.1, true)
        draw_polyline(points, color, 1.15 + fy * 0.55, true)
        if local_energy > 0.07:
            var highlight := HIGH
            highlight.a = minf(0.32, local_energy * 0.72) * point_light
            draw_polyline(points, highlight, 0.55, true)

    # Sparse longitudinal seams make the surface read as a spatial point/mesh
    # volume rather than a stack of unrelated waveform plots.
    for x: int in range(0, COLS, 6):
        var column := PackedVector2Array()
        for y: int in range(ROWS):
            column.append(_project(x, y))
        var seam := Color(0.26, 0.53, 0.58, 0.12 + point_light * 0.10)
        draw_polyline(column, seam, 0.65, true)

    # Peak glints are sampled from actual field curvature, never a decorative
    # random star layer.
    if point_light > 0.02:
        for y: int in range(2, ROWS - 2, 4):
            for x: int in range(2, COLS - 2, 6):
                var h := _height[_idx(x, y)]
                var curvature := absf(
                    _height[_idx(x - 1, y)] + _height[_idx(x + 1, y)] +
                    _height[_idx(x, y - 1)] + _height[_idx(x, y + 1)] - h * 4.0
                )
                if curvature > 0.10:
                    var glint := HIGH
                    glint.a = clampf(curvature * point_light * 0.9, 0.0, 0.48)
                    draw_circle(_project(x, y), 0.8 + curvature * 2.2, glint, true, -1.0, true)

    end_design_draw()


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "height": _height.duplicate(),
        "velocity": _velocity.duplicate(),
        "accum": _accum,
        "auto_armed": _auto_armed,
        "auto_index": _auto_index,
        "energy": _energy,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var count := COLS * ROWS
    var v: Variant = state.get("height", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == count:
        _height = (v as PackedFloat32Array).duplicate()
        _next_height.resize(count)
    v = state.get("velocity", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == count:
        _velocity = (v as PackedFloat32Array).duplicate()
        _next_velocity.resize(count)
    _accum = float(state.get("accum", _accum))
    _auto_armed = bool(state.get("auto_armed", _auto_armed))
    _auto_index = int(state.get("auto_index", _auto_index))
    _energy = float(state.get("energy", _energy))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "field_resolution": Vector2i(COLS, ROWS),
        "wave_energy": _energy,
        "render_mode": "projected_vector_topography",
    }
