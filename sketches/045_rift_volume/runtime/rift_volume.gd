extends "res://sketches/_shared/design_sketch_base.gd"

const GRID_X: int = 64
const GRID_Y: int = 36
const STEP_SECONDS: float = 1.0 / 20.0

@export_range(0.7, 1.45, 0.01) var volume_scale: float = 1.0
@export_range(0.2, 1.6, 0.01) var tunnel: float = 0.86
@export_range(0.96, 0.9995, 0.0005) var scar_memory: float = 0.994
@export_range(0.0, 1.0, 0.01) var scar_diffusion: float = 0.28
@export_range(0.0, 1.0, 0.01) var spectral: float = 0.32
@export_range(0.0, 1.0, 0.01) var roughness: float = 0.58
@export_range(0.1, 2.2, 0.01) var drift: float = 0.76

var _scar := PackedFloat32Array()
var _next_scar := PackedFloat32Array()
var _anchors := PackedVector2Array([Vector2(0.31, 0.38), Vector2(0.67, 0.31), Vector2(0.58, 0.70)])
var _targets := PackedVector2Array([Vector2(0.26, 0.28), Vector2(0.74, 0.42), Vector2(0.46, 0.74)])
var _velocities := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _accum: float = 0.0
var _target_timer: float = 0.7
var _event_counter: int = 29
var _pointer_was_down: bool = false
var _state_image: Image
var _front_texture: ImageTexture
var _back_texture: ImageTexture

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    var count := GRID_X * GRID_Y
    _scar.resize(count)
    _next_scar.resize(count)
    _build_textures()
    super._ready()
    _push_shader()


func _build_textures() -> void:
    _state_image = Image.create(GRID_X, GRID_Y, false, Image.FORMAT_RGBA8)
    _write_image()
    _front_texture = ImageTexture.create_from_image(_state_image)
    _back_texture = ImageTexture.create_from_image(_state_image)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"volume_scale","label":"VOLUME SCALE","type":"float","min":0.7,"max":1.45,"step":0.01},
        {"id":"tunnel","label":"TUNNEL WIDTH","type":"float","min":0.2,"max":1.6,"step":0.01},
        {"id":"scar_memory","label":"SCAR MEMORY","type":"float","min":0.96,"max":0.9995,"step":0.0005},
        {"id":"scar_diffusion","label":"SCAR DIFFUSION","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"spectral","label":"SPECTRAL EDGE","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"roughness","label":"ROUGHNESS","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"drift","label":"MASS DRIFT","type":"float","min":0.1,"max":2.2,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "volume_scale": return volume_scale
        "tunnel": return tunnel
        "scar_memory": return scar_memory
        "scar_diffusion": return scar_diffusion
        "spectral": return spectral
        "roughness": return roughness
        "drift": return drift
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "volume_scale": volume_scale = clampf(float(value), 0.7, 1.45)
        "tunnel": tunnel = clampf(float(value), 0.2, 1.6)
        "scar_memory": scar_memory = clampf(float(value), 0.96, 0.9995)
        "scar_diffusion": scar_diffusion = clampf(float(value), 0.0, 1.0)
        "spectral": spectral = clampf(float(value), 0.0, 1.0)
        "roughness": roughness = clampf(float(value), 0.0, 1.0)
        "drift": drift = clampf(float(value), 0.1, 2.2)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    if pointer_down:
        var uv := (pointer_position / DESIGN_SIZE).clamp(Vector2.ZERO, Vector2.ONE)
        _stamp_scar(uv, 3 if _pointer_was_down else 5, 0.48 if _pointer_was_down else 0.92)
        if not _pointer_was_down:
            for i: int in range(_anchors.size()):
                var delta := _anchors[i] - uv
                var distance := delta.length()
                if distance < 0.48 and distance > 0.001:
                    _velocities[i] = _velocities[i] + delta / distance * (0.20 * (1.0 - distance / 0.48))
        _publish_state()
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _update_anchors(delta)
    _accum += delta
    var steps := 0
    while _accum >= STEP_SECONDS and steps < 2:
        _simulate_scar_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        steps += 1
    if steps > 0:
        _publish_state()
    else:
        _push_shader()


func _update_anchors(delta: float) -> void:
    _target_timer -= delta
    if _target_timer <= 0.0:
        _event_counter += 1
        _target_timer = 1.5 + _hash01i(_event_counter * 47) * 2.7
        var index := _event_counter % _targets.size()
        _targets[index] = Vector2(
            lerpf(0.18, 0.82, _hash01i(_event_counter * 67 + 7)),
            lerpf(0.18, 0.82, _hash01i(_event_counter * 89 + 13))
        )

    for i: int in range(_anchors.size()):
        var velocity := _velocities[i]
        velocity += (_targets[i] - _anchors[i]) * delta * (0.52 + drift * 0.58)
        velocity *= exp(-delta * 1.34)
        _anchors[i] = (_anchors[i] + velocity * delta).clamp(Vector2(0.10, 0.12), Vector2(0.90, 0.88))
        _velocities[i] = velocity


func _simulate_scar_step(dt: float) -> void:
    var decay := pow(scar_memory, dt * 3.0)
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x, y)
            var left := _scar[_idx(wrapi(x - 1, 0, GRID_X), y)]
            var right := _scar[_idx(wrapi(x + 1, 0, GRID_X), y)]
            var up := _scar[_idx(x, wrapi(y - 1, 0, GRID_Y))]
            var down := _scar[_idx(x, wrapi(y + 1, 0, GRID_Y))]
            var average := (left + right + up + down) * 0.25
            _next_scar[i] = clampf(lerpf(_scar[i], average, scar_diffusion * 0.22) * decay, 0.0, 1.0)
    var temp := _scar
    _scar = _next_scar
    _next_scar = temp


