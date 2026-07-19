extends Control
class_name WindowManager

@export_category("Dependencies")
@export var window_base_scene: PackedScene

@export_category("Fallback OS Reserved Areas")
@export var reserved_top_height: float = 19.0
@export var reserved_bottom_height: float = 0.0
@export var reserved_left_width: float = 0.0
@export var reserved_right_width: float = 0.0

var open_windows: Dictionary = {}
var saved_window_states: Dictionary = {}
var focused_app_id: String = ""

var _last_work_rect: Rect2 = Rect2()
var _last_pixel_scale: int = 1
var _layout_refresh_queued: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sync_metrics()
	_last_work_rect = get_work_area_rect()
	_last_pixel_scale = KubuOSMetrics.get_pixel_scale()

	if not KubuOSMetrics.metrics_changed.is_connected(_on_metrics_changed):
		KubuOSMetrics.metrics_changed.connect(_on_metrics_changed)

	GlobalSignals.request_open_app.connect(_on_request_open_app)
	GlobalSignals.request_close_app.connect(close_window)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		cycle_windows()
		get_viewport().set_input_as_handled()


func _on_request_open_app(app: AppResource) -> void:
	if app == null:
		return

	var app_id: String = app.app_id.strip_edges()

	if app_id.is_empty():
		push_error("WindowManager: AppResource has an empty app_id.")
		return

	if open_windows.has(app_id):
		focus_window(app_id)
		return

	var new_window: WindowBase = window_base_scene.instantiate() as WindowBase

	if new_window == null:
		push_error(
			"WindowManager: window_base_scene did not instantiate a WindowBase."
		)
		return

	add_child(new_window)

	var profile: WindowPresentationProfile = app.resolve_window_profile()
	new_window.setup(app_id, app.app_name, profile)
	open_windows[app_id] = new_window

	new_window.window_focused.connect(focus_window.bind(app_id))
	new_window.window_closed.connect(_on_window_closed.bind(app_id))
	new_window.window_moved.connect(_on_window_changed.bind(app_id))
	new_window.window_resized.connect(_on_window_changed.bind(app_id))
	new_window.presentation_changed.connect(
		_on_window_presentation_changed.bind(app_id)
	)

	if app.app_scene != null:
		var app_instance: Node = app.app_scene.instantiate()

		if app_instance == null:
			push_error(
				"WindowManager: app_scene for '%s' could not be instantiated."
				% app_id
			)
		else:
			new_window.content_container.add_child(app_instance)

			if app_instance is Control:
				var app_control := app_instance as Control
				app_control.custom_minimum_size = Vector2.ZERO
				app_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				app_control.size_flags_vertical = Control.SIZE_EXPAND_FILL

			_restore_app_session_state(app_id, app_instance)
	else:
		push_warning(
			"WindowManager: AppResource '%s' has no app_scene."
			% app_id
		)

	_apply_saved_or_default_window_state(app_id, new_window)
	call_deferred("_notify_app_window_presentation", new_window)

	GlobalSignals.app_opened.emit(app_id)
	focus_window(app_id)


func focus_window(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]

	if window == null:
		return

	focused_app_id = app_id
	window.move_to_front()
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
		GlobalSignals.app_focused.emit("")

	GlobalSignals.app_closed.emit(app_id)
	window.queue_free()


func _restore_app_session_state(
	app_id: String,
	app_instance: Node
) -> void:
	if app_instance == null:
		return

	if not AppSessionStore.has_app_state(app_id):
		return

	if not app_instance.has_method("restore_app_session_state"):
		return

	var stored_state: Dictionary = AppSessionStore.get_app_state(app_id)
	app_instance.call_deferred("restore_app_session_state", stored_state)


func _save_app_session_state(
	app_id: String,
	window: WindowBase
) -> void:
	if app_id.is_empty() or window == null:
		return

	var app_instance: Node = _get_window_app_instance(window)

	if app_instance == null:
		return

	if not app_instance.has_method("get_app_session_state"):
		return

	var returned_state: Variant = app_instance.call("get_app_session_state")

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
	_clamp_window_to_work_area(window)
	_save_window_state(app_id, window)


