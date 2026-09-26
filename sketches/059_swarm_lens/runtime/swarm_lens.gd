extends "res://sketches/_shared/design_sketch_base.gd"

const AGENTS: int = 190
const MAX_SOURCES: int = 6
const SAFE := Rect2(62.0, 48.0, 1156.0, 624.0)

@export_range(0.2, 3.5, 0.01) var field_strength: float = 1.38
@export_range(-2.5, 2.5, 0.01) var swirl: float = 0.88
@export_range(70.0, 360.0, 1.0) var reach: float = 230.0
@export_range(0.05, 2.5, 0.01) var damping: float = 0.34
@export_range(0.0, 2.0, 0.01) var coherence: float = 0.46
@export_range(0.0, 2.0, 0.01) var wander: float = 0.42

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _energy := PackedFloat32Array()
var _sources := PackedVector2Array()
var _polarities := PackedFloat32Array()
var _grabbed_source: int = -1
var _pointer_was_down: bool = false
var _source_counter: int = 0


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _positions.clear()
    _velocities.clear()
    _energy.clear()
    _sources.clear()
    _polarities.clear()
    _grabbed_source = -1
    _pointer_was_down = false
    _source_counter = 0
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _positions.resize(AGENTS)
    _velocities.resize(AGENTS)
    _energy.resize(AGENTS)
    for i: int in range(AGENTS):
        _positions[i] = Vector2(lerpf(SAFE.position.x, SAFE.end.x, _hash01i(i * 83 + 7)), lerpf(SAFE.position.y, SAFE.end.y, _hash01i(i * 113 + 19)))
        var angle := TAU * _hash01i(i * 149 + 23)
        _velocities[i] = Vector2(cos(angle), sin(angle)) * (18.0 + _hash01i(i * 167 + 31) * 34.0)
        _energy[i] = 0.0
    _sources.append(DESIGN_SIZE * 0.5 + Vector2(-160.0, 0.0))
    _polarities.append(1.0)
    _sources.append(DESIGN_SIZE * 0.5 + Vector2(160.0, 0.0))
    _polarities.append(-1.0)
    _source_counter = 2


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"field_strength","label":"FIELD STRENGTH","type":"float","min":0.2,"max":3.5,"step":0.01},
        {"id":"swirl","label":"ORBIT / RADIAL","type":"float","min":-2.5,"max":2.5,"step":0.01},
        {"id":"reach","label":"SOURCE REACH","type":"float","min":70.0,"max":360.0,"step":1.0},
        {"id":"damping","label":"MOMENTUM DRAG","type":"float","min":0.05,"max":2.5,"step":0.01},
        {"id":"coherence","label":"SWARM COHERENCE","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"wander","label":"SPATIAL WANDER","type":"float","min":0.0,"max":2.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "field_strength": return field_strength
        "swirl": return swirl
        "reach": return reach
        "damping": return damping
        "coherence": return coherence
        "wander": return wander
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "field_strength": field_strength = clampf(float(value), 0.2, 3.5)
        "swirl": swirl = clampf(float(value), -2.5, 2.5)
        "reach": reach = clampf(float(value), 70.0, 360.0)
        "damping": damping = clampf(float(value), 0.05, 2.5)
        "coherence": coherence = clampf(float(value), 0.0, 2.0)
        "wander": wander = clampf(float(value), 0.0, 2.0)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down and not _pointer_was_down:
        _grabbed_source = _nearest_source(pointer_position, 58.0)
        if _grabbed_source < 0:
            _grabbed_source = _add_source(pointer_position)
    if pointer_down and _grabbed_source >= 0:
        _sources[_grabbed_source] = Vector2(clampf(pointer_position.x, SAFE.position.x, SAFE.end.x), clampf(pointer_position.y, SAFE.position.y, SAFE.end.y))
    elif not pointer_down and _pointer_was_down:
        _grabbed_source = -1
    _pointer_was_down = pointer_down


func _add_source(position: Vector2) -> int:
    var polarity := 1.0 if (_source_counter % 2) == 0 else -1.0
    if _sources.size() < MAX_SOURCES:
        _sources.append(position)
        _polarities.append(polarity)
        _source_counter += 1
        return _sources.size() - 1
    var index := _source_counter % MAX_SOURCES
    _sources[index] = position
    _polarities[index] = polarity
    _source_counter += 1
    return index


func _nearest_source(point: Vector2, radius: float) -> int:
    var best := -1
    var best_distance := radius
    for i: int in range(_sources.size()):
        var distance := point.distance_to(_sources[i])
        if distance < best_distance:
            best_distance = distance
            best = i
    return best


func _update_source_simulation(delta: float) -> void:
    var next_velocities := _velocities.duplicate()
    for i: int in range(AGENTS):
        var position := _positions[i]
        var velocity := _velocities[i]
        var force := Vector2.ZERO
        var local_energy := 0.0
        for source_index: int in range(_sources.size()):
            var offset := _sources[source_index] - position
            var distance := maxf(12.0, offset.length())
            if distance > reach:
                continue
            var falloff := 1.0 - distance / reach
            var normal := offset / distance
            var tangent := Vector2(-normal.y, normal.x)
            var polarity := _polarities[source_index]
            force += normal * polarity * field_strength * falloff * 120.0
            force += tangent * swirl * polarity * falloff * 92.0
            local_energy = maxf(local_energy, falloff)
        if coherence > 0.001:
            var neighbour_a := (i + 17) % AGENTS
            var neighbour_b := (i + 61) % AGENTS
            var target_velocity := (_velocities[neighbour_a] + _velocities[neighbour_b]) * 0.5
            force += (target_velocity - velocity) * coherence * 0.46
        var spatial := Vector2(sin(position.y * 0.012 + float(i % 9) * 0.31), cos(position.x * 0.010 + float(i % 13) * 0.19))
        force += spatial * wander * 14.0
        velocity += force * delta
        velocity *= exp(-delta * damping)
        velocity = velocity.limit_length(250.0)
        next_velocities[i] = velocity
        _energy[i] = lerpf(_energy[i], local_energy, clampf(delta * 5.0, 0.0, 1.0))
    _velocities = next_velocities
    for i: int in range(AGENTS):
        _positions[i] += _velocities[i] * delta
        if _positions[i].x < SAFE.position.x:
            _positions[i].x = SAFE.end.x
        elif _positions[i].x > SAFE.end.x:
            _positions[i].x = SAFE.position.x
        if _positions[i].y < SAFE.position.y:
            _positions[i].y = SAFE.end.y
        elif _positions[i].y > SAFE.end.y:
            _positions[i].y = SAFE.position.y
    queue_redraw()


func _draw() -> void:
    begin_design_draw(Color(0.035, 0.045, 0.055, 1.0))
    for i: int in range(AGENTS):
        var position := _positions[i]
        var velocity := _velocities[i]
        var speed := velocity.length()
        var direction := velocity.normalized() if speed > 0.2 else Vector2.RIGHT
        var tangent := Vector2(-direction.y, direction.x)
        var length := 7.0 + clampf(speed / 25.0, 0.0, 13.0)
        var width := 1.6 + _energy[i] * 2.2
        var nose := position + direction * length
        var tail := position - direction * length * 0.55
        var shard := PackedVector2Array([nose, tail + tangent * width, tail - tangent * width])
        var color := Color(0.42, 0.70, 0.78, 0.58)
        color = color.lerp(Color(0.98, 0.48, 0.16, 0.94), _energy[i])
        draw_colored_polygon(shard, color)
    for source_index: int in range(_sources.size()):
        var p := _sources[source_index]
        var polarity := _polarities[source_index]
        var grabbed := source_index == _grabbed_source
        var size := 9.0 if not grabbed else 14.0
        var color := Color(0.94, 0.72, 0.30, 0.94) if polarity > 0.0 else Color(0.38, 0.82, 0.90, 0.94)
        var diamond := PackedVector2Array([p + Vector2(0.0, -size), p + Vector2(size, 0.0), p + Vector2(0.0, size), p + Vector2(-size, 0.0)])
        draw_colored_polygon(diamond, color)
        draw_line(p + Vector2(-size * 1.8, 0.0), p + Vector2(size * 1.8, 0.0), Color(color.r, color.g, color.b, 0.42), 1.0, true)
        draw_line(p + Vector2(0.0, -size * 1.8), p + Vector2(0.0, size * 1.8), Color(color.r, color.g, color.b, 0.42), 1.0, true)
    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {"positions": _positions.duplicate(), "velocities": _velocities.duplicate(), "energy": _energy.duplicate(), "sources": _sources.duplicate(), "polarities": _polarities.duplicate(), "source_counter": _source_counter}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("positions", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == AGENTS:
        _positions = (value as PackedVector2Array).duplicate()
    value = state.get("velocities", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == AGENTS:
        _velocities = (value as PackedVector2Array).duplicate()
    value = state.get("energy", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == AGENTS:
        _energy = (value as PackedFloat32Array).duplicate()
    value = state.get("sources", PackedVector2Array())
    if value is PackedVector2Array:
        _sources = (value as PackedVector2Array).duplicate()
    value = state.get("polarities", PackedFloat32Array())
    if value is PackedFloat32Array:
        _polarities = (value as PackedFloat32Array).duplicate()
    _source_counter = int(state.get("source_counter", _source_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {"agents": AGENTS, "sources": _sources.size(), "grabbed_source": _grabbed_source}
