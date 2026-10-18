extends Control
class_name WindowManager

const SAVE_DATA_VERSION: int = 2

@export_category("Dependencies")
@export var window_base_scene: PackedScene

var open_windows: Dictionary = {}
var saved_window_states: Dictionary = {}
var focused_app_id: String = ""
var _saved_open_app_ids: Array[String] = []

var _layout_refresh_queued: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not KubuOSMetrics.metrics_changed.is_connected(_on_metrics_changed):
		KubuOSMetrics.metrics_changed.connect(_on_metrics_changed)

	resized.connect(_queue_layout_refresh)
	GlobalSignals.workspace_activated.connect(_on_workspace_activated)
	GlobalSignals.request_open_app.connect(_on_request_open_app)
	GlobalSignals.request_close_app.connect(close_window)
	GlobalSignals.request_open_system_settings.connect(
		_on_request_open_system_settings
	)

	var registration_errors: PackedStringArray = (
		SaveManager.register_save_section(self)
	)

	for error: String in registration_errors:
		push_error("WindowManager save registration: %s" % error)

	call_deferred("_restore_saved_open_windows")


func _exit_tree() -> void:
	SaveManager.unregister_save_section(self)


func get_save_section_id() -> String:
	return str(SaveConstants.SECTION_WINDOW_STATES)


func prepare_for_save() -> void:
	for raw_app_id: Variant in open_windows.keys():
		var app_id: String = str(raw_app_id)
		var window := open_windows.get(app_id) as WindowBase

		if window == null:
			continue

		window._cancel_geometry_motion()
		_save_app_session_state(app_id, window)
		_save_window_state(app_id, window)


func export_save_data() -> Dictionary:
	var serialized_states: Dictionary = {}

	for raw_app_id: Variant in saved_window_states.keys():
		var app_id: String = str(raw_app_id).strip_edges()
		var raw_state: Variant = saved_window_states[raw_app_id]

		if app_id.is_empty() or raw_state is not Dictionary:
			continue

		serialized_states[app_id] = _serialize_window_state(
			raw_state as Dictionary
		)

	return {
		"version": SAVE_DATA_VERSION,
		"open_app_ids": _get_open_app_ids_in_z_order(),
		"focused_app_id": focused_app_id,
		"window_states": serialized_states
	}


func import_save_data(data: Dictionary) -> void:
	reset_save_data()

	if int(data.get("version", -1)) not in [1, SAVE_DATA_VERSION]:
		push_warning("WindowManager: unsupported save version.")
		return

	var raw_states: Variant = data.get("window_states", {})

	if raw_states is Dictionary:
		for raw_app_id: Variant in (raw_states as Dictionary).keys():
			var app_id: String = str(raw_app_id).strip_edges()
			var raw_state: Variant = raw_states[raw_app_id]

			if app_id.is_empty() or raw_state is not Dictionary:
				continue

			saved_window_states[app_id] = _deserialize_window_state(
				raw_state as Dictionary
			)

	_saved_open_app_ids = _read_id_array(data.get("open_app_ids", []))
	focused_app_id = str(data.get("focused_app_id", "")).strip_edges()
	call_deferred("_restore_saved_open_windows")


func reset_save_data() -> void:
	for value: Variant in open_windows.values():
		if value is WindowBase:
			(value as WindowBase).queue_free()

	open_windows.clear()
	saved_window_states.clear()
	focused_app_id = ""
	_saved_open_app_ids.clear()


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if int(data.get("version", -1)) not in [1, SAVE_DATA_VERSION]:
		errors.append("Unsupported WindowManager save version.")

	if data.get("window_states", {}) is not Dictionary:
		errors.append("window_states must be a Dictionary.")

	if data.get("open_app_ids", []) is not Array:
		errors.append("open_app_ids must be an Array.")

	return errors


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		cycle_windows()
		get_viewport().set_input_as_handled()


