extends "res://sketches/_shared/design_sketch_base.gd"

const COLS := 52
const ROWS := 30
const CELL_W := 1280.0 / float(COLS - 1)
const CELL_H := 720.0 / float(ROWS - 1)
const PARTICLE_COUNT := 76
const BG := Color(0.012, 0.025, 0.055, 1.0)
const WAVE_LOW := Color(0.08, 0.28, 0.52, 1.0)
const WAVE_HIGH := Color(0.24, 0.88, 0.92, 1.0)
const PARTICLE := Color(0.96, 0.92, 0.75, 1.0)
const VOID_CENTER := Vector2(910.0, 340.0)

@export_range(0.05, 2.0, 0.01) var wave_tension: float = 0.92
@export_range(0.82, 0.999, 0.001) var wave_damping: float = 0.982
@export_range(0.0, 2.5, 0.01) var flow_gain: float = 1.16
@export_range(0.65, 0.99, 0.01) var particle_inertia: float = 0.91
@export_range(28.0, 130.0, 1.0) var reconnect_radius: float = 74.0
@export_range(0.02, 0.8, 0.01) var regime_rate: float = 0.21
@export_range(60.0, 260.0, 1.0) var void_radius: float = 158.0
@export_range(0.0, 1.4, 0.01) var memory_gain: float = 0.42
@export_range(20.0, 160.0, 1.0) var particle_speed: float = 78.0

var _height: PackedFloat32Array = PackedFloat32Array()
var _velocity: PackedFloat32Array = PackedFloat32Array()
var _memory: PackedFloat32Array = PackedFloat32Array()
var _next_height: PackedFloat32Array = PackedFloat32Array()
var _next_velocity: PackedFloat32Array = PackedFloat32Array()

var _particle_pos: Array[Vector2] = []
var _particle_vel: Array[Vector2] = []
var _accum: float = 0.0
var _regime_clock: float = 0.0
var _regime: float = 1.0
var _last_pointer: Vector2 = Vector2.ZERO
var _has_last_pointer: bool = false
var _gesture: Vector2 = Vector2.ZERO


