extends "res://sketches/_shared/design_sketch_base.gd"

const MAX_FILINGS: int = 1100
const MAX_POLES: int = 4
const SAFE := Rect2(58.0, 48.0, 1164.0, 624.0)

@export_range(2.0, 4.0, 1.0) var pole_count: float = 3.0
@export_range(0.2, 4.0, 0.01) var field_strength: float = 1.42
@export_range(0.1, 4.0, 0.01) var align_response: float = 1.28
@export_range(0.0, 1.0, 0.01) var hysteresis: float = 0.72
@export_range(300.0, 1100.0, 1.0) var filing_density: float = 920.0
@export_range(4.0, 24.0, 0.5) var filing_length: float = 12.5
@export_range(0.0, 1.5, 0.01) var pole_drift: float = 0.28
@export_range(0.0, 1.0, 0.01) var drag_inertia: float = 0.62

var _positions := PackedVector2Array()
var _angles := PackedFloat32Array()
var _angular_velocity := PackedFloat32Array()
var _chain := PackedFloat32Array()

var _poles := PackedVector2Array([
    Vector2(330.0, 258.0),
    Vector2(912.0, 238.0),
    Vector2(708.0, 520.0),
    Vector2(1030.0, 520.0),
])
var _pole_targets := PackedVector2Array([
    Vector2(300.0, 230.0),
    Vector2(940.0, 278.0),
    Vector2(650.0, 546.0),
    Vector2(1040.0, 494.0),
])
var _pole_velocities := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _polarities := PackedFloat32Array([1.0, -1.0, 1.0, -1.0])
var _grabbed: int = -1
var _pointer_was_down: bool = false
var _last_pointer := Vector2.ZERO
var _target_timer: float = 2.8
var _event_counter: int = 73

var _root: Node2D
var _shadow_instance: MultiMeshInstance2D
var _core_instance: MultiMeshInstance2D
var _shadow_mesh: MultiMesh
var _core_mesh: MultiMesh


func _ready() -> void:
    _build_filings()
    _build_multimeshes()
    super._ready()
    _refresh_instances()


func reset_state() -> void:
    _angles.clear()
    _angular_velocity.clear()
    _chain.clear()
    _positions.clear()
    _poles = PackedVector2Array([
        Vector2(330.0, 258.0), Vector2(912.0, 238.0), Vector2(708.0, 520.0), Vector2(1030.0, 520.0)
    ])
    _pole_targets = PackedVector2Array([
        Vector2(300.0, 230.0), Vector2(940.0, 278.0), Vector2(650.0, 546.0), Vector2(1040.0, 494.0)
    ])
    _pole_velocities = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
    _event_counter = 73
    _target_timer = 2.8
    _build_filings()
    _refresh_instances()


func _build_filings() -> void:
    if _positions.size() == MAX_FILINGS:
        return
    _positions.resize(MAX_FILINGS)
    _angles.resize(MAX_FILINGS)
    _angular_velocity.resize(MAX_FILINGS)
    _chain.resize(MAX_FILINGS)
    for i: int in range(MAX_FILINGS):
        _positions[i] = SAFE.position + Vector2(
            _hash01i(i * 61 + 7) * SAFE.size.x,
            _hash01i(i * 103 + 17) * SAFE.size.y
        )
        _angles[i] = (_hash01i(i * 131 + 29) - 0.5) * PI
        _angular_velocity[i] = 0.0
        _chain[i] = 0.0


