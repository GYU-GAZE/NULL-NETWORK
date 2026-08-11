extends Control
class_name KubuNotificationPanel

signal panel_opened
signal panel_closed

@export_category("Fallback Layout")
@export var taskbar_height: float = 19.0
@export var panel_size: Vector2 = Vector2(360, 300)
@export var right_margin: float = 6.0
@export var top_gap: float = 0.0

@export_category("Animation")
@export var slide_duration: float = 0.22
@export var start_open: bool = false

@export_category("Behavior")
@export var close_on_notification_target: bool = true

@onready var panel_container: Control = %PanelContainer
@onready var notification_center: KubuNotificationCenter = %KubuNotificationCenter

var is_open: bool = false
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true

	_sync_metrics()

	if not KubuOSMetrics.metrics_changed.is_connected(_on_metrics_changed):
		KubuOSMetrics.metrics_changed.connect(_on_metrics_changed)

	if panel_container != null:
		panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
		panel_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel_container.custom_minimum_size = Vector2.ZERO

	if not GlobalSignals.request_toggle_notification_center.is_connected(toggle):
		GlobalSignals.request_toggle_notification_center.connect(toggle)

	if not GlobalSignals.request_close_notification_center.is_connected(close):
		GlobalSignals.request_close_notification_center.connect(close)

	if notification_center != null:
		if not notification_center.notification_target_requested.is_connected(_on_notification_target_requested):
			notification_center.notification_target_requested.connect(_on_notification_target_requested)

	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)

	await get_tree().process_frame

	is_open = start_open
	_apply_layout(false)


func open() -> void:
	if is_open:
		return

	is_open = true
	_apply_layout(true)
	panel_opened.emit()


func close() -> void:
	if not is_open:
		return

	is_open = false
	_apply_layout(true)
	panel_closed.emit()


func toggle() -> void:
	if is_open:
		close()
		return

	open()


func _on_resized() -> void:
	_apply_layout(false)


func _sync_metrics() -> void:
	taskbar_height = KubuOSMetrics.taskbar_height
	panel_size = KubuOSMetrics.notification_panel_size
	right_margin = KubuOSMetrics.notification_right_margin
	top_gap = KubuOSMetrics.notification_top_gap


func _on_metrics_changed() -> void:
	_sync_metrics()
	_apply_layout(false)


func _apply_layout(animated: bool) -> void:
	if panel_container == null:
		return

	panel_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_container.custom_minimum_size = Vector2.ZERO
	panel_container.size = panel_size

	var runtime_panel_size: Vector2 = _get_runtime_panel_size()
	var target_position: Vector2 = _get_open_position(runtime_panel_size)

	if not is_open:
		target_position = _get_closed_position(runtime_panel_size)

	if not animated:
		panel_container.position = target_position
		return

	_kill_tween()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(
		panel_container,
		"position",
		target_position,
		slide_duration
	)


func _get_open_position(runtime_panel_size: Vector2) -> Vector2:
	var root_size: Vector2 = _get_root_size()
	var chrome_right: float = KubuOSMetrics.reserved_right_width

	var x: float = (
		root_size.x
		- chrome_right
		- runtime_panel_size.x
		- right_margin
	)
	var y: float = taskbar_height + top_gap

	x = clamp(x, 0.0, max(0.0, root_size.x - chrome_right - runtime_panel_size.x))

	return Vector2(x, y)


func _get_closed_position(runtime_panel_size: Vector2) -> Vector2:
	var open_position: Vector2 = _get_open_position(runtime_panel_size)

	return Vector2(
		open_position.x,
		-runtime_panel_size.y
	)


func _get_runtime_panel_size() -> Vector2:
	var runtime_size: Vector2 = panel_container.size

	if runtime_size.x <= 0.0 or runtime_size.y <= 0.0:
		runtime_size = panel_size

	return Vector2(
		max(1.0, runtime_size.x),
		max(1.0, runtime_size.y)
	)


func _get_root_size() -> Vector2:
	var root_size: Vector2 = size

	if root_size.x <= 0.0 or root_size.y <= 0.0:
		root_size = get_viewport_rect().size

	return root_size


func _on_notification_target_requested(target_url: String) -> void:
	if close_on_notification_target:
		close()

	print("Notification target requested: ", target_url)


func _kill_tween() -> void:
	if _tween == null:
		return

	if _tween.is_running():
		_tween.kill()

	_tween = null
