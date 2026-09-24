extends "res://app/main/main_runtime_diagnostics_publish.gd"

# Hardened Windows runtime layer.
#
# Telemetry has proven three independent failure classes on this Windows/Godot
# setup:
# 1. resizing the SubViewport for presentation can transiently leave its update
#    mode at UPDATE_DISABLED (0);
# 2. an exact monitor-sized borderless client is reported as
#    EXCLUSIVE_FULLSCREEN and needs a FULLSCREEN bridge before WINDOWED;
# 3. synchronous telemetry publication can block the Godot main thread long
#    enough for Windows to mark the application as "Not responding".
#
# Keep rendering realtime, use the verified fullscreen bridge, and publish
# telemetry through a single asynchronous child process. New snapshots are
# coalesced while a publish is already running, so diagnostic traffic can never
# stall the application or create competing Git locks.

const HARDENED_DIAGNOSTIC_REVISION: int = 6
const CHECKPOINT_PUBLISH_SCRIPT: String = "res://scripts/publish-telemetry-diagnostics.ps1"

var _last_recovered_update_mode_frame: int = -1

var _telemetry_publisher_pid: int = -1
var _telemetry_publish_active_snapshot: String = ""
var _telemetry_publish_active_reason: String = ""
var _telemetry_publish_pending_snapshot: String = ""
var _telemetry_publish_pending_reason: String = ""
var _telemetry_publish_serial: int = 0


func _process(delta: float) -> void:
    super._process(delta)

    if DisplayServer.get_name() == "headless":
        return

    _pump_telemetry_publisher()
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
    # EXCLUSIVE_FULLSCREEN. Bridge through regular FULLSCREEN before WINDOWED.
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

    # Checkpoints use the same single-flight publisher as normal telemetry.
    # They never wait on Git, PowerShell or the network from the Godot thread.
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


# Override the synchronous publisher inherited from main_runtime_diagnostics_publish.gd.
# The old OS.execute() path blocked the UI thread while PowerShell waited on a
# competing publisher lock. This method only snapshots and queues work.
func _publish_telemetry_to_github(reason: String) -> void:
    _queue_telemetry_publish(reason)


func _publish_checkpoint_snapshot(reason: String) -> void:
    _queue_telemetry_publish(reason)


func _queue_telemetry_publish(reason: String) -> void:
    if OS.get_name() != "Windows":
        return
    if _telemetry_path.is_empty() or not FileAccess.file_exists(_telemetry_path):
        return

    if _telemetry_file != null:
        _telemetry_file.flush()

    var snapshot_path: String = _write_telemetry_snapshot(reason)
    if snapshot_path.is_empty():
        return

    var safe_reason: String = reason.to_snake_case()

    if _telemetry_publisher_pid > 0 and OS.is_process_running(_telemetry_publisher_pid):
        # Coalesce to the newest complete snapshot. Intermediate state is already
        # preserved inside that JSONL, so starting more Git processes adds no
        # diagnostic value and only creates lock contention.
        if not _telemetry_publish_pending_snapshot.is_empty() \
        and FileAccess.file_exists(_telemetry_publish_pending_snapshot):
            DirAccess.remove_absolute(_telemetry_publish_pending_snapshot)

        _telemetry_publish_pending_snapshot = snapshot_path
        _telemetry_publish_pending_reason = safe_reason
        print(
            "CREATIVE_LAB_TELEMETRY_QUEUED reason=",
            safe_reason,
            " active_pid=",
            _telemetry_publisher_pid
        )
        return

    _start_telemetry_publisher(snapshot_path, safe_reason)


func _write_telemetry_snapshot(reason: String) -> String:
    var source_path: String = ProjectSettings.globalize_path(_telemetry_path)
    var source: FileAccess = FileAccess.open(source_path, FileAccess.READ)
    if source == null:
        return ""

    _telemetry_publish_serial += 1
    var safe_reason: String = reason.to_snake_case()
    var snapshot_name: String = "publish_%06d_%06d_%s.jsonl" % [
        _telemetry_publish_serial,
        _telemetry_sequence,
        safe_reason,
    ]
    var snapshot_res_path: String = "%s/%s" % [WORKSPACE_TELEMETRY_DIR, snapshot_name]
    var snapshot_path: String = ProjectSettings.globalize_path(snapshot_res_path)

    var snapshot: FileAccess = FileAccess.open(snapshot_path, FileAccess.WRITE)
    if snapshot == null:
        source.close()
        return ""

    snapshot.store_buffer(source.get_buffer(source.get_length()))
    snapshot.flush()
    snapshot.close()
    source.close()
    return snapshot_path


func _start_telemetry_publisher(snapshot_path: String, reason: String) -> void:
    var script_path: String = ProjectSettings.globalize_path(CHECKPOINT_PUBLISH_SCRIPT)
    var repo_root: String = ProjectSettings.globalize_path("res://")

    var arguments: PackedStringArray = PackedStringArray([
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", script_path,
        "-RepoRoot", repo_root,
        "-TelemetryFile", snapshot_path,
        "-Reason", reason,
    ])

    var pid: int = OS.create_process("powershell.exe", arguments)
    if pid <= 0:
        push_warning("Could not start telemetry publisher for %s." % reason)
        if FileAccess.file_exists(snapshot_path):
            DirAccess.remove_absolute(snapshot_path)
        return

    _telemetry_publisher_pid = pid
    _telemetry_publish_active_snapshot = snapshot_path
    _telemetry_publish_active_reason = reason
    print("CREATIVE_LAB_TELEMETRY_PUBLISH_START pid=", pid, " reason=", reason)


func _pump_telemetry_publisher() -> void:
    if _telemetry_publisher_pid <= 0:
        return
    if OS.is_process_running(_telemetry_publisher_pid):
        return

    var finished_pid: int = _telemetry_publisher_pid
    var exit_code: int = OS.get_process_exit_code(finished_pid)
    var finished_reason: String = _telemetry_publish_active_reason
    var finished_snapshot: String = _telemetry_publish_active_snapshot

    _telemetry_publisher_pid = -1
    _telemetry_publish_active_reason = ""
    _telemetry_publish_active_snapshot = ""

    if not finished_snapshot.is_empty() and FileAccess.file_exists(finished_snapshot):
        DirAccess.remove_absolute(finished_snapshot)

    if exit_code == 0:
        print(
            "CREATIVE_LAB_TELEMETRY_PUBLISH_COMPLETE pid=",
            finished_pid,
            " reason=",
            finished_reason,
            " schema=4 revision=",
            HARDENED_DIAGNOSTIC_REVISION
        )
    else:
        push_warning(
            "Telemetry publisher exited with code %d for %s; latest complete snapshot remains queued locally."
            % [exit_code, finished_reason]
        )

    if _telemetry_publish_pending_snapshot.is_empty():
        return

    var next_snapshot: String = _telemetry_publish_pending_snapshot
    var next_reason: String = _telemetry_publish_pending_reason
    _telemetry_publish_pending_snapshot = ""
    _telemetry_publish_pending_reason = ""

    if FileAccess.file_exists(next_snapshot):
        _start_telemetry_publisher(next_snapshot, next_reason)
