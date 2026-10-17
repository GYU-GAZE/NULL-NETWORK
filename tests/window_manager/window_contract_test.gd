extends Node

const WINDOW: PackedScene = preload("res://systems/window_manager/window_base.tscn")
const MANAGER: PackedScene = preload("res://systems/window_manager/window_manager.tscn")
const PROBE: Script = preload("res://tests/window_manager/window_ready_probe.gd")
const WORKSPACE: PackedScene = preload("res://systems/workspace/workspace_manager.tscn")
var failures := PackedStringArray()
var focus_events: Array[String] = []
var manager: WindowManager
var capture_directory: String = ""


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="):
			capture_directory = argument.trim_prefix("--capture-directory=")
			DirAccess.make_dir_recursive_absolute(capture_directory)
			KubuDisplaySetting.set_windowed_size(Vector2i(1800, 1200))
	_test_geometry()
	manager = MANAGER.instantiate() as WindowManager
	manager.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	manager.size = Vector2(1000, 700)
	add_child(manager)
	GlobalSignals.app_focused.connect(func(id: String) -> void: focus_events.append(id))
	await _test_ready_and_save()
	await _test_imported_legacy_save()
	await _test_input_and_focus()
	await _test_apps_and_workspace()
	manager.reset_save_data()
	manager.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("WINDOW_CONTRACT_TEST: PASS")
	else:
		for failure: String in failures:
			push_error(failure)
		print("WINDOW_CONTRACT_TEST: FAIL (%d)" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_geometry() -> void:
	var work := Rect2(11, 23, 800, 600)
	var start := Rect2(110, 120, 400, 300)
	var minimum := Vector2(180, 120)
	for mode: int in range(1, 9):
		for delta: Vector2 in [Vector2(27, 31), Vector2(-27, -31), Vector2(10000, 10000), Vector2(-10000, -10000)]:
			var result := WindowGeometry.resize(start, delta, mode, minimum, work)
			check(work.encloses(result), "Resize %d escaped work area: %s" % [mode, result])
			check(result.size.x >= minimum.x and result.size.y >= minimum.y, "Resize %d violated minimum" % mode)
			check(result.position == result.position.round() and result.size == result.size.round(), "Resize %d used subpixels" % mode)
			if mode in [1, 5, 7]:
				check(result.end.x == start.end.x, "Left resize moved right edge")
			elif mode in [2, 6, 8]:
				check(result.position.x == start.position.x, "Right resize moved left edge")
			else:
				check(result.position.x == start.position.x and result.size.x == start.size.x, "Vertical resize changed width")
			if mode in [3, 5, 6]:
				check(result.end.y == start.end.y, "Top resize moved bottom edge")
			elif mode in [4, 7, 8]:
				check(result.position.y == start.position.y, "Bottom resize moved top edge")
			else:
				check(result.position.y == start.position.y and result.size.y == start.size.y, "Horizontal resize changed height")
	var tiny := Rect2(0, 19, 80, 40)
	check(WindowGeometry.resolve(Rect2(-999, -999, -5, -4), minimum, tiny) == tiny, "Small work area policy is inconsistent")
	check(WindowGeometry.resolve(Rect2(Vector2(INF, NAN), Vector2(INF, NAN)), minimum, work) == Rect2(work.position, minimum), "Nonfinite legacy geometry was not normalized")
	var odd_display := KubuOSMetrics.get_work_area_rect(Vector2(640.5, 360.5))
	check(odd_display.end == Vector2(640, 360), "Odd physical display size produced half logical pixels or rounded outside display")
	var random := RandomNumberGenerator.new()
	random.seed = 8128
	for index: int in range(1000):
		var request := Rect2(Vector2(random.randf_range(-2000, 2000), random.randf_range(-2000, 2000)), Vector2(random.randf_range(-500, 2000), random.randf_range(-500, 2000)))
		var result := WindowGeometry.resolve(request, minimum, work)
		check(work.encloses(result) and result.size.x >= minimum.x and result.size.y >= minimum.y, "Random geometry %d invalid" % index)


func _make_probe_app(id: String) -> AppResource:
	var node := Control.new()
	node.set_script(PROBE)
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	var app := AppResource.new()
	app.app_id = id
	app.app_name = id
	app.app_scene = scene
	app.default_window_size = Vector2(480, 320)
	app.min_window_size = Vector2(240, 180)
	app.can_resize = true
	return app


func _test_ready_and_save() -> void:
	var app := _make_probe_app("ready_probe")
	manager.saved_window_states[app.app_id] = {"position": Vector2(-800, -500), "size": Vector2(100, 90), "is_maximized": true, "pixel_scale": 2}
	manager._on_request_open_app(app)
	var window := manager.open_windows[app.app_id] as WindowBase
	var probe := window.content_container.get_child(0) as Control
	check(probe.get("ready_window_rect") == manager.get_work_area_rect(), "App _ready saw pre-maximize geometry")
	check(probe.get("ready_maximized"), "App _ready missed maximized state")
	check(probe.get("ready_size") == window.content_container.size, "App _ready saw stale content dimensions: %s vs %s" % [probe.get("ready_size"), window.content_container.size])
	_surface(window)
	await window.wait_until_opened()
	check(probe.size == probe.get("ready_size"), "App size changed after ready due to stale shell layout")
	await window.restore_from_maximized(false)
	check(window.size == app.min_window_size, "Legacy sub-minimum size was not normalized")
	var restored := window.get_rect()
	await window.maximize(false)
	await window.restore_from_maximized(false)
	check(window.get_rect() == restored, "Maximize/restore lost rectangle")
	manager._on_window_changed(app.app_id)
	var data := manager.export_save_data()
	check(data.version == 2, "Save schema was not migrated")
	var encoded: Dictionary = data.window_states[app.app_id]
	var decoded := manager._deserialize_window_state(encoded)
	check(decoded.position == restored.position and decoded.size == restored.size, "Geometry serialization lost rectangle")
	manager._on_window_closed(app.app_id)
	check(not manager.export_save_data().open_app_ids.has(app.app_id), "Closing app remained in saved open IDs before queue_free")
	manager._on_request_open_app(app)
	window = manager.open_windows[app.app_id] as WindowBase
	check(window.get_rect() == restored, "Reopening did not restore normalized geometry")
	check(manager.validate_save_data({"version": 1, "window_states": {}, "open_app_ids": []}).is_empty(), "v1 saves rejected")
	manager._on_request_open_app(app)
	check(manager.open_windows.size() == 1, "Single-instance contract duplicated app")
	await window.wait_until_opened()
	manager.reset_save_data()
	await get_tree().process_frame


func _test_input_and_focus() -> void:
	var app := _make_probe_app("input_probe")
	manager._on_request_open_app(app)
	var window := manager.open_windows[app.app_id] as WindowBase
	await window.wait_until_opened()
	# Parent-local coordinates must survive canvas translation/scaling. The OS
	# scale belongs to the root window and must never be multiplied in again.
	manager.position = Vector2(13, 17)
	manager.scale = Vector2(2, 2)
	var before_drag := window.get_rect()
	var drag := InputEventMouseButton.new()
	drag.button_index = MOUSE_BUTTON_LEFT
	drag.pressed = true
	drag.position = Vector2(100, 12)
	window._on_top_bar_gui_input(drag)
	var parent_mouse := window._control_point_in_parent(window.top_bar, drag.position)
	var movement := InputEventMouseMotion.new()
	movement.position = manager.get_global_transform_with_canvas() * (parent_mouse + Vector2(21, 17))
	window._input(movement)
	check(window.position == before_drag.position + Vector2(21, 17), "Dragging mixed local/global/scaled coordinates")
	window.cancel_interaction()
	manager.position = Vector2.ZERO
	manager.scale = Vector2.ONE
	var start := Rect2(180, 140, 480, 320)
	var points := [Vector2(1, 160), Vector2(479, 160), Vector2(240, 1), Vector2(240, 319), Vector2(1, 1), Vector2(479, 1), Vector2(1, 319), Vector2(479, 319)]
	for mode: int in range(1, 9):
		window.apply_resolved_geometry(start)
		_surface(window)
		var point: Vector2 = points[mode - 1]
		check(window.resize_border._has_point(point), "Resize edge %d not hittable" % mode)
		check(window._get_resize_mode(point) == mode, "Edge detector chose wrong resize mode %d" % mode)
		_move_mouse(window.global_position + point)
		await get_tree().process_frame
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = point
		window._on_resize_border_gui_input(down)
		check(window.is_resizing and window.resize_border.force_capture, "Resize %d did not capture mouse" % mode)
		# Capture must include the cursor beyond the original perimeter.
		check(window.resize_border._has_point(Vector2(-100, -100)), "Captured resize lost outside cursor")
		var delta := Vector2(28, 22)
		_move_mouse(window.global_position + point + delta)
		await get_tree().process_frame
		var expected := WindowGeometry.resize(start, delta, mode, window.min_window_size, manager.get_work_area_rect())
		check(window.get_rect() == expected, "Input resize %d gave %s expected %s" % [mode, window.get_rect(), expected])
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		window._input(release)
		check(not window.is_resizing and not window.resize_border.force_capture and window.resize_mode == WindowBase.ResizeMode.NONE, "Release left stale capture")
		check(not window.resize_border._has_point(Vector2(-100, -100)), "Release still intercepts outside events")
		_surface(window)
	var close_center := window.close_button.get_global_rect().get_center()
	var border_close := window.resize_border.get_global_transform().affine_inverse() * close_center
	check(not window.resize_border._has_point(border_close), "Resize overlay swallowed Close button")
	var original_taskbar := KubuOSMetrics.taskbar_height
	KubuOSMetrics.taskbar_height = 45
	KubuOSMetrics.emit_changed()
	await get_tree().process_frame
	await get_tree().process_frame
	check(manager.get_work_area_rect().encloses(window.get_rect()), "Chrome metric change left window outside area")
	KubuOSMetrics.taskbar_height = original_taskbar
	KubuOSMetrics.emit_changed()
	window.is_resizing = true
	window.resize_border.force_capture = true
	window.notification(WindowBase.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not window.is_resizing and not window.resize_border.force_capture, "Focus loss left capture")
	window.is_dragging = true
	window.resize_border.force_capture = true
	await window.maximize(false)
	check(not window.is_dragging and not window.resize_border.force_capture, "Maximize did not cancel gesture")
	await window.restore_from_maximized(false)
	# Start another transition before the first timer completes, then resize host.
	window.maximize()
	window.restore_from_maximized()
	manager.size = Vector2(390, 270)
	await get_tree().create_timer(0.3).timeout
	check(manager.get_work_area_rect().encloses(window.get_rect()), "Display resize during transition escaped bounds")
	_surface(window)
	var second := _make_probe_app("focus_probe")
	manager._on_request_open_app(second)
	check(manager.focused_app_id == second.app_id, "Open did not focus app")
	var next := InputEventAction.new()
	next.action = "ui_focus_next"
	next.pressed = true
	manager._input(next)
	check(manager.focused_app_id == app.app_id and focus_events.back() == app.app_id, "Keyboard cycling did not update focus signals")
	check(manager.get_child(manager.get_child_count() - 1) == window, "Focus and z-order disagree")
	manager._on_window_closed(app.app_id)
	check(manager.focused_app_id == second.app_id, "Closing focused window did not select remaining window")
	var closing := manager.open_windows[second.app_id] as WindowBase
	closing.is_resizing = true
	closing.resize_border.force_capture = true
	closing.close()
	check(not closing.is_resizing and not closing.resize_border.force_capture, "Close retained mouse capture")
	await get_tree().create_timer(0.25).timeout
	manager.size = Vector2(1000, 700)


func _test_apps_and_workspace() -> void:
	for id: String in ["browser", "social", "profile", "calendar", "encyclopedia", "system_settings"]:
		var app := ContentRegistry.get_app(id)
		check(app != null, "Missing app %s" % id)
		if app == null:
			continue
		manager._on_request_open_app(app)
		var window := manager.open_windows[id] as WindowBase
		await window.wait_until_opened()
		check(window.size == app.default_window_size, "%s default size was proportionally scaled" % id)
		window.apply_resolved_geometry(manager.resolve_window_geometry(window, Rect2(window.position, Vector2.ONE)))
		check(window.size == app.min_window_size, "%s minimum is not a real minimum" % id)
		await get_tree().process_frame
		var content := window.content_container.get_child(0) as Control
		print("APP_GEOMETRY ", id, " outer=", window.size, " viewport=", window.content_container.size, " app=", content.size, " minimum=", content.get_combined_minimum_size())
		await _capture(id)
		_surface(window)
		var saved_minimum := window.min_window_size
		manager.size = Vector2(310, 220)
		await get_tree().process_frame
		await get_tree().process_frame
		check(manager.get_work_area_rect().encloses(window.get_rect()), "%s escaped a work area smaller than its minimum" % id)
		check(window.min_window_size == saved_minimum, "%s mutated its declared minimum on a small display" % id)
		_surface(window)
		manager.size = Vector2(1000, 700)
		await get_tree().process_frame
		await get_tree().process_frame
		await window.maximize(false)
		await window.restore_from_maximized(false)
		_surface(window)
		manager._on_window_closed(id)
		await get_tree().process_frame
	# Forum is a Browser site, not an installed AppResource. Exercise the same
	# production scene in a normal shell without inventing a catalog entry.
	var forum := _make_probe_app("forum_fixture")
	forum.app_scene = load("res://apps/forum/forum_app.tscn") as PackedScene
	manager._on_request_open_app(forum)
	var forum_window := manager.open_windows[forum.app_id] as WindowBase
	await forum_window.wait_until_opened()
	await _capture("forum")
	_surface(forum_window)
	manager._on_window_closed(forum.app_id)
	await get_tree().process_frame
	var workspace := WORKSPACE.instantiate() as WorkspaceManager
	workspace.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	workspace.size = manager.size
	add_child(workspace)
	var app := _make_probe_app("coexist_window")
	manager._on_request_open_app(app)
	var workspace_app := ContentRegistry.get_app("navigator")
	manager._on_request_open_app(workspace_app)
	check(not manager.open_windows.has("navigator"), "WORKSPACE was opened as a window")
	check(workspace.get_active_workspace_id() == "navigator", "Workspace activation was lost")
	check(manager.focused_app_id.is_empty(), "Workspace activation retained stale window focus")
	manager.focus_window(app.app_id)
	check(manager.focused_app_id == app.app_id, "Window over workspace could not regain focus")
	manager._on_window_closed(app.app_id)
	await get_tree().process_frame
	check(workspace.get_active_workspace_id() == "navigator", "Closing window destroyed workspace")
	workspace.clear_active_workspace()
	workspace.queue_free()
	await get_tree().process_frame


func _surface(window: WindowBase) -> void:
	check(window.scale == Vector2.ONE and window.visual_root.scale == Vector2.ONE, "Window changed fixed 2x presentation")
	check(window.visual_root.size == window.size and window.resize_border.size == window.size, "Visual/resize surfaces diverged from outer rectangle")
	check(window.resize_border.position == Vector2.ZERO, "Resize hitbox origin shifted")
	check(not window.resize_border._has_point(window.size * 0.5), "Resize border intercepted app center")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _move_mouse(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	get_viewport().push_input(motion, true)


func _test_imported_legacy_save() -> void:
	var legacy := {
		"version": 1,
		"open_app_ids": ["browser"],
		"focused_app_id": "browser",
		"window_states": {
			"browser": {
				"position": {"x": -900, "y": 5000},
				"size": {"x": 96, "y": 12},
				"work_rect": {"position": {"x": 0, "y": 19}, "size": {"x": 1280, "y": 701}},
				"pixel_scale": 1,
				"is_maximized": true
			}
		}
	}
	manager.import_save_data(legacy)
	# Save restoration intentionally reopens registered apps on a deferred pass
	# after all save sections are imported. Individual app mounting is synchronous.
	await get_tree().process_frame
	await get_tree().process_frame
	check(manager.open_windows.has("browser"), "Import did not reopen saved app")
	if manager.open_windows.has("browser"):
		var window := manager.open_windows["browser"] as WindowBase
		check(window.is_maximized and window.get_rect() == manager.get_work_area_rect(), "Legacy maximized save did not use current work area")
		await window.wait_until_opened()
		await window.restore_from_maximized(false)
		check(manager.get_work_area_rect().encloses(window.get_rect()), "Legacy restore rectangle remains unreachable")
		check(window.size == ContentRegistry.get_app("browser").min_window_size, "Legacy 96x12 window bypassed new minimum")
		_surface(window)
	manager.reset_save_data()
	await get_tree().process_frame


func _capture(id: String) -> void:
	if capture_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(capture_directory.path_join(id + ".png"))
