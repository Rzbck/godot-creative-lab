extends "res://sketches/_shared/design_sketch_base.gd"

const BODY_COUNT := 24
const FIELD_X := 40
const FIELD_Y := 23
const FW := 1280.0 / float(FIELD_X)
const FH := 720.0 / float(FIELD_Y)
const BG := Color(0.01, 0.012, 0.016, 1.0)
const LIGHT := Color(0.92, 0.96, 0.88, 1.0)
const HOT := Color(1.0, 0.22, 0.08, 1.0)

@export_range(0.2, 2.0, 0.01) var motion: float = 0.82
@export_range(0.2, 2.0, 0.01) var phase_rate: float = 0.9
@export_range(0.5, 2.0, 0.01) var field_gain: float = 1.0

var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _radii: PackedFloat32Array = PackedFloat32Array()
var _phases: PackedByteArray = PackedByteArray()
var _phase_clock := 0.0


func _ready() -> void:
    super._ready()
    _seed_bodies()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"motion", "label":"MOTION", "type":"float", "min":0.2, "max":2.0, "step":0.01},
        {"id":"phase_rate", "label":"PHASE RATE", "type":"float", "min":0.2, "max":2.0, "step":0.01},
        {"id":"field_gain", "label":"FIELD", "type":"float", "min":0.5, "max":2.0, "step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "motion": return motion
        "phase_rate": return phase_rate
        "field_gain": return field_gain
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "motion": motion = clampf(float(value), 0.2, 2.0)
        "phase_rate": phase_rate = clampf(float(value), 0.2, 2.0)
        "field_gain": field_gain = clampf(float(value), 0.5, 2.0)
        _: return


func _seed_bodies() -> void:
    if not _positions.is_empty():
        return
    for i: int in range(BODY_COUNT):
        var x := 90.0 + hash01(float(i) * 6.7) * 1100.0
        var y := 70.0 + hash01(float(i) * 14.2 + 1.0) * 580.0
        var a := hash01(float(i) * 22.9 + 8.0) * TAU
        var r := 16.0 + hash01(float(i) * 3.9 + 12.0) * 22.0
        _positions.append(Vector2(x, y))
        _velocities.append(Vector2.from_angle(a) * (14.0 + hash01(float(i) * 19.0) * 34.0))
        _radii.append(r)
        _phases.append(i % 2)


func _update_source_simulation(delta: float) -> void:
    _seed_bodies()
    var forces: Array[Vector2] = []
    forces.resize(_positions.size())
    forces.fill(Vector2.ZERO)

    for i: int in range(_positions.size()):
        for j: int in range(i + 1, _positions.size()):
            var delta_p := _positions[j] - _positions[i]
            var dist := delta_p.length()
            var min_dist := _radii[i] + _radii[j] + 4.0
            if dist < min_dist and dist > 0.001:
                var normal := delta_p / dist
                var push := (min_dist - dist) * 5.5
                forces[i] -= normal * push
                forces[j] += normal * push
            elif dist < 170.0 and dist > 0.001:
                var normal := delta_p / dist
                var same := _phases[i] == _phases[j]
                var pull := (1.0 - dist / 170.0) * (10.0 if same else -7.0)
                forces[i] += normal * pull
                forces[j] -= normal * pull

    if pointer_down:
        for i: int in range(_positions.size()):
            var d := _positions[i].distance_to(pointer_position)
            if d < 190.0:
                _phases[i] = 1
                var away := _positions[i] - pointer_position
                if away.length() > 0.001:
                    forces[i] += away.normalized() * (1.0 - d / 190.0) * 70.0

    for i: int in range(_positions.size()):
        var v := _velocities[i]
        v += forces[i] * delta
        v += Vector2(
            sin(sketch_time * 0.37 + float(i) * 1.1),
            cos(sketch_time * 0.29 + float(i) * 1.7)
        ) * delta * 5.0
        v = v.limit_length(74.0 * motion)
        var p := _positions[i] + v * delta * motion
        var r := _radii[i]
        if p.x < r or p.x > DESIGN_SIZE.x - r:
            v.x *= -1.0
        if p.y < r or p.y > DESIGN_SIZE.y - r:
            v.y *= -1.0
        p.x = clampf(p.x, r, DESIGN_SIZE.x - r)
        p.y = clampf(p.y, r, DESIGN_SIZE.y - r)
        _positions[i] = p
        _velocities[i] = v

    _phase_clock += delta * phase_rate
    if _phase_clock >= 0.55:
        _phase_clock = fmod(_phase_clock, 0.55)
        _step_phases()


func _step_phases() -> void:
    var next := _phases.duplicate()
    for i: int in range(_positions.size()):
        var opposite := 0
        var same := 0
        for j: int in range(_positions.size()):
            if i == j:
                continue
            if _positions[i].distance_to(_positions[j]) > 125.0:
                continue
            if _phases[i] == _phases[j]:
                same += 1
            else:
                opposite += 1
        if opposite >= 3 and opposite > same:
            next[i] = 1 - _phases[i]
        elif same == 0 and opposite > 0:
            next[i] = 1 - _phases[i]
    _phases = next


func _field_at(point: Vector2) -> Vector2:
    var best := INF
    var signed_phase := 0.0
    for i: int in range(_positions.size()):
        var sdf := point.distance_to(_positions[i]) - _radii[i] * field_gain
        if sdf < best:
            best = sdf
            signed_phase = 1.0 if _phases[i] == 1 else -1.0
    return Vector2(best, signed_phase)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "radii": _radii.duplicate(),
        "phases": _phases.duplicate(),
        "phase_clock": _phase_clock,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var p: Variant = state.get("positions", [])
    if p is Array:
        _positions.assign(p)
    var v: Variant = state.get("velocities", [])
    if v is Array:
        _velocities.assign(v)
    var r: Variant = state.get("radii", PackedFloat32Array())
    if r is PackedFloat32Array:
        _radii = (r as PackedFloat32Array).duplicate()
    var ph: Variant = state.get("phases", PackedByteArray())
    if ph is PackedByteArray:
        _phases = (ph as PackedByteArray).duplicate()
    _phase_clock = float(state.get("phase_clock", _phase_clock))


func _get_custom_live_debug_state() -> Dictionary:
    var hot := 0
    for p: int in _phases:
        hot += p
    return {"bodies": _positions.size(), "hot_phase": hot}


func _draw() -> void:
    begin_design_draw(BG)

    for gy: int in range(FIELD_Y):
        for gx: int in range(FIELD_X):
            var center := Vector2((float(gx) + 0.5) * FW, (float(gy) + 0.5) * FH)
            var field := _field_at(center)
            var edge := exp(-absf(field.x) * 0.055)
            if edge < 0.045:
                continue
            var color := HOT if field.y > 0.0 else LIGHT
            color.a = clampf(edge * 0.72, 0.0, 0.72)
            draw_rect(Rect2(Vector2(float(gx) * FW, float(gy) * FH), Vector2(FW + 0.5, FH + 0.5)), color, true)

    for i: int in range(_positions.size()):
        var c := HOT if _phases[i] == 1 else LIGHT
        c.a = 0.92
        draw_circle(_positions[i], _radii[i] * 0.24, c)
        var ring := c
        ring.a = 0.22
        draw_circle(_positions[i], _radii[i], ring, false, 1.2)

    end_design_draw()
