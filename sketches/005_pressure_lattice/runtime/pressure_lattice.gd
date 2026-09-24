extends "res://sketches/_shared/design_sketch_base.gd"

const BG: Color = Color(0.012, 0.015, 0.022, 1.0)
const MAX_MARKS: int = 4

@export_range(5, 14, 1) var grid_columns: int = 7
@export_range(0.0, 2.0, 0.01) var field_strength: float = 0.9
@export_range(8.0, 36.0, 0.1) var line_density: float = 19.0
@export_range(0.1, 2.0, 0.01) var memory_decay: float = 0.55
@export_range(0.2, 3.0, 0.01) var gesture_gain: float = 1.25
@export_range(0.4, 1.8, 0.01) var contrast: float = 1.05
@export_range(0.0, 1.0, 0.01) var pulse: float = 0.32
@export_range(0.0, 1.0, 0.01) var palette_mix: float = 0.18

@onready var _surface: ColorRect = $ShaderSurface
@onready var _shader_material: ShaderMaterial = $ShaderSurface.material as ShaderMaterial

var _marks: Array[Dictionary] = []
var _mark_accumulator: float = 0.0
var _last_pointer: Vector2 = Vector2.ZERO
var _pointer_history_ready: bool = false
var _gesture_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
    super._ready()
    _surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _update_surface_layout()
    _update_shader_uniforms()


func get_parameter_schema() -> Array[Dictionary]:
    return [
        {"id": "grid_columns", "label": "GRID COLUMNS", "type": "int", "min": 5.0, "max": 14.0, "step": 1.0},
        {"id": "field_strength", "label": "FIELD", "type": "float", "min": 0.0, "max": 2.0, "step": 0.01},
        {"id": "line_density", "label": "LINE DENSITY", "type": "float", "min": 8.0, "max": 36.0, "step": 0.1},
        {"id": "memory_decay", "label": "MEMORY DECAY", "type": "float", "min": 0.1, "max": 2.0, "step": 0.01},
        {"id": "gesture_gain", "label": "GESTURE ENERGY", "type": "float", "min": 0.2, "max": 3.0, "step": 0.01},
        {"id": "contrast", "label": "CONTRAST", "type": "float", "min": 0.4, "max": 1.8, "step": 0.01},
        {"id": "pulse", "label": "PULSE", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01},
        {"id": "palette_mix", "label": "PALETTE", "type": "float", "min": 0.0, "max": 1.0, "step": 0.01}
    ]


func get_parameter_value(parameter_id: String) -> Variant:
    match parameter_id:
        "grid_columns": return grid_columns
        "field_strength": return field_strength
        "line_density": return line_density
        "memory_decay": return memory_decay
        "gesture_gain": return gesture_gain
        "contrast": return contrast
        "pulse": return pulse
        "palette_mix": return palette_mix
        _: return null


func set_parameter_value(parameter_id: String, value: Variant) -> void:
    match parameter_id:
        "grid_columns": grid_columns = clampi(int(value), 5, 14)
        "field_strength": field_strength = clampf(float(value), 0.0, 2.0)
        "line_density": line_density = clampf(float(value), 8.0, 36.0)
        "memory_decay": memory_decay = clampf(float(value), 0.1, 2.0)
        "gesture_gain": gesture_gain = clampf(float(value), 0.2, 3.0)
        "contrast": contrast = clampf(float(value), 0.4, 1.8)
        "pulse": pulse = clampf(float(value), 0.0, 1.0)
        "palette_mix": palette_mix = clampf(float(value), 0.0, 1.0)
        _: return
    _update_shader_uniforms()
    queue_redraw()