func _on_request_open_app(app: AppResource) -> void:
	if app == null:
		return

	if app.presentation_mode == AppResource.PresentationMode.WORKSPACE:
		GlobalSignals.request_activate_workspace.emit(app)
		return

	var app_id: String = app.app_id.strip_edges()

	if app_id.is_empty():
		push_error("WindowManager: AppResource has an empty app_id.")
		return

	if open_windows.has(app_id):
		focus_window(app_id, true)
		return

	var new_window: WindowBase = window_base_scene.instantiate() as WindowBase

	if new_window == null:
		push_error(
			"WindowManager: window_base_scene did not instantiate a WindowBase."
		)
		return

	new_window.geometry_resolver = resolve_window_geometry
	add_child(new_window)

	new_window.setup(
		app_id,
		app.app_name,
		app.default_window_size,
		app.min_window_size,
		app.can_resize
	)

	open_windows[app_id] = new_window
	_apply_saved_or_default_window_state(app_id, new_window)
	new_window.window_focused.connect(focus_window.bind(app_id))
	new_window.window_closed.connect(_on_window_closed.bind(app_id))
	new_window.window_moved.connect(_on_window_changed.bind(app_id))
	new_window.window_resized.connect(_on_window_changed.bind(app_id))

	if app.app_scene != null:
		var app_instance: Node = app.app_scene.instantiate()

		if app_instance == null:
			push_error(
				"WindowManager: app_scene for '%s' could not be instantiated."
				% app_id
			)
		else:
			new_window.mount_app(app_instance)
			_restore_app_session_state(app_id, app_instance)
	else:
		push_warning(
			"WindowManager: AppResource '%s' has no app_scene."
			% app_id
		)

	GlobalSignals.app_opened.emit(app_id)
	focus_window(app_id)


func _on_request_open_system_settings() -> void:
	var settings_app: AppResource = ContentRegistry.get_app("system_settings")
	if settings_app == null:
		push_error("WindowManager: System Settings app is not registered.")
		return
	_on_request_open_app(settings_app)


func focus_window(app_id: String, request_feedback: bool = false) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]

	if not is_instance_valid(window) or window.is_closing():
		return

	var changed := focused_app_id != app_id
	focused_app_id = app_id
	for candidate: WindowBase in open_windows.values():
		if is_instance_valid(candidate):
			candidate.has_window_focus = candidate == window
	window.move_to_front()
	if changed or request_feedback:
		window.pulse()

	GlobalSignals.app_focused.emit(app_id)


func close_window(app_id: String) -> void:
	if open_windows.has(app_id):
		open_windows[app_id].close()


func _on_window_closed(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]

	_save_app_session_state(app_id, window)
	_save_window_state(app_id, window)

	open_windows.erase(app_id)

	if focused_app_id == app_id:
		focused_app_id = ""
		var remaining := _get_open_app_ids_in_z_order()
		remaining.erase(app_id)
		if remaining.is_empty():
			GlobalSignals.app_focused.emit("")
		else:
			focus_window(remaining.back())

	GlobalSignals.app_closed.emit(app_id)

	window.queue_free()


func _restore_app_session_state(
	app_id: String,
	app_instance: Node
) -> void:
	if app_instance == null:
		return

	if _uses_dedicated_save_section(app_instance):
		return

	if not AppSessionStore.has_app_state(app_id):
		return

	if not app_instance.has_method("restore_app_session_state"):
		return

	var stored_state: Dictionary = AppSessionStore.get_app_state(app_id)

	app_instance.call_deferred(
		"restore_app_session_state",
		stored_state
	)


func _save_app_session_state(
	app_id: String,
	window: WindowBase
) -> void:
	if app_id.is_empty() or window == null:
		return

	var app_instance: Node = _get_window_app_instance(window)

	if app_instance == null:
		return

	if _uses_dedicated_save_section(app_instance):
		return

	if not app_instance.has_method("get_app_session_state"):
		return

	var returned_state: Variant = app_instance.call(
		"get_app_session_state"
	)

	if not returned_state is Dictionary:
		push_warning(
			"WindowManager: app '%s' returned a non-Dictionary session state."
			% app_id
		)
		return

	AppSessionStore.save_app_state(
		app_id,
		returned_state as Dictionary
	)


func _get_window_app_instance(window: WindowBase) -> Node:
	if window == null:
		return null

	if not is_instance_valid(window.content_container):
		return null

	if window.content_container.get_child_count() <= 0:
		return null

	return window.content_container.get_child(0)


func _on_window_changed(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]
	_save_window_state(app_id, window)


func cycle_windows() -> void:
	if open_windows.size() <= 1:
		return
	for child: Node in get_children():
		if child is WindowBase and not (child as WindowBase).is_closing():
			focus_window((child as WindowBase).app_id)
			break