func _build_multimeshes() -> void:
    if is_instance_valid(_root):
        return
    _root = Node2D.new()
    _root.name = "FilingField"
    add_child(_root)

    _shadow_instance = MultiMeshInstance2D.new()
    _shadow_instance.name = "Shadow"
    _root.add_child(_shadow_instance)
    _core_instance = MultiMeshInstance2D.new()
    _core_instance.name = "Core"
    _root.add_child(_core_instance)

    _shadow_mesh = MultiMesh.new()
    _shadow_mesh.transform_format = MultiMesh.TRANSFORM_2D
    _shadow_mesh.use_colors = true
    _shadow_mesh.instance_count = MAX_FILINGS
    var shadow_quad := QuadMesh.new()
    shadow_quad.size = Vector2(2.5, 14.0)
    _shadow_mesh.mesh = shadow_quad
    _shadow_instance.multimesh = _shadow_mesh

    _core_mesh = MultiMesh.new()
    _core_mesh.transform_format = MultiMesh.TRANSFORM_2D
    _core_mesh.use_colors = true
    _core_mesh.instance_count = MAX_FILINGS
    var core_quad := QuadMesh.new()
    core_quad.size = Vector2(1.15, 12.0)
    _core_mesh.mesh = core_quad
    _core_instance.multimesh = _core_mesh

    _refresh_visible_count()
    _sync_root_transform()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"pole_count","label":"POLE COUNT","type":"int","min":2,"max":4,"step":1},
        {"id":"field_strength","label":"FIELD STRENGTH","type":"float","min":0.2,"max":4.0,"step":0.01},
        {"id":"align_response","label":"ALIGN RESPONSE","type":"float","min":0.1,"max":4.0,"step":0.01},
        {"id":"hysteresis","label":"MAGNETIC MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"filing_density","label":"FILING COUNT","type":"int","min":300,"max":1100,"step":1},
        {"id":"filing_length","label":"FILING LENGTH","type":"float","min":4.0,"max":24.0,"step":0.5},
        {"id":"pole_drift","label":"POLE DRIFT","type":"float","min":0.0,"max":1.5,"step":0.01},
        {"id":"drag_inertia","label":"DRAG INERTIA","type":"float","min":0.0,"max":1.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "pole_count": return int(round(pole_count))
        "field_strength": return field_strength
        "align_response": return align_response
        "hysteresis": return hysteresis
        "filing_density": return int(round(filing_density))
        "filing_length": return filing_length
        "pole_drift": return pole_drift
        "drag_inertia": return drag_inertia
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "pole_count": pole_count = clampf(float(value), 2.0, 4.0)
        "field_strength": field_strength = clampf(float(value), 0.2, 4.0)
        "align_response": align_response = clampf(float(value), 0.1, 4.0)
        "hysteresis": hysteresis = clampf(float(value), 0.0, 1.0)
        "filing_density": filing_density = clampf(float(value), 300.0, 1100.0)
        "filing_length": filing_length = clampf(float(value), 4.0, 24.0)
        "pole_drift": pole_drift = clampf(float(value), 0.0, 1.5)
        "drag_inertia": drag_inertia = clampf(float(value), 0.0, 1.0)
        _: return
    _refresh_visible_count()
    _refresh_instances()
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down and not _pointer_was_down:
        _grabbed = _nearest_pole(pointer_position, 96.0)
        _last_pointer = pointer_position
    elif pointer_down and _grabbed >= 0:
        var delta := pointer_position - _last_pointer
        _poles[_grabbed] = pointer_position.clamp(SAFE.position, SAFE.end)
        _pole_targets[_grabbed] = _poles[_grabbed]
        _pole_velocities[_grabbed] = delta * lerpf(2.0, 11.0, drag_inertia)
        _last_pointer = pointer_position
    elif not pointer_down and _pointer_was_down:
        if _grabbed >= 0:
            _pole_targets[_grabbed] = (_poles[_grabbed] + _pole_velocities[_grabbed] * 0.15 * drag_inertia).clamp(SAFE.position, SAFE.end)
        _grabbed = -1
    _pointer_was_down = pointer_down


func _nearest_pole(position: Vector2, radius: float) -> int:
    var active_count := clampi(int(round(pole_count)), 2, MAX_POLES)
    var best := -1
    var best_distance := radius
    for i: int in range(active_count):
        var distance := position.distance_to(_poles[i])
        if distance < best_distance:
            best_distance = distance
            best = i
    return best


func _update_source_simulation(delta: float) -> void:
    _target_timer -= delta
    if _target_timer <= 0.0:
        _event_counter += 1
        _target_timer = 2.2 + _hash01i(_event_counter * 47 + 7) * 4.8
        var active_count := clampi(int(round(pole_count)), 2, MAX_POLES)
        var index := _event_counter % active_count
        if index != _grabbed:
            var amount := 160.0 * pole_drift
            _pole_targets[index] = (_poles[index] + Vector2(
                (_hash01i(_event_counter * 67 + 13) - 0.5) * amount * 2.0,
                (_hash01i(_event_counter * 83 + 19) - 0.5) * amount * 1.4
            )).clamp(SAFE.position, SAFE.end)

    var active_poles := clampi(int(round(pole_count)), 2, MAX_POLES)
    for p: int in range(active_poles):
        if p == _grabbed:
            continue
        var velocity := _pole_velocities[p]
        velocity += (_pole_targets[p] - _poles[p]) * delta * (0.18 + pole_drift * 0.32)
        velocity *= exp(-delta * lerpf(2.8, 0.62, drag_inertia))
        _poles[p] = (_poles[p] + velocity * delta).clamp(SAFE.position, SAFE.end)
        _pole_velocities[p] = velocity

    var count := clampi(int(round(filing_density)), 1, MAX_FILINGS)
    var response := 1.3 + align_response * 3.2
    var memory_damping := lerpf(9.0, 0.44, hysteresis)
    for i: int in range(count):
        var field := Vector2.ZERO
        var field_magnitude := 0.0
        var pos := _positions[i]
        for p: int in range(active_poles):
            var d := pos - _poles[p]
            var distance := maxf(22.0, d.length())
            var direction := d / distance
            var contribution := _polarities[p] * field_strength * 16500.0 / (distance * distance)
            field += direction * contribution
            field_magnitude += absf(contribution)

        if field.length() < 0.0001:
            continue
        var target_angle := field.angle()
        var current := _angles[i]
        var delta_angle := wrapf(target_angle - current, -PI * 0.5, PI * 0.5)
        var angular_velocity := _angular_velocity[i]
        angular_velocity += delta_angle * response * delta
        angular_velocity *= exp(-delta * memory_damping)
        current += angular_velocity * delta * (1.0 + align_response)

        var chain_target := clampf(field_magnitude * 0.64, 0.0, 1.0)
        var chain_rate := lerpf(7.0, 0.8, hysteresis) if chain_target < _chain[i] else 5.0
        _chain[i] = lerpf(_chain[i], chain_target, clampf(delta * chain_rate, 0.0, 1.0))
        _angles[i] = current
        _angular_velocity[i] = angular_velocity

    _sync_root_transform()
    _refresh_instances()
    queue_redraw()


func _sync_root_transform() -> void:
    if not is_instance_valid(_root):
        return
    var transform_data := get_design_transform()
    var scale_value := float(transform_data["scale"])
    _root.position = transform_data["origin"] as Vector2
    _root.scale = Vector2(scale_value, scale_value)


func _refresh_visible_count() -> void:
    if _shadow_mesh == null or _core_mesh == null:
        return
    var count := clampi(int(round(filing_density)), 1, MAX_FILINGS)
    _shadow_mesh.visible_instance_count = count
    _core_mesh.visible_instance_count = count


func _refresh_instances() -> void:
    if _shadow_mesh == null or _core_mesh == null:
        return
    var count := clampi(int(round(filing_density)), 1, MAX_FILINGS)
    for i: int in range(count):
        var chain := _chain[i]
        var length_scale := filing_length / 12.0 * lerpf(0.68, 1.72, chain)
        var core_transform := Transform2D(_angles[i] - PI * 0.5, Vector2(1.0, length_scale), 0.0, _positions[i])
        var shadow_transform := Transform2D(_angles[i] - PI * 0.5, Vector2(1.0, length_scale * 1.06), 0.0, _positions[i] + Vector2(1.8, 2.1))
        _core_mesh.set_instance_transform_2d(i, core_transform)
        _shadow_mesh.set_instance_transform_2d(i, shadow_transform)

        var core := Color(0.07, 0.065, 0.060, lerpf(0.54, 0.98, chain))
        core = core.lerp(Color(0.28, 0.17, 0.09, 0.98), chain * 0.46)
        _core_mesh.set_instance_color(i, core)
        _shadow_mesh.set_instance_color(i, Color(0.02, 0.02, 0.02, 0.10 + chain * 0.08))


func _draw() -> void:
    begin_design_draw(Color(0.80, 0.78, 0.70, 1.0))
    for band: int in range(12):
        var t := float(band) / 11.0
        draw_rect(Rect2(0.0, t * DESIGN_SIZE.y, DESIGN_SIZE.x, DESIGN_SIZE.y / 11.0 + 1.0), Color(0.78 + t * 0.035, 0.765 + t * 0.03, 0.70 + t * 0.02, 0.34), true)

    var active_count := clampi(int(round(pole_count)), 2, MAX_POLES)
    for p: int in range(active_count):
        var positive := _polarities[p] > 0.0
        var color := Color(0.82, 0.18, 0.12, 0.88) if positive else Color(0.12, 0.32, 0.78, 0.88)
        var radius := 13.0 if p != _grabbed else 18.0
        draw_circle(_poles[p], radius + 5.0, Color(color.r, color.g, color.b, 0.08), true)
        draw_arc(_poles[p], radius, 0.0, TAU, 48, color, 2.2, true)
        draw_circle(_poles[p], 3.2, color, true)
    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "angles": _angles.duplicate(),
        "angular_velocity": _angular_velocity.duplicate(),
        "chain": _chain.duplicate(),
        "poles": _poles.duplicate(),
        "pole_targets": _pole_targets.duplicate(),
        "pole_velocities": _pole_velocities.duplicate(),
        "target_timer": _target_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("angles", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_FILINGS: _angles = (v as PackedFloat32Array).duplicate()
    v = state.get("angular_velocity", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_FILINGS: _angular_velocity = (v as PackedFloat32Array).duplicate()
    v = state.get("chain", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_FILINGS: _chain = (v as PackedFloat32Array).duplicate()
    v = state.get("poles", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == MAX_POLES: _poles = (v as PackedVector2Array).duplicate()
    v = state.get("pole_targets", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == MAX_POLES: _pole_targets = (v as PackedVector2Array).duplicate()
    v = state.get("pole_velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == MAX_POLES: _pole_velocities = (v as PackedVector2Array).duplicate()
    _target_timer = float(state.get("target_timer", _target_timer))
    _event_counter = int(state.get("event_counter", _event_counter))
    _refresh_instances()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "visible_filings": int(round(filing_density)),
        "active_poles": int(round(pole_count)),
        "grabbed_pole": _grabbed,
        "render_mode": "multimesh_magnetic_powder",
    }
