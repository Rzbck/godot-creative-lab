extends "res://sketches/_shared/design_sketch_base.gd"

const MAX_FILAMENTS: int = 220
const SAFE := Rect2(24.0, 20.0, 1232.0, 680.0)

@export_range(0.15, 4.0, 0.01) var viscosity: float = 1.05
@export_range(0.0, 2.8, 0.01) var curl: float = 1.18
@export_range(70.0, 220.0, 1.0) var filament_density: float = 174.0
@export_range(0.0, 1.0, 0.01) var pigment_split: float = 0.54
@export_range(0.12, 1.0, 0.01) var bleed: float = 0.62
@export_range(0.2, 4.0, 0.01) var brush_force: float = 1.75
@export_range(28.0, 220.0, 1.0) var brush_radius: float = 108.0
@export_range(0.0, 1.0, 0.01) var eddy_memory: float = 0.78

var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _pigments := PackedFloat32Array()
var _ages := PackedFloat32Array()
var _lifetimes := PackedFloat32Array()
var _respawns := PackedInt32Array()
var _trails: Array = []

var _eddy_positions := PackedVector2Array()
var _eddy_strengths := PackedFloat32Array()
var _eddy_spins := PackedFloat32Array()
var _eddy_ages := PackedFloat32Array()

var _last_pointer := Vector2(-1000.0, -1000.0)
var _pointer_velocity := Vector2.ZERO
var _pointer_was_down: bool = false
var _event_counter: int = 19


func _ready() -> void:
    _seed_filaments()
    super._ready()


func reset_state() -> void:
    _positions.clear()
    _velocities.clear()
    _pigments.clear()
    _ages.clear()
    _lifetimes.clear()
    _respawns.clear()
    _trails.clear()
    _eddy_positions.clear()
    _eddy_strengths.clear()
    _eddy_spins.clear()
    _eddy_ages.clear()
    _event_counter = 19
    _seed_filaments()
    queue_redraw()


