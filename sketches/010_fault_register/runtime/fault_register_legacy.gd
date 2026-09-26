extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.94, 0.935, 0.91, 1.0)
const INK: Color = Color(0.055, 0.055, 0.06, 1.0)
const RED: Color = Color(0.92, 0.08, 0.07, 1.0)
const BLUE: Color = Color(0.05, 0.28, 0.88, 1.0)
const LINES: Array[String] = ["ORDER", "IS A TEMPORARY", "AGREEMENT"]
const BASELINES: Array[float] = [245.0, 390.0, 540.0]
const MAX_SCARS: int = 8

@export_range(90.0, 340.0, 1.0) var fracture_radius: float = 210.0
@export_range(0.2, 2.8, 0.01) var stress_gain: float = 1.0
@export_range(0.0, 1.0, 0.01) var scar_memory: float = 0.78
@export_range(0.2, 3.0, 0.01) var recovery: float = 1.1
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


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "fracture_radius", "label": "FAULT RADIUS", "type": "float", "min": 90.0, "max": 340.0, "step": 1.0},
        {"id": "stress_gain", "label": "STRESS", "type": "float", "min": 0.2, "max": 2.8, "step": 0.01},
        {"id": "scar_memory", "label": "SCAR MEMORY", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "recovery", "label": "RECOVERY", "type": "float", "min": 0.2, "max": 3.0, "step": 0.01},
        {"id": "registration", "label": "REGISTRATION", "type": "float", "min": 0.0, "max": 24.0, "step": 0.1},
        {"id": "grid_tension", "label": "GRID TENSION", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "fracture_radius": return fracture_radius
        "stress_gain": return stress_gain
        "scar_memory": return scar_memory
        "recovery": return recovery
        "registration": return registration
        "grid_tension": return grid_tension
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "fracture_radius": fracture_radius = clampf(float(value), 90.0, 340.0)
        "stress_gain": stress_gain = clampf(float(value), 0.2, 2.8)
        "scar_memory": scar_memory = clampf(float(value), 0.0, 1.0)
        "recovery": recovery = clampf(float(value), 0.2, 3.0)
        "registration": registration = clampf(float(value), 0.0, 24.0)
        "grid_tension": grid_tension = clampf(float(value), 0.0, 1.0)
        _: return
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    for scar_index: int in range(_scars.size() - 1, -1, -1):
        var scar: Dictionary = _scars[scar_index]
        var decay_rate: float = lerpf(0.22, 0.018, scar_memory)
        var energy: float = float(scar.get("energy", 0.0)) - delta * decay_rate
        if energy <= 0.0:
            _scars.remove_at(scar_index)
            continue
        scar["energy"] = energy
        _scars[scar_index] = scar

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
        _active_shear.x = clampf(_active_shear.x, -180.0, 180.0)
        _active_shear.y = clampf(_active_shear.y, -110.0, 110.0)
        _active_energy = clampf(0.18 + _press_age * 0.34 + _active_shear.length() / 240.0, 0.0, 1.5)
    else:
        if _was_down and _active_energy > 0.05:
            _scars.append({
                "anchor": _active_anchor,
                "shear": _active_shear * (0.28 + scar_memory * 0.44),
                "energy": clampf(_active_energy * (0.35 + scar_memory * 0.55), 0.0, 1.35),
            })
            while _scars.size() > MAX_SCARS:
                _scars.remove_at(0)
        _press_age = 0.0
        _active_shear = _active_shear.lerp(Vector2.ZERO, clampf(delta * recovery * 2.0, 0.0, 1.0))
        _active_energy = lerpf(_active_energy, 0.0, clampf(delta * recovery * 2.4, 0.0, 1.0))

    _was_down = pointer_down


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


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "scar_count": _scars.size(),
        "active_energy": _active_energy,
        "active_shear": _active_shear,
    }


func _draw() -> void:
    begin_design_draw(BG)
    var font: Font = ThemeDB.fallback_font
    _draw_grid(font)
    _draw_statement(font)
    _draw_fault_markers()
    end_design_draw()


