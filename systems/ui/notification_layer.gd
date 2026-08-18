extends Control
class_name NotificationLayer

@export_category("Scene")
@export var toast_scene: PackedScene

@export_category("Fallback OS Chrome Position")
@export var taskbar_height: float = 19.0
@export var right_margin: float = 6.0
@export var top_gap: float = 4.0
@export var hidden_extra_y: float = 6.0

@export_category("Behavior")
@export var max_visible_notifications: int = 1
@export var suppress_when_notification_center_open: bool = false

var queue: Array[Dictionary] = []
var active_toasts: Array[NotificationToast] = []
var is_notification_center_open: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sync_metrics()

	if not KubuOSMetrics.metrics_changed.is_connected(_on_metrics_changed):
		KubuOSMetrics.metrics_changed.connect(_on_metrics_changed)

	if not UniversalNotifications.notification_requested.is_connected(_on_notification_requested):
		UniversalNotifications.notification_requested.connect(_on_notification_requested)

	if GlobalSignals.has_signal("request_toggle_notification_center"):
		if not GlobalSignals.request_toggle_notification_center.is_connected(_on_notification_center_toggled):
			GlobalSignals.request_toggle_notification_center.connect(_on_notification_center_toggled)

	if GlobalSignals.has_signal("request_close_notification_center"):
		if not GlobalSignals.request_close_notification_center.is_connected(_on_notification_center_closed):
			GlobalSignals.request_close_notification_center.connect(_on_notification_center_closed)


func _sync_metrics() -> void:
	taskbar_height = KubuOSMetrics.taskbar_height
	right_margin = KubuOSMetrics.toast_right_margin
	top_gap = KubuOSMetrics.toast_top_gap
	hidden_extra_y = KubuOSMetrics.toast_hidden_extra_y


func _on_metrics_changed() -> void:
	_sync_metrics()


func _on_notification_requested(title: String, message: String) -> void:
	queue.append({
		"title": title,
		"message": message
	})

	_try_show_next()


func _try_show_next() -> void:
	if toast_scene == null:
		push_error("NotificationLayer: toast_scene não configurada.")
		return

	if suppress_when_notification_center_open and is_notification_center_open:
		return

	if active_toasts.size() >= max_visible_notifications:
		return

	if queue.is_empty():
		return

	var data: Dictionary = queue.pop_front()

	var toast: NotificationToast = toast_scene.instantiate() as NotificationToast

	if toast == null:
		push_error("NotificationLayer: toast_scene precisa ter root NotificationToast.")
		return

	add_child(toast)
	active_toasts.append(toast)

	toast.set_anchors_preset(Control.PRESET_TOP_LEFT)
	toast.position = Vector2.ZERO

	toast.setup(
		str(data.get("title", "")),
		str(data.get("message", ""))
	)

	if not toast.finished.is_connected(_on_toast_finished):
		toast.finished.connect(_on_toast_finished)

	await get_tree().process_frame
	await get_tree().process_frame

	var toast_size: Vector2 = toast.get_combined_minimum_size()

	if toast_size.x <= 0.0 or toast_size.y <= 0.0:
		toast_size = Vector2(320, 80)

	toast.size = toast_size

	var final_pos: Vector2 = _get_toast_final_position(toast)
	var hidden_pos: Vector2 = _get_toast_hidden_position(toast, final_pos)

	toast.play(final_pos, hidden_pos)


func _get_toast_final_position(toast: NotificationToast) -> Vector2:
	var layer_size: Vector2 = _get_layer_size()
	var toast_size: Vector2 = toast.size

	if toast_size.x <= 0.0 or toast_size.y <= 0.0:
		toast_size = toast.get_combined_minimum_size()

	var chrome_right: float = KubuOSMetrics.reserved_right_width
	var x: float = layer_size.x - chrome_right - toast_size.x - right_margin
	var y: float = taskbar_height + top_gap

	x = clamp(x, 0.0, max(0.0, layer_size.x - chrome_right - toast_size.x))
	y = clamp(y, taskbar_height, max(taskbar_height, layer_size.y - toast_size.y))

	return KubuOSMetrics.snap_vector(Vector2(x, y))


func _get_toast_hidden_position(toast: NotificationToast, final_pos: Vector2) -> Vector2:
	var toast_size: Vector2 = toast.size

	if toast_size.x <= 0.0 or toast_size.y <= 0.0:
		toast_size = toast.get_combined_minimum_size()

	return KubuOSMetrics.snap_vector(Vector2(
		final_pos.x,
		-toast_size.y - hidden_extra_y
	))


func _get_layer_size() -> Vector2:
	var layer_size: Vector2 = size

	if layer_size.x <= 0.0 or layer_size.y <= 0.0:
		layer_size = get_viewport_rect().size

	return layer_size


func _on_toast_finished(toast: NotificationToast) -> void:
	active_toasts.erase(toast)
	_try_show_next()


func _on_notification_center_toggled() -> void:
	is_notification_center_open = not is_notification_center_open


func _on_notification_center_closed() -> void:
	is_notification_center_open = false