func _ready() -> void:
    super._ready()
    _seed_system()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"wave_tension", "label":"WAVE TENSION", "type":"float", "min":0.05, "max":2.0, "step":0.01},
        {"id":"wave_damping", "label":"WAVE DAMPING", "type":"float", "min":0.82, "max":0.999, "step":0.001},
        {"id":"flow_gain", "label":"FLOW GAIN", "type":"float", "min":0.0, "max":2.5, "step":0.01},
        {"id":"particle_inertia", "label":"PARTICLE INERTIA", "type":"float", "min":0.65, "max":0.99, "step":0.01},
        {"id":"reconnect_radius", "label":"RECONNECT RANGE", "type":"float", "min":28.0, "max":130.0, "step":1.0},
        {"id":"regime_rate", "label":"REGIME RATE", "type":"float", "min":0.02, "max":0.8, "step":0.01},
        {"id":"void_radius", "label":"VOID RADIUS", "type":"float", "min":60.0, "max":260.0, "step":1.0},
        {"id":"memory_gain", "label":"FIELD MEMORY", "type":"float", "min":0.0, "max":1.4, "step":0.01},
        {"id":"particle_speed", "label":"CURRENT SPEED", "type":"float", "min":20.0, "max":160.0, "step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "wave_tension": return wave_tension
        "wave_damping": return wave_damping
        "flow_gain": return flow_gain
        "particle_inertia": return particle_inertia
        "reconnect_radius": return reconnect_radius
        "regime_rate": return regime_rate
        "void_radius": return void_radius
        "memory_gain": return memory_gain
        "particle_speed": return particle_speed
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "wave_tension": wave_tension = clampf(float(value), 0.05, 2.0)
        "wave_damping": wave_damping = clampf(float(value), 0.82, 0.999)
        "flow_gain": flow_gain = clampf(float(value), 0.0, 2.5)
        "particle_inertia": particle_inertia = clampf(float(value), 0.65, 0.99)
        "reconnect_radius": reconnect_radius = clampf(float(value), 28.0, 130.0)
        "regime_rate": regime_rate = clampf(float(value), 0.02, 0.8)
        "void_radius": void_radius = clampf(float(value), 60.0, 260.0)
        "memory_gain": memory_gain = clampf(float(value), 0.0, 1.4)
        "particle_speed": particle_speed = clampf(float(value), 20.0, 160.0)
        _: return


func _idx(x: int, y: int) -> int:
    return clampi(y, 0, ROWS - 1) * COLS + clampi(x, 0, COLS - 1)


func _seed_system() -> void:
    if _height.size() == COLS * ROWS:
        return

    var count := COLS * ROWS
    _height.resize(count)
    _velocity.resize(count)
    _memory.resize(count)
    _next_height.resize(count)
    _next_velocity.resize(count)
    _height.fill(0.0)
    _velocity.fill(0.0)
    _memory.fill(0.0)
    _next_height.fill(0.0)
    _next_velocity.fill(0.0)

    for y: int in range(ROWS):
        for x: int in range(COLS):
            var p := Vector2(float(x) * CELL_W, float(y) * CELL_H)
            var d1 := p.distance_to(Vector2(310.0, 270.0))
            var d2 := p.distance_to(Vector2(610.0, 510.0))
            _height[_idx(x, y)] = exp(-d1 * d1 / 21000.0) * 0.72 - exp(-d2 * d2 / 18000.0) * 0.48

    for i: int in range(PARTICLE_COUNT):
        var p := Vector2(
            56.0 + hash01(float(i) * 17.9) * 1160.0,
            42.0 + hash01(float(i) * 31.7 + 3.0) * 636.0
        )
        if p.distance_to(VOID_CENTER) < void_radius + 24.0:
            p.x = fposmod(p.x + void_radius * 1.4 + 180.0, 1180.0) + 50.0
        var angle := hash01(float(i) * 9.3 + 5.0) * TAU
        _particle_pos.append(p)
        _particle_vel.append(Vector2.from_angle(angle) * particle_speed * 0.5)


func _on_pointer_changed() -> void:
    if pointer_down and _has_last_pointer:
        var delta_pointer := pointer_position - _last_pointer
        _gesture = _gesture.lerp(delta_pointer * 12.0, 0.34)
    elif not pointer_down:
        _gesture *= 0.82
    _last_pointer = pointer_position
    _has_last_pointer = pointer_active


func _update_source_simulation(delta: float) -> void:
    _seed_system()

    _regime_clock += delta
    var period := lerpf(12.0, 2.4, clampf(regime_rate, 0.0, 0.8) / 0.8)
    if _regime_clock >= period:
        _regime_clock = 0.0
        _regime *= -1.0

    if pointer_down:
        _inject_wave(pointer_position, _gesture)

    _accum += delta
    while _accum >= 1.0 / 36.0:
        _accum -= 1.0 / 36.0
        _step_wave()

    _update_particles(delta)
    _gesture *= pow(0.91, delta * 60.0)


func _step_wave() -> void:
    for y: int in range(ROWS):
        for x: int in range(COLS):
            var i := _idx(x, y)
            var h := _height[i]
            var lap := (
                _height[_idx(x - 1, y)] +
                _height[_idx(x + 1, y)] +
                _height[_idx(x, y - 1)] +
                _height[_idx(x, y + 1)] -
                h * 4.0
            )
            var memory := lerpf(_memory[i], h, 0.035 + memory_gain * 0.022)
            _memory[i] = memory
            var v := _velocity[i]
            v += lap * wave_tension * 0.18
            v += (memory - h) * memory_gain * 0.035
            v *= wave_damping
            _next_velocity[i] = clampf(v, -0.42, 0.42)
            _next_height[i] = clampf(h + _next_velocity[i], -1.4, 1.4)

    var temp_h := _height
    _height = _next_height
    _next_height = temp_h
    var temp_v := _velocity
    _velocity = _next_velocity
    _next_velocity = temp_v


func _inject_wave(point: Vector2, gesture: Vector2) -> void:
    var cx := clampi(int(round(point.x / CELL_W)), 0, COLS - 1)
    var cy := clampi(int(round(point.y / CELL_H)), 0, ROWS - 1)
    var strength := clampf(gesture.length() / 260.0, 0.12, 1.0)
    var sign_value := 1.0 if gesture.x + gesture.y >= 0.0 else -1.0
    for oy: int in range(-2, 3):
        for ox: int in range(-2, 3):
            var d := Vector2(float(ox), float(oy)).length()
            if d > 2.6:
                continue
            var i := _idx(cx + ox, cy + oy)
            _velocity[i] += sign_value * strength * (1.0 - d / 3.0) * 0.24


func _sample_height(point: Vector2) -> float:
    var x := clampi(int(round(point.x / CELL_W)), 0, COLS - 1)
    var y := clampi(int(round(point.y / CELL_H)), 0, ROWS - 1)
    return _height[_idx(x, y)]


func _sample_gradient(point: Vector2) -> Vector2:
    var x := clampi(int(round(point.x / CELL_W)), 1, COLS - 2)
    var y := clampi(int(round(point.y / CELL_H)), 1, ROWS - 2)
    return Vector2(
        _height[_idx(x + 1, y)] - _height[_idx(x - 1, y)],
        _height[_idx(x, y + 1)] - _height[_idx(x, y - 1)]
    )


func _update_particles(delta: float) -> void:
    for i: int in range(_particle_pos.size()):
        var p := _particle_pos[i]
        var gradient := _sample_gradient(p)
        var tangent := Vector2(-gradient.y, gradient.x) * _regime
        var desired := (tangent * 0.82 + gradient * 0.24) * flow_gain
        desired += Vector2(0.18 * _regime, 0.0)
        if desired.length_squared() < 0.0001:
            desired = Vector2(_regime, 0.0)
        desired = desired.normalized() * particle_speed

        var v := _particle_vel[i] * particle_inertia + desired * (1.0 - particle_inertia)

        var away_void := p - VOID_CENTER
        var dist_void := away_void.length()
        if dist_void < void_radius + 54.0 and dist_void > 0.001:
            var w := 1.0 - dist_void / (void_radius + 54.0)
            v += away_void / dist_void * w * particle_speed * 0.9

        if pointer_down:
            var d := p.distance_to(pointer_position)
            if d < 150.0 and _gesture.length() > 1.0:
                var w := 1.0 - d / 150.0
                v = v.lerp(_gesture.normalized() * particle_speed * 1.3, w * 0.44)

        p += v * delta
        if p.x < 8.0: p.x = 1272.0
        if p.x > 1272.0: p.x = 8.0
        if p.y < 8.0: p.y = 712.0
        if p.y > 712.0: p.y = 8.0

        _particle_pos[i] = p
        _particle_vel[i] = v.limit_length(particle_speed * 1.5)

        var cx := clampi(int(round(p.x / CELL_W)), 0, COLS - 1)
        var cy := clampi(int(round(p.y / CELL_H)), 0, ROWS - 1)
        var index := _idx(cx, cy)
        _velocity[index] += clampf(v.length() / maxf(1.0, particle_speed), 0.0, 1.5) * 0.0015 * _regime


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "height": _height.duplicate(),
        "velocity": _velocity.duplicate(),
        "memory": _memory.duplicate(),
        "particle_pos": _particle_pos.duplicate(),
        "particle_vel": _particle_vel.duplicate(),
        "accum": _accum,
        "regime_clock": _regime_clock,
        "regime": _regime,
        "last_pointer": _last_pointer,
        "has_last_pointer": _has_last_pointer,
        "gesture": _gesture,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var hv: Variant = state.get("height", PackedFloat32Array())
    if hv is PackedFloat32Array:
        _height = (hv as PackedFloat32Array).duplicate()
        _next_height.resize(_height.size())
    var vv: Variant = state.get("velocity", PackedFloat32Array())
    if vv is PackedFloat32Array:
        _velocity = (vv as PackedFloat32Array).duplicate()
        _next_velocity.resize(_velocity.size())
    var mv: Variant = state.get("memory", PackedFloat32Array())
    if mv is PackedFloat32Array: _memory = (mv as PackedFloat32Array).duplicate()
    var pp: Variant = state.get("particle_pos", [])
    if pp is Array: _particle_pos.assign(pp)
    var pv: Variant = state.get("particle_vel", [])
    if pv is Array: _particle_vel.assign(pv)
    _accum = float(state.get("accum", _accum))
    _regime_clock = float(state.get("regime_clock", _regime_clock))
    _regime = float(state.get("regime", _regime))
    var lp: Variant = state.get("last_pointer", _last_pointer)
    if lp is Vector2: _last_pointer = lp as Vector2
    _has_last_pointer = bool(state.get("has_last_pointer", _has_last_pointer))
    var gv: Variant = state.get("gesture", _gesture)
    if gv is Vector2: _gesture = gv as Vector2


func _get_custom_live_debug_state() -> Dictionary:
    return {"regime": _regime, "particles": _particle_pos.size()}


func _draw() -> void:
    begin_design_draw(BG)

    if _height.size() == COLS * ROWS:
        for y: int in range(0, ROWS, 2):
            for x: int in range(COLS - 1):
                var p1 := Vector2(float(x) * CELL_W, float(y) * CELL_H + _height[_idx(x, y)] * 24.0)
                var p2 := Vector2(float(x + 1) * CELL_W, float(y) * CELL_H + _height[_idx(x + 1, y)] * 24.0)
                if p1.distance_to(VOID_CENTER) < void_radius or p2.distance_to(VOID_CENTER) < void_radius:
                    continue
                var amp := absf((_height[_idx(x, y)] + _height[_idx(x + 1, y)]) * 0.5)
                var c := WAVE_LOW.lerp(WAVE_HIGH, clampf(amp, 0.0, 1.0))
                c.a = 0.10 + clampf(amp, 0.0, 1.0) * 0.50
                draw_line(p1, p2, c, 0.8 + amp * 1.6, true)

    for i: int in range(_particle_pos.size()):
        for j: int in range(i + 1, _particle_pos.size()):
            var d := _particle_pos[i].distance_to(_particle_pos[j])
            if d > reconnect_radius:
                continue
            var hi := _sample_height(_particle_pos[i])
            var hj := _sample_height(_particle_pos[j])
            if hi * hj < -0.03:
                continue
            var c := WAVE_HIGH
            c.a = (1.0 - d / reconnect_radius) * 0.16
            draw_line(_particle_pos[i], _particle_pos[j], c, 0.8, true)

    for i: int in range(_particle_pos.size()):
        var p := _particle_pos[i]
        var speed := clampf(_particle_vel[i].length() / maxf(1.0, particle_speed), 0.0, 1.5)
        var c := PARTICLE.lerp(WAVE_HIGH, clampf(speed - 0.4, 0.0, 1.0))
        draw_circle(p, 1.8 + speed * 1.2, c)

    draw_circle(VOID_CENTER, void_radius, BG)
    draw_arc(VOID_CENTER, void_radius, 0.0, TAU, 72, Color(WAVE_HIGH.r, WAVE_HIGH.g, WAVE_HIGH.b, 0.08), 1.0)

    end_design_draw()
