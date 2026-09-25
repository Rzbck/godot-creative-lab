extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 80
const ROWS := 45
const BG := Color(0.008, 0.011, 0.016, 1.0)
const LOW := Color(0.03, 0.07, 0.11, 1.0)
const MID := Color(0.16, 0.46, 0.50, 1.0)
const HIGH := Color(0.96, 0.84, 0.46, 1.0)

@export_range(0.1, 3.0, 0.01) var transport: float = 1.18
@export_range(0.1, 0.95, 0.01) var channel_density: float = 0.58
@export_range(0.0, 2.0, 0.01) var jam_strength: float = 0.92
@export_range(0.1, 2.5, 0.01) var release_threshold: float = 1.05
@export_range(0.05, 2.0, 0.01) var obstacle_memory: float = 0.74
@export_range(0.1, 2.5, 0.01) var source_power: float = 1.20
@export_range(0.01, 0.8, 0.01) var decay: float = 0.16
@export_range(2.0, 10.0, 1.0) var quantization: float = 5.0
@export_range(20.0, 180.0, 1.0) var touch_radius: float = 78.0

var _energy := PackedFloat32Array()
var _pressure := PackedFloat32Array()
var _obstacle := PackedFloat32Array()
var _next_energy := PackedFloat32Array()
var _next_pressure := PackedFloat32Array()
var _gates := PackedFloat32Array()
var _gate_targets := PackedFloat32Array()
var _field_image: Image
var _field_texture: ImageTexture
var _accum := 0.0
var _event_clock := 1.9
var _event_index := 0


