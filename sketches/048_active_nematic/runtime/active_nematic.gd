extends "res://sketches/_shared/design_sketch_base.gd"

const GRID_X: int = 40
const GRID_Y: int = 22
const CELL_COUNT: int = GRID_X * GRID_Y
const STEP_SECONDS: float = 1.0 / 30.0

@export_range(0.0, 2.8, 0.01) var activity: float = 1.08
@export_range(0.1, 3.0, 0.01) var alignment: float = 1.42
@export_range(0.0, 1.0, 0.01) var flow_memory: float = 0.72
@export_range(0.0, 2.2, 0.01) var defect_birth: float = 0.58
@export_range(0.2, 4.0, 0.01) var brush_twist: float = 1.72
@export_range(34.0, 250.0, 1.0) var brush_radius: float = 128.0
@export_range(5.0, 28.0, 0.5) var rod_length: float = 15.0
@export_range(0.0, 0.92, 0.01) var order_gate: float = 0.18

var _angles := PackedFloat32Array()
var _spin := PackedFloat32Array()
var _order := PackedFloat32Array()
var _next_angles := PackedFloat32Array()
var _next_spin := PackedFloat32Array()
var _positions := PackedVector2Array()
var _accum: float = 0.0
var _event_counter: int = 91
var _pointer_was_down: bool = false
var _last_pointer := Vector2.ZERO

var _field_root: Node2D
var _halo_instance: MultiMeshInstance2D
var _core_instance: MultiMeshInstance2D
var _halo_mesh: MultiMesh
var _core_mesh: MultiMesh


func _ready() -> void:
    _build_state()
    _build_multimesh()
    super._ready()
    _refresh_instances()


func reset_state() -> void:
    _angles.clear()
    _spin.clear()
    _order.clear()
    _next_angles.clear()
    _next_spin.clear()
    _positions.clear()
    _event_counter = 91
    _build_state()
    _refresh_instances()


func _build_state() -> void:
    if _angles.size() == CELL_COUNT:
        return
    _angles.resize(CELL_COUNT)
    _spin.resize(CELL_COUNT)
    _order.resize(CELL_COUNT)
    _next_angles.resize(CELL_COUNT)
    _next_spin.resize(CELL_COUNT)
    _positions.resize(CELL_COUNT)

    var margin := Vector2(48.0, 42.0)
    var span := DESIGN_SIZE - margin * 2.0
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x, y)
            var uv := Vector2(
                float(x) / float(GRID_X - 1),
                float(y) / float(GRID_Y - 1)
            )
            var jitter := Vector2(
                (_hash01i(i * 31 + 7) - 0.5) * 7.0,
                (_hash01i(i * 43 + 17) - 0.5) * 7.0
            )
            _positions[i] = margin + uv * span + jitter

            var p := uv - Vector2(0.46, 0.53)
            var base_angle := p.angle() * 0.5 + (_hash01i(i * 59 + 23) - 0.5) * 0.48
            if x > GRID_X / 2:
                base_angle += 0.72
            _angles[i] = base_angle
            _spin[i] = (_hash01i(i * 71 + 29) - 0.5) * 0.16
            _order[i] = 0.55


