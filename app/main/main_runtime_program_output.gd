extends "res://app/main/main_runtime_gallery_persistence.gd"

# Program-output layer.
#
# The workstation/editor is a PREVIEW surface. LIVE OUT is the PROGRAM surface.
# Once a sketch is sent to PROGRAM, it owns its native output renderer and keeps
# running even when the user returns to the gallery, settings, about, or opens a
# different sketch. This is deliberately the first deck-like boundary needed for
# future A/B/C mixing without coupling navigation to the physical output.

const PROGRAM_OUTPUT_REVISION: int = 1

var _program_project_id: String = ""
var _program_definition: Dictionary = {}
var _program_detached: bool = false


func _ready() -> void:
    super._ready()
    _remove_gallery_rollover_tooltips()
    _sync_program_ui()


func _process(delta: float) -> void:
    super._process(delta)

    # The parent LIVE OUT layer deliberately budgets the editor preview while it
    # is the source feeding PROGRAM. Once PROGRAM is detached, a newly opened
    # sketch must regain a normal realtime preview instead of inheriting that
    # budget simply because another sketch is still live on the output screen.
    if _live_output_active and not _program_editor_is_linked_source():
        sketch_viewport_container.stretch = true
        sketch_viewport_container.stretch_shrink = 1
        if is_instance_valid(_active_sketch):
            sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

    _sync_program_ui()


func _build_gallery() -> void:
    super._build_gallery()
    _remove_gallery_rollover_tooltips()


func _remove_gallery_rollover_tooltips() -> void:
    for child: Node in gallery_grid.get_children():
        if child is Control:
            (child as Control).tooltip_text = ""


func _active_project_id() -> String:
    if not is_instance_valid(_active_sketch):
        return ""
    return str(_active_definition.get("id", ""))


func _program_editor_is_linked_source() -> bool:
    if _program_detached or _program_project_id.is_empty():
        return false
    if not is_instance_valid(_active_sketch):
        return false
    return _active_project_id() == _program_project_id


func _enter_render_fullscreen() -> void:
    if not is_instance_valid(_active_sketch) or _presentation_transition:
        return

    var current_id: String = _active_project_id()
    if current_id.is_empty():
        return

    # Same linked source = normal toggle OFF. Any other editor project (including
    # reopening the same project after it was detached) means TAKE this preview
    # to PROGRAM and replace the previous live sketch.
    if _live_output_active and _program_editor_is_linked_source():
        _stop_live_output("toggle")
        return

    var replacing: bool = _live_output_active and is_instance_valid(_live_output_sketch)
    var previous_program_id: String = _program_project_id

    _program_project_id = current_id
    _program_definition = _active_definition.duplicate(true)
    _program_detached = false

    if replacing:
        # The parent interprets an active LIVE OUT as "toggle off". Temporarily
        # expose the state as inactive so it executes its proven renderer setup
        # path directly. No stop/publish cycle occurs in between, and hide/show
        # happens in the same frame before Windows can present an intermediate UI.
        _live_output_active = false

    super._enter_render_fullscreen()

    if not _live_output_active:
        # Start failed before a usable replacement became active. Keep metadata
        # honest; the catalog scenes are validated by CI, so this is defensive.
        _program_project_id = previous_program_id if replacing else ""
        _program_detached = replacing
        if not replacing:
            _program_definition.clear()
        _sync_program_ui()
        return

    _telemetry_event("live_output_replaced" if replacing else "program_output_linked", {
        "program_output_revision": PROGRAM_OUTPUT_REVISION,
        "previous_program_project_id": previous_program_id,
        "program_project_id": _program_project_id,
        "editor_project_id": _active_project_id(),
        "replacing": replacing,
    })
    _sync_program_ui()


func _stop_live_output(reason: String) -> void:
    # Navigation must never be an output transport command. Before the editor
    # source is destroyed, copy its final state to the PROGRAM renderer and let
    # that renderer become autonomous.
    if reason == "project_unload" and _live_output_active and is_instance_valid(_live_output_sketch):
        _detach_program_output(reason)
        return

    super._stop_live_output(reason)

    _program_project_id = ""
    _program_definition.clear()
    _program_detached = false
    _sync_program_ui()


func _detach_program_output(reason: String) -> void:
    if not _live_output_active or not is_instance_valid(_live_output_sketch):
        return
    if _program_detached:
        return

    if _program_editor_is_linked_source():
        _sync_all_live_output_parameters()
        _sync_live_output_runtime_state(true)

    # Follower mode freezes the output simulation because the editor is the
    # authority. Once detached, PROGRAM becomes its own simulation authority.
    if _live_output_sketch.has_method("set_live_sync_follower"):
        _live_output_sketch.call("set_live_sync_follower", false)
    _live_output_sketch.set_process(true)
    # Native Window input is forwarded explicitly below. Keep direct _input off
    # to prevent a touchscreen from generating two pointer streams.
    _live_output_sketch.set_process_input(false)

    _program_detached = true
    _live_state_sync_supported = false
    _live_preview_accumulator = 0.0
    sketch_viewport_container.stretch_shrink = 1
    sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

    _telemetry_event("program_output_detached", {
        "program_output_revision": PROGRAM_OUTPUT_REVISION,
        "reason": reason,
        "program_project_id": _program_project_id,
        "output_sync_state": _live_sync_debug_state(_live_output_sketch),
    })