func _on_window_presentation_changed(
	state: int,
	content_size: Vector2,
	app_id: String
) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]
	var app_instance: Node = _get_window_app_instance(window)

	if app_instance == null:
		return

	if app_instance.has_method("on_window_presentation_changed"):
		app_instance.call(
			"on_window_presentation_changed",
			state,
			content_size
		)


func _notify_app_window_presentation(window: WindowBase) -> void:
	if window == null or not is_instance_valid(window):
		return

	var content_size: Vector2 = window.size
	if is_instance_valid(window.content_container):
		content_size = window.content_container.size

	_on_window_presentation_changed(
		int(window.presentation_state),
		KubuOSMetrics.snap_vector(content_size),
		window.app_id
	)


func cycle_windows() -> void:
	if open_windows.size() <= 1:
		return

	for child in get_children():
		if child is WindowBase:
			var window := child as WindowBase
			window.move_to_front()
			window.pulse()
			focused_app_id = window.app_id
			GlobalSignals.app_focused.emit(window.app_id)
			break


func get_work_area_position() -> Vector2:
	if KubuOSMetrics != null and KubuOSMetrics.has_method("get_work_area_position"):
		return KubuOSMetrics.get_work_area_position()

	return Vector2(
		reserved_left_width,
		reserved_top_height
	)


func get_work_area_size() -> Vector2:
	var parent_size: Vector2 = _get_parent_size()

	if KubuOSMetrics != null and KubuOSMetrics.has_method("get_work_area_size"):
		return KubuOSMetrics.get_work_area_size(parent_size)

	return Vector2(
		max(0.0, parent_size.x - reserved_left_width - reserved_right_width),
		max(0.0, parent_size.y - reserved_top_height - reserved_bottom_height)
	)


func get_work_area_rect() -> Rect2:
	return Rect2(get_work_area_position(), get_work_area_size())


func _get_parent_size() -> Vector2:
	var parent_size: Vector2 = size

	if parent_size.x <= 0.0 or parent_size.y <= 0.0:
		parent_size = get_viewport_rect().size

	return KubuOSMetrics.snap_vector(parent_size)


func _sync_metrics() -> void:
	reserved_top_height = KubuOSMetrics.taskbar_height
	reserved_bottom_height = KubuOSMetrics.dock_height
	reserved_left_width = KubuOSMetrics.reserved_left_width
	reserved_right_width = KubuOSMetrics.reserved_right_width


func _on_metrics_changed() -> void:
	_sync_metrics()
	_queue_layout_refresh()


func _queue_layout_refresh() -> void:
	if _layout_refresh_queued:
		return

	_layout_refresh_queued = true
	call_deferred("_refresh_window_layout")


func _refresh_window_layout() -> void:
	_layout_refresh_queued = false

	var new_work_rect: Rect2 = get_work_area_rect()
	var new_pixel_scale: int = KubuOSMetrics.get_pixel_scale()
	var work_area_changed: bool = (
		_is_valid_work_rect(_last_work_rect)
		and not _last_work_rect.is_equal_approx(new_work_rect)
	)
	var scale_changed: bool = (
		_last_pixel_scale > 0
		and new_pixel_scale != _last_pixel_scale
	)

	for value in open_windows.values():
		if not value is WindowBase:
			continue

		var window := value as WindowBase

		if window.is_maximized:
			if (work_area_changed or scale_changed) and _is_valid_work_rect(_last_work_rect):
				window.restore_position = _remap_position_between_work_areas(
					window.restore_position,
					window.restore_size,
					_last_work_rect,
					new_work_rect
				)
				window.restore_size = _fit_size_to_work_area(
					window.restore_size,
					window.min_window_size,
					new_work_rect.size
				)

			window.apply_maximized_geometry()
		else:
			if (work_area_changed or scale_changed) and _is_valid_work_rect(_last_work_rect):
				window.position = _remap_position_between_work_areas(
					window.position,
					window.size,
					_last_work_rect,
					new_work_rect
				)

			_adapt_window_to_work_area(window, new_work_rect)

		_save_window_state(window.app_id, window)
		call_deferred("_notify_app_window_presentation", window)

	_last_work_rect = new_work_rect
	_last_pixel_scale = new_pixel_scale