func get_work_area_position() -> Vector2:
	return get_work_area_rect().position


func get_work_area_size() -> Vector2:
	return get_work_area_rect().size


func get_work_area_rect() -> Rect2:
	# The dock intentionally floats over windows. Only structural chrome reserves
	# area here, exactly as for workspaces.
	return KubuOSMetrics.get_work_area_rect(_get_parent_size())


func _get_parent_size() -> Vector2:
	var parent_size: Vector2 = size

	if parent_size.x <= 0.0 or parent_size.y <= 0.0:
		parent_size = get_viewport_rect().size

	# Odd physical display sizes can expose a half logical unit. Never round the
	# usable area outward past the last complete 2x pixel pair.
	return parent_size.floor()


func _on_metrics_changed() -> void:
	_queue_layout_refresh()


func _queue_layout_refresh() -> void:
	for value: Variant in open_windows.values():
		if value is WindowBase:
			(value as WindowBase).cancel_interaction()
	if _layout_refresh_queued:
		return

	_layout_refresh_queued = true
	call_deferred("_refresh_window_layout")


func _refresh_window_layout() -> void:
	_layout_refresh_queued = false
	for value: Variant in open_windows.values():
		if value is not WindowBase:
			continue
		var window := value as WindowBase
		window._cancel_geometry_motion()
		var restore_rect := resolve_window_geometry(window, Rect2(window.restore_position, window.restore_size))
		window.restore_position = restore_rect.position
		window.restore_size = restore_rect.size
		if window.is_maximized:
			window.apply_maximized_geometry()
		else:
			window.apply_resolved_geometry(resolve_window_geometry(window, window.get_rect()))
		_save_window_state(window.app_id, window)


func _apply_saved_or_default_window_state(app_id: String, window: WindowBase) -> void:
	if saved_window_states.has(app_id):
		_apply_saved_window_state(saved_window_states[app_id], window)
	else:
		_apply_default_window_state(window)

	_save_window_state(app_id, window)


func _apply_saved_window_state(state: Dictionary, window: WindowBase) -> void:
	var target_rect := Rect2(state.get("position", window.position), state.get("size", window.size))
	# v1 already stored outer logical rectangles, not the half-scale visual size.
	# Old physical-density workspaces are remapped once using the saved work area.
	var saved_scale: int = int(state.get("pixel_scale", 2))
	var saved_work: Rect2 = state.get("work_rect", Rect2())
	if saved_scale != 2 and _is_valid_work_rect(saved_work):
		target_rect = _remap_rect_between_work_areas(target_rect, saved_work, get_work_area_rect())
	window.apply_resolved_geometry(resolve_window_geometry(window, target_rect))
	if bool(state.get("is_maximized", false)):
		window.maximize(false)


func _apply_default_window_state(window: WindowBase) -> void:
	var work := get_work_area_rect()
	var target := resolve_window_geometry(window, Rect2(work.position, window.size))
	target.position = (work.position + (work.size - target.size) * 0.5).round()
	window.apply_resolved_geometry(target)


func _save_window_state(app_id: String, window: WindowBase) -> void:
	if app_id.is_empty():
		return

	var saved_position: Vector2 = window.position
	var saved_size: Vector2 = window.size

	if window.is_maximized:
		saved_position = window.restore_position
		saved_size = window.restore_size

	saved_window_states[app_id] = {
		"position": KubuOSMetrics.snap_vector(saved_position),
		"size": KubuOSMetrics.snap_vector(saved_size),
		"work_rect": get_work_area_rect(),
		"pixel_scale": KubuOSMetrics.get_pixel_scale(),
		"is_maximized": window.is_maximized
	}


func _remap_rect_between_work_areas(
	source_rect: Rect2,
	old_work_rect: Rect2,
	new_work_rect: Rect2
) -> Rect2:
	if not _is_valid_work_rect(old_work_rect):
		return source_rect

	var relative_position := Vector2(
		(source_rect.position.x - old_work_rect.position.x) / old_work_rect.size.x,
		(source_rect.position.y - old_work_rect.position.y) / old_work_rect.size.y
	)
	var relative_size := Vector2(
		source_rect.size.x / old_work_rect.size.x,
		source_rect.size.y / old_work_rect.size.y
	)

	return Rect2(
		KubuOSMetrics.snap_vector(
			new_work_rect.position + (new_work_rect.size * relative_position)
		),
		KubuOSMetrics.snap_vector(new_work_rect.size * relative_size)
	)


