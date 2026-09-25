extends "res://sketches/_shared/design_sketch_base.gd"

const GRID_X: int = 80
const GRID_Y: int = 45
const STEP_SECONDS: float = 1.0 / 30.0

@export_range(0.0, 2.8, 0.01) var buoyancy: float = 1.24
@export_range(0.0, 2.8, 0.01) var vorticity: float = 1.18
@export_range(0.0, 1.0, 0.01) var diffusion: float = 0.22
@export_range(0.2, 2.0, 0.01) var viscosity: float = 0.78
@export_range(0.88, 1.0, 0.001) var persistence: float = 0.976
@export_range(0.2, 2.4, 0.01) var source_rate: float = 1.08
@export_range(-1.57, 1.57, 0.01) var knife_angle: float = 0.34
@export_range(0.0, 1.0, 0.01) var chromaticity: float = 0.22
@export_range(0.0, 2.0, 0.01) var micro_detail: float = 1.06

var _density := PackedFloat32Array()
var _temperature := PackedFloat32Array()
var _vel_x := PackedFloat32Array()
var _vel_y := PackedFloat32Array()
var _next_density := PackedFloat32Array()
var _next_temperature := PackedFloat32Array()
var _next_vel_x := PackedFloat32Array()
var _next_vel_y := PackedFloat32Array()
var _accum: float = 0.0
var _source_reservoir := PackedFloat32Array([0.82, 0.35, 0.61])
var _source_x := PackedInt32Array([19, 41, 61])
var _state_image: Image
var _state_texture: ImageTexture

@onready var _surface: ColorRect = $ShaderSurface


func _ready() -> void:
    _allocate_state()
    _seed_plumes()
    _build_texture()
    super._ready()
    _push_shader()


func _allocate_state() -> void:
    var count := GRID_X * GRID_Y
    _density.resize(count)
    _temperature.resize(count)
    _vel_x.resize(count)
    _vel_y.resize(count)
    _next_density.resize(count)
    _next_temperature.resize(count)
    _next_vel_x.resize(count)
    _next_vel_y.resize(count)
    for i: int in range(count):
        _density[i] = 0.0
        _temperature[i] = 0.0
        _vel_x[i] = 0.0
        _vel_y[i] = 0.0


func _seed_plumes() -> void:
    _inject_plume(19, GRID_Y - 5, 0.78, 0.96, 0.18)
    _inject_plume(41, GRID_Y - 7, 0.56, 0.74, -0.11)
    _inject_plume(61, GRID_Y - 4, 0.66, 0.88, 0.09)


