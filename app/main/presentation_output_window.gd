extends Window

signal exit_requested
signal input_forwarded(event: InputEvent)


func _ready() -> void:
    close_requested.connect(_on_close_requested)


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_F11:
                exit_requested.emit()
                set_input_as_handled()
                return

    input_forwarded.emit(event)


func _on_close_requested() -> void:
    exit_requested.emit()