func resolve_window_geometry(
	window: WindowBase,
	requested: Rect2,
	mode: WindowBase.ResizeMode = WindowBase.ResizeMode.NONE,
	start: Rect2 = Rect2()
) -> Rect2:
	var work := get_work_area_rect()
	if mode != WindowBase.ResizeMode.NONE:
		return WindowGeometry.resize(start, requested.position - start.position, mode, window.min_window_size, work)
	return WindowGeometry.resolve(requested, window.min_window_size, work)


func _on_workspace_activated(app_id: String) -> void:
	if not app_id.is_empty():
		# workspace_activated already informs the dock. Do not emit app_focused("")
		# here: WorkspaceManager uses that signal to restore workspace focus.
		focused_app_id = ""


func _is_valid_work_rect(work_rect: Rect2) -> bool:
	return work_rect.size.x > 0.0 and work_rect.size.y > 0.0


func _uses_dedicated_save_section(app_instance: Node) -> bool:
	return (
		app_instance != null
		and app_instance.has_method("get_save_section_id")
		and app_instance.has_method("export_save_data")
		and app_instance.has_method("import_save_data")
		and app_instance.has_method("reset_save_data")
	)


func _restore_saved_open_windows() -> void:
	if not is_inside_tree() or _saved_open_app_ids.is_empty():
		return

	var app_ids: Array[String] = _saved_open_app_ids.duplicate()
	var desired_focus_id: String = focused_app_id
	_saved_open_app_ids.clear()

	for app_id: String in app_ids:
		var app: AppResource = ContentRegistry.get_app(app_id)

		if app == null:
			push_warning(
				"WindowManager: saved app '%s' is not registered." % app_id
			)
			continue

		_on_request_open_app(app)

	if not desired_focus_id.is_empty() and open_windows.has(desired_focus_id):
		focus_window(desired_focus_id)


func _get_open_app_ids_in_z_order() -> Array[String]:
	var result: Array[String] = []

	for child: Node in get_children():
		if child is not WindowBase:
			continue

		var app_id: String = (child as WindowBase).app_id.strip_edges()
		if open_windows.get(app_id) != child or (child as WindowBase).is_closing():
			continue

		if not app_id.is_empty():
			result.append(app_id)

	return result


func _serialize_window_state(state: Dictionary) -> Dictionary:
	var position: Vector2 = state.get("position", Vector2.ZERO)
	var size_value: Vector2 = state.get("size", Vector2.ZERO)
	var work_rect: Rect2 = state.get("work_rect", Rect2())

	return {
		"position": _vector_to_data(position),
		"size": _vector_to_data(size_value),
		"work_rect": {
			"position": _vector_to_data(work_rect.position),
			"size": _vector_to_data(work_rect.size)
		},
		"pixel_scale": int(state.get("pixel_scale", 1)),
		"is_maximized": bool(state.get("is_maximized", false))
	}


func _deserialize_window_state(state: Dictionary) -> Dictionary:
	var raw_work_rect: Variant = state.get("work_rect", {})
	var work_rect := Rect2()

	if raw_work_rect is Dictionary:
		work_rect = Rect2(
			_data_to_vector(raw_work_rect.get("position", {})),
			_data_to_vector(raw_work_rect.get("size", {}))
		)

	return {
		"position": _data_to_vector(state.get("position", {})),
		"size": _data_to_vector(state.get("size", {})),
		"work_rect": work_rect,
		"pixel_scale": maxi(1, int(state.get("pixel_scale", 1))),
		"is_maximized": bool(state.get("is_maximized", false))
	}


func _vector_to_data(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _data_to_vector(value: Variant) -> Vector2:
	if value is Vector2:
		return value

	if value is Dictionary:
		return Vector2(
			float(value.get("x", 0.0)),
			float(value.get("y", 0.0))
		)

	return Vector2.ZERO


func _read_id_array(value: Variant) -> Array[String]:
	var result: Array[String] = []

	if value is not Array:
		return result

	for raw_id: Variant in value:
		var clean_id: String = str(raw_id).strip_edges()

		if not clean_id.is_empty() and not result.has(clean_id):
			result.append(clean_id)

	return result
