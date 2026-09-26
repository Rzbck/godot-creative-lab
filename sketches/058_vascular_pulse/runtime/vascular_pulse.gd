extends "res://sketches/_shared/design_sketch_base.gd"

const NODES: int = 84
const SAFE := Rect2(76.0, 56.0, 1128.0, 608.0)

@export_range(0.1, 4.0, 0.01) var conduction: float = 1.46
@export_range(0.02, 2.5, 0.01) var leak: float = 0.42
@export_range(0.0, 2.0, 0.01) var remodel: float = 0.86
@export_range(0.0, 2.0, 0.01) var pump: float = 0.54
@export_range(0.0, 2.0, 0.01) var recoil: float = 0.62
@export_range(0.4, 2.5, 0.01) var contrast: float = 1.24

var _positions := PackedVector2Array()
var _offsets := PackedVector2Array()
var _velocities := PackedVector2Array()
var _pressure := PackedFloat32Array()
var _memory := PackedFloat32Array()
var _edges: Array[Vector2i] = []
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5
var _pump_timer: float = 1.0
var _pump_counter: int = 67


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _positions.clear()
    _offsets.clear()
    _velocities.clear()
    _pressure.clear()
    _memory.clear()
    _edges.clear()
    _pointer_was_down = false
    _last_pointer = DESIGN_SIZE * 0.5
    _pump_timer = 1.0
    _pump_counter = 67
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _positions.resize(NODES)
    _offsets.resize(NODES)
    _velocities.resize(NODES)
    _pressure.resize(NODES)
    _memory.resize(NODES)
    for i: int in range(NODES):
        var band := i % 7
        var rank := int(i / 7)
        var x := lerpf(SAFE.position.x + 30.0, SAFE.end.x - 30.0, (float(rank) + 0.22 * _hash01i(i * 47 + 3)) / 11.8)
        var y := lerpf(SAFE.position.y + 34.0, SAFE.end.y - 34.0, (float(band) + 0.18 + 0.58 * _hash01i(i * 71 + 11)) / 7.0)
        y += sin(float(rank) * 0.72 + float(band) * 0.41) * 22.0
        _positions[i] = Vector2(x, y)
        _offsets[i] = Vector2.ZERO
        _velocities[i] = Vector2.ZERO
        _pressure[i] = 0.06 + _hash01i(i * 101 + 17) * 0.08
        _memory[i] = 0.12 + _hash01i(i * 59 + 23) * 0.12
    _build_edges()


