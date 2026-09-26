extends "res://sketches/_shared/design_sketch_base.gd"

const CHANNELS: int = 10
const HISTORY_MAX: int = 180
const STEP_SECONDS: float = 1.0 / 30.0
const DRAW_SAMPLES: int = 220

@export_range(0.2, 3.0, 0.01) var drive: float = 1.06
@export_range(0.0, 2.0, 0.01) var coupling: float = 0.76
@export_range(0.4, 4.5, 0.01) var damping: float = 1.82
@export_range(0.0, 2.0, 0.01) var memory_fold: float = 1.0
@export_range(0.0, 1.0, 0.01) var chroma: float = 0.46
@export_range(0.3, 2.4, 0.01) var filament: float = 1.08

var _current := PackedFloat32Array()
var _velocity := PackedFloat32Array()
var _targets := PackedFloat32Array()
var _bases := PackedFloat32Array()
var _history: Array = []
var _staples: Array = []
var _accum: float = 0.0
var _target_timer: float = 0.2
var _event_counter: int = 37
var _pointer_was_down: bool = false
var _active_staple: int = -1
var _last_pointer := DESIGN_SIZE * 0.5
var _gesture_velocity := Vector2.ZERO


func _ready() -> void:
    for i: int in range(CHANNELS):
        var base := lerpf(0.12, 0.88, float(i) / float(CHANNELS - 1))
        _bases.append(base)
        _current.append(base + (_hash01i(i * 41 + 3) - 0.5) * 0.045)
        _velocity.append(0.0)
        _targets.append(base + (_hash01i(i * 67 + 17) - 0.5) * 0.11)
    for i: int in range(40):
        _append_history_sample()
    super._ready()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id":"drive","label":"SOURCE DRIVE","type":"float","min":0.2,"max":3.0,"step":0.01},
        {"id":"coupling","label":"RIBBON COUPLING","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"damping","label":"DAMPING","type":"float","min":0.4,"max":4.5,"step":0.01},
        {"id":"memory_fold","label":"TIME FOLD","type":"float","min":0.0,"max":2.0,"step":0.01},
        {"id":"chroma","label":"CHROMA","type":"float","min":0.0,"max":1.0,"step":0.01},
        {"id":"filament","label":"FILAMENT","type":"float","min":0.3,"max":2.4,"step":0.01},
    ]


func get_parameter_value(id: String) -> Variant:
    match id:
        "drive": return drive
        "coupling": return coupling
        "damping": return damping
        "memory_fold": return memory_fold
        "chroma": return chroma
        "filament": return filament
        _: return null


func set_parameter_value(id: String, value: Variant) -> void:
    match id:
        "drive": drive = clampf(float(value), 0.2, 3.0)
        "coupling": coupling = clampf(float(value), 0.0, 2.0)
        "damping": damping = clampf(float(value), 0.4, 4.5)
        "memory_fold": memory_fold = clampf(float(value), 0.0, 2.0)
        "chroma": chroma = clampf(float(value), 0.0, 1.0)
        "filament": filament = clampf(float(value), 0.3, 2.4)
        _: return
    queue_redraw()


func _on_pointer_changed() -> void:
    var delta_pointer := pointer_position - _last_pointer
    _gesture_velocity = _gesture_velocity.lerp(delta_pointer, 0.38)
    _last_pointer = pointer_position

    if pointer_down and not _pointer_was_down:
        var staple := {
            "x": clampf(pointer_position.x / DESIGN_SIZE.x, 0.03, 0.97),
            "depth": clampf((pointer_position.y / DESIGN_SIZE.y - 0.5) * 2.0, -1.0, 1.0),
            "width": 0.10,
        }
        _staples.append(staple)
        while _staples.size() > 8:
            _staples.remove_at(0)
        _active_staple = _staples.size() - 1

    if pointer_down and _active_staple >= 0 and _active_staple < _staples.size():
        var staple: Dictionary = _staples[_active_staple]
        staple["depth"] = clampf((pointer_position.y / DESIGN_SIZE.y - 0.5) * 2.0, -1.0, 1.0)
        staple["width"] = clampf(0.07 + absf(_gesture_velocity.x) / 900.0, 0.07, 0.22)
        _staples[_active_staple] = staple

    if not pointer_down:
        _active_staple = -1
    _pointer_was_down = pointer_down


func _update_source_simulation(delta: float) -> void:
    _accum += delta
    var steps := 0
    while _accum >= STEP_SECONDS and steps < 3:
        _simulate_step(STEP_SECONDS)
        _accum -= STEP_SECONDS
        steps += 1