func _draw_grid(font: Font) -> void:
    var left: float = 88.0
    var top: float = 102.0
    var width: float = 1104.0
    var height: float = 510.0
    var grid_color: Color = INK
    grid_color.a = 0.13 + grid_tension * 0.08

    for column: int in range(7):
        var x: float = left + float(column) * width / 6.0
        var p0: Vector2 = Vector2(x, top)
        var p1: Vector2 = Vector2(x, top + height)
        p0 += _fault_offset(p0) * 0.35
        p1 += _fault_offset(p1) * 0.35
        draw_line(p0, p1, grid_color, 1.0)

    for row: int in range(9):
        var y: float = top + float(row) * height / 8.0
        var p0: Vector2 = Vector2(left, y)
        var p1: Vector2 = Vector2(left + width, y)
        p0 += _fault_offset(p0) * 0.25
        p1 += _fault_offset(p1) * 0.25
        draw_line(p0, p1, grid_color, 1.0)

    draw_string(font, Vector2(88.0, 82.0), "STRUCTURE / STRESS / RESIDUE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.055, 0.055, 0.06, 0.45))
    draw_string(font, Vector2(1130.0, 82.0), "10", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, RED)


func _draw_statement(font: Font) -> void:
    for line_index: int in range(LINES.size()):
        var text: String = LINES[line_index]
        var font_size: int = [118, 64, 98][line_index]
        var tracking: float = [10.0, 8.0, 12.0][line_index]
        var widths: Array[float] = []
        var total_width: float = 0.0
        for index: int in range(text.length()):
            var glyph: String = text.substr(index, 1)
            var width: float = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
            widths.append(width)
            total_width += width
            if index < text.length() - 1:
                total_width += tracking

        var cursor_x: float = 120.0 if line_index != 1 else 310.0
        var baseline: float = BASELINES[line_index]
        if cursor_x + total_width > 1160.0:
            cursor_x = maxf(104.0, 1160.0 - total_width)

        for index: int in range(text.length()):
            var glyph: String = text.substr(index, 1)
            var center: Vector2 = Vector2(cursor_x + widths[index] * 0.5, baseline - float(font_size) * 0.36)
            var offset: Vector2 = _fault_offset(center)
            var local_energy: float = _fault_energy(center)
            var base_pos: Vector2 = Vector2(cursor_x, baseline) + offset

            if glyph != " ":
                var split: Vector2 = Vector2(registration * local_energy, -registration * 0.35 * local_energy)
                var blue_color: Color = BLUE
                blue_color.a = local_energy * 0.34
                var red_color: Color = RED
                red_color.a = local_energy * 0.38
                if local_energy > 0.02:
                    draw_string(font, base_pos - split, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, blue_color)
                    draw_string(font, base_pos + split, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, red_color)
                draw_string(font, base_pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, INK)

            cursor_x += widths[index] + tracking


func _fault_offset(point: Vector2) -> Vector2:
    var total: Vector2 = Vector2.ZERO
    for scar: Dictionary in _scars:
        total += _single_fault_offset(point, scar)
    if _active_energy > 0.001:
        total += _single_fault_offset(point, {
            "anchor": _active_anchor,
            "shear": _active_shear,
            "energy": _active_energy,
        })
    return total


func _single_fault_offset(point: Vector2, fault: Dictionary) -> Vector2:
    var anchor_variant: Variant = fault.get("anchor", Vector2.ZERO)
    var shear_variant: Variant = fault.get("shear", Vector2.ZERO)
    if not anchor_variant is Vector2 or not shear_variant is Vector2:
        return Vector2.ZERO
    var anchor: Vector2 = anchor_variant as Vector2
    var shear: Vector2 = shear_variant as Vector2
    var distance: float = point.distance_to(anchor)
    if distance >= fracture_radius:
        return Vector2.ZERO
    var radial: float = 1.0 - distance / fracture_radius
    var side: float = -1.0 if point.y < anchor.y else 1.0
    var energy: float = float(fault.get("energy", 0.0))
    return Vector2(shear.x * side, shear.y) * radial * energy * grid_tension


func _fault_energy(point: Vector2) -> float:
    var energy: float = 0.0
    for scar: Dictionary in _scars:
        var anchor_variant: Variant = scar.get("anchor", Vector2.ZERO)
        if not anchor_variant is Vector2:
            continue
        var distance: float = point.distance_to(anchor_variant as Vector2)
        if distance < fracture_radius:
            energy = maxf(energy, (1.0 - distance / fracture_radius) * float(scar.get("energy", 0.0)))
    if _active_energy > 0.001:
        var active_distance: float = point.distance_to(_active_anchor)
        if active_distance < fracture_radius:
            energy = maxf(energy, (1.0 - active_distance / fracture_radius) * _active_energy)
    return clampf(energy, 0.0, 1.0)


func _draw_fault_markers() -> void:
    for scar: Dictionary in _scars:
        var anchor_variant: Variant = scar.get("anchor", Vector2.ZERO)
        if not anchor_variant is Vector2:
            continue
        var anchor: Vector2 = anchor_variant as Vector2
        var energy: float = clampf(float(scar.get("energy", 0.0)), 0.0, 1.0)
        var c: Color = RED
        c.a = 0.08 + energy * 0.12
        draw_circle(anchor, 3.0 + energy * 4.0, c)

    if _active_energy > 0.02:
        var c: Color = RED
        c.a = 0.62
        draw_line(_active_anchor - Vector2(14.0, 0.0), _active_anchor + Vector2(14.0, 0.0), c, 2.0)
        draw_line(_active_anchor - Vector2(0.0, 14.0), _active_anchor + Vector2(0.0, 14.0), c, 2.0)