func _stamp_scar(uv: Vector2, radius: int, amount: float) -> void:
    var center := Vector2i(
        clampi(int(uv.x * float(GRID_X)), 0, GRID_X - 1),
        clampi(int(uv.y * float(GRID_Y)), 0, GRID_Y - 1)
    )
    for oy: int in range(-radius, radius + 1):
        for ox: int in range(-radius, radius + 1):
            var d := Vector2(float(ox), float(oy)).length()
            if d > float(radius) + 0.25:
                continue
            var x := wrapi(center.x + ox, 0, GRID_X)
            var y := wrapi(center.y + oy, 0, GRID_Y)
            var falloff := 1.0 - d / (float(radius) + 0.5)
            var i := _idx(x, y)
            _scar[i] = clampf(_scar[i] + falloff * amount, 0.0, 1.0)


func _write_image() -> void:
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var v := _scar[_idx(x, y)]
            _state_image.set_pixel(x, y, Color(v, v * v, 0.0, 1.0))


func _publish_state() -> void:
    if _state_image == null or _back_texture == null:
        return
    _write_image()
    _back_texture.update(_state_image)
    var material := _surface.material as ShaderMaterial
    if material != null:
        material.set_shader_parameter("u_scar", _back_texture)
    var temp := _front_texture
    _front_texture = _back_texture
    _back_texture = temp
    _push_shader()


func _push_shader() -> void:
    if not is_instance_valid(_surface) or _front_texture == null:
        return
    var material := _surface.material as ShaderMaterial
    if material == null:
        return
    material.set_shader_parameter("u_scar", _front_texture)
    material.set_shader_parameter("u_anchor0", _anchors[0])
    material.set_shader_parameter("u_anchor1", _anchors[1])
    material.set_shader_parameter("u_anchor2", _anchors[2])
    material.set_shader_parameter("u_volume_scale", volume_scale)
    material.set_shader_parameter("u_tunnel", tunnel)
    material.set_shader_parameter("u_spectral", spectral)
    material.set_shader_parameter("u_roughness", roughness)


func _idx(x: int, y: int) -> int:
    return y * GRID_X + x


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "scar": _scar.duplicate(),
        "anchors": _anchors.duplicate(),
        "targets": _targets.duplicate(),
        "velocities": _velocities.duplicate(),
        "target_timer": _target_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("scar", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == GRID_X * GRID_Y: _scar = (v as PackedFloat32Array).duplicate()
    v = state.get("anchors", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 3: _anchors = (v as PackedVector2Array).duplicate()
    v = state.get("targets", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 3: _targets = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == 3: _velocities = (v as PackedVector2Array).duplicate()
    _target_timer = float(state.get("target_timer", _target_timer))
    _event_counter = int(state.get("event_counter", _event_counter))
    _publish_state()


func _get_custom_live_debug_state() -> Dictionary:
    var scar_mass := 0.0
    for v: float in _scar: scar_mass += v
    return {
        "scar_mass": scar_mass,
        "render_mode": "stateful_sdf_raymarch",
    }


func _draw() -> void:
    pass