func _sync_live_output_runtime_state(force: bool = false) -> void:
    if not _program_editor_is_linked_source():
        return
    super._sync_live_output_runtime_state(force)


func _sync_all_live_output_parameters() -> void:
    if not _program_editor_is_linked_source():
        return
    super._sync_all_live_output_parameters()


func _sync_live_output_parameter(parameter_id: String) -> void:
    if not _program_editor_is_linked_source():
        return
    super._sync_live_output_parameter(parameter_id)


func _ensure_realtime_viewport_updates() -> void:
    if _live_output_active and not _program_editor_is_linked_source():
        # Bypass the parent's LIVE-source budget while preserving the already
        # validated ancestor behavior for a normal editor preview.
        var saved_live_state: bool = _live_output_active
        _live_output_active = false
        super._ensure_realtime_viewport_updates()
        _live_output_active = saved_live_state
        return

    super._ensure_realtime_viewport_updates()


func _on_presentation_output_input_forwarded(event: InputEvent) -> void:
    if not _live_output_active or not is_instance_valid(_live_output_sketch):
        return

    if _program_editor_is_linked_source():
        super._on_presentation_output_input_forwarded(event)
        return

    # PROGRAM may be live while the editor is in Gallery or editing another
    # project. Reuse the proven touch/mouse mapping pipeline, but target the
    # autonomous PROGRAM renderer rather than whatever happens to be open in the
    # workstation.
    var saved_active_sketch: Node = _active_sketch
    var saved_definition: Dictionary = _active_definition

    _active_sketch = _live_output_sketch
    _active_definition = _program_definition
    super._on_presentation_output_input_forwarded(event)
    _active_sketch = saved_active_sketch
    _active_definition = saved_definition


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE and _live_output_active:
                # ESC is navigation on the workstation. The project unload path
                # detaches PROGRAM first, so output keeps running.
                if project_view.visible and is_instance_valid(_active_sketch):
                    _show_gallery()
                    get_viewport().set_input_as_handled()
                    return

            if key_event.keycode == KEY_F11:
                if is_instance_valid(_active_sketch):
                    _enter_render_fullscreen()
                    get_viewport().set_input_as_handled()
                    return
                if _live_output_active:
                    # No preview is selected: F11 remains a global emergency
                    # transport toggle for the current PROGRAM output.
                    _stop_live_output("keyboard_global")
                    get_viewport().set_input_as_handled()
                    return

    super._input(event)


func _open_sketch(definition: Dictionary) -> void:
    super._open_sketch(definition)

    if _live_output_active and not _program_editor_is_linked_source():
        sketch_viewport_container.stretch_shrink = 1
        sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

    _sync_program_ui()


func _show_gallery() -> void:
    super._show_gallery()
    _remove_gallery_rollover_tooltips()
    _sync_program_ui()


func _show_settings() -> void:
    super._show_settings()
    _sync_program_ui()


func _show_about() -> void:
    super._show_about()
    _sync_program_ui()


func _sync_program_ui() -> void:
    if not is_instance_valid(fullscreen_button):
        return

    if not _live_output_active or _program_project_id.is_empty():
        fullscreen_button.text = "LIVE OUT"
        fullscreen_button.tooltip_text = "Send this preview to the physical PROGRAM output."
        return

    var program_label: String = _program_project_id.to_upper()

    if is_instance_valid(_active_sketch):
        var editor_label: String = _active_project_id().to_upper()
        if _program_editor_is_linked_source():
            fullscreen_button.text = "STOP LIVE"
            fullscreen_button.tooltip_text = "Stop PROGRAM output. ESC only returns to Gallery."
            page_tag.text = "[LIVE OUT]"
            status_label.text = "PROGRAM %s LIVE / LINKED / ESC=GALLERY / F11=STOP" % program_label
        else:
            fullscreen_button.text = "TAKE LIVE"
            fullscreen_button.tooltip_text = "Replace PROGRAM %s with this preview." % program_label
            page_tag.text = "[PREVIEW]"
            status_label.text = "PREVIEW %s / PROGRAM %s LIVE / F11=TAKE LIVE / ESC=GALLERY" % [
                editor_label,
                program_label,
            ]
        return

    if gallery_view.visible:
        status_label.text = "GALLERY / %d PATCHES / PROGRAM %s LIVE / CLICK TO OPEN" % [
            _catalog.size(),
            program_label,
        ]
    elif page_spacer.visible:
        status_label.text = "PROGRAM %s LIVE / OUTPUT CONTINUES IN BACKGROUND" % program_label


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["program_output_revision"] = PROGRAM_OUTPUT_REVISION
    enriched["program_project_id"] = _program_project_id
    enriched["program_detached"] = _program_detached
    enriched["editor_project_id"] = _active_project_id()
    enriched["program_editor_linked"] = _program_editor_is_linked_source()
    super._telemetry_event(event_name, enriched)