func _apply_saved_or_default_window_state(app_id: String, window: WindowBase) -> void:
	if saved_window_states.has(app_id):
		_apply_saved_window_state(saved_window_states[app_id], window)
	else:
		_apply_default_window_state(window)

	_clamp_window_to_work_area(window)
	_save_window_state(app_id, window)


func _apply_saved_window_state(state: Dictionary, window: WindowBase) -> void:
	var current_work_rect: Rect2 = get_work_area_rect()
	var saved_work_rect: Rect2 = state.get("work_rect", Rect2())
	var target_position: Vector2 = state.get("position", window.position)
	var target_size: Vector2 = state.get("size", window.size)
	var target_state: int = int(state.get(
		"presentation_state",
		WindowBase.PresentationState.CUSTOM
	))
	var should_maximize: bool = bool(state.get("is_maximized", false))
	var restore_state: int = int(state.get(
		"restore_presentation_state",
		target_state
	))

	if _is_valid_work_rect(saved_work_rect):
		target_position = _remap_position_between_work_areas(
			target_position,
			target_size,
			saved_work_rect,
			current_work_rect
		)

	var resolved: Dictionary = _resolve_size_for_work_area(
		window,
		target_size,
		target_state,
		current_work_rect.size
	)
	target_size = resolved["size"]
	target_state = int(resolved["state"])

	window.apply_restored_geometry(
		target_position,
		target_size,
		target_state,
		should_maximize,
		restore_state
	)


func _apply_default_window_state(window: WindowBase) -> void:
	var work_rect: Rect2 = get_work_area_rect()
	var target_state: int = int(window.get_initial_presentation_state())
	var should_maximize: bool = target_state == WindowBase.PresentationState.MAXIMIZED
	var target_size: Vector2 = window.get_preferred_size()

	if target_state == WindowBase.PresentationState.COMPACT:
		target_size = window.get_compact_size()

	var resolved: Dictionary = _resolve_size_for_work_area(
		window,
		target_size,
		target_state,
		work_rect.size
	)
	target_size = resolved["size"]
	target_state = int(resolved["state"])

	var target_position: Vector2 = KubuOSMetrics.snap_vector(
		work_rect.position + ((work_rect.size - target_size) / 2.0)
	)

	window.apply_restored_geometry(
		target_position,
		target_size,
		target_state,
		should_maximize,
		target_state
	)


func _resolve_size_for_work_area(
	window: WindowBase,
	requested_size: Vector2,
	requested_state: int,
	work_size: Vector2
) -> Dictionary:
	var resolved_size: Vector2 = KubuOSMetrics.snap_vector(requested_size)
	var resolved_state: int = requested_state

	if _size_fits(resolved_size, work_size):
		return {
			"size": resolved_size,
			"state": resolved_state
		}

	if window.supports_compact():
		var compact_size: Vector2 = window.get_compact_size()

		if _size_fits(compact_size, work_size):
			return {
				"size": compact_size,
				"state": WindowBase.PresentationState.COMPACT
			}

	resolved_size = _fit_size_to_work_area(
		resolved_size,
		window.min_window_size,
		work_size
	)

	if resolved_state != WindowBase.PresentationState.COMPACT:
		resolved_state = WindowBase.PresentationState.CUSTOM

	return {
		"size": resolved_size,
		"state": resolved_state
	}


