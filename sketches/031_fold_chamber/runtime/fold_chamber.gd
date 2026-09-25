extends "res://sketches/_shared/design_sketch_base.gd"

const GRID_X := 15
const GRID_Y := 10
const POINT_COUNT := GRID_X * GRID_Y
const SAFE := Rect2(74.0, 52.0, 1132.0, 616.0)
const BG := Color(0.006, 0.008, 0.012, 1.0)
const LOW := Color(0.035, 0.055, 0.072, 1.0)
const MID := Color(0.22, 0.30, 0.34, 1.0)
const HIGH := Color(0.91, 0.82, 0.66, 1.0)

@export_range(0.2, 2.5, 0.01) var relief_depth: float = 1.25
@export_range(0.2, 3.0, 0.01) var stiffness: float = 1.18
@export_range(0.02, 0.95, 0.01) var damping: float = 0.31
@export_range(0.1, 2.5, 0.01) var coupling: float = 1.05
@export_range(0.2, 2.2, 0.01) var facet_contrast: float = 1.22
@export_range(0.0, 1.0, 0.01) var metallic_warmth: float = 0.34
@export_range(0.1, 3.0, 0.01) var touch_force: float = 1.45
@export_range(25.0, 220.0, 1.0) var touch_radius: float = 104.0

var _base := PackedVector2Array()
var _height := PackedFloat32Array()
var _velocity := PackedFloat32Array()
var _stress := PackedFloat32Array()
var _next_height := PackedFloat32Array()
var _next_velocity := PackedFloat32Array()
var _triangles := PackedInt32Array()
var _neighbors: Array = []
var _load_pos := Vector2(0.68, 0.36)
var _load_target := Vector2(0.68, 0.36)
var _load_energy := 0.8
var _load_index := 0
var _last_pointer := Vector2(640.0, 360.0)
var _gesture_velocity := Vector2.ZERO


func _ready() -> void:
    super._ready()
    _build_mesh()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"relief_depth","label":"RELIEF DEPTH","type":"float","min":0.2,"max":2.5,"step":0.01},
        {"id":"stiffness","label":"SURFACE STIFFNESS","type":"float","min":0.2,"max":3.0,"step":0.01},
        {"id":"damping","label":"DAMPING","type":"float","min":0.02,"max":0.95,"step":0.01},
        {"id":"coupling","label":"NEIGHBOUR COUPLING","type":"float","min":0.1,"max":2.5,"step":0.01},
        {"id":"facet_contrast","label":"FACET CONTRAST","type":"float","min":0.2,"max":2.2,"step":0.01},
        {"id":"metallic_warmth","label":"METAL WARMTH","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"touch_force","label":"PRESSURE FORCE","type":"float","min":0.1,"max":3.0,"step":0.01},
        {"id":"touch_radius","label":"PRESSURE RADIUS","type":"float","min":25.0,"max":220.0,"step":1.0},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "relief_depth": return relief_depth
        "stiffness": return stiffness
        "damping": return damping
        "coupling": return coupling
        "facet_contrast": return facet_contrast
        "metallic_warmth": return metallic_warmth
        "touch_force": return touch_force
        "touch_radius": return touch_radius
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "relief_depth": relief_depth = clampf(float(value), 0.2, 2.5)
        "stiffness": stiffness = clampf(float(value), 0.2, 3.0)
        "damping": damping = clampf(float(value), 0.02, 0.95)
        "coupling": coupling = clampf(float(value), 0.1, 2.5)
        "facet_contrast": facet_contrast = clampf(float(value), 0.2, 2.2)
        "metallic_warmth": metallic_warmth = clampf(float(value), 0.0, 1.0)
        "touch_force": touch_force = clampf(float(value), 0.1, 3.0)
        "touch_radius": touch_radius = clampf(float(value), 25.0, 220.0)
        _: return


func _build_mesh() -> void:
    if _base.size() == POINT_COUNT:
        return
    _base.resize(POINT_COUNT)
    _height.resize(POINT_COUNT)
    _velocity.resize(POINT_COUNT)
    _stress.resize(POINT_COUNT)
    _next_height.resize(POINT_COUNT)
    _next_velocity.resize(POINT_COUNT)
    _height.fill(0.0)
    _velocity.fill(0.0)
    _stress.fill(0.0)

    var index := 0
    for gy: int in range(GRID_Y):
        for gx: int in range(GRID_X):
            var fx := float(gx) / float(GRID_X - 1)
            var fy := float(gy) / float(GRID_Y - 1)
            var edge := gx == 0 or gx == GRID_X - 1 or gy == 0 or gy == GRID_Y - 1
            var jitter_x := 0.0 if edge else (_hash01(index * 17 + 3) - 0.5) * 0.052
            var jitter_y := 0.0 if edge else (_hash01(index * 29 + 11) - 0.5) * 0.070
            _base[index] = SAFE.position + Vector2(
                clampf(fx + jitter_x, 0.0, 1.0) * SAFE.size.x,
                clampf(fy + jitter_y, 0.0, 1.0) * SAFE.size.y
            )
            index += 1

    _triangles = Geometry2D.triangulate_delaunay(_base)
    _neighbors.clear()
    for _i: int in range(POINT_COUNT):
        _neighbors.append(PackedInt32Array())

    var seen: Dictionary = {}
    for t: int in range(0, _triangles.size(), 3):
        _add_edge(_triangles[t], _triangles[t + 1], seen)
        _add_edge(_triangles[t + 1], _triangles[t + 2], seen)
        _add_edge(_triangles[t + 2], _triangles[t], seen)

    _inject_pressure(Vector2(360.0, 258.0), 128.0, 0.62)
    _inject_pressure(Vector2(868.0, 472.0), 168.0, -0.48)


func _add_edge(a: int, b: int, seen: Dictionary) -> void:
    var lo := mini(a, b)
    var hi := maxi(a, b)
    var key := lo * 4096 + hi
    if seen.has(key):
        return
    seen[key] = true
    var na: PackedInt32Array = _neighbors[a]
    var nb: PackedInt32Array = _neighbors[b]
    na.append(b)
    nb.append(a)
    _neighbors[a] = na
    _neighbors[b] = nb


func _on_pointer_changed() -> void:
    var delta_pos := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pos, 0.34)
    _last_pointer = pointer_position
    if pointer_down:
        var sign_value := -1.0 if _gesture_velocity.y > 0.0 else 1.0
        _inject_pressure(pointer_position, touch_radius, touch_force * sign_value * 0.16)


