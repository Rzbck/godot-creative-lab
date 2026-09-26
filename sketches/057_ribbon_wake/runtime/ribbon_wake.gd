extends "res://sketches/_shared/design_sketch_base.gd"

const RIBBONS: int = 16
const SEGMENTS: int = 18
const POINTS: int = RIBBONS * SEGMENTS
const SAFE := Rect2(68.0, 54.0, 1144.0, 612.0)

@export_range(0.2, 4.0, 0.01) var tension: float = 1.42
@export_range(0.05, 3.0, 0.01) var damping: float = 0.54
@export_range(0.0, 2.5, 0.01) var current: float = 0.74
@export_range(0.0, 2.0, 0.01) var crosslink: float = 0.38
@export_range(4.0, 26.0, 1.0) var ribbon_width: float = 13.0
@export_range(0.0, 2.0, 0.01) var memory: float = 0.92

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _rest := PackedVector2Array()
var _strain := PackedFloat32Array()
var _pointer_was_down: bool = false
var _last_pointer := DESIGN_SIZE * 0.5


func _ready() -> void:
    _allocate()
    super._ready()


func reset_state() -> void:
    _positions.clear()
    _velocities.clear()
    _rest.clear()
    _strain.clear()
    _pointer_was_down = false
    _last_pointer = DESIGN_SIZE * 0.5
    _allocate()
    queue_redraw()