func _build_multimesh() -> void:
    if is_instance_valid(_field_root):
        return
    _field_root = Node2D.new()
    _field_root.name = "NematicField"
    add_child(_field_root)

    _halo_instance = MultiMeshInstance2D.new()
    _halo_instance.name = "Halo"
    _field_root.add_child(_halo_instance)
    _core_instance = MultiMeshInstance2D.new()
    _core_instance.name = "Core"
    _field_root.add_child(_core_instance)

    _halo_mesh = MultiMesh.new()
    _halo_mesh.transform_format = MultiMesh.TRANSFORM_2D
    _halo_mesh.use_colors = true
    _halo_mesh.instance_count = CELL_COUNT
    var halo_quad := QuadMesh.new()
    halo_quad.size = Vector2(3.4, 17.0)
    _halo_mesh.mesh = halo_quad
    _halo_instance.multimesh = _halo_mesh

    _core_mesh = MultiMesh.new()
    _core_mesh.transform_format = MultiMesh.TRANSFORM_2D
    _core_mesh.use_colors = true
    _core_mesh.instance_count = CELL_COUNT
    var core_quad := QuadMesh.new()
    core_quad.size = Vector2(1.05, 14.0)
    _core_mesh.mesh = core_quad
    _core_instance.multimesh = _core_mesh

    var halo_material := CanvasItemMaterial.new()
    halo_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    _halo_instance.material = halo_material
    _sync_field_transform()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"activity","label":"ACTIVITY","type":"float","min":0.0,"max":2.8,"step":0.01},
        {"id":"alignment","label":"ALIGNMENT","type":"float","min":0.1,"max":3.0,"step":0.01},
        {"id":"flow_memory","label":"FLOW MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"defect_birth","label":"DEFECT BIRTH","type":"float","min":0.0,"max":2.2,"step":0.01},
        {"id":"brush_twist","label":"BRUSH TWIST","type":"float","min":0.2,"max":4.0,"step":0.01},
        {"id":"brush_radius","label":"BRUSH RADIUS","type":"float","min":34.0,"max":250.0,"step":1.0},
        {"id":"rod_length","label":"FILAMENT LENGTH","type":"float","min":5.0,"max":28.0,"step":0.5},
        {"id":"order_gate","label":"ORDER GATE","type":"float","min":0.0,"max":0.92,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "activity": return activity
        "alignment": return alignment
        "flow_memory": return flow_memory
        "defect_birth": return defect_birth
        "brush_twist": return brush_twist
        "brush_radius": return brush_radius
        "rod_length": return rod_length
        "order_gate": return order_gate
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "activity": activity = clampf(float(value), 0.0, 2.8)
        "alignment": alignment = clampf(float(value), 0.1, 3.0)
        "flow_memory": flow_memory = clampf(float(value), 0.0, 1.0)
        "defect_birth": defect_birth = clampf(float(value), 0.0, 2.2)
        "brush_twist": brush_twist = clampf(float(value), 0.2, 4.0)
        "brush_radius": brush_radius = clampf(float(value), 34.0, 250.0)
        "rod_length": rod_length = clampf(float(value), 5.0, 28.0)
        "order_gate": order_gate = clampf(float(value), 0.0, 0.92)
        _: return
    _refresh_instances()


func _on_pointer_changed() -> void:
    if pointer_down:
        var gesture := Vector2.ZERO
        if _pointer_was_down:
            gesture = pointer_position - _last_pointer
        _apply_twist(pointer_position, gesture)
        _last_pointer = pointer_position
        _refresh_instances()
    _pointer_was_down = pointer_down


func _apply_twist(center: Vector2, gesture: Vector2) -> void:
    var gesture_sign := 1.0
    if gesture.length() > 2.0:
        gesture_sign = 1.0 if gesture.x - gesture.y * 0.45 >= 0.0 else -1.0
    for i: int in range(CELL_COUNT):
        var d := _positions[i] - center
        var distance := d.length()
        if distance >= brush_radius:
            continue
        var falloff := 1.0 - smoothstep(0.0, brush_radius, distance)
        var tangent_angle := d.angle() + PI * 0.5
        var current := _angles[i]
        var delta_angle := wrapf(tangent_angle - current, -PI * 0.5, PI * 0.5)
        _angles[i] = current + delta_angle * falloff * 0.42 * brush_twist
        _spin[i] += gesture_sign * falloff * brush_twist * 0.18


func _update_source_simulation(delta: float) -> void:
    _accum += delta
    var steps := 0
    while _accum >= STEP_SECONDS and steps < 2:
        _simulate_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        steps += 1
    _sync_field_transform()
    if steps > 0:
        _refresh_instances()


func _simulate_step(dt: float) -> void:
    _event_counter += 1
    var memory_damping := lerpf(5.0, 0.42, flow_memory)
    for y: int in range(GRID_Y):
        for x: int in range(GRID_X):
            var i := _idx(x, y)
            var cx := 0.0
            var cy := 0.0
            var neighbour_count := 0.0
            var spread := 0.0
            var a := _angles[i]
            for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
                var nx := clampi(x + offset.x, 0, GRID_X - 1)
                var ny := clampi(y + offset.y, 0, GRID_Y - 1)
                var na := _angles[_idx(nx, ny)]
                cx += cos(na * 2.0)
                cy += sin(na * 2.0)
                spread += absf(wrapf(na - a, -PI * 0.5, PI * 0.5))
                neighbour_count += 1.0

            var mean_angle := 0.5 * atan2(cy, cx)
            var order := clampf(Vector2(cx, cy).length() / maxf(1.0, neighbour_count), 0.0, 1.0)
            var align_delta := wrapf(mean_angle - a, -PI * 0.5, PI * 0.5)
            var local_stress := spread / maxf(1.0, neighbour_count)

            var spin := _spin[i]
            spin += align_delta * alignment * dt * 4.2
            spin += (local_stress - 0.28) * activity * dt * 0.84
            spin *= exp(-dt * memory_damping)

            if defect_birth > 0.0:
                var trigger := _hash01i(_event_counter * 977 + i * 43)
                if trigger < defect_birth * dt * 0.012:
                    var polarity := -1.0 if _hash01i(_event_counter * 383 + i * 17) < 0.5 else 1.0
                    spin += polarity * (0.8 + defect_birth * 0.9)

            _next_spin[i] = spin
            _next_angles[i] = a + spin * dt * (0.7 + activity * 0.72)
            _order[i] = lerpf(_order[i], order, clampf(dt * 3.4, 0.0, 1.0))

    var temp_angles := _angles
    _angles = _next_angles
    _next_angles = temp_angles
    var temp_spin := _spin
    _spin = _next_spin
    _next_spin = temp_spin


func _sync_field_transform() -> void:
    if not is_instance_valid(_field_root):
        return
    var transform_data := get_design_transform()
    var s := float(transform_data["scale"])
    _field_root.position = transform_data["origin"] as Vector2
    _field_root.scale = Vector2(s, s)


func _refresh_instances() -> void:
    if _halo_mesh == null or _core_mesh == null:
        return
    for i: int in range(CELL_COUNT):
        var order := _order[i]
        var visible := smoothstep(order_gate, minf(1.0, order_gate + 0.22), order)
        var spin_energy := clampf(absf(_spin[i]) * 0.55, 0.0, 1.0)
        var length_scale := rod_length / 14.0 * lerpf(0.62, 1.18, order)
        var transform := Transform2D(_angles[i] - PI * 0.5, Vector2(1.0, length_scale), 0.0, _positions[i])
        _halo_mesh.set_instance_transform_2d(i, transform)
        _core_mesh.set_instance_transform_2d(i, transform)

        var cool := Color(0.18, 0.82, 0.84, 0.62)
        var warm := Color(1.0, 0.46, 0.20, 0.94)
        var pale := Color(0.86, 0.94, 0.90, 0.88)
        var color := cool.lerp(pale, order).lerp(warm, spin_energy * 0.78)
        color.a *= visible
        var halo := color
        halo.a = 0.028 * visible * (0.35 + spin_energy)
        _halo_mesh.set_instance_color(i, halo)
        _core_mesh.set_instance_color(i, color)


func _draw() -> void:
    begin_design_draw(Color(0.008, 0.013, 0.015, 1.0))
    for band: int in range(9):
        var t := float(band) / 8.0
        draw_rect(Rect2(0.0, t * DESIGN_SIZE.y, DESIGN_SIZE.x, DESIGN_SIZE.y / 8.0 + 1.0), Color(0.008 + t * 0.006, 0.014 + t * 0.010, 0.017 + t * 0.012, 0.72), true)
    if pointer_down:
        draw_arc(pointer_position, brush_radius, 0.0, TAU, 72, Color(0.95, 0.58, 0.26, 0.16), 1.2, true)
    end_design_draw()


func _idx(x: int, y: int) -> int:
    return y * GRID_X + x


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "angles": _angles.duplicate(),
        "spin": _spin.duplicate(),
        "order": _order.duplicate(),
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("angles", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == CELL_COUNT: _angles = (v as PackedFloat32Array).duplicate()
    v = state.get("spin", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == CELL_COUNT: _spin = (v as PackedFloat32Array).duplicate()
    v = state.get("order", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == CELL_COUNT: _order = (v as PackedFloat32Array).duplicate()
    _event_counter = int(state.get("event_counter", _event_counter))
    _refresh_instances()


func _get_custom_live_debug_state() -> Dictionary:
    var mean_order := 0.0
    for value: float in _order:
        mean_order += value
    mean_order /= float(maxi(1, _order.size()))
    return {
        "mean_order": mean_order,
        "cell_count": CELL_COUNT,
        "render_mode": "multimesh_active_nematic",
    }
