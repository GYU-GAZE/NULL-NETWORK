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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sync_metrics()

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

	var app_id: String = app.app_id

	if open_windows.has(app_id):
		focus_window(app_id)
		return

	var window_size: Vector2 = app.default_window_size
	var min_window_size: Vector2 = app.min_window_size
	var can_resize: bool = app.can_resize

	var new_window: WindowBase = window_base_scene.instantiate() as WindowBase
	add_child(new_window)

	new_window.setup(
		app.app_id,
		app.app_name,
		window_size,
		min_window_size,
		can_resize
	)

	open_windows[app_id] = new_window

	if app.app_scene:
		var app_instance: Node = app.app_scene.instantiate()
		new_window.content_container.add_child(app_instance)

		if app_instance is Control:
			var app_control := app_instance as Control
			app_control.custom_minimum_size = Vector2.ZERO
			app_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			app_control.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_apply_saved_or_default_window_state(app_id, new_window)

	new_window.window_focused.connect(focus_window.bind(app_id))
	new_window.window_closed.connect(_on_window_closed.bind(app_id))
	new_window.window_moved.connect(_on_window_changed.bind(app_id))
	new_window.window_resized.connect(_on_window_changed.bind(app_id))

	focus_window(app_id)


func focus_window(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]
	window.move_to_front()
	window.pulse()


func close_window(app_id: String) -> void:
	if open_windows.has(app_id):
		open_windows[app_id].close()


func _on_window_closed(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]
	_save_window_state(app_id, window)

	open_windows.erase(app_id)
	window.queue_free()


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
	return Vector2(
		reserved_left_width,
		reserved_top_height
	)


func get_work_area_size() -> Vector2:
	var parent_size: Vector2 = _get_parent_size()

	return Vector2(
		max(0.0, parent_size.x - reserved_left_width - reserved_right_width),
		max(0.0, parent_size.y - reserved_top_height - reserved_bottom_height)
	)


func _get_parent_size() -> Vector2:
	var parent_size: Vector2 = size

	if parent_size.x <= 0.0 or parent_size.y <= 0.0:
		parent_size = get_viewport_rect().size

	return parent_size


func _sync_metrics() -> void:
	reserved_top_height = KubuOSMetrics.taskbar_height
	reserved_bottom_height = KubuOSMetrics.dock_height
	reserved_left_width = KubuOSMetrics.reserved_left_width
	reserved_right_width = KubuOSMetrics.reserved_right_width


func _on_metrics_changed() -> void:
	_sync_metrics()

	for window in open_windows.values():
		if window is WindowBase:
			_clamp_window_to_work_area(window as WindowBase)


func _apply_saved_or_default_window_state(app_id: String, window: WindowBase) -> void:
	if saved_window_states.has(app_id):
		var state: Dictionary = saved_window_states[app_id]

		if state.has("size"):
			window.size = _enforce_min_size(state["size"], window.min_window_size)

		if state.has("position"):
			window.position = state["position"]
	else:
		var work_position: Vector2 = get_work_area_position()
		var work_size: Vector2 = get_work_area_size()

		window.position = work_position + ((work_size - window.size) / 2.0)

	_clamp_window_to_work_area(window)
	_save_window_state(app_id, window)


func _save_window_state(app_id: String, window: WindowBase) -> void:
	if window.is_maximized:
		saved_window_states[app_id] = {
			"position": window.restore_position,
			"size": window.restore_size
		}
		return

	saved_window_states[app_id] = {
		"position": window.position,
		"size": window.size
	}


func _clamp_window_to_work_area(window: WindowBase) -> void:
	if window == null:
		return

	var work_position: Vector2 = get_work_area_position()
	var work_size: Vector2 = get_work_area_size()

	var max_allowed_size: Vector2 = Vector2(
		max(window.min_window_size.x, work_size.x),
		max(window.min_window_size.y, work_size.y)
	)

	window.size = Vector2(
		min(window.size.x, max_allowed_size.x),
		min(window.size.y, max_allowed_size.y)
	)

	var max_position: Vector2 = work_position + Vector2(
		max(0.0, work_size.x - window.size.x),
		max(0.0, work_size.y - window.size.y)
	)

	window.position = Vector2(
		clamp(window.position.x, work_position.x, max_position.x),
		clamp(window.position.y, work_position.y, max_position.y)
	)


func _enforce_min_size(value: Vector2, min_size: Vector2) -> Vector2:
	return Vector2(
		max(value.x, min_size.x),
		max(value.y, min_size.y)
	)
