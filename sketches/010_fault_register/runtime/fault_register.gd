extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.94, 0.935, 0.91, 1.0)
const INK: Color = Color(0.055, 0.055, 0.06, 1.0)
const RED: Color = Color(0.92, 0.08, 0.07, 1.0)
const BLUE: Color = Color(0.05, 0.28, 0.88, 1.0)
const LINES: Array[String] = ["ORDER", "IS A TEMPORARY", "AGREEMENT"]
const BASELINES: Array[float] = [232.0, 400.0, 574.0]
const MAX_SCARS: int = 10

@export_range(0.0, 1.0, 0.01) var tectonic_drift: float = 0.56
@export_range(0.2, 2.8, 0.01) var stress_gain: float = 1.0
@export_range(0.0, 1.0, 0.01) var scar_memory: float = 0.78
@export_range(0.2, 3.0, 0.01) var repair: float = 1.0
@export_range(0.0, 24.0, 0.1) var registration: float = 8.0
@export_range(0.0, 1.0, 0.01) var grid_tension: float = 0.82

var _scars: Array[Dictionary] = []
var _active_anchor: Vector2 = Vector2.ZERO
var _active_shear: Vector2 = Vector2.ZERO
var _active_energy: float = 0.0
var _press_age: float = 0.0
var _was_down: bool = false
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO
var _auto_accumulator: float = 0.0
var _auto_serial: int = 0


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "tectonic_drift", "label": "TECTONIC DRIFT", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "stress_gain", "label": "STRESS", "type": "float", "min": 0.2, "max": 2.8, "step": 0.01},
        {"id": "scar_memory", "label": "SCAR MEMORY", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "repair", "label": "REPAIR", "type": "float", "min": 0.2, "max": 3.0, "step": 0.01},
        {"id": "registration", "label": "INK REGISTER", "type": "float", "min": 0.0, "max": 24.0, "step": 0.1},
        {"id": "grid_tension", "label": "GRID TENSION", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "tectonic_drift": return tectonic_drift
        "stress_gain": return stress_gain
        "scar_memory": return scar_memory
        "repair": return repair
        "registration": return registration
        "grid_tension": return grid_tension
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "tectonic_drift": tectonic_drift = clampf(float(value), 0.0, 1.0)
        "stress_gain": stress_gain = clampf(float(value), 0.2, 2.8)
        "scar_memory": scar_memory = clampf(float(value), 0.0, 1.0)
        "repair": repair = clampf(float(value), 0.2, 3.0)
        "registration": registration = clampf(float(value), 0.0, 24.0)
        "grid_tension": grid_tension = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    for scar_index: int in range(_scars.size() - 1, -1, -1):
        var scar: Dictionary = _scars[scar_index]
        var decay_rate: float = lerpf(0.22, 0.018, scar_memory) * repair
        var energy: float = float(scar.get("energy", 0.0)) - delta * decay_rate
        if energy <= 0.0:
            _scars.remove_at(scar_index)
            continue
        scar["energy"] = energy
        scar["age"] = float(scar.get("age", 0.0)) + delta
        _scars[scar_index] = scar

    # Even untouched, the structure accumulates and releases small faults.
    _auto_accumulator += delta * (0.32 + tectonic_drift * 0.92)
    if tectonic_drift > 0.02 and _auto_accumulator >= 3.6:
        _auto_accumulator = fmod(_auto_accumulator, 3.6)
        _seed_autonomous_fault()

    var target_velocity: Vector2 = Vector2.ZERO
    if pointer_active:
        if _pointer_ready and delta > 0.0001:
            target_velocity = (pointer_position - _last_pointer) / delta
        _last_pointer = pointer_position
        _pointer_ready = true
    else:
        _pointer_ready = false
    _gesture_velocity = _gesture_velocity.lerp(target_velocity, clampf(delta * 10.0, 0.0, 1.0))

    if pointer_down and not _was_down:
        _active_anchor = pointer_position
        _active_shear = Vector2.ZERO
        _active_energy = 0.12
        _press_age = 0.0

    if pointer_down:
        _press_age += delta
        var displacement: Vector2 = pointer_position - _active_anchor
        var velocity_term: Vector2 = _gesture_velocity * 0.035
        var target_shear: Vector2 = (displacement * 0.42 + velocity_term) * stress_gain
        _active_shear = _active_shear.lerp(target_shear, clampf(delta * 7.5, 0.0, 1.0))
        _active_shear.x = clampf(_active_shear.x, -190.0, 190.0)
        _active_shear.y = clampf(_active_shear.y, -120.0, 120.0)
        _active_energy = clampf(0.18 + _press_age * 0.34 + _active_shear.length() / 230.0, 0.0, 1.55)
    else:
        if _was_down and _active_energy > 0.05:
            _append_scar(
                _active_anchor,
                _active_shear * (0.30 + scar_memory * 0.48),
                clampf(_active_energy * (0.35 + scar_memory * 0.58), 0.0, 1.4),
                false
            )
        _press_age = 0.0
        _active_shear = _active_shear.lerp(Vector2.ZERO, clampf(delta * repair * 2.0, 0.0, 1.0))
        _active_energy = lerpf(_active_energy, 0.0, clampf(delta * repair * 2.4, 0.0, 1.0))

    _was_down = pointer_down


func _seed_autonomous_fault() -> void:
    _auto_serial += 1
    var seed: float = float(_auto_serial)
    var anchor: Vector2 = Vector2(
        lerpf(110.0, 1170.0, hash01(seed * 7.1 + 2.0)),
        lerpf(90.0, 630.0, hash01(seed * 5.3 + 9.0))
    )
    var angle: float = hash01(seed * 11.7 + 3.0) * TAU
    var amplitude: float = (12.0 + hash01(seed * 4.7) * 42.0) * tectonic_drift
    var shear: Vector2 = Vector2(cos(angle), sin(angle) * 0.55) * amplitude
    _append_scar(anchor, shear, 0.16 + tectonic_drift * 0.22, true)


func _append_scar(anchor: Vector2, shear: Vector2, energy: float, autonomous: bool) -> void:
    _scars.append({
        "anchor": anchor,
        "shear": shear,
        "energy": energy,
        "autonomous": autonomous,
        "age": 0.0,
    })
    while _scars.size() > MAX_SCARS:
        _scars.remove_at(0)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "scars": _scars.duplicate(true),
        "active_anchor": _active_anchor,
        "active_shear": _active_shear,
        "active_energy": _active_energy,
        "press_age": _press_age,
        "was_down": _was_down,
        "last_pointer": _last_pointer,
        "pointer_ready": _pointer_ready,
        "gesture_velocity": _gesture_velocity,
        "auto_accumulator": _auto_accumulator,
        "auto_serial": _auto_serial,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _scars.clear()
    var scars_variant: Variant = state.get("scars", [])
    if scars_variant is Array:
        for item: Variant in scars_variant as Array:
            if item is Dictionary:
                _scars.append((item as Dictionary).duplicate(true))
    var anchor_variant: Variant = state.get("active_anchor", _active_anchor)
    if anchor_variant is Vector2:
        _active_anchor = anchor_variant as Vector2
    var shear_variant: Variant = state.get("active_shear", _active_shear)
    if shear_variant is Vector2:
        _active_shear = shear_variant as Vector2
    _active_energy = float(state.get("active_energy", _active_energy))
    _press_age = float(state.get("press_age", _press_age))
    _was_down = bool(state.get("was_down", _was_down))
    var pointer_variant: Variant = state.get("last_pointer", _last_pointer)
    if pointer_variant is Vector2:
        _last_pointer = pointer_variant as Vector2
    _pointer_ready = bool(state.get("pointer_ready", _pointer_ready))
    var velocity_variant: Variant = state.get("gesture_velocity", _gesture_velocity)
    if velocity_variant is Vector2:
        _gesture_velocity = velocity_variant as Vector2
    _auto_accumulator = float(state.get("auto_accumulator", _auto_accumulator))
    _auto_serial = int(state.get("auto_serial", _auto_serial))


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "scar_count": _scars.size(),
        "active_energy": _active_energy,
        "active_shear": _active_shear,
        "auto_serial": _auto_serial,
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_living_grid()
    _draw_statement(font)
    end_design_draw()


func _draw_living_grid() -> void:
    var grid_color: Color = INK
    grid_color.a = 0.065 + grid_tension * 0.09

    for column: int in range(9):
        var x: float = float(column) / 8.0 * DESIGN_SIZE.x
        var points: PackedVector2Array = PackedVector2Array()
        for step: int in range(19):
            var y: float = float(step) / 18.0 * DESIGN_SIZE.y
            var p: Vector2 = Vector2(x, y)
            p += _fault_offset(p) * 0.32
            points.append(p)
        draw_polyline(points, grid_color, 1.0, true)

    for row: int in range(7):
        var y: float = float(row) / 6.0 * DESIGN_SIZE.y
        var points: PackedVector2Array = PackedVector2Array()
        for step: int in range(25):
            var x: float = float(step) / 24.0 * DESIGN_SIZE.x
            var p: Vector2 = Vector2(x, y)
            p += _fault_offset(p) * 0.26
            points.append(p)
        draw_polyline(points, grid_color, 1.0, true)


func _draw_statement(font: Font) -> void:
    for line_index: int in range(LINES.size()):
        var text: String = LINES[line_index]
        var font_size: int = [128, 68, 108][line_index]
        var tracking: float = [12.0, 10.0, 14.0][line_index]
        var widths: Array[float] = []
        var total_width: float = 0.0
        for char_index: int in range(text.length()):
            var glyph: String = text.substr(char_index, 1)
            var width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
            widths.append(width)
            total_width += width
            if char_index < text.length() - 1:
                total_width += tracking

        var cursor_x: float = (DESIGN_SIZE.x - total_width) * 0.5
        for char_index: int in range(text.length()):
            var glyph: String = text.substr(char_index, 1)
            if glyph == " ":
                cursor_x += widths[char_index] + tracking
                continue
            var baseline: Vector2 = Vector2(cursor_x, BASELINES[line_index])
            _draw_faulted_glyph(font, glyph, font_size, baseline, line_index, char_index)
            cursor_x += widths[char_index] + tracking


func _draw_faulted_glyph(
    font: Font,
    glyph: String,
    font_size: int,
    baseline: Vector2,
    line_index: int,
    char_index: int
) -> void:
    var contours: Array[PackedVector2Array] = get_glyph_outline_contours(font, glyph, font_size, baseline, 7)
    if contours.is_empty():
        draw_string(font, baseline, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)
        return

    var black_set: Array[PackedVector2Array] = []
    var red_set: Array[PackedVector2Array] = []
    var blue_set: Array[PackedVector2Array] = []
    var max_energy: float = 0.0

    for contour_index: int in range(contours.size()):
        var black: PackedVector2Array = PackedVector2Array()
        var red: PackedVector2Array = PackedVector2Array()
        var blue: PackedVector2Array = PackedVector2Array()
        for point_index: int in range(contours[contour_index].size()):
            var p: Vector2 = contours[contour_index][point_index]
            var offset: Vector2 = _fault_offset(p)
            var energy: float = _fault_energy(p)
            max_energy = maxf(max_energy, energy)
            var anatomy: float = sin(p.x * 0.025 + p.y * 0.018 + float(char_index) * 0.7 + float(line_index))
            var structural_offset: Vector2 = offset * (0.72 + anatomy * 0.12)
            var q: Vector2 = p + structural_offset
            black.append(q)
            var split: Vector2 = Vector2(registration * energy, -registration * energy * 0.32)
            red.append(q + split)
            blue.append(q - split)
        black_set.append(black)
        red_set.append(red)
        blue_set.append(blue)

    if max_energy > 0.015:
        var red_color: Color = RED
        red_color.a = max_energy * 0.40
        var blue_color: Color = BLUE
        blue_color.a = max_energy * 0.34
        draw_outline_contours(red_set, red_color, 1.5, true)
        draw_outline_contours(blue_set, blue_color, 1.4, true)

    var ink: Color = INK
    ink.a = 0.94
    draw_outline_contours(black_set, ink, 2.2, true)


func _fault_offset(point: Vector2) -> Vector2:
    var total: Vector2 = Vector2.ZERO
    for scar: Dictionary in _scars:
        total += _single_fault_offset(point, scar)
    if _active_energy > 0.001:
        total += _single_fault_offset(point, {
            "anchor": _active_anchor,
            "shear": _active_shear,
            "energy": _active_energy,
            "age": _press_age,
        })
    return total


func _single_fault_offset(point: Vector2, fault: Dictionary) -> Vector2:
    var anchor_variant: Variant = fault.get("anchor", Vector2.ZERO)
    var shear_variant: Variant = fault.get("shear", Vector2.ZERO)
    if not anchor_variant is Vector2 or not shear_variant is Vector2:
        return Vector2.ZERO
    var anchor: Vector2 = anchor_variant as Vector2
    var shear: Vector2 = shear_variant as Vector2
    var radius: float = 145.0 + grid_tension * 120.0
    var distance: float = point.distance_to(anchor)
    if distance >= radius:
        return Vector2.ZERO
    var radial: float = 1.0 - distance / radius
    var fault_angle: float = atan2(shear.y, shear.x + 0.001)
    var normal: Vector2 = Vector2(-sin(fault_angle), cos(fault_angle))
    var side: float = signf((point - anchor).dot(normal))
    if absf(side) < 0.1:
        side = 1.0
    var energy: float = float(fault.get("energy", 0.0))
    var age: float = float(fault.get("age", 0.0))
    var slip: float = 0.86 + 0.14 * sin(age * 2.7 + distance * 0.03)
    return shear * side * radial * energy * grid_tension * slip


func _fault_energy(point: Vector2) -> float:
    var energy: float = 0.0
    var radius: float = 145.0 + grid_tension * 120.0
    for scar: Dictionary in _scars:
        var anchor_variant: Variant = scar.get("anchor", Vector2.ZERO)
        if not anchor_variant is Vector2:
            continue
        var distance: float = point.distance_to(anchor_variant as Vector2)
        if distance < radius:
            energy = maxf(energy, (1.0 - distance / radius) * float(scar.get("energy", 0.0)))
    if _active_energy > 0.001:
        var active_distance: float = point.distance_to(_active_anchor)
        if active_distance < radius:
            energy = maxf(energy, (1.0 - active_distance / radius) * _active_energy)
    return clampf(energy, 0.0, 1.0)