func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _seed()
    _refresh_texture()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"transport", "label":"LIGHT TRANSPORT", "type":"float", "min":0.1, "max":3.0, "step":0.01},
        {"id":"channel_density", "label":"CHANNEL DENSITY", "type":"float", "min":0.1, "max":0.95, "step":0.01},
        {"id":"jam_strength", "label":"JAM STRENGTH", "type":"float", "min":0.0, "max":2.0, "step":0.01},
        {"id":"release_threshold", "label":"RELEASE THRESHOLD", "type":"float", "min":0.1, "max":2.5, "step":0.01},
        {"id":"obstacle_memory", "label":"OBSTACLE MEMORY", "type":"float", "min":0.05, "max":2.0, "step":0.01},
        {"id":"source_power", "label":"SOURCE POWER", "type":"float", "min":0.1, "max":2.5, "step":0.01},
        {"id":"decay", "label":"ABSORPTION", "type":"float", "min":0.01, "max":0.8, "step":0.01},
        {"id":"quantization", "label":"LIGHT LEVELS", "type":"int", "min":2, "max":10, "step":1},
        {"id":"touch_radius", "label":"OBSTACLE RADIUS", "type":"float", "min":20.0, "max":180.0, "step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "transport": return transport
        "channel_density": return channel_density
        "jam_strength": return jam_strength
        "release_threshold": return release_threshold
        "obstacle_memory": return obstacle_memory
        "source_power": return source_power
        "decay": return decay
        "quantization": return int(round(quantization))
        "touch_radius": return touch_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "transport": transport = clampf(float(value), 0.1, 3.0)
        "channel_density": channel_density = clampf(float(value), 0.1, 0.95)
        "jam_strength": jam_strength = clampf(float(value), 0.0, 2.0)
        "release_threshold": release_threshold = clampf(float(value), 0.1, 2.5)
        "obstacle_memory": obstacle_memory = clampf(float(value), 0.05, 2.0)
        "source_power": source_power = clampf(float(value), 0.1, 2.5)
        "decay": decay = clampf(float(value), 0.01, 0.8)
        "quantization": quantization = clampf(float(value), 2.0, 10.0)
        "touch_radius": touch_radius = clampf(float(value), 20.0, 180.0)
        _: return


func _idx(x: int, y: int) -> int:
    return clampi(y, 0, ROWS - 1) * COLS + clampi(x, 0, COLS - 1)


func _seed() -> void:
    if _energy.size() == COLS * ROWS:
        return
    var count := COLS * ROWS
    _energy.resize(count)
    _pressure.resize(count)
    _obstacle.resize(count)
    _next_energy.resize(count)
    _next_pressure.resize(count)
    _energy.fill(0.0)
    _pressure.fill(0.0)
    _obstacle.fill(0.0)
    _next_energy.fill(0.0)
    _next_pressure.fill(0.0)
    _gates.resize(6)
    _gate_targets.resize(6)
    for i: int in range(6):
        _gates[i] = 0.62 + _hash01(i * 17 + 3) * 0.38
        _gate_targets[i] = _gates[i]
    _field_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
    _field_texture = ImageTexture.create_from_image(_field_image)


func _update_source_simulation(delta: float) -> void:
    _seed()
    if pointer_down:
        _place_obstacle(pointer_position)

    _event_clock -= delta
    if _event_clock <= 0.0:
        var band := int(_hash01(_event_index * 31 + 5) * 6.0) % 6
        var jam := _hash01(_event_index * 47 + 9) < 0.56
        _gate_targets[band] = 0.08 if jam else 1.0
        _event_clock = 1.3 + _hash01(_event_index * 61 + 11) * 4.8
        _event_index += 1

    for band: int in range(6):
        _gates[band] = lerpf(_gates[band], _gate_targets[band], clampf(delta * (0.42 + jam_strength * 0.34), 0.0, 1.0))
        if _gates[band] < 0.18 and _hash01(_event_index * 73 + band * 19) > 0.88:
            _gate_targets[band] = 1.0

    var stepped := false
    _accum += delta
    while _accum >= 1.0 / 24.0:
        _accum -= 1.0 / 24.0
        _step_field(1.0 / 24.0)
        stepped = true
    if stepped:
        _refresh_texture()


func _step_field(dt: float) -> void:
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var current := _energy[i]
            var neighbours := 0.0
            var weight := 0.0
            var directions := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
            for d_index: int in range(4):
                var d: Vector2i = directions[d_index]
                var nx := x + d.x
                var ny := y + d.y
                if nx < 0 or nx >= COLS or ny < 0 or ny >= ROWS:
                    continue
                var edge_open := _edge_open(x, y, d_index)
                if edge_open <= 0.0:
                    continue
                neighbours += _energy[_idx(nx, ny)] * edge_open
                weight += edge_open

            var average := current if weight <= 0.001 else neighbours / weight
            var band := clampi(int(float(x) / float(COLS) * 6.0), 0, 5)
            var gate := _gates[band]
            var block := clampf(_obstacle[i] + (1.0 - gate) * jam_strength * 0.72, 0.0, 1.0)
            var delta_light := (average - current) * transport * (1.0 - block) * dt * 4.2
            var next_value := current + delta_light
            var next_pressure := _pressure[i]

            if average > current and block > 0.05:
                next_pressure += (average - current) * block * jam_strength * dt * 2.8
            else:
                next_pressure = maxf(0.0, next_pressure - dt * 0.10)

            if next_pressure > release_threshold:
                next_value += next_pressure * 0.34
                next_pressure *= 0.28

            if x <= 1:
                var source_band := clampi(int(float(y) / float(ROWS) * 6.0), 0, 5)
                var source_gate := 0.42 + _gates[source_band] * 0.58
                next_value = maxf(next_value, source_power * source_gate * (0.62 + _hash01(y * 17 + source_band * 7) * 0.38))

            next_value = maxf(0.0, next_value - decay * dt * (0.7 + current * 0.8))
            _next_energy[i] = clampf(next_value, 0.0, 1.8)
            _next_pressure[i] = clampf(next_pressure, 0.0, 3.0)
            _obstacle[i] = maxf(0.0, _obstacle[i] - dt * (0.08 + 0.34 / maxf(obstacle_memory, 0.05)))

    var temp := _energy
    _energy = _next_energy
    _next_energy = temp
    temp = _pressure
    _pressure = _next_pressure
    _next_pressure = temp


func _edge_open(x: int, y: int, direction: int) -> float:
    var h := _hash01(x * 92821 + y * 68917 + direction * 31337)
    if h > channel_density:
        return 0.0
    return 0.35 + h * 0.65


func _place_obstacle(point: Vector2) -> void:
    var cx := int(point.x / DESIGN_SIZE.x * float(COLS))
    var cy := int(point.y / DESIGN_SIZE.y * float(ROWS))
    var rx := maxi(1, int(touch_radius / DESIGN_SIZE.x * float(COLS)))
    var ry := maxi(1, int(touch_radius / DESIGN_SIZE.y * float(ROWS)))
    for oy: int in range(-ry, ry + 1):
        for ox: int in range(-rx, rx + 1):
            var x := cx + ox
            var y := cy + oy
            if x < 0 or x >= COLS or y < 0 or y >= ROWS:
                continue
            var norm := Vector2(float(ox) / float(maxi(1, rx)), float(oy) / float(maxi(1, ry))).length()
            if norm > 1.0:
                continue
            var i := _idx(x, y)
            var force := 1.0 - norm
            _obstacle[i] = maxf(_obstacle[i], force)
            _pressure[i] = minf(3.0, _pressure[i] + force * 0.16)


func _refresh_texture() -> void:
    var levels := maxi(2, int(round(quantization)))
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var value := clampf(_energy[i] / 1.35, 0.0, 1.0)
            var q := floor(value * float(levels - 1) + 0.5) / float(levels - 1)
            var pressure_value := clampf(_pressure[i] / maxf(0.1, release_threshold * 1.6), 0.0, 1.0)
            var c := LOW.lerp(MID, q).lerp(HIGH, smoothstep(0.58, 1.0, q))
            c = c.lerp(HIGH, pressure_value * 0.36)
            c *= 1.0 - _obstacle[i] * 0.78
            _field_image.set_pixel(x, y, c)
    _field_texture.update(_field_image)


func _draw() -> void:
    begin_design_draw(BG)
    if _field_texture != null:
        draw_texture_rect(_field_texture, Rect2(Vector2.ZERO, DESIGN_SIZE), false)
    end_design_draw()


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "energy": _energy.duplicate(), "pressure": _pressure.duplicate(), "obstacle": _obstacle.duplicate(),
        "gates": _gates.duplicate(), "gate_targets": _gate_targets.duplicate(),
        "event_clock": _event_clock, "event_index": _event_index, "accum": _accum,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("energy", PackedFloat32Array())
    if v is PackedFloat32Array: _energy = (v as PackedFloat32Array).duplicate()
    v = state.get("pressure", PackedFloat32Array())
    if v is PackedFloat32Array: _pressure = (v as PackedFloat32Array).duplicate()
    v = state.get("obstacle", PackedFloat32Array())
    if v is PackedFloat32Array: _obstacle = (v as PackedFloat32Array).duplicate()
    v = state.get("gates", PackedFloat32Array())
    if v is PackedFloat32Array: _gates = (v as PackedFloat32Array).duplicate()
    v = state.get("gate_targets", PackedFloat32Array())
    if v is PackedFloat32Array: _gate_targets = (v as PackedFloat32Array).duplicate()
    _event_clock = float(state.get("event_clock", _event_clock))
    _event_index = int(state.get("event_index", _event_index))
    _accum = float(state.get("accum", _accum))
    _next_energy.resize(_energy.size())
    _next_pressure.resize(_pressure.size())
    _refresh_texture()