func _allocate() -> void:
    _positions.resize(POINTS)
    _velocities.resize(POINTS)
    _rest.resize(POINTS)
    _strain.resize(POINTS)
    for ribbon_index: int in range(RIBBONS):
        var y := lerpf(SAFE.position.y + 32.0, SAFE.end.y - 32.0, float(ribbon_index) / float(RIBBONS - 1))
        for segment: int in range(SEGMENTS):
            var i := _idx(ribbon_index, segment)
            var x := lerpf(SAFE.position.x + 24.0, SAFE.end.x - 24.0, float(segment) / float(SEGMENTS - 1))
            var offset := (_hash01i(i * 89 + 5) - 0.5) * 22.0
            var p := Vector2(x, y + offset)
            _positions[i] = p
            _rest[i] = p
            _velocities[i] = Vector2.ZERO
            _strain[i] = 0.0


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"tension","label":"RIBBON TENSION","type":"float","min":0.2,"max":4.0,"step":0.01},
        {"id":"damping","label":"INK DRAG","type":"float","min":0.05,"max":3.0,"step":0.01},
        {"id":"current","label":"SPATIAL CURRENT","type":"float","min":0.0,"max":2.5,"step":0.01},
        {"id":"crosslink","label":"CROSS-LINK","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"ribbon_width","label":"RIBBON WIDTH","type":"float","min":4.0,"max":26.0,"step":1.0},
        {"id":"memory","label":"DEFORMATION MEMORY","type":"float","min":0.0,"max":2.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "tension": return tension
        "damping": return damping
        "current": return current
        "crosslink": return crosslink
        "ribbon_width": return ribbon_width
        "memory": return memory
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "tension": tension = clampf(float(value), 0.2, 4.0)
        "damping": damping = clampf(float(value), 0.05, 3.0)
        "current": current = clampf(float(value), 0.0, 2.5)
        "crosslink": crosslink = clampf(float(value), 0.0, 2.0)
        "ribbon_width": ribbon_width = clampf(float(value), 4.0, 26.0)
        "memory": memory = clampf(float(value), 0.0, 2.0)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down:
        var motion := pointer_position - _last_pointer
        var brush := 132.0
        for i: int in range(POINTS):
            var offset := pointer_position - _positions[i]
            var distance := offset.length()
            if distance >= brush:
                continue
            var falloff := 1.0 - distance / brush
            _velocities[i] += (offset * 0.12 + motion * (1.05 + memory * 0.38)) * falloff
            _strain[i] = minf(1.6, _strain[i] + falloff * 0.20 * (0.5 + memory))
            _rest[i] += motion * falloff * memory * 0.085
            _rest[i].x = clampf(_rest[i].x, SAFE.position.x + 16.0, SAFE.end.x - 16.0)
            _rest[i].y = clampf(_rest[i].y, SAFE.position.y + 16.0, SAFE.end.y - 16.0)

    _last_pointer = pointer_position
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    var forces := PackedVector2Array()
    forces.resize(POINTS)
    for i: int in range(POINTS):
        forces[i] = Vector2.ZERO
        _strain[i] *= exp(-delta * (0.14 + 0.42 / maxf(0.2, memory + 0.2)))

    for ribbon_index: int in range(RIBBONS):
        for segment: int in range(SEGMENTS):
            var i := _idx(ribbon_index, segment)
            var position := _positions[i]
            var force := (_rest[i] - position) * tension * 0.54
            if segment > 0:
                force += (_positions[_idx(ribbon_index, segment - 1)] - position) * tension * 1.8
            if segment + 1 < SEGMENTS:
                force += (_positions[_idx(ribbon_index, segment + 1)] - position) * tension * 1.8
            if crosslink > 0.001:
                if ribbon_index > 0:
                    force += (_positions[_idx(ribbon_index - 1, segment)] - position) * crosslink * 0.36
                if ribbon_index + 1 < RIBBONS:
                    force += (_positions[_idx(ribbon_index + 1, segment)] - position) * crosslink * 0.36
            var flow := Vector2(sin(position.y * 0.018 + float(ribbon_index) * 0.37), cos(position.x * 0.014 + float(segment) * 0.23))
            force += flow * current * (8.0 + _strain[i] * 12.0)
            if _velocities[i].length() > 0.1:
                var tangent := Vector2(-_velocities[i].y, _velocities[i].x).normalized()
                force += tangent * _strain[i] * memory * 4.5
            forces[i] = force

    for i: int in range(POINTS):
        _velocities[i] += forces[i] * delta
        _velocities[i] *= exp(-delta * damping)
        _velocities[i] = _velocities[i].limit_length(280.0)
        _positions[i] += _velocities[i] * delta
        _positions[i].x = clampf(_positions[i].x, SAFE.position.x, SAFE.end.x)
        _positions[i].y = clampf(_positions[i].y, SAFE.position.y, SAFE.end.y)
    queue_redraw()


func _draw() -> void:
    begin_design_draw(Color(0.94, 0.925, 0.88, 1.0))
    for ribbon_index: int in range(RIBBONS):
        for segment: int in range(SEGMENTS - 1):
            var i := _idx(ribbon_index, segment)
            var j := _idx(ribbon_index, segment + 1)
            var a := _positions[i]
            var b := _positions[j]
            var direction := (b - a).normalized()
            if direction.length() <= 0.001:
                continue
            var normal := Vector2(-direction.y, direction.x)
            var energy := clampf((_strain[i] + _strain[j]) * 0.35, 0.0, 1.0)
            var width := ribbon_width * (0.62 + energy * 0.48)
            var quad := PackedVector2Array([a + normal * width, b + normal * width, b - normal * width, a - normal * width])
            var base := Color(0.10, 0.16, 0.18, 0.58)
            base = base.lerp(Color(0.76, 0.23, 0.14, 0.82), energy)
            draw_colored_polygon(quad, base)
            draw_line(a + normal * width * 0.86, b + normal * width * 0.86, Color(0.96, 0.90, 0.76, 0.15 + energy * 0.20), 1.0, true)
    end_design_draw()


func _idx(ribbon_index: int, segment: int) -> int:
    return ribbon_index * SEGMENTS + segment


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    return {"positions": _positions.duplicate(), "velocities": _velocities.duplicate(), "rest": _rest.duplicate(), "strain": _strain.duplicate()}


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var value: Variant = state.get("positions", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == POINTS:
        _positions = (value as PackedVector2Array).duplicate()
    value = state.get("velocities", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == POINTS:
        _velocities = (value as PackedVector2Array).duplicate()
    value = state.get("rest", PackedVector2Array())
    if value is PackedVector2Array and (value as PackedVector2Array).size() == POINTS:
        _rest = (value as PackedVector2Array).duplicate()
    value = state.get("strain", PackedFloat32Array())
    if value is PackedFloat32Array and (value as PackedFloat32Array).size() == POINTS:
        _strain = (value as PackedFloat32Array).duplicate()


func _get_custom_live_debug_state() -> Dictionary:
    return {"ribbons": RIBBONS, "segments_per_ribbon": SEGMENTS}
