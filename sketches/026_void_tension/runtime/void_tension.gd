extends "res://sketches/_shared/design_sketch_base.gd"

const NODE_COUNT := 18
const FIELD_W := 96
const FIELD_H := 54
const BG := Color(0.012, 0.014, 0.020, 1.0)
const COLD := Color(0.065, 0.085, 0.12, 1.0)
const MID := Color(0.28, 0.43, 0.48, 1.0)
const HOT := Color(0.96, 0.56, 0.22, 1.0)

@export_range(0.2, 3.0, 0.01) var tension: float = 1.22
@export_range(0.1, 0.99, 0.01) var damping: float = 0.82
@export_range(0.0, 2.0, 0.01) var fold_strength: float = 0.72
@export_range(0.2, 2.0, 0.01) var stress_propagation: float = 0.88
@export_range(0.2, 2.5, 0.01) var fracture_threshold: float = 1.08
@export_range(0.05, 1.5, 0.01) var repair_rate: float = 0.42
@export_range(20.0, 180.0, 1.0) var cut_radius: float = 72.0
@export_range(0.2, 2.0, 0.01) var territory_contrast: float = 0.92

var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _rest_positions: Array[Vector2] = []
var _stress := PackedFloat32Array()
var _edges: Array[Dictionary] = []
var _field_image: Image
var _field_texture: ImageTexture
var _field_clock := 0.0
var _event_clock := 1.7
var _event_index := 0
var _last_pointer := Vector2.ZERO
var _pointer_velocity := Vector2.ZERO
var _cut_latch := false