func _adapt_window_to_work_area(window: WindowBase, work_rect: Rect2) -> void:
	var resolved: Dictionary = _resolve_size_for_work_area(
		window,
		window.size,
		int(window.presentation_state),
		work_rect.size
	)
	var resolved_size: Vector2 = resolved["size"]
	var resolved_state: int = int(resolved["state"])

	window.apply_restored_geometry(
		window.position,
		resolved_size,
		resolved_state,
		false,
		resolved_state
	)
	_clamp_window_to_work_area(window)


func _save_window_state(app_id: String, window: WindowBase) -> void:
	if app_id.is_empty():
		return

	var saved_position: Vector2 = window.position
	var saved_size: Vector2 = window.size
	var saved_state: int = int(window.presentation_state)

	if window.is_maximized:
		saved_position = window.restore_position
		saved_size = window.restore_size

	saved_window_states[app_id] = {
		"position": KubuOSMetrics.snap_vector(saved_position),
		"size": KubuOSMetrics.snap_vector(saved_size),
		"presentation_state": saved_state,
		"restore_presentation_state": int(window.restore_presentation_state),
		"is_maximized": window.is_maximized,
		"work_rect": get_work_area_rect(),
		"pixel_scale": KubuOSMetrics.get_pixel_scale()
	}


func _remap_position_between_work_areas(
	source_position: Vector2,
	source_size: Vector2,
	old_work_rect: Rect2,
	new_work_rect: Rect2
) -> Vector2:
	if not _is_valid_work_rect(old_work_rect):
		return source_position

	var old_travel := Vector2(
		max(1.0, old_work_rect.size.x - source_size.x),
		max(1.0, old_work_rect.size.y - source_size.y)
	)
	var relative_position := Vector2(
		(source_position.x - old_work_rect.position.x) / old_travel.x,
		(source_position.y - old_work_rect.position.y) / old_travel.y
	)
	relative_position.x = clamp(relative_position.x, 0.0, 1.0)
	relative_position.y = clamp(relative_position.y, 0.0, 1.0)

	var new_travel := Vector2(
		max(0.0, new_work_rect.size.x - source_size.x),
		max(0.0, new_work_rect.size.y - source_size.y)
	)

	return KubuOSMetrics.snap_vector(
		new_work_rect.position + (new_travel * relative_position)
	)


func _clamp_window_to_work_area(window: WindowBase) -> void:
	if window == null:
		return

	var work_rect: Rect2 = get_work_area_rect()

	if not _is_valid_work_rect(work_rect):
		return

	if window.is_maximized:
		window.apply_maximized_geometry()
		return

	window.size = _fit_size_to_work_area(
		window.size,
		window.min_window_size,
		work_rect.size
	)

	var max_position := work_rect.position + Vector2(
		max(0.0, work_rect.size.x - window.size.x),
		max(0.0, work_rect.size.y - window.size.y)
	)

	window.position = KubuOSMetrics.snap_vector(Vector2(
		clamp(window.position.x, work_rect.position.x, max_position.x),
		clamp(window.position.y, work_rect.position.y, max_position.y)
	))


func _fit_size_to_work_area(
	requested_size: Vector2,
	minimum_size: Vector2,
	work_size: Vector2
) -> Vector2:
	var effective_minimum := Vector2(
		min(minimum_size.x, max(1.0, work_size.x)),
		min(minimum_size.y, max(1.0, work_size.y))
	)

	return KubuOSMetrics.snap_vector(Vector2(
		clamp(requested_size.x, effective_minimum.x, max(1.0, work_size.x)),
		clamp(requested_size.y, effective_minimum.y, max(1.0, work_size.y))
	))


func _size_fits(requested_size: Vector2, work_size: Vector2) -> bool:
	return (
		requested_size.x <= work_size.x
		and requested_size.y <= work_size.y
	)


func _is_valid_work_rect(work_rect: Rect2) -> bool:
	return work_rect.size.x > 0.0 and work_rect.size.y > 0.0
