extends "res://sketches/_shared/design_sketch_base.gd"

const MAX_MOTES := 900
const SAFE := Rect2(44.0, 36.0, 1192.0, 648.0)
const BG := Color(0.003, 0.006, 0.014, 1.0)
const COLD := Color(0.055, 0.34, 0.62, 0.76)
const HOT := Color(0.96, 0.73, 0.32, 0.94)
const CORE := Color(0.72, 0.94, 1.0, 0.96)

@export_range(0.1, 3.0, 0.01) var flow_strength: float = 1.18
@export_range(0.0, 2.5, 0.01) var attraction: float = 0.82
@export_range(0.1, 4.0, 0.01) var drag: float = 1.22
@export_range(0.2, 2.5, 0.01) var trail_length: float = 1.12
@export_range(280.0, 900.0, 1.0) var population: float = 720.0
@export_range(0.0, 1.0, 0.01) var chroma: float = 0.42
@export_range(0.1, 2.5, 0.01) var source_inertia: float = 0.72
@export_range(0.1, 3.0, 0.01) var touch_pull: float = 1.35

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _ages := PackedFloat32Array()
var _lifetimes := PackedFloat32Array()
var _charges := PackedFloat32Array()
var _respawn_count := PackedInt32Array()
var _source := Vector2(640.0, 360.0)
var _source_velocity := Vector2.ZERO
var _source_target := Vector2(830.0, 248.0)
var _source_index := 0
var _wake := 0.0
var _particle_root: Node2D
var _halo_instance: MultiMeshInstance2D
var _core_instance: MultiMeshInstance2D
var _halo_mesh: MultiMesh
var _core_mesh: MultiMesh