func _update_source_simulation(delta: float) -> void:
    for mark_index: int in range(_marks.size() - 1, -1, -1):
        var mark: Dictionary = _marks[mark_index]
        var energy: float = float(mark.get("energy", 0.0)) - memory_decay * delta
        var age: float = float(mark.get("age", 0.0)) + delta
        if energy <= 0.0:
            _marks.remove_at(mark_index)
            continue
        mark["energy"] = energy
        mark["age"] = age
        _marks[mark_index] = mark

    var target_velocity: Vector2 = Vector2.ZERO
    if pointer_active:
        if _pointer_history_ready and delta > 0.0001:
            target_velocity = (pointer_position - _last_pointer) / delta
        _last_pointer = pointer_position
        _pointer_history_ready = true
    else:
        _pointer_history_ready = false

    _gesture_velocity = _gesture_velocity.lerp(
        target_velocity,
        clampf(delta * 10.0, 0.0, 1.0)
    )

    _mark_accumulator += delta
    if not pointer_active:
        return

    var interval: float = 0.06
    if _mark_accumulator < interval:
        return
    _mark_accumulator = fmod(_mark_accumulator, interval)

    var speed_energy: float = clampf(_gesture_velocity.length() / 850.0, 0.0, 1.0)
    var authored_energy: float = (0.24 + speed_energy * 0.76) * gesture_gain
    if pointer_down:
        authored_energy *= 1.28
    authored_energy = clampf(authored_energy, 0.0, 1.6)

    _marks.append({
        "position": pointer_position,
        "energy": authored_energy,
        "age": 0.0,
    })
    while _marks.size() > MAX_MARKS:
        _marks.remove_at(0)


func _get_custom_live_sync_state() -> Dictionary:
    return {
        "marks": _marks.duplicate(true),
        "mark_accumulator": _mark_accumulator,
        "last_pointer": _last_pointer,
        "pointer_history_ready": _pointer_history_ready,
        "gesture_velocity": _gesture_velocity,
    }


func _apply_custom_live_sync_state(state: Dictionary) -> void:
    _marks.clear()
    var marks_variant: Variant = state.get("marks", [])
    if marks_variant is Array:
        for item: Variant in marks_variant as Array:
            if item is Dictionary:
                _marks.append((item as Dictionary).duplicate(true))
    _mark_accumulator = float(state.get("mark_accumulator", _mark_accumulator))
    var pointer_variant: Variant = state.get("last_pointer", _last_pointer)
    if pointer_variant is Vector2:
        _last_pointer = pointer_variant as Vector2
    _pointer_history_ready = bool(state.get("pointer_history_ready", _pointer_history_ready))
    var velocity_variant: Variant = state.get("gesture_velocity", _gesture_velocity)
    if velocity_variant is Vector2:
        _gesture_velocity = velocity_variant as Vector2
    _update_shader_uniforms()


func _get_custom_live_debug_state() -> Dictionary:
    return {
        "mark_count": _marks.size(),
        "gesture_speed": _gesture_velocity.length(),
    }


func _draw() -> void:
    begin_design_draw(BG)
    end_design_draw()
    _update_surface_layout()
    _update_shader_uniforms()


func _update_surface_layout() -> void:
    if not is_instance_valid(_surface):
        return
    var transform_data: Dictionary = get_design_transform()
    _surface.position = transform_data["origin"] as Vector2
    var scale_value: float = float(transform_data["scale"])
    _surface.scale = Vector2(scale_value, scale_value)
    _surface.size = DESIGN_SIZE


func _update_shader_uniforms() -> void:
    if not is_instance_valid(_shader_material):
        return

    _shader_material.set_shader_parameter("u_time", sketch_time)
    _shader_material.set_shader_parameter("u_grid_columns", float(grid_columns))
    _shader_material.set_shader_parameter("u_field_strength", field_strength)
    _shader_material.set_shader_parameter("u_line_density", line_density)
    _shader_material.set_shader_parameter("u_contrast", contrast)
    _shader_material.set_shader_parameter("u_pulse", pulse)
    _shader_material.set_shader_parameter("u_palette_mix", palette_mix)

    for mark_index: int in range(MAX_MARKS):
        var encoded: Vector4 = Vector4(-2.0, -2.0, 0.0, 0.0)
        if mark_index < _marks.size():
            var mark: Dictionary = _marks[mark_index]
            var position_variant: Variant = mark.get("position", Vector2.ZERO)
            if position_variant is Vector2:
                var position: Vector2 = position_variant as Vector2
                encoded = Vector4(
                    position.x / DESIGN_SIZE.x,
                    position.y / DESIGN_SIZE.y,
                    clampf(float(mark.get("energy", 0.0)), 0.0, 1.6),
                    float(mark.get("age", 0.0))
                )
        _shader_material.set_shader_parameter("u_mark%d" % mark_index, encoded)