func _seed_filaments() -> void:
    if _positions.size() == MAX_FILAMENTS:
        return
    _positions.resize(MAX_FILAMENTS)
    _velocities.resize(MAX_FILAMENTS)
    _pigments.resize(MAX_FILAMENTS)
    _ages.resize(MAX_FILAMENTS)
    _lifetimes.resize(MAX_FILAMENTS)
    _respawns.resize(MAX_FILAMENTS)
    _trails.clear()

    for i: int in range(MAX_FILAMENTS):
        var lane := i % 3
        var phase := _hash01i(i * 41 + 7)
        var base_y: float = float([178.0, 362.0, 544.0][lane])
        _positions[i] = Vector2(
            lerpf(58.0, 1190.0, phase),
            base_y + (_hash01i(i * 67 + 13) - 0.5) * 118.0
        )
        _velocities[i] = Vector2(
            24.0 + _hash01i(i * 83 + 17) * 64.0,
            (_hash01i(i * 97 + 29) - 0.5) * 30.0
        )
        _pigments[i] = _hash01i(i * 113 + 31)
        _lifetimes[i] = 9.0 + _hash01i(i * 127 + 37) * 21.0
        _ages[i] = _hash01i(i * 139 + 43) * _lifetimes[i]
        _respawns[i] = 0
        var trail := PackedVector2Array()
        trail.append(_positions[i])
        _trails.append(trail)


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"viscosity","label":"VISCOSITY","type":"float","min":0.15,"max":4.0,"step":0.01},
        {"id":"curl","label":"VORTICITY","type":"float","min":0.0,"max":2.8,"step":0.01},
        {"id":"filament_density","label":"FILAMENT COUNT","type":"int","min":70,"max":220,"step":1},
        {"id":"pigment_split","label":"PIGMENT SPLIT","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"bleed","label":"WET BLEED","type":"float","min":0.12,"max":1.0,"step":0.01},
        {"id":"brush_force","label":"BRUSH FORCE","type":"float","min":0.2,"max":4.0,"step":0.01},
        {"id":"brush_radius","label":"BRUSH RADIUS","type":"float","min":28.0,"max":220.0,"step":1.0},
        {"id":"eddy_memory","label":"EDDY MEMORY","type":"float","min":0.0,"max":1.0,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "viscosity": return viscosity
        "curl": return curl
        "filament_density": return int(round(filament_density))
        "pigment_split": return pigment_split
        "bleed": return bleed
        "brush_force": return brush_force
        "brush_radius": return brush_radius
        "eddy_memory": return eddy_memory
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "viscosity": viscosity = clampf(float(value), 0.15, 4.0)
        "curl": curl = clampf(float(value), 0.0, 2.8)
        "filament_density": filament_density = clampf(float(value), 70.0, 220.0)
        "pigment_split": pigment_split = clampf(float(value), 0.0, 1.0)
        "bleed": bleed = clampf(float(value), 0.12, 1.0)
        "brush_force": brush_force = clampf(float(value), 0.2, 4.0)
        "brush_radius": brush_radius = clampf(float(value), 28.0, 220.0)
        "eddy_memory": eddy_memory = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    if pointer_down:
        if _last_pointer.x > -900.0:
            _pointer_velocity = (_pointer_velocity * 0.45 + (pointer_position - _last_pointer) * 0.55).limit_length(110.0)
        if not _pointer_was_down or pointer_position.distance_to(_last_pointer) > 24.0:
            _write_eddy(pointer_position, _pointer_velocity)
        _last_pointer = pointer_position
    elif _pointer_was_down:
        _pointer_velocity *= 0.72
        _last_pointer = Vector2(-1000.0, -1000.0)
    _pointer_was_down = pointer_down


func _write_eddy(position: Vector2, gesture: Vector2) -> void:
    var spin := 1.0
    if absf(gesture.x) + absf(gesture.y) > 2.0:
        spin = 1.0 if gesture.x * 0.72 - gesture.y * 0.38 >= 0.0 else -1.0
    elif _eddy_spins.size() % 2 == 1:
        spin = -1.0
    _eddy_positions.append(position.clamp(SAFE.position, SAFE.end))
    _eddy_strengths.append(0.56 + minf(1.7, gesture.length() / 42.0) * brush_force)
    _eddy_spins.append(spin)
    _eddy_ages.append(0.0)
    while _eddy_positions.size() > 12:
        _remove_eddy(0)


func _remove_eddy(index: int) -> void:
    _eddy_positions.remove_at(index)
    _eddy_strengths.remove_at(index)
    _eddy_spins.remove_at(index)
    _eddy_ages.remove_at(index)


func _update_source_simulation(delta: float) -> void:
    var memory_seconds := lerpf(0.8, 12.0, eddy_memory)
    for i: int in range(_eddy_positions.size() - 1, -1, -1):
        _eddy_ages[i] += delta
        _eddy_strengths[i] *= exp(-delta / memory_seconds)
        if _eddy_strengths[i] < 0.025:
            _remove_eddy(i)

    var count := clampi(int(round(filament_density)), 1, MAX_FILAMENTS)
    var damping := exp(-delta * (0.34 + viscosity * 0.68))
    for i: int in range(count):
        var pos := _positions[i]
        var vel := _velocities[i]

        var nx := (pos.x - 640.0) / 640.0
        var ny := (pos.y - 360.0) / 360.0
        var background := Vector2(
            58.0 + sin(ny * 5.7 + nx * 1.8) * 24.0 * curl,
            cos(nx * 4.1 - ny * 2.3) * 31.0 * curl
        )
        var force := (background - vel) * (0.38 + curl * 0.20)

        for e: int in range(_eddy_positions.size()):
            var d := pos - _eddy_positions[e]
            var distance := maxf(12.0, d.length())
            if distance > brush_radius * 2.4:
                continue
            var tangent := Vector2(-d.y, d.x) / distance
            var falloff := exp(-distance / maxf(18.0, brush_radius))
            force += tangent * _eddy_spins[e] * _eddy_strengths[e] * falloff * (310.0 + brush_force * 130.0)
            force += -d / distance * _eddy_strengths[e] * falloff * 34.0

        vel += force * delta
        vel *= damping
        var max_speed := lerpf(95.0, 310.0, clampf(curl / 2.8, 0.0, 1.0)) + brush_force * 24.0
        if vel.length() > max_speed:
            vel = vel.normalized() * max_speed
        pos += vel * delta
        _ages[i] += delta

        var outside := pos.x < SAFE.position.x - 90.0 or pos.x > SAFE.end.x + 90.0 or pos.y < SAFE.position.y - 90.0 or pos.y > SAFE.end.y + 90.0
        if outside or _ages[i] > _lifetimes[i]:
            _respawn_filament(i)
            continue

        _positions[i] = pos
        _velocities[i] = vel
        var trail: PackedVector2Array = _trails[i]
        if trail.is_empty() or trail[trail.size() - 1].distance_to(pos) > 3.2:
            trail.append(pos)
        var max_points := clampi(int(lerpf(10.0, 54.0, bleed)), 8, 58)
        while trail.size() > max_points:
            trail.remove_at(0)
        _trails[i] = trail


func _respawn_filament(i: int) -> void:
    _respawns[i] += 1
    var r := _respawns[i]
    var lane := (i + r) % 3
    var base_y: float = float([172.0, 356.0, 540.0][lane])
    var from_left := _hash01i(i * 193 + r * 31) > 0.18
    var x := 46.0 if from_left else lerpf(110.0, 1160.0, _hash01i(i * 211 + r * 43))
    _positions[i] = Vector2(x, base_y + (_hash01i(i * 223 + r * 59) - 0.5) * 150.0)
    _velocities[i] = Vector2(42.0 + _hash01i(i * 227 + r * 61) * 62.0, (_hash01i(i * 229 + r * 71) - 0.5) * 26.0)
    _ages[i] = 0.0
    _lifetimes[i] = 9.0 + _hash01i(i * 233 + r * 73) * 22.0
    _pigments[i] = _hash01i(i * 239 + r * 79)
    var trail := PackedVector2Array()
    trail.append(_positions[i])
    _trails[i] = trail


func _draw() -> void:
    begin_design_draw(Color(0.012, 0.011, 0.017, 1.0))

    for band: int in range(10):
        var t := float(band) / 9.0
        var c := Color(0.014 + t * 0.010, 0.012 + t * 0.006, 0.020 + t * 0.014, 0.48)
        draw_rect(Rect2(0.0, t * DESIGN_SIZE.y, DESIGN_SIZE.x, DESIGN_SIZE.y / 9.0 + 1.0), c, true)

    var count := clampi(int(round(filament_density)), 1, MAX_FILAMENTS)
    for i: int in range(count):
        var trail_variant: Variant = _trails[i]
        if not trail_variant is PackedVector2Array:
            continue
        var trail := trail_variant as PackedVector2Array
        if trail.size() < 2:
            continue
        var pigment := _pigments[i]
        var a := Color(0.13, 0.34, 0.72, 0.88)
        var b := Color(0.88, 0.16, 0.34, 0.90)
        var c := Color(0.97, 0.72, 0.33, 0.88)
        var ink := a.lerp(b, smoothstep(maxf(0.02, pigment_split - 0.20), minf(0.98, pigment_split + 0.20), pigment))
        if pigment > 0.84:
            ink = ink.lerp(c, (pigment - 0.84) / 0.16)
        var speed := _velocities[i].length()
        var wet_alpha := 0.06 + bleed * 0.09
        var halo := ink
        halo.a = wet_alpha
        draw_polyline(trail, halo, 5.5 + bleed * 7.5, true)
        ink.a = 0.34 + clampf(speed / 330.0, 0.0, 0.54)
        draw_polyline(trail, ink, 1.05 + bleed * 1.55, true)

    for e: int in range(_eddy_positions.size()):
        var strength := clampf(_eddy_strengths[e], 0.0, 1.6)
        draw_arc(_eddy_positions[e], brush_radius * (0.14 + strength * 0.10), 0.0, TAU, 42, Color(0.95, 0.88, 0.72, 0.05 * strength), 1.0, true)

    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    var trails_copy: Array = []
    for trail_variant: Variant in _trails:
        if trail_variant is PackedVector2Array:
            trails_copy.append((trail_variant as PackedVector2Array).duplicate())
    return {
        "positions": _positions.duplicate(),
        "velocities": _velocities.duplicate(),
        "pigments": _pigments.duplicate(),
        "ages": _ages.duplicate(),
        "lifetimes": _lifetimes.duplicate(),
        "respawns": _respawns.duplicate(),
        "trails": trails_copy,
        "eddy_positions": _eddy_positions.duplicate(),
        "eddy_strengths": _eddy_strengths.duplicate(),
        "eddy_spins": _eddy_spins.duplicate(),
        "eddy_ages": _eddy_ages.duplicate(),
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("positions", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == MAX_FILAMENTS: _positions = (v as PackedVector2Array).duplicate()
    v = state.get("velocities", PackedVector2Array())
    if v is PackedVector2Array and (v as PackedVector2Array).size() == MAX_FILAMENTS: _velocities = (v as PackedVector2Array).duplicate()
    v = state.get("pigments", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_FILAMENTS: _pigments = (v as PackedFloat32Array).duplicate()
    v = state.get("ages", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_FILAMENTS: _ages = (v as PackedFloat32Array).duplicate()
    v = state.get("lifetimes", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == MAX_FILAMENTS: _lifetimes = (v as PackedFloat32Array).duplicate()
    v = state.get("respawns", PackedInt32Array())
    if v is PackedInt32Array and (v as PackedInt32Array).size() == MAX_FILAMENTS: _respawns = (v as PackedInt32Array).duplicate()
    v = state.get("trails", [])
    if v is Array:
        _trails.clear()
        for item: Variant in v as Array:
            if item is PackedVector2Array: _trails.append((item as PackedVector2Array).duplicate())
    v = state.get("eddy_positions", PackedVector2Array())
    if v is PackedVector2Array: _eddy_positions = (v as PackedVector2Array).duplicate()
    v = state.get("eddy_strengths", PackedFloat32Array())
    if v is PackedFloat32Array: _eddy_strengths = (v as PackedFloat32Array).duplicate()
    v = state.get("eddy_spins", PackedFloat32Array())
    if v is PackedFloat32Array: _eddy_spins = (v as PackedFloat32Array).duplicate()
    v = state.get("eddy_ages", PackedFloat32Array())
    if v is PackedFloat32Array: _eddy_ages = (v as PackedFloat32Array).duplicate()
    queue_redraw()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "visible_filaments": int(round(filament_density)),
        "eddy_count": _eddy_positions.size(),
        "render_mode": "stateful_vector_ink",
    }
