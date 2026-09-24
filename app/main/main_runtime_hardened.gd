extends "res://app/main/main_runtime_diagnostics_publish.gd"

# Hardened Windows runtime layer.
#
# The schema-4 telemetry from 60b1428 proved two separate failures:
# 1. resizing the SubViewport for presentation could leave its update mode at
#    UPDATE_DISABLED (0), which made source/assigned/composite frames all black;
# 2. an exact monitor-sized borderless client is reported by Windows/Godot as
#    EXCLUSIVE_FULLSCREEN, and direct EXCLUSIVE_FULLSCREEN -> WINDOWED requests
#    can remain stuck for many frames on Godot 4.7/Windows.
#
# This layer keeps the realtime SubViewport on UPDATE_ALWAYS and uses the
# documented/observed FULLSCREEN bridge before WINDOWED. It also publishes
# closed-file checkpoint snapshots asynchronously so useful diagnostics survive
# an interruption before the normal end-of-transition publication.

const HARDENED_DIAGNOSTIC_REVISION: int = 5
const CHECKPOINT_PUBLISH_SCRIPT: String = "res://scripts/publish-telemetry-diagnostics.ps1"

var _last_recovered_update_mode_frame: int = -1


func _process(delta: float) -> void:
    super._process(delta)

    if DisplayServer.get_name() == "headless":
        return

    _ensure_realtime_viewport_updates()


func _sync_preview_resolution(force: bool = false) -> void:
    super._sync_preview_resolution(force)

    if not _suspend_preview_resolution_sync:
        _ensure_realtime_viewport_updates()


func _ensure_realtime_viewport_updates() -> void:
    if not is_instance_valid(_active_sketch):
        return

    var current_mode: int = int(sketch_viewport.render_target_update_mode)
    if current_mode == int(SubViewport.UPDATE_ALWAYS):
        return

    sketch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

    var process_frame: int = Engine.get_process_frames()
    if process_frame == _last_recovered_update_mode_frame:
        return
    _last_recovered_update_mode_frame = process_frame

    _telemetry_event("viewport_update_mode_recovered", {
        "diagnostic_revision": HARDENED_DIAGNOSTIC_REVISION,
        "previous_update_mode": current_mode,
        "new_update_mode": int(sketch_viewport.render_target_update_mode),
        "process_frame": process_frame,
    })


func _release_to_windowed(telemetry_event_name: String) -> bool:
    var root_window: Window = get_window()
    root_window.unresizable = false

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

    var current_mode: int = DisplayServer.window_get_mode()

    # Godot 4.7 / Windows can keep an exact monitor-sized borderless client in
    # EXCLUSIVE_FULLSCREEN. The upstream bug report for this behavior notes that
    # FULLSCREEN -> WINDOWED works even when EXCLUSIVE_FULLSCREEN -> WINDOWED
    # does not. Bridge through regular FULLSCREEN and request WINDOWED as soon as
    # that intermediate mode is observed instead of waiting in a MAXIMIZED loop.
    if current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
        _telemetry_event("window_mode_bridge_request", {
            "diagnostic_revision": HARDENED_DIAGNOSTIC_REVISION,
            "from_mode": _window_mode_name(current_mode),
            "target_mode": "fullscreen",
        })

        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

        for attempt: int in range(WINDOW_MODE_TRANSITION_ATTEMPTS):
            await get_tree().process_frame
            current_mode = DisplayServer.window_get_mode()

            var bridge_ok: bool = current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
                or current_mode == DisplayServer.WINDOW_MODE_WINDOWED

            _telemetry_event("window_mode_bridge_step", {
                "diagnostic_revision": HARDENED_DIAGNOSTIC_REVISION,
                "attempt": attempt + 1,
                "target_mode": "fullscreen",
                "mode_ok": bridge_ok,
                "matched": bridge_ok,
            })

            if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
                return true
            if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
                break

    current_mode = DisplayServer.window_get_mode()
    if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
        return true

    # Regular FULLSCREEN is deliberately used as the release bridge above. As
    # soon as it is reached, switch to WINDOWED immediately.
    for attempt: int in range(WINDOW_MODE_TRANSITION_ATTEMPTS):
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        await get_tree().process_frame

        current_mode = DisplayServer.window_get_mode()
        var mode_ok: bool = current_mode == DisplayServer.WINDOW_MODE_WINDOWED

        _telemetry_event(telemetry_event_name, {
            "diagnostic_revision": HARDENED_DIAGNOSTIC_REVISION,
            "attempt": attempt + 1,
            "target_mode": "windowed",
            "mode_ok": mode_ok,
            "rect_ok": false,
            "matched": mode_ok,
        })

        if mode_ok:
            return true

    return false