func _build_edges() -> void:
    _edges.clear()
    for i: int in range(NODES):
        var candidates: Array[Dictionary] = []
        for j: int in range(NODES):
            if i == j:
                continue
            var distance := _positions[i].distance_to(_positions[j])
            if distance > 190.0:
                continue
            candidates.append({"index": j, "distance": distance})
        candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
            return float(a["distance"]) < float(b["distance"])
        )
        var links := mini(3, candidates.size())
        for c: int in range(links):
            var j := int(candidates[c]["index"])
            if j <= i:
                continue
            var edge := Vector2i(i, j)
            if not _edges.has(edge):
                _edges.append(edge)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"conduction","label":"FLOW CONDUCTION","type":"float","min":0.1,"max":4.0,"step":0.01},
        {"id":"leak","label":"PRESSURE LEAK","type":"float","min":0.02,"max":2.5,"step":0.01},
        {"id":"remodel","label":"VESSEL REMODEL","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"pump","label":"AUTONOMOUS PUMP","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"recoil","label":"ELASTIC RECOIL","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"contrast","label":"FLOW CONTRAST","type":"float","min":0.4,"max":2.5,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "conduction": return conduction
        "leak": return leak
        "remodel": return remodel
        "pump": return pump
        "recoil": return recoil
        "contrast": return contrast
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "conduction": conduction = clampf(float(value), 0.1, 4.0)
        "leak": leak = clampf(float(value), 0.02, 2.5)
        "remodel": remodel = clampf(float(value), 0.0, 2.0)
        "pump": pump = clampf(float(value), 0.0, 2.0)
        "recoil": recoil = clampf(float(value), 0.0, 2.0)
        "contrast": contrast = clampf(float(value), 0.4, 2.5)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down:
        var motion := pointer_position - _last_pointer
        var brush := 126.0
        for i: int in range(NODES):
            var display_position := _positions[i] + _offsets[i]
            var distance := pointer_position.distance_to(display_position)
            if distance >= brush:
                continue
            var falloff := 1.0 - distance / brush
            _pressure[i] = minf(2.2, _pressure[i] + falloff * 0.24)
            _memory[i] = minf(1.8, _memory[i] + falloff * remodel * 0.06)
            _velocities[i] += motion * falloff * 0.18 * (0.5 + recoil)
    _last_pointer = pointer_position
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _pump_timer -= delta * maxf(0.08, pump)
    if _pump_timer <= 0.0 and pump > 0.01:
        _pump_counter += 1
        _pump_timer = 0.65 + _hash01i(_pump_counter * 89 + 7) * 2.8
        var i := int(_hash01i(_pump_counter * 127 + 13) * float(NODES - 1))
        _pressure[i] = minf(2.2, _pressure[i] + 0.48 + pump * 0.46)
        var direction := Vector2(_hash01i(_pump_counter * 151 + 17) - 0.5, _hash01i(_pump_counter * 173 + 29) - 0.5).normalized()
        _velocities[i] += direction * pump * 20.0

    var delta_pressure := PackedFloat32Array()
    delta_pressure.resize(NODES)
    var motion_force := PackedVector2Array()
    motion_force.resize(NODES)
    for i: int in range(NODES):
        delta_pressure[i] = -_pressure[i] * leak
        motion_force[i] = -_offsets[i] * recoil * 2.4

    for edge: Vector2i in _edges:
        var a := edge.x
        var b := edge.y
        var flow := (_pressure[a] - _pressure[b]) * conduction
        delta_pressure[a] -= flow
        delta_pressure[b] += flow
        var flow_energy := clampf(absf(flow) * 0.08, 0.0, 1.0)
        _memory[a] = clampf(_memory[a] + flow_energy * remodel * delta * 0.28, 0.02, 1.8)
        _memory[b] = clampf(_memory[b] + flow_energy * remodel * delta * 0.28, 0.02, 1.8)
        var pa := _positions[a] + _offsets[a]
        var pb := _positions[b] + _offsets[b]
        var direction := (pb - pa).normalized()
        motion_force[a] += direction * flow * recoil * 2.6
        motion_force[b] -= direction * flow * recoil * 2.6

    for i: int in range(NODES):
        _pressure[i] = clampf(_pressure[i] + delta_pressure[i] * delta, 0.0, 2.2)
        _memory[i] = maxf(0.02, _memory[i] * exp(-delta * (0.015 + 0.035 / maxf(0.1, remodel + 0.1))))
        _velocities[i] += motion_force[i] * delta
        _velocities[i] *= exp(-delta * (1.1 + leak * 0.18))
        _velocities[i] = _velocities[i].limit_length(80.0)
        _offsets[i] += _velocities[i] * delta
        _offsets[i] = _offsets[i].limit_length(24.0 + recoil * 14.0)
    queue_redraw()


func _draw() -> void:
    begin_design_draw(Color(0.075, 0.055, 0.052, 1.0))
    for edge: Vector2i in _edges:
        var a := edge.x
        var b := edge.y
        var pa := _positions[a] + _offsets[a]
        var pb := _positions[b] + _offsets[b]
        var flow := absf(_pressure[a] - _pressure[b])
        var memory_value := (_memory[a] + _memory[b]) * 0.5
        var energy := clampf(flow * contrast * 0.72, 0.0, 1.0)
        var width := 0.8 + memory_value * 2.8 + energy * 3.8
        var color := Color(0.35, 0.08, 0.08, 0.46)
        color = color.lerp(Color(0.95, 0.42, 0.16, 0.94), energy)
        draw_line(pa, pb, color, width, true)
        if energy > 0.28:
            draw_line(pa, pb, Color(1.0, 0.78, 0.43, energy * 0.24), maxf(0.8, width * 0.24), true)
    for i: int in range(NODES):
        var p := _positions[i] + _offsets[i]
        var energy := clampf(_pressure[i] * contrast * 0.55, 0.0, 1.0)
        var size := 2.0 + _memory[i] * 1.5 + energy * 2.0
        var diamond := PackedVector2Array([p + Vector2(0.0, -size), p + Vector2(size, 0.0), p + Vector2(0.0, size), p + Vector2(-size, 0.0)])
        draw_colored_polygon(diamond, Color(0.82, 0.34, 0.17, 0.54 + energy * 0.40))
    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {"offsets": _offsets.duplicate(), "velocities": _velocities.duplicate(), "pressure": _pressure.duplicate(), "memory": _memory.duplicate(), "pump_timer": _pump_timer, "pump_counter": _pump_counter}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("offsets", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == NODES:
        _offsets = (value as PackedVector2Array).duplicate()
    value = state.get("velocities", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == NODES:
        _velocities = (value as PackedVector2Array).duplicate()
    value = state.get("pressure", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == NODES:
        _pressure = (value as PackedFloat32Array).duplicate()
    value = state.get("memory", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == NODES:
        _memory = (value as PackedFloat32Array).duplicate()
    _pump_timer = float(state.get("pump_timer", _pump_timer))
    _pump_counter = int(state.get("pump_counter", _pump_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {"nodes": NODES, "edges": _edges.size()}