func _build_texture() -> void:
    _state_image = Image.create(GRID_X, GRID_Y, false, Image.FORMAT_RGBA8)
    _write_image()
    _state_texture = ImageTexture.create_from_image(_state_image)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"buoyancy","label":"BUOYANCY","type":"float","min":0.0,"max":2.8,"step":0.01},
        {"id":"vorticity","label":"VORTICITY","type":"float","min":0.0,"max":2.8,"step":0.01},
        {"id":"diffusion","label":"DIFFUSION","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"viscosity","label":"VISCOSITY","type":"float","min":0.2,"max":2.0,"step":0.01},
        {"id":"persistence","label":"MEMORY","type":"float","min":0.88,"max":1.0,"step":0.001},
        {"id":"source_rate","label":"SOURCE RATE","type":"float","min":0.2,"max":2.4,"step":0.01},
        {"id":"knife_angle","label":"KNIFE ANGLE","type":"float","min":-1.57,"max":1.57,"step":0.01},
        {"id":"chromaticity","label":"CHROMATICITY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"micro_detail","label":"MICRO DETAIL","type":"float","min":0.0,"max":2.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "buoyancy": return buoyancy
        "vorticity": return vorticity
        "diffusion": return diffusion
        "viscosity": return viscosity
        "persistence": return persistence
        "source_rate": return source_rate
        "knife_angle": return knife_angle
        "chromaticity": return chromaticity
        "micro_detail": return micro_detail
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "buoyancy": buoyancy = clampf(float(value), 0.0, 2.8)
        "vorticity": vorticity = clampf(float(value), 0.0, 2.8)
        "diffusion": diffusion = clampf(float(value), 0.0, 1.0)
        "viscosity": viscosity = clampf(float(value), 0.2, 2.0)
        "persistence": persistence = clampf(float(value), 0.88, 1.0)
        "source_rate": source_rate = clampf(float(value), 0.2, 2.4)
        "knife_angle": knife_angle = clampf(float(value), -1.57, 1.57)
        "chromaticity": chromaticity = clampf(float(value), 0.0, 1.0)
        "micro_detail": micro_detail = clampf(float(value), 0.0, 2.0)
        _: return
    _push_shader()


func _on_pointer_changed() -> void:
    if not pointer_down:
        return
    var gx := clampi(int(pointer_position.x / DESIGN_SIZE.x * float(GRID_X)), 2, GRID_X - 3)
    var gy := clampi(int(pointer_position.y / DESIGN_SIZE.y * float(GRID_Y)), 2, GRID_Y - 3)
    for oy: int in range(-3, 4):
        for ox: int in range(-3, 4):
            var d := Vector2(float(ox), float(oy))
            var dist := d.length()
            if dist > 3.4:
                continue
            var falloff := 1.0 - dist / 3.5
            var i := _idx(gx + ox, gy + oy)
            _density[i] = clampf(_density[i] + falloff * 0.16, 0.0, 1.0)
            _temperature[i] = clampf(_temperature[i] + falloff * 0.22, 0.0, 1.0)
            if dist > 0.2:
                var tangent := Vector2(-d.y, d.x).normalized()
                _vel_x[i] += tangent.x * falloff * 0.42
                _vel_y[i] += tangent.y * falloff * 0.42


func _update_source_simulation(delta: float) -> void:
    _accum += delta
    var steps := 0
    while _accum >= STEP_SECONDS and steps < 2:
        _simulate_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        steps += 1
    if steps > 0:
        _write_image()
        _state_texture.update(_state_image)
        _push_shader()


func _simulate_step(dt: float) -> void:
    for s: int in range(3):
        var sample_i := _idx(_source_x[s], GRID_Y - 5 - s)
        var quiet := 1.0 - clampf(_density[sample_i] * 1.7, 0.0, 1.0)
        _source_reservoir[s] += dt * source_rate * (0.16 + quiet * 0.22 + float(s) * 0.018)
        if _source_reservoir[s] > 1.0 and quiet > 0.28:
            _source_reservoir[s] = 0.08 + float(s) * 0.06
            _inject_plume(_source_x[s], GRID_Y - 4 - s, 0.46 + quiet * 0.34, 0.68 + quiet * 0.28, (float(s)-1.0)*0.12)

    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x,y)
            if x == 0 or y == 0 or x == GRID_X - 1 or y == GRID_Y - 1:
                _next_density[i] = 0.0
                _next_temperature[i] = 0.0
                _next_vel_x[i] = 0.0
                _next_vel_y[i] = 0.0
                continue

            var u := _vel_x[i]
            var v := _vel_y[i]
            var bx := clampi(int(round(float(x) - u * dt * 5.2)),1,GRID_X-2)
            var by := clampi(int(round(float(y) - v * dt * 5.2)),1,GRID_Y-2)
            var bi := _idx(bx,by)

            var d0 := _density[bi]
            var t0 := _temperature[bi]
            var u0 := _vel_x[bi]
            var v0 := _vel_y[bi]

            var left := _idx(x-1,y)
            var right := _idx(x+1,y)
            var up := _idx(x,y-1)
            var down := _idx(x,y+1)

            var avg_d := (_density[left]+_density[right]+_density[up]+_density[down])*0.25
            var avg_t := (_temperature[left]+_temperature[right]+_temperature[up]+_temperature[down])*0.25
            var avg_u := (_vel_x[left]+_vel_x[right]+_vel_x[up]+_vel_x[down])*0.25
            var avg_v := (_vel_y[left]+_vel_y[right]+_vel_y[up]+_vel_y[down])*0.25
            var curl := (_vel_y[right]-_vel_y[left]-(_vel_x[down]-_vel_x[up]))*0.5
            var grad_tx := (_temperature[right]-_temperature[left])*0.5
            var grad_ty := (_temperature[down]-_temperature[up])*0.5

            var next_u := lerpf(u0,avg_u,clampf(diffusion*0.18,0.0,0.25))
            var next_v := lerpf(v0,avg_v,clampf(diffusion*0.18,0.0,0.25))
            next_u += (-grad_tx*0.12 + curl*0.018*vorticity)*dt*30.0
            next_v += (-t0*0.065*buoyancy - grad_ty*0.035 - curl*0.014*vorticity)*dt*30.0
            var vel_decay := pow(0.965, viscosity)
            next_u *= vel_decay
            next_v *= vel_decay

            var next_d := lerpf(d0,avg_d,clampf(diffusion*0.24,0.0,0.32))*persistence
            var next_t := lerpf(t0,avg_t,clampf(diffusion*0.18,0.0,0.28))*lerpf(0.94,0.995,persistence)

            _next_density[i] = clampf(next_d,0.0,1.0)
            _next_temperature[i] = clampf(next_t,0.0,1.0)
            _next_vel_x[i] = clampf(next_u,-2.5,2.5)
            _next_vel_y[i] = clampf(next_v,-2.5,2.5)

    var td := _density; _density = _next_density; _next_density = td
    var tt := _temperature; _temperature = _next_temperature; _next_temperature = tt
    var tu := _vel_x; _vel_x = _next_vel_x; _next_vel_x = tu
    var tv := _vel_y; _vel_y = _next_vel_y; _next_vel_y = tv


func _inject_plume(x: int, y: int, density_amount: float, heat_amount: float, horizontal: float) -> void:
    for oy: int in range(-2,3):
        for ox: int in range(-2,3):
            var px := clampi(x+ox,1,GRID_X-2)
            var py := clampi(y+oy,1,GRID_Y-2)
            var dist := Vector2(float(ox),float(oy)).length()
            if dist > 2.7: continue
            var f := 1.0-dist/2.8
            var i := _idx(px,py)
            _density[i] = clampf(_density[i]+density_amount*f,0.0,1.0)
            _temperature[i] = clampf(_temperature[i]+heat_amount*f,0.0,1.0)
            _vel_x[i] += horizontal*f
            _vel_y[i] -= 0.25*f


func _write_image() -> void:
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x,y)
            _state_image.set_pixel(x,y,Color(_density[i],_temperature[i],clampf(0.5+_vel_x[i]*0.16,0.0,1.0),clampf(0.5+_vel_y[i]*0.16,0.0,1.0)))