func _inject_pressure(point: Vector2, radius: float, impulse: float) -> void:
    if _base.is_empty():
        return
    for i: int in range(_base.size()):
        var d := _base[i].distance_to(point)
        if d >= radius:
            continue
        var w := 1.0 - d / maxf(1.0, radius)
        w = w * w * (3.0 - 2.0 * w)
        _velocity[i] += impulse * w
        _height[i] += impulse * w * 0.12


func _update_source_simulation(delta: float) -> void:
    _build_mesh()

    var load_distance := _load_pos.distance_to(_load_target)
    if load_distance < 0.025:
        _load_index += 1
        _load_target = Vector2(
            0.12 + _hash01(_load_index * 31 + 5) * 0.76,
            0.10 + _hash01(_load_index * 47 + 13) * 0.80
        )
        _load_energy = 0.36 + _hash01(_load_index * 59 + 7) * 0.64
    _load_pos = _load_pos.lerp(_load_target, clampf(delta * (0.12 + _load_energy * 0.22), 0.0, 1.0))
    _load_energy = maxf(0.16, _load_energy - delta * 0.025)

    var auto_point := SAFE.position + _load_pos * SAFE.size
    _inject_pressure(auto_point, 118.0 + _load_energy * 110.0, _load_energy * delta * 0.72)

    for i: int in range(POINT_COUNT):
        var ns: PackedInt32Array = _neighbors[i]
        var average := _height[i]
        if not ns.is_empty():
            average = 0.0
            for j: int in ns:
                average += _height[j]
            average /= float(ns.size())

        var lap := average - _height[i]
        _stress[i] = lerpf(_stress[i], absf(lap), clampf(delta * 4.0, 0.0, 1.0))
        var restoring := -_height[i] * stiffness
        var coupled := lap * coupling * 7.0
        var acceleration := restoring + coupled
        var v := _velocity[i] + acceleration * delta
        v *= exp(-damping * delta * 4.8)
        _next_velocity[i] = v
        _next_height[i] = clampf(_height[i] + v * delta, -1.8, 1.8)

    var temp_h := _height
    _height = _next_height
    _next_height = temp_h
    var temp_v := _velocity
    _velocity = _next_velocity
    _next_velocity = temp_v
    _gesture_velocity *= exp(-delta * 6.0)


