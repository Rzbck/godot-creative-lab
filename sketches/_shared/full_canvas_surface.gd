extends ColorRect

# Shared contract for shader-backed artwork surfaces.
# A ShaderSurface must cover the actual SubViewport, not a hard-coded 1280x720
# rectangle. This keeps Gallery thumbnails, resizable PREVIEW, F11 presentation
# and PROGRAM output on the same full-canvas contract.

var _last_viewport_size: Vector2 = Vector2(-1.0, -1.0)


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    sync_to_viewport(true)


func _process(_delta: float) -> void:
    sync_to_viewport(false)


func sync_to_viewport(force: bool = false) -> void:
    var viewport_size := get_viewport_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    if not force and viewport_size.is_equal_approx(_last_viewport_size):
        return

    _last_viewport_size = viewport_size
    position = Vector2.ZERO
    size = viewport_size