func _ready() -> void:
    super._ready()
    _build_particles()
    _build_multimeshes()
    _refresh_instances()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"flow_strength","label":"FIELD STRENGTH","type":"float","min":0.1,"max":3.0,"step":0.01},
        {"id":"attraction","label":"SOURCE GRAVITY","type":"float","min":0.0,"max":2.5,"step":0.01},
        {"id":"drag","label":"DRAG","type":"float","min":0.1,"max":4.0,"step":0.01},
        {"id":"trail_length","label":"STREAK LENGTH","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"population","label":"MOTE DENSITY","type":"int","min":280,"max":900,"step":1},
        {"id":"chroma","label":"SPECTRAL MIX","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"source_inertia","label":"SOURCE INERTIA","type":"float","min":0.1,"max":2.5,"step":0.01},
        {"id":"touch_pull","label":"TOUCH GRAVITY","type":"float","min":0.1,"max":3.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "flow_strength": return flow_strength
        "attraction": return attraction
        "drag": return drag
        "trail_length": return trail_length
        "population": return int(round(population))
        "chroma": return chroma
        "source_inertia": return source_inertia
        "touch_pull": return touch_pull
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "flow_strength": flow_strength = clampf(float(value), 0.1, 3.0)
        "attraction": attraction = clampf(float(value), 0.0, 2.5)
        "drag": drag = clampf(float(value), 0.1, 4.0)
        "trail_length": trail_length = clampf(float(value), 0.2, 2.5)
        "population": population = clampf(float(value), 280.0, 900.0)
        "chroma": chroma = clampf(float(value), 0.0, 1.0)
        "source_inertia": source_inertia = clampf(float(value), 0.1, 2.5)
        "touch_pull": touch_pull = clampf(float(value), 0.1, 3.0)
        _: return
    _refresh_visible_count()


func _build_particles() -> void:
    if _positions.size() == MAX_MOTES:
        return
    _positions.resize(MAX_MOTES)
    _velocities.resize(MAX_MOTES)
    _ages.resize(MAX_MOTES)
    _lifetimes.resize(MAX_MOTES)
    _charges.resize(MAX_MOTES)
    _respawn_count.resize(MAX_MOTES)

    for i: int in range(MAX_MOTES):
        var fx := _hash01(i * 31 + 7)
        var fy := _hash01(i * 47 + 19)
        _positions[i] = SAFE.position + Vector2(fx * SAFE.size.x, fy * SAFE.size.y)
        var angle := _hash01(i * 67 + 3) * TAU
        var speed := 12.0 + _hash01(i * 79 + 23) * 54.0
        _velocities[i] = Vector2(cos(angle), sin(angle)) * speed
        _lifetimes[i] = 5.0 + _hash01(i * 97 + 11) * 17.0
        _ages[i] = _hash01(i * 101 + 29) * _lifetimes[i]
        _charges[i] = _hash01(i * 131 + 37) * 2.0 - 1.0
        _respawn_count[i] = 0


func _build_multimeshes() -> void:
    if is_instance_valid(_particle_root):
        return

    _particle_root = Node2D.new()
    _particle_root.name = "ParticleField"
    add_child(_particle_root)

    _halo_instance = MultiMeshInstance2D.new()
    _halo_instance.name = "Halo"
    _particle_root.add_child(_halo_instance)
    _core_instance = MultiMeshInstance2D.new()
    _core_instance.name = "Core"
    _particle_root.add_child(_core_instance)

    _halo_mesh = MultiMesh.new()
    _halo_mesh.transform_format = MultiMesh.TRANSFORM_2D
    _halo_mesh.use_colors = true
    _halo_mesh.instance_count = MAX_MOTES
    var halo_quad := QuadMesh.new()
    halo_quad.size = Vector2(4.6, 18.0)
    _halo_mesh.mesh = halo_quad
    _halo_instance.multimesh = _halo_mesh

    _core_mesh = MultiMesh.new()
    _core_mesh.transform_format = MultiMesh.TRANSFORM_2D
    _core_mesh.use_colors = true
    _core_mesh.instance_count = MAX_MOTES
    var core_quad := QuadMesh.new()
    core_quad.size = Vector2(1.25, 10.0)
    _core_mesh.mesh = core_quad
    _core_instance.multimesh = _core_mesh

    var additive_halo := CanvasItemMaterial.new()
    additive_halo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    _halo_instance.material = additive_halo
    var additive_core := CanvasItemMaterial.new()
    additive_core.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    _core_instance.material = additive_core

    _refresh_visible_count()
    _sync_particle_root_transform()


func _refresh_visible_count() -> void:
    if _halo_mesh == null or _core_mesh == null:
        return
    var count := clampi(int(round(population)), 1, MAX_MOTES)
    _halo_mesh.visible_instance_count = count
    _core_mesh.visible_instance_count = count


func _sync_particle_root_transform() -> void:
    if not is_instance_valid(_particle_root):
        return
    var transform_data := get_design_transform()
    var s := float(transform_data["scale"])
    _particle_root.position = transform_data["origin"] as Vector2
    _particle_root.scale = Vector2(s, s)


func _on_pointer_changed() -> void:
    if pointer_down:
        _source_target = pointer_position.clamp(SAFE.position, SAFE.end)
        _wake = minf(1.0, _wake + 0.22)


func _update_source_simulation(delta: float) -> void:
    _build_particles()
    _build_multimeshes()

    var to_target := _source_target - _source
    if to_target.length() < 24.0 and not pointer_down:
        _source_index += 1
        _source_target = SAFE.position + Vector2(
            _hash01(_source_index * 83 + 17) * SAFE.size.x,
            _hash01(_source_index * 109 + 31) * SAFE.size.y
        )

    var spring := 0.35 + source_inertia * 0.52
    _source_velocity += to_target * spring * delta
    _source_velocity *= exp(-delta * (0.62 + source_inertia * 0.18))
    _source += _source_velocity * delta
    _source = _source.clamp(SAFE.position, SAFE.end)
    _wake = maxf(0.0, _wake - delta * 0.34)

    var count := clampi(int(round(population)), 1, MAX_MOTES)
    for i: int in range(count):
        var pos := _positions[i]
        var vel := _velocities[i]
        var charge := _charges[i]

        var spatial := Vector2(
            sin(pos.y * 0.0107 + charge * 2.7) + cos(pos.x * 0.0049 - charge),
            cos(pos.x * 0.0091 - charge * 2.1) - sin(pos.y * 0.0057 + charge)
        )
        var field := spatial * (18.0 + flow_strength * 33.0)

        var delta_source := _source - pos
        var distance := maxf(22.0, delta_source.length())
        var radial := delta_source / distance
        var tangent := Vector2(-radial.y, radial.x) * signf(charge if absf(charge) > 0.05 else 1.0)
        var gravity := radial * attraction * 7800.0 / distance
        var orbit := tangent * flow_strength * 2400.0 / sqrt(distance)
        var touch_boost := 1.0 + _wake * touch_pull * 0.9

        vel += (field + gravity + orbit * touch_boost) * delta
        vel *= exp(-delta * drag * 0.58)
        var max_speed := 170.0 + flow_strength * 110.0
        if vel.length() > max_speed:
            vel = vel.normalized() * max_speed
        pos += vel * delta

        _ages[i] += delta
        var outside := pos.x < SAFE.position.x - 70.0 or pos.x > SAFE.end.x + 70.0 or pos.y < SAFE.position.y - 70.0 or pos.y > SAFE.end.y + 70.0
        if outside or _ages[i] >= _lifetimes[i]:
            _respawn_particle(i)
        else:
            _positions[i] = pos
            _velocities[i] = vel

    _sync_particle_root_transform()
    _refresh_instances()


func _respawn_particle(i: int) -> void:
    _respawn_count[i] += 1
    var r := _respawn_count[i]
    var angle := _hash01(i * 211 + r * 37 + 5) * TAU
    var radius := 36.0 + _hash01(i * 223 + r * 41 + 13) * 240.0
    _positions[i] = (_source + Vector2(cos(angle), sin(angle)) * radius).clamp(SAFE.position, SAFE.end)
    var tangent := Vector2(-sin(angle), cos(angle))
    _velocities[i] = tangent * (24.0 + _hash01(i * 227 + r * 53 + 17) * 92.0)
    _lifetimes[i] = 5.5 + _hash01(i * 229 + r * 61 + 23) * 18.0
    _ages[i] = 0.0
    _charges[i] = _hash01(i * 233 + r * 67 + 29) * 2.0 - 1.0


func _refresh_instances() -> void:
    if _halo_mesh == null or _core_mesh == null:
        return
    var count := clampi(int(round(population)), 1, MAX_MOTES)
    for i: int in range(count):
        var vel := _velocities[i]
        var speed := vel.length()
        var life := clampf(_ages[i] / maxf(0.01, _lifetimes[i]), 0.0, 1.0)
        var fade := smoothstep(0.0, 0.12, life) * (1.0 - smoothstep(0.76, 1.0, life))
        var angle := vel.angle() - PI * 0.5
        var length_scale := (0.48 + speed / 150.0) * trail_length
        var width_scale := 0.58 + (1.0 - fade) * 0.14
        var transform := Transform2D(angle, Vector2(width_scale, length_scale), 0.0, _positions[i])
        _halo_mesh.set_instance_transform_2d(i, transform)
        _core_mesh.set_instance_transform_2d(i, transform)

        var spectral := clampf((_charges[i] * 0.5 + 0.5) * chroma + speed / 420.0, 0.0, 1.0)
        var color := COLD.lerp(HOT, spectral).lerp(CORE, clampf(speed / 260.0, 0.0, 0.52))
        var halo := color
        halo.a = 0.055 * fade
        color.a = (0.20 + minf(0.68, speed / 280.0)) * fade
        _halo_mesh.set_instance_color(i, halo)
        _core_mesh.set_instance_color(i, color)


func _draw() -> void:
    begin_design_draw(BG)
    # A quiet depth field gives the luminous motes a material darkness to cut
    # through without drawing debug grids or decorative UI chrome.
    for band: int in range(12):
        var t := float(band) / 11.0
        var y := t * DESIGN_SIZE.y
        var c := Color(0.006 + t * 0.006, 0.010 + t * 0.012, 0.021 + t * 0.020, 0.34)
        draw_rect(Rect2(0.0, y, DESIGN_SIZE.x, DESIGN_SIZE.y / 11.0 + 1.0), c, true)
    end_design_draw()


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "ages": _ages.duplicate(),
        "lifetimes": _lifetimes.duplicate(),
        "charges": _charges.duplicate(),
        "respawn_count": _respawn_count.duplicate(),
        "source": _source,
        "source_velocity": _source_velocity,
        "source_target": _source_target,
        "source_index": _source_index,
        "wake": _wake,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == MAX_MOTES:
        _positions = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == MAX_MOTES:
        _velocities = (v as PackedVector2Array).duplicate()
    v = state.get("ages", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_MOTES:
        _ages = (v as PackedFloat32Array).duplicate()
    v = state.get("lifetimes", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_MOTES:
        _lifetimes = (v as PackedFloat32Array).duplicate()
    v = state.get("charges", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_MOTES:
        _charges = (v as PackedFloat32Array).duplicate()
    v = state.get("respawn_count", PackedInt32Array())
    if v is PackedInt32Array and (v as PackedInt32Array).size() == MAX_MOTES:
        _respawn_count = (v as PackedInt32Array).duplicate()
    var p: Variant = state.get("source", _source)
    if p is Vector2: _source = p as Vector2
    p = state.get("source_velocity", _source_velocity)
    if p is Vector2: _source_velocity = p as Vector2
    p = state.get("source_target", _source_target)
    if p is Vector2: _source_target = p as Vector2
    _source_index = int(state.get("source_index", _source_index))
    _wake = float(state.get("wake", _wake))
    _refresh_instances()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "visible_motes": int(round(population)),
        "source": _source,
        "wake": _wake,
        "render_mode": "multimesh_streak_field",
    }