func _project_point(index: int) -> Vector2:
    var h := _height[index] * relief_depth
    var p := _base[index]
    return p + Vector2(h * 15.0, -h * 38.0)


func _draw() -> void:
    begin_design_draw(BG)
    if _triangles.is_empty():
        end_design_draw()
        return

    var light_angle := -0.72 + metallic_warmth * 0.48
    var light := Vector3(cos(light_angle), -0.62, sin(light_angle) + 1.15).normalized()

    for t: int in range(0, _triangles.size(), 3):
        var ia := _triangles[t]
        var ib := _triangles[t + 1]
        var ic := _triangles[t + 2]
        var pa := _project_point(ia)
        var pb := _project_point(ib)
        var pc := _project_point(ic)

        var a3 := Vector3(_base[ia].x / 180.0, _base[ia].y / 180.0, _height[ia] * relief_depth)
        var b3 := Vector3(_base[ib].x / 180.0, _base[ib].y / 180.0, _height[ib] * relief_depth)
        var c3 := Vector3(_base[ic].x / 180.0, _base[ic].y / 180.0, _height[ic] * relief_depth)
        var normal := (b3 - a3).cross(c3 - a3).normalized()
        if normal.z < 0.0:
            normal = -normal
        var diffuse := clampf(normal.dot(light) * 0.5 + 0.5, 0.0, 1.0)
        diffuse = pow(diffuse, facet_contrast)
        var local_stress := clampf((_stress[ia] + _stress[ib] + _stress[ic]) * 2.4, 0.0, 1.0)
        var base_color := LOW.lerp(MID, diffuse)
        var warm := Color(0.58, 0.37, 0.23, 1.0).lerp(HIGH, diffuse)
        var color := base_color.lerp(warm, metallic_warmth * (0.18 + local_stress * 0.46))
        color = color.lerp(HIGH, local_stress * 0.16)
        draw_colored_polygon(PackedVector2Array([pa, pb, pc]), color)

    # Hairline triangulation and stressed seams create a second detail scale.
    var drawn: Dictionary = {}
    for t: int in range(0, _triangles.size(), 3):
        var ids := [_triangles[t], _triangles[t + 1], _triangles[t + 2]]
        for e: int in range(3):
            var a: int = ids[e]
            var b: int = ids[(e + 1) % 3]
            var lo := mini(a, b)
            var hi := maxi(a, b)
            var key := lo * 4096 + hi
            if drawn.has(key):
                continue
            drawn[key] = true
            var seam := clampf((_stress[a] + _stress[b]) * 3.0, 0.0, 1.0)
            draw_line(_project_point(a), _project_point(b), Color(0.02, 0.025, 0.03, 0.50 + seam * 0.22), 1.0, true)
            if seam > 0.16:
                draw_line(_project_point(a), _project_point(b), HIGH * Color(1.0, 1.0, 1.0, seam * 0.23), 0.55, true)

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
        "stress": _stress.duplicate(),
        "load_pos": _load_pos,
        "load_target": _load_target,
        "load_energy": _load_energy,
        "load_index": _load_index,
        "last_pointer": _last_pointer,
        "gesture_velocity": _gesture_velocity,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("height", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == POINT_COUNT:
        _height = (v as PackedFloat32Array).duplicate()
        _next_height.resize(POINT_COUNT)
    v = state.get("velocity", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == POINT_COUNT:
        _velocity = (v as PackedFloat32Array).duplicate()
        _next_velocity.resize(POINT_COUNT)
    v = state.get("stress", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == POINT_COUNT:
        _stress = (v as PackedFloat32Array).duplicate()
    var p: Variant = state.get("load_pos", _load_pos)
    if p is Vector2: _load_pos = p as Vector2
    p = state.get("load_target", _load_target)
    if p is Vector2: _load_target = p as Vector2
    _load_energy = float(state.get("load_energy", _load_energy))
    _load_index = int(state.get("load_index", _load_index))
    p = state.get("last_pointer", _last_pointer)
    if p is Vector2: _last_pointer = p as Vector2
    p = state.get("gesture_velocity", _gesture_velocity)
    if p is Vector2: _gesture_velocity = p as Vector2


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "point_count": POINT_COUNT,
        "triangle_count": int(_triangles.size() / 3),
        "load_energy": _load_energy,
    }