func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _build_system()
    _refresh_field()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"tension", "label":"NETWORK TENSION", "type":"float", "min":0.2, "max":3.0, "step":0.01},
        {"id":"damping", "label":"INERTIA DAMPING", "type":"float", "min":0.1, "max":0.99, "step":0.01},
        {"id":"fold_strength", "label":"FOLD BIAS", "type":"float", "min":0.0, "max":2.0, "step":0.01},
        {"id":"stress_propagation", "label":"STRESS PROPAGATION", "type":"float", "min":0.2, "max":2.0, "step":0.01},
        {"id":"fracture_threshold", "label":"FRACTURE THRESHOLD", "type":"float", "min":0.2, "max":2.5, "step":0.01},
        {"id":"repair_rate", "label":"REPAIR RATE", "type":"float", "min":0.05, "max":1.5, "step":0.01},
        {"id":"cut_radius", "label":"CUT RADIUS", "type":"float", "min":20.0, "max":180.0, "step":1.0},
        {"id":"territory_contrast", "label":"TERRITORY CONTRAST", "type":"float", "min":0.2, "max":2.0, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "tension": return tension
        "damping": return damping
        "fold_strength": return fold_strength
        "stress_propagation": return stress_propagation
        "fracture_threshold": return fracture_threshold
        "repair_rate": return repair_rate
        "cut_radius": return cut_radius
        "territory_contrast": return territory_contrast
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "tension": tension = clampf(float(value), 0.2, 3.0)
        "damping": damping = clampf(float(value), 0.1, 0.99)
        "fold_strength": fold_strength = clampf(float(value), 0.0, 2.0)
        "stress_propagation": stress_propagation = clampf(float(value), 0.2, 2.0)
        "fracture_threshold": fracture_threshold = clampf(float(value), 0.2, 2.5)
        "repair_rate": repair_rate = clampf(float(value), 0.05, 1.5)
        "cut_radius": cut_radius = clampf(float(value), 20.0, 180.0)
        "territory_contrast": territory_contrast = clampf(float(value), 0.2, 2.0)
        _: return


func _build_system() -> void:
    if not _positions.is_empty():
        return
    _stress.resize(NODE_COUNT)
    _stress.fill(0.0)
    for i: int in range(NODE_COUNT):
        var col := i % 6
        var row := i / 6
        var x := 130.0 + float(col) * 205.0 + (_hash01(i * 11 + 3) - 0.5) * 92.0
        var y := 120.0 + float(row) * 235.0 + (_hash01(i * 17 + 7) - 0.5) * 118.0
        if row == 1:
            x += 58.0
        var p := Vector2(clampf(x, 72.0, 1208.0), clampf(y, 72.0, 648.0))
        _positions.append(p)
        _rest_positions.append(p)
        _velocities.append(Vector2.ZERO)

    var edge_keys: Dictionary = {}
    for i: int in range(NODE_COUNT):
        for pass_index: int in range(3):
            var best := -1
            var best_distance := INF
            for j: int in range(NODE_COUNT):
                if i == j:
                    continue
                var key := _edge_key(i, j)
                if edge_keys.has(key):
                    continue
                var d := _positions[i].distance_squared_to(_positions[j])
                if d < best_distance:
                    best_distance = d
                    best = j
            if best >= 0:
                var key := _edge_key(i, best)
                edge_keys[key] = true
                _edges.append({
                    "a": mini(i, best),
                    "b": maxi(i, best),
                    "rest": _positions[i].distance_to(_positions[best]),
                    "broken": 0.0,
                    "scar": 0.0,
                })

    _field_image = Image.create(FIELD_W, FIELD_H, false, Image.FORMAT_RGBA8)
    _field_texture = ImageTexture.create_from_image(_field_image)


func _update_source_simulation(delta: float) -> void:
    _build_system()
    var dt := minf(delta, 1.0 / 30.0)

    _pointer_velocity = (_pointer_velocity * 0.72) + ((pointer_position - _last_pointer) / maxf(delta, 0.001)) * 0.28
    _last_pointer = pointer_position

    if pointer_down:
        if not _cut_latch or _pointer_velocity.length() > 120.0:
            _cut_near(pointer_position)
        _cut_latch = true
    else:
        _cut_latch = false

    _event_clock -= delta
    if _event_clock <= 0.0:
        var node_index := int(_hash01(_event_index * 31 + 5) * float(NODE_COUNT - 1))
        _stress[node_index] = minf(2.2, _stress[node_index] + 0.48 + _hash01(_event_index * 43 + 9) * 0.54)
        _event_clock = 1.4 + _hash01(_event_index * 59 + 13) * 3.8
        _event_index += 1

    var forces: Array[Vector2] = []
    forces.resize(NODE_COUNT)
    for i: int in range(NODE_COUNT):
        var home := (_rest_positions[i] - _positions[i]) * (0.18 + tension * 0.12)
        var fold_axis := 430.0 + _hash01(i * 19 + 4) * 270.0
        var side := -1.0 if _positions[i].x < fold_axis else 1.0
        home.y += side * _stress[i] * fold_strength * 28.0
        forces[i] = home

    var next_stress := _stress.duplicate()
    for edge_index: int in range(_edges.size()):
        var edge: Dictionary = _edges[edge_index]
        var a := int(edge["a"])
        var b := int(edge["b"])
        var broken := float(edge["broken"])
        if broken > 0.0:
            broken = maxf(0.0, broken - dt * repair_rate)
            edge["broken"] = broken
            edge["scar"] = minf(1.0, float(edge["scar"]) + dt * 0.07)
            _edges[edge_index] = edge
            continue

        var delta_p := _positions[b] - _positions[a]
        var length := maxf(0.001, delta_p.length())
        var rest := float(edge["rest"])
        var stretch := (length - rest) / maxf(1.0, rest)
        var dir := delta_p / length
        var stiffness := tension * (1.0 - float(edge["scar"]) * 0.38)
        var force := dir * stretch * stiffness * 190.0
        forces[a] += force
        forces[b] -= force

        var transmitted := absf(stretch) * stress_propagation * 0.42
        next_stress[a] = maxf(next_stress[a], _stress[b] * 0.36 + transmitted)
        next_stress[b] = maxf(next_stress[b], _stress[a] * 0.36 + transmitted)

        if absf(stretch) * tension + maxf(_stress[a], _stress[b]) * 0.35 > fracture_threshold:
            edge["broken"] = 0.65 + float(edge["scar"]) * 0.8
            edge["scar"] = minf(1.0, float(edge["scar"]) + 0.16)
            _edges[edge_index] = edge
            next_stress[a] = minf(2.5, next_stress[a] + 0.36)
            next_stress[b] = minf(2.5, next_stress[b] + 0.36)

    for i: int in range(NODE_COUNT):
        next_stress[i] = maxf(0.0, next_stress[i] - dt * (0.18 + repair_rate * 0.10))
        _stress[i] = lerpf(_stress[i], next_stress[i], clampf(dt * (1.8 + stress_propagation), 0.0, 1.0))
        _velocities[i] = (_velocities[i] + forces[i] * dt) * pow(damping, dt * 60.0)
        _positions[i] += _velocities[i] * dt
        _positions[i].x = clampf(_positions[i].x, 54.0, 1226.0)
        _positions[i].y = clampf(_positions[i].y, 54.0, 666.0)

    _field_clock += delta
    if _field_clock >= 1.0 / 14.0:
        _field_clock = 0.0
        _refresh_field()


func _cut_near(point: Vector2) -> void:
    for edge_index: int in range(_edges.size()):
        var edge: Dictionary = _edges[edge_index]
        if float(edge["broken"]) > 0.0:
            continue
        var a := int(edge["a"])
        var b := int(edge["b"])
        var closest := Geometry2D.get_closest_point_to_segment(point, _positions[a], _positions[b])
        var d := point.distance_to(closest)
        if d > cut_radius:
            continue
        var force := clampf(1.0 - d / cut_radius, 0.0, 1.0)
        edge["broken"] = 0.8 + force * 1.2
        edge["scar"] = minf(1.0, float(edge["scar"]) + force * 0.22)
        _edges[edge_index] = edge
        _stress[a] = minf(2.5, _stress[a] + force * 0.8)
        _stress[b] = minf(2.5, _stress[b] + force * 0.8)
        var tangent := (_positions[b] - _positions[a]).orthogonal().normalized()
        _velocities[a] += tangent * force * 120.0
        _velocities[b] -= tangent * force * 120.0


func _refresh_field() -> void:
    if _field_image == null:
        return
    for y: int in range(FIELD_H):
        for x: int in range(FIELD_W):
            var p := Vector2((float(x) + 0.5) / float(FIELD_W) * 1280.0, (float(y) + 0.5) / float(FIELD_H) * 720.0)
            var nearest := -1
            var nearest_d := INF
            var second_d := INF
            for i: int in range(NODE_COUNT):
                var d := p.distance_squared_to(_positions[i])
                if d < nearest_d:
                    second_d = nearest_d
                    nearest_d = d
                    nearest = i
                elif d < second_d:
                    second_d = d
            var boundary := 1.0 - clampf((sqrt(second_d) - sqrt(nearest_d)) / 95.0, 0.0, 1.0)
            var stress_value := 0.0 if nearest < 0 else clampf(_stress[nearest] / 1.7, 0.0, 1.0)
            var base := COLD.lerp(MID, clampf(boundary * territory_contrast, 0.0, 1.0))
            var color := base.lerp(HOT, stress_value * (0.28 + boundary * 0.72))
            color.a = 0.72 + boundary * 0.28
            _field_image.set_pixel(x, y, color)
    _field_texture.update(_field_image)


func _draw() -> void:
    begin_design_draw(BG)
    if _field_texture != null:
        draw_texture_rect(_field_texture, Rect2(Vector2.ZERO, DESIGN_SIZE), false)

    for edge: Dictionary in _edges:
        var a := int(edge["a"])
        var b := int(edge["b"])
        var broken := float(edge["broken"])
        var stress_value := clampf((_stress[a] + _stress[b]) * 0.35, 0.0, 1.0)
        if broken > 0.0:
            var c := HOT
            c.a = 0.18 + stress_value * 0.28
            var mid := (_positions[a] + _positions[b]) * 0.5
            draw_line(_positions[a], mid.lerp(_positions[a], 0.15), c, 1.0)
            draw_line(_positions[b], mid.lerp(_positions[b], 0.15), c, 1.0)
        else:
            var c := Color(0.64, 0.78, 0.81, 0.18 + stress_value * 0.58)
            draw_line(_positions[a], _positions[b], c, 1.1 + stress_value * 1.7, true)

    for i: int in range(NODE_COUNT):
        var s := clampf(_stress[i] / 1.5, 0.0, 1.0)
        draw_circle(_positions[i], 2.4 + s * 4.8, MID.lerp(HOT, s))
    end_design_draw()


func _edge_key(a: int, b: int) -> String:
    return "%d:%d" % [mini(a, b), maxi(a, b)]


func _hash01(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "stress": _stress.duplicate(),
        "edges": _edges.duplicate(true),
        "event_clock": _event_clock,
        "event_index": _event_index,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var positions_variant: Variant = state.get("positions", [])
    if positions_variant is Array:
        _positions.assign(positions_variant as Array)
    var velocities_variant: Variant = state.get("velocities", [])
    if velocities_variant is Array:
        _velocities.assign(velocities_variant as Array)
    var stress_variant: Variant = state.get("stress", PackedFloat32Array())
    if stress_variant is PackedFloat32Array:
        _stress = (stress_variant as PackedFloat32Array).duplicate()
    var edges_variant: Variant = state.get("edges", [])
    if edges_variant is Array:
        _edges = (edges_variant as Array).duplicate(true)
    _event_clock = float(state.get("event_clock", _event_clock))
    _event_index = int(state.get("event_index", _event_index))
    _refresh_field()