func _simulate_step(dt: float) -> void:
    _target_timer -= dt
    if _target_timer <= 0.0:
        _event_counter += 1
        _target_timer = 0.42 + _hash01i(_event_counter * 47) * 0.92
        var index := _event_counter % CHANNELS
        _targets[index] = clampf(
            _bases[index] + (_hash01i(_event_counter * 83 + index * 13) - 0.5) * 0.24,
            0.06,
            0.94
        )

    var next_velocity := _velocity.duplicate()
    for i: int in range(CHANNELS):
        var deviation := _current[i] - _bases[i]
        var neighbour_deviation := 0.0
        var neighbour_count := 0.0
        if i > 0:
            neighbour_deviation += _current[i - 1] - _bases[i - 1]
            neighbour_count += 1.0
        if i + 1 < CHANNELS:
            neighbour_deviation += _current[i + 1] - _bases[i + 1]
            neighbour_count += 1.0
        if neighbour_count > 0.0:
            neighbour_deviation /= neighbour_count

        var force := (_targets[i] - _current[i]) * drive
        force += (neighbour_deviation - deviation) * coupling
        var velocity := (_velocity[i] + force * dt) * exp(-damping * dt)
        next_velocity[i] = velocity

    _velocity = next_velocity
    for i: int in range(CHANNELS):
        _current[i] = clampf(_current[i] + _velocity[i] * dt, 0.04, 0.96)
    _append_history_sample()


func _append_history_sample() -> void:
    _history.append(_current.duplicate())
    while _history.size() > HISTORY_MAX:
        _history.remove_at(0)


func _history_index_for_u(u: float) -> int:
    if _history.is_empty():
        return 0
    var base := u * float(_history.size() - 1)
    var shift := 0.0
    for staple_variant: Variant in _staples:
        if not staple_variant is Dictionary:
            continue
        var staple := staple_variant as Dictionary
        var sx := float(staple.get("x", 0.5))
        var width := maxf(0.01, float(staple.get("width", 0.1)))
        var distance := absf(u - sx)
        if distance < width:
            var falloff := 1.0 - distance / width
            shift += float(staple.get("depth", 0.0)) * falloff * falloff * memory_fold * float(_history.size()) * 0.28
    return clampi(int(round(base + shift)), 0, _history.size() - 1)


func _draw() -> void:
    begin_design_draw(Color(0.005, 0.006, 0.011, 1.0))
    if _history.size() < 2:
        end_design_draw()
        return

    for channel: int in range(CHANNELS):
        var poly := PackedVector2Array()
        for sample: int in range(DRAW_SAMPLES):
            var u := float(sample) / float(DRAW_SAMPLES - 1)
            var history_index := _history_index_for_u(u)
            var frame_variant: Variant = _history[history_index]
            if not frame_variant is PackedFloat32Array:
                continue
            var frame := frame_variant as PackedFloat32Array
            var y := frame[channel] * DESIGN_SIZE.y
            poly.append(Vector2(34.0 + u * (DESIGN_SIZE.x - 68.0), y))

        if poly.size() < 2:
            continue
        var channel_u := float(channel) / float(CHANNELS - 1)
        var hue := lerpf(0.52, 0.86, clampf(channel_u * 0.58 + chroma * 0.42, 0.0, 1.0))
        var core := Color.from_hsv(hue, 0.24 + chroma * 0.46, 0.84, 0.80)
        draw_polyline(poly, Color(core.r, core.g, core.b, 0.035 * filament), 5.0 + filament * 2.0, true)
        draw_polyline(poly, core, 0.75 + filament * 0.48, true)

    for staple_variant: Variant in _staples:
        if not staple_variant is Dictionary:
            continue
        var staple := staple_variant as Dictionary
        var x := float(staple.get("x", 0.5)) * DESIGN_SIZE.x
        var width := float(staple.get("width", 0.1)) * DESIGN_SIZE.x
        draw_line(Vector2(x, 58.0), Vector2(x, 662.0), Color(0.86, 0.92, 1.0, 0.055), 0.8, true)
        draw_line(Vector2(x - width, 360.0), Vector2(x + width, 360.0), Color(0.86, 0.92, 1.0, 0.028), 0.8, true)

    end_design_draw()


func _hash01i(value: int) -> float:
    var x := value * 1103515245 + 12345
    x = x ^ (x >> 16)
    x = x & 2147483647
    return float(x % 100000) / 100000.0


func _get_custom_live_sync_state() -> Dictionary:
    var history_copy: Array = []
    for frame_variant: Variant in _history:
        if frame_variant is PackedFloat32Array:
            history_copy.append((frame_variant as PackedFloat32Array).duplicate())
    return {
        "current": _current.duplicate(),
        "velocity": _velocity.duplicate(),
        "targets": _targets.duplicate(),
        "history": history_copy,
        "staples": _staples.duplicate(true),
        "target_timer": _target_timer,
        "event_counter": _event_counter,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    var v: Variant = state.get("current", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == CHANNELS: _current = (v as PackedFloat32Array).duplicate()
    v = state.get("velocity", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == CHANNELS: _velocity = (v as PackedFloat32Array).duplicate()
    v = state.get("targets", PackedFloat32Array())
    if v is PackedFloat32Array and (v as PackedFloat32Array).size() == CHANNELS: _targets = (v as PackedFloat32Array).duplicate()
    v = state.get("history", [])
    if v is Array:
        _history.clear()
        for frame_variant: Variant in v as Array:
            if frame_variant is PackedFloat32Array:
                _history.append((frame_variant as PackedFloat32Array).duplicate())
    v = state.get("staples", [])
    if v is Array: _staples = (v as Array).duplicate(true)
    _target_timer = float(state.get("target_timer", _target_timer))
    _event_counter = int(state.get("event_counter", _event_counter))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "history_frames": _history.size(),
        "time_folds": _staples.size(),
        "render_mode": "vector_temporal_slicing",
    }