func _push_shader() -> void:
    if not is_instance_valid(_surface) or _state_texture == null: return
    var material := _surface.material as ShaderMaterial
    if material == null: return
    material.set_shader_parameter("u_state",_state_texture)
    material.set_shader_parameter("u_texel",Vector2(1.0/float(GRID_X),1.0/float(GRID_Y)))
    material.set_shader_parameter("u_knife_angle",knife_angle)
    material.set_shader_parameter("u_chromaticity",chromaticity)
    material.set_shader_parameter("u_micro",micro_detail)


func _idx(x: int,y: int) -> int:
    return y*GRID_X+x


func _get_custom_live_sync_state() -> Dictionary:
    return {"density":_density.duplicate(),"temperature":_temperature.duplicate(),"vel_x":_vel_x.duplicate(),"vel_y":_vel_y.duplicate(),"reservoir":_source_reservoir.duplicate()}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("density",PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size()==GRID_X*GRID_Y: _density=(v as PackedFloat32Array).duplicate()
    v=state.get("temperature",PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size()==GRID_X*GRID_Y: _temperature=(v as PackedFloat32Array).duplicate()
    v=state.get("vel_x",PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size()==GRID_X*GRID_Y: _vel_x=(v as PackedFloat32Array).duplicate()
    v=state.get("vel_y",PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size()==GRID_X*GRID_Y: _vel_y=(v as PackedFloat32Array).duplicate()
    v=state.get("reservoir",PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size()==3: _source_reservoir=(v as PackedFloat32Array).duplicate()
    _write_image(); _state_texture.update(_state_image); _push_shader()


func _get_custom_live_debug_state() -> Dictionary:
    var mass := 0.0
    for d: float in _density: mass += d
    return {"density_mass":mass,"render_mode":"schlieren_full_resolution"}


func _draw() -> void:
    pass
