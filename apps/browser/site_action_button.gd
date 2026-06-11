extends Button
class_name SiteActionButton

signal browser_navigation_requested(url: String)

enum FlagMode {
	NONE,
	SET,
	TOGGLE
}

enum NumberMode {
	NONE,
	SET,
	ADD
}

enum VisibilityMode {
	NONE,
	SHOW,
	HIDE,
	TOGGLE
}

enum FailedConditionBehavior {
	DO_NOTHING,
	DISABLE_BUTTON,
	HIDE_BUTTON
}

@export_category("Condition")
@export var required_flag_name: String = ""
@export var required_flag_value: bool = true
@export var failed_condition_behavior: FailedConditionBehavior = FailedConditionBehavior.DO_NOTHING

@export_category("Failed Condition Alert")
@export var show_alert_on_failed_condition: bool = false
@export var failed_alert_title: String = "Access denied"
@export_multiline var failed_alert_message: String = "You cannot do that yet."
@export var failed_alert_animation: UniversalAlerts.AlertAnimation = UniversalAlerts.AlertAnimation.SHAKE

@export_category("Navigation")
@export var target_url: String = ""

@export_category("Game Flag")
@export var flag_name: String = ""
@export var flag_mode: FlagMode = FlagMode.NONE
@export var flag_value: bool = true

@export_category("Number Variable")
@export var number_var_name: String = ""
@export var number_mode: NumberMode = NumberMode.NONE
@export var number_value: int = 0

@export_category("Single Node Visibility")
@export var target_node_path: NodePath
@export var visibility_mode: VisibilityMode = VisibilityMode.NONE

@export_category("Multiple Node Visibility")
@export var nodes_to_show: Array[NodePath] = []
@export var nodes_to_hide: Array[NodePath] = []
@export var nodes_to_toggle: Array[NodePath] = []

@export_category("Notification")
@export var show_notification: bool = false
@export var notification_title: String = ""
@export_multiline var notification_message: String = ""

@export_category("Alert")
@export var show_alert: bool = false
@export var alert_title: String = ""
@export_multiline var alert_message: String = ""
@export var alert_animation: UniversalAlerts.AlertAnimation = UniversalAlerts.AlertAnimation.POP


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	_apply_condition_visual_state()


func _on_pressed() -> void:
	if not _is_condition_met():
		_apply_failed_condition_action()
		return

	_apply_flag_action()
	_apply_number_action()
	_apply_single_visibility_action()
	_apply_multiple_visibility_actions()
	_apply_notification_action()
	_apply_alert_action()
	_apply_navigation_action()


func _is_condition_met() -> bool:
	var clean_required_flag: String = required_flag_name.strip_edges()

	if clean_required_flag.is_empty():
		return true

	return GameState.get_flag(clean_required_flag) == required_flag_value


func _apply_condition_visual_state() -> void:
	if _is_condition_met():
		disabled = false
		visible = true
		return

	match failed_condition_behavior:
		FailedConditionBehavior.DO_NOTHING:
			return

		FailedConditionBehavior.DISABLE_BUTTON:
			disabled = true

		FailedConditionBehavior.HIDE_BUTTON:
			visible = false


func _apply_failed_condition_action() -> void:
	if not show_alert_on_failed_condition:
		return

	UniversalAlerts.show_alert(
		failed_alert_title,
		failed_alert_message,
		failed_alert_animation
	)


func _apply_flag_action() -> void:
	var clean_flag_name: String = flag_name.strip_edges()

	if clean_flag_name.is_empty():
		return

	match flag_mode:
		FlagMode.SET:
			GameState.set_flag(clean_flag_name, flag_value)

		FlagMode.TOGGLE:
			GameState.toggle_flag(clean_flag_name)

		FlagMode.NONE:
			return


func _apply_number_action() -> void:
	var clean_var_name: String = number_var_name.strip_edges()

	if clean_var_name.is_empty():
		return

	match number_mode:
		NumberMode.SET:
			GameState.set_number(clean_var_name, number_value)

		NumberMode.ADD:
			GameState.add_number(clean_var_name, number_value)

		NumberMode.NONE:
			return


func _apply_single_visibility_action() -> void:
	if visibility_mode == VisibilityMode.NONE:
		return

	if target_node_path.is_empty():
		return

	_apply_visibility_to_node_path(target_node_path, visibility_mode)


func _apply_multiple_visibility_actions() -> void:
	for node_path in nodes_to_show:
		_apply_visibility_to_node_path(node_path, VisibilityMode.SHOW)

	for node_path in nodes_to_hide:
		_apply_visibility_to_node_path(node_path, VisibilityMode.HIDE)

	for node_path in nodes_to_toggle:
		_apply_visibility_to_node_path(node_path, VisibilityMode.TOGGLE)


func _apply_visibility_to_node_path(node_path: NodePath, mode: VisibilityMode) -> void:
	if node_path.is_empty():
		return

	var target_node: Node = get_node_or_null(node_path)

	if target_node == null:
		push_warning("SiteActionButton: node_path inválido: %s" % str(node_path))
		return

	if not target_node is CanvasItem:
		push_warning("SiteActionButton: target_node precisa herdar CanvasItem para usar visible.")
		return

	var canvas_item: CanvasItem = target_node as CanvasItem

	match mode:
		VisibilityMode.SHOW:
			canvas_item.visible = true

		VisibilityMode.HIDE:
			canvas_item.visible = false

		VisibilityMode.TOGGLE:
			canvas_item.visible = not canvas_item.visible

		VisibilityMode.NONE:
			return


func _apply_notification_action() -> void:
	if not show_notification:
		return

	UniversalNotifications.push(notification_title, notification_message)


func _apply_alert_action() -> void:
	if not show_alert:
		return

	UniversalAlerts.show_alert(alert_title, alert_message, alert_animation)


func _apply_navigation_action() -> void:
	var clean_url: String = target_url.strip_edges()

	if clean_url.is_empty():
		return

	browser_navigation_requested.emit(clean_url)