func _telemetry_event(event_name: String, data: Dictionary = {}) -> void:
    var enriched: Dictionary = data.duplicate(true)
    enriched["diagnostic_revision"] = HARDENED_DIAGNOSTIC_REVISION

    super._telemetry_event(event_name, enriched)

    # Closed-file snapshots let GitHub receive the last useful state even if the
    # app is interrupted before presentation_exit_complete/post-exit probes.
    if event_name == "presentation_enter_complete" \
    or event_name == "presentation_exit_request" \
    or event_name == "presentation_exit_preview_released":
        call_deferred("_publish_checkpoint_snapshot", event_name)


func _collect_fullscreen_probe_series(generation: int) -> void:
    var frame_offsets: Array[int] = [1, 6, 30, 90, 180]
    var previous_offset: int = 0

    for probe_index: int in range(frame_offsets.size()):
        var frame_offset: int = frame_offsets[probe_index]
        for _frame: int in range(frame_offset - previous_offset):
            await get_tree().process_frame
        previous_offset = frame_offset

        if generation != _fullscreen_probe_generation or not _fullscreen_active:
            return

        _telemetry_event("render_probe_fullscreen", {
            "diagnostic_revision": HARDENED_DIAGNOSTIC_REVISION,
            "probe_index": probe_index,
            "frame_offset": frame_offset,
        })

        # One durable snapshot after the fullscreen state has had time to settle.
        if frame_offset == 30 or frame_offset == 180:
            _publish_checkpoint_snapshot("fullscreen_probe_%d" % frame_offset)


func _collect_post_exit_probe_series(generation: int) -> void:
    var frame_offsets: Array[int] = [1, 6, 12, 30, 60, 120, 180]
    var previous_offset: int = 0

    for probe_index: int in range(frame_offsets.size()):
        var frame_offset: int = frame_offsets[probe_index]
        for _frame: int in range(frame_offset - previous_offset):
            await get_tree().process_frame
        previous_offset = frame_offset

        if generation != _post_exit_probe_generation or _fullscreen_active:
            return

        _telemetry_event("render_probe_post_exit", {
            "diagnostic_revision": HARDENED_DIAGNOSTIC_REVISION,
            "probe_index": probe_index,
            "frame_offset": frame_offset,
        })

        if frame_offset == 1 or frame_offset == 30 or frame_offset == 180:
            _publish_checkpoint_snapshot("post_exit_probe_%d" % frame_offset)

    if generation == _post_exit_probe_generation and not _fullscreen_active:
        _publish_telemetry_to_github("post_exit_diagnostics")


func _publish_checkpoint_snapshot(reason: String) -> void:
    if OS.get_name() != "Windows":
        return
    if _telemetry_path.is_empty() or not FileAccess.file_exists(_telemetry_path):
        return

    if _telemetry_file != null:
        _telemetry_file.flush()

    var source_path: String = ProjectSettings.globalize_path(_telemetry_path)
    var snapshot_name: String = "checkpoint_%06d.jsonl" % _telemetry_sequence
    var snapshot_res_path: String = "%s/%s" % [WORKSPACE_TELEMETRY_DIR, snapshot_name]
    var snapshot_path: String = ProjectSettings.globalize_path(snapshot_res_path)

    var source: FileAccess = FileAccess.open(source_path, FileAccess.READ)
    if source == null:
        return

    var snapshot: FileAccess = FileAccess.open(snapshot_path, FileAccess.WRITE)
    if snapshot == null:
        source.close()
        return

    snapshot.store_buffer(source.get_buffer(source.get_length()))
    snapshot.flush()
    snapshot.close()
    source.close()

    var script_path: String = ProjectSettings.globalize_path(CHECKPOINT_PUBLISH_SCRIPT)
    var repo_root: String = ProjectSettings.globalize_path("res://")
    var safe_reason: String = reason.to_snake_case()

    var arguments: PackedStringArray = PackedStringArray([
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", script_path,
        "-RepoRoot", repo_root,
        "-TelemetryFile", snapshot_path,
        "-Reason", safe_reason,
    ])

    var pid: int = OS.create_process("powershell.exe", arguments)
    if pid > 0:
        print("CREATIVE_LAB_TELEMETRY_CHECKPOINT pid=", pid, " reason=", safe_reason)
    else:
        push_warning("Could not start checkpoint telemetry publisher for %s." % safe_reason)
