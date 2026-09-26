extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 128
const ROWS := 72
const CELL_W := 1280.0 / float(COLS)
const CELL_H := 720.0 / float(ROWS)

@export_range(0.0, 2.2, 0.01) var feedback_gain: float = 0.92
@export_range(0.1, 2.5, 0.01) var diffusion: float = 1.14
@export_range(0.01, 0.8, 0.01) var decay: float = 0.13
@export_range(0.1, 2.5, 0.01) var inertia: float = 0.86
@export_range(0.08, 0.85, 0.01) var threshold: float = 0.34
@export_range(0.0, 2.0, 0.01) var relief: float = 1.08
@export_range(0.0, 1.0, 0.01) var grain: float = 0.42
@export_range(0.0, 1.0, 0.01) var chroma: float = 0.31
@export_range(18.0, 180.0, 1.0) var touch_radius: float = 82.0

var _memory := PackedFloat32Array()
var _velocity := PackedFloat32Array()
var _echo := PackedFloat32Array()
var _next_memory := PackedFloat32Array()
var _next_velocity := PackedFloat32Array()
var _next_echo := PackedFloat32Array()
var _field_image: Image
var _field_texture: ImageTexture
var _accum := 0.0
var _auto_armed := true
var _auto_index := 0
var _last_max := 0.0
var _last_pointer := Vector2(640.0, 360.0)
var _gesture_velocity := Vector2.ZERO

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    super._ready()
    _ensure_field()
    _seed_initial_state()
    _refresh_texture()
    _push_shader()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"feedback_gain","label":"MEMORY FEEDBACK","type":"float","min":0.0,"max":2.2,"step":0.01},
        {"id":"diffusion","label":"DIFFUSION","type":"float","min":0.1,"max":2.5,"step":0.01},
        {"id":"decay","label":"DECAY","type":"float","min":0.01,"max":0.8,"step":0.01},
        {"id":"inertia","label":"MATERIAL INERTIA","type":"float","min":0.1,"max":2.5,"step":0.01},
        {"id":"threshold","label":"PHASE THRESHOLD","type":"float","min":0.08,"max":0.85,"step":0.01},
        {"id":"relief","label":"OPTICAL RELIEF","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"grain","label":"MICRO GRAIN","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"chroma","label":"SPECTRAL MIX","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"touch_radius","label":"MEMORY BRUSH","type":"float","min":18.0,"max":180.0,"step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "feedback_gain": return feedback_gain
        "diffusion": return diffusion
        "decay": return decay
        "inertia": return inertia
        "threshold": return threshold
        "relief": return relief
        "grain": return grain
        "chroma": return chroma
        "touch_radius": return touch_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "feedback_gain": feedback_gain = clampf(float(value), 0.0, 2.2)
        "diffusion": diffusion = clampf(float(value), 0.1, 2.5)
        "decay": decay = clampf(float(value), 0.01, 0.8)
        "inertia": inertia = clampf(float(value), 0.1, 2.5)
        "threshold": threshold = clampf(float(value), 0.08, 0.85)
        "relief": relief = clampf(float(value), 0.0, 2.0)
        "grain": grain = clampf(float(value), 0.0, 1.0)
        "chroma": chroma = clampf(float(value), 0.0, 1.0)
        "touch_radius": touch_radius = clampf(float(value), 18.0, 180.0)
        _: return
    _push_shader()


func _idx(x: int, y: int) -> int:
    return posmod(y, ROWS) * COLS + posmod(x, COLS)


func _ensure_field() -> void:
    var count := COLS * ROWS
    if _memory.size() == count:
        return
    _memory.resize(count)
    _velocity.resize(count)
    _echo.resize(count)
    _next_memory.resize(count)
    _next_velocity.resize(count)
    _next_echo.resize(count)
    _memory.fill(0.0)
    _velocity.fill(0.0)
    _echo.fill(0.0)
    _next_memory.fill(0.0)
    _next_velocity.fill(0.0)
    _next_echo.fill(0.0)
    _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    _field_texture = ImageTexture.create_from_image(_field_image)


func _seed_initial_state() -> void:
    _deposit(Vector2(318.0, 236.0), 92.0, 0.78)
    _deposit(Vector2(846.0, 468.0), 128.0, 0.62)
    _deposit(Vector2(1038.0, 194.0), 66.0, -0.46)


func _on_pointer_changed() -> void:
    var delta_pos := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pos, 0.38)
    _last_pointer = pointer_position
    if pointer_down:
        var speed := clampf(_gesture_velocity.length() / 46.0, 0.0, 1.0)
        _deposit(pointer_position, touch_radius, 0.22 + speed * 0.34)


func _deposit(point: Vector2, radius: float, amount: float) -> void:
    if _memory.is_empty():
        return
    var cx := int(point.x / CELL_W)
    var cy := int(point.y / CELL_H)
    var rx := maxi(1, int(ceil(radius / CELL_W)))
    var ry := maxi(1, int(ceil(radius / CELL_H)))
    for oy: int in range(-ry, ry + 1):
        for ox: int in range(-rx, rx + 1):
            var nx := cx + ox
            var ny := cy + oy
            if nx < 0 or nx >= COLS or ny < 0 or ny >= ROWS:
                continue
            var world := Vector2((float(nx) + 0.5) * CELL_W, (float(ny) + 0.5) * CELL_H)
            var d := world.distance_to(point)
            if d > radius:
                continue
            var w := 1.0 - d / maxf(1.0, radius)
            w = w * w * (3.0 - 2.0 * w)
            var i := _idx(nx, ny)
            _velocity[i] += amount * w * 2.1
            _memory[i] = clampf(_memory[i] + amount * w * 0.22, 0.0, 1.4)


