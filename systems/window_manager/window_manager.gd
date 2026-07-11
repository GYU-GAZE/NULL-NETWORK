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

	new_window.setup(
		app_id,
		app.app_name,
		app.default_window_size,
		app.min_window_size,
		app.can_resize
	)

	open_windows[app_id] = new_window

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

	new_window.window_focused.connect(focus_window.bind(app_id))
	new_window.window_closed.connect(_on_window_closed.bind(app_id))
	new_window.window_moved.connect(_on_window_changed.bind(app_id))
	new_window.window_resized.connect(_on_window_changed.bind(app_id))

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
	_clamp_window_to_work_area(window)
	_save_window_state(app_id, window)


func cycle_windows() -> void:
	if open_windows.size() <= 1:
		return

	for child in get_children():
		if child is WindowBase:
			child.move_to_front()
			child.pulse()
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
	var scale_changed: bool = (
		_last_pixel_scale > 0
		and new_pixel_scale != _last_pixel_scale
	)

	for value in open_windows.values():
		if not value is WindowBase:
			continue

		var window := value as WindowBase

		if window.is_maximized:
			if scale_changed and _is_valid_work_rect(_last_work_rect):
				var restore_rect := Rect2(window.restore_position, window.restore_size)
				var remapped_restore := _remap_rect_between_work_areas(
					restore_rect,
					_last_work_rect,
					new_work_rect
				)
				window.restore_position = remapped_restore.position
				window.restore_size = remapped_restore.size

			window.apply_maximized_geometry()
		else:
			if scale_changed and _is_valid_work_rect(_last_work_rect):
				_remap_window_between_work_areas(window, _last_work_rect, new_work_rect)
			else:
				_clamp_window_to_work_area(window)

		_save_window_state(window.app_id, window)

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
	var target_rect := Rect2(
		state.get("position", window.position),
		state.get("size", window.size)
	)

	var saved_scale: int = int(state.get("pixel_scale", KubuOSMetrics.get_pixel_scale()))
	var saved_work_rect: Rect2 = state.get("work_rect", Rect2())
	var current_work_rect: Rect2 = get_work_area_rect()

	if (
		saved_scale != KubuOSMetrics.get_pixel_scale()
		and _is_valid_work_rect(saved_work_rect)
	):
		target_rect = _remap_rect_between_work_areas(
			target_rect,
			saved_work_rect,
			current_work_rect
		)

	window.size = _fit_size_to_work_area(
		target_rect.size,
		window.min_window_size,
		current_work_rect.size
	)
	window.position = KubuOSMetrics.snap_vector(target_rect.position)


func _apply_default_window_state(window: WindowBase) -> void:
	var work_rect: Rect2 = get_work_area_rect()
	var reference_size: Vector2 = KubuOSMetrics.get_work_area_size(
		KubuOSMetrics.reference_workspace
	)

	var size_ratio := Vector2(
		_safe_ratio(window.size.x, reference_size.x),
		_safe_ratio(window.size.y, reference_size.y)
	)

	size_ratio.x = clamp(size_ratio.x, 0.0, 1.0)
	size_ratio.y = clamp(size_ratio.y, 0.0, 1.0)

	var target_size := Vector2(
		work_rect.size.x * size_ratio.x,
		work_rect.size.y * size_ratio.y
	)

	window.size = _fit_size_to_work_area(
		target_size,
		window.min_window_size,
		work_rect.size
	)
	window.position = KubuOSMetrics.snap_vector(
		work_rect.position + ((work_rect.size - window.size) / 2.0)
	)


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
		"pixel_scale": KubuOSMetrics.get_pixel_scale()
	}


func _remap_window_between_work_areas(
	window: WindowBase,
	old_work_rect: Rect2,
	new_work_rect: Rect2
) -> void:
	var current_rect := Rect2(window.position, window.size)
	var remapped_rect := _remap_rect_between_work_areas(
		current_rect,
		old_work_rect,
		new_work_rect
	)

	window.size = _fit_size_to_work_area(
		remapped_rect.size,
		window.min_window_size,
		new_work_rect.size
	)
	window.position = KubuOSMetrics.snap_vector(remapped_rect.position)
	_clamp_window_to_work_area(window)


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


func _safe_ratio(value: float, divisor: float) -> float:
	if divisor <= 0.0:
		return 0.0

	return value / divisor


func _is_valid_work_rect(work_rect: Rect2) -> bool:
	return work_rect.size.x > 0.0 and work_rect.size.y > 0.0
