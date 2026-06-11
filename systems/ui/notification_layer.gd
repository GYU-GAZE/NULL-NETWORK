extends Control
class_name NotificationLayer

@export var toast_scene: PackedScene
@export var top_offset: float = 40.0
@export var right_offset: float = 16.0
@export var hidden_offset_y: float = -120.0
@export var max_visible_notifications: int = 1

var queue: Array[Dictionary] = []
var active_toasts: Array[NotificationToast] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not UniversalNotifications.notification_requested.is_connected(_on_notification_requested):
		UniversalNotifications.notification_requested.connect(_on_notification_requested)


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
	toast.size = toast.get_combined_minimum_size()

	toast.setup(
		str(data.get("title", "")),
		str(data.get("message", ""))
	)

	if not toast.finished.is_connected(_on_toast_finished):
		toast.finished.connect(_on_toast_finished)

	await get_tree().process_frame
	await get_tree().process_frame

	var final_pos: Vector2 = _get_toast_final_position(toast)
	var hidden_pos: Vector2 = _get_toast_hidden_position(toast, final_pos)

	toast.play(final_pos, hidden_pos)


func _get_toast_final_position(toast: NotificationToast) -> Vector2:
	var layer_size: Vector2 = size
	var toast_size: Vector2 = toast.size

	if layer_size.x <= 0.0 or layer_size.y <= 0.0:
		layer_size = get_viewport_rect().size

	if toast_size.x <= 0.0 or toast_size.y <= 0.0:
		toast_size = toast.get_combined_minimum_size()

	var x: float = layer_size.x - toast_size.x - right_offset
	var y: float = top_offset

	x = clamp(x, 0.0, max(0.0, layer_size.x - toast_size.x))
	y = clamp(y, 0.0, max(0.0, layer_size.y - toast_size.y))

	return Vector2(x, y)


func _get_toast_hidden_position(toast: NotificationToast, final_pos: Vector2) -> Vector2:
	var toast_size: Vector2 = toast.size

	if toast_size.x <= 0.0 or toast_size.y <= 0.0:
		toast_size = toast.get_combined_minimum_size()

	return Vector2(
		final_pos.x,
		-toast_size.y - abs(hidden_offset_y)
	)


func _on_toast_finished(toast: NotificationToast) -> void:
	active_toasts.erase(toast)
	_try_show_next()