func _update_source_simulation(delta: float) -> void:
    _ensure_field()
    _accum += delta
    var stepped := false
    while _accum >= 1.0 / 24.0:
        _accum -= 1.0 / 24.0
        _step_field(1.0 / 24.0)
        stepped = true
    if stepped:
        _refresh_texture()
    _gesture_velocity *= exp(-delta * 7.0)
    _push_shader()


func _step_field(dt: float) -> void:
    var max_value := 0.0
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var m := _memory[i]
            var v := _velocity[i]
            var e := _echo[i]
            var neighbour := (
                _memory[_idx(x - 1, y)] + _memory[_idx(x + 1, y)] +
                _memory[_idx(x, y - 1)] + _memory[_idx(x, y + 1)]
            ) * 0.25
            var lap := neighbour - m
            var phase_drive := maxf(0.0, neighbour + e * 0.32 - threshold)
            var acceleration := lap * diffusion * 7.2 + phase_drive * feedback_gain * 2.4 - m * 0.26
            v += acceleration * dt
            v *= exp(-dt * (0.72 + inertia * 0.42))
            var next_m := m + v * dt
            next_m -= decay * dt * (0.42 + next_m * 0.84)
            next_m = clampf(next_m, 0.0, 1.35)
            var next_e := lerpf(e, m, clampf(dt * (0.34 + feedback_gain * 0.16), 0.0, 1.0))
            _next_memory[i] = next_m
            _next_velocity[i] = v
            _next_echo[i] = next_e
            max_value = maxf(max_value, next_m)

    var temp := _memory
    _memory = _next_memory
    _next_memory = temp
    temp = _velocity
    _velocity = _next_velocity
    _next_velocity = temp
    temp = _echo
    _echo = _next_echo
    _next_echo = temp

    # Autonomous events are triggered by material quietness rather than a clock.
    # The field must genuinely settle before another event can happen.
    _last_max = max_value
    if max_value < 0.115 and _auto_armed:
        _auto_index += 1
        var p := Vector2(
            100.0 + _hash01(_auto_index * 43 + 7) * 1080.0,
            80.0 + _hash01(_auto_index * 71 + 23) * 560.0
        )
        var sign_value := -1.0 if _hash01(_auto_index * 89 + 31) < 0.28 else 1.0
        _deposit(p, 54.0 + _hash01(_auto_index * 97 + 41) * 128.0, sign_value * (0.48 + _hash01(_auto_index * 103 + 5) * 0.42))
        _auto_armed = false
    elif max_value > 0.48:
        _auto_armed = true


func _refresh_texture() -> void:
    if _field_image == null:
        _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var m := clampf(_memory[i], 0.0, 1.0)
            var e := clampf(_echo[i], 0.0, 1.0)
            var v := clampf(absf(_velocity[i]) * 0.45, 0.0, 1.0)
            _field_image.set_pixel(x, y, Color(m, e, v, 1.0))
    if _field_texture == null:
        _field_texture = ImageTexture.create_from_image(_field_image)
    else:
        _field_texture.update(_field_image)


func _push_shader() -> void:
    if not is_instance_valid(_surface) or _field_texture == null:
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_memory", _field_texture)
    material.set_shader_parameter("u_texel", Vector2(1.0 / float(COLS), 1.0 / float(ROWS)))
    material.set_shader_parameter("u_relief", relief)
    material.set_shader_parameter("u_grain", grain)
    material.set_shader_parameter("u_chroma", chroma)
    material.set_shader_parameter("u_feedback", feedback_gain)
    material.set_shader_parameter("u_threshold", threshold)


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "memory": _memory.duplicate(),
        "velocity": _velocity.duplicate(),
        "echo": _echo.duplicate(),
        "accum": _accum,
        "auto_armed": _auto_armed,
        "auto_index": _auto_index,
        "last_max": _last_max,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var count := COLS * ROWS
    var v: Variant = state.get("memory", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == count:
        _memory = (v as PackedFloat32Array).duplicate()
        _next_memory.resize(count)
    v = state.get("velocity", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == count:
        _velocity = (v as PackedFloat32Array).duplicate()
        _next_velocity.resize(count)
    v = state.get("echo", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == count:
        _echo = (v as PackedFloat32Array).duplicate()
        _next_echo.resize(count)
    _accum = float(state.get("accum", _accum))
    _auto_armed = bool(state.get("auto_armed", _auto_armed))
    _auto_index = int(state.get("auto_index", _auto_index))
    _last_max = float(state.get("last_max", _last_max))
    _refresh_texture()
    _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "field_resolution": Vector2i(COLS, ROWS),
        "peak_memory": _last_max,
        "render_mode": "temporal_field_to_fullres_material",
    }


func _draw() -> void:
    pass
