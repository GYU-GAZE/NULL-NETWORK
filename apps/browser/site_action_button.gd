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

@export_category("Action Resource")
## Preferred authoring path. New site interactions should use SiteActionData so
## game-state conditions/effects share the same pipeline as dialogues/events.
@export var action_data: SiteActionData

@export_category("Condition Presentation")
@export var failed_condition_behavior: FailedConditionBehavior = FailedConditionBehavior.DO_NOTHING

enum FailedConditionBehavior {
	DO_NOTHING,
	DISABLE_BUTTON,
	HIDE_BUTTON
}

@export_category("Motion")
@export var motion_profile: UiMotionProfileData = preload(
	"res://data/content/ui/motion/null_network_motion.tres"
)

# -----------------------------------------------------------------------------
# Legacy compatibility
# -----------------------------------------------------------------------------
# Existing .tscn content can keep using these fields while it is migrated to
# SiteActionData. They intentionally remain functional, but no new gameplay
# state logic should be authored here.
@export_category("Legacy: Condition")
@export var required_flag_name: String = ""
@export var required_flag_value: bool = true

@export_category("Legacy: Failed Condition Alert")
@export var show_alert_on_failed_condition: bool = false
@export var failed_alert_title: String = "Access denied"
@export_multiline var failed_alert_message: String = "You cannot do that yet."
@export var failed_alert_animation: UniversalAlerts.AlertAnimation = UniversalAlerts.AlertAnimation.SHAKE

@export_category("Legacy: Navigation")
@export var target_url: String = ""

@export_category("Legacy: Game Flag")
@export var flag_name: String = ""
@export var flag_mode: FlagMode = FlagMode.NONE
@export var flag_value: bool = true

@export_category("Legacy: Number Variable")
@export var number_var_name: String = ""
@export var number_mode: NumberMode = NumberMode.NONE
@export var number_value: int = 0

@export_category("Legacy: Single Node Visibility")
@export var target_node_path: NodePath
@export var visibility_mode: VisibilityMode = VisibilityMode.NONE

@export_category("Legacy: Multiple Node Visibility")
@export var nodes_to_show: Array[NodePath] = []
@export var nodes_to_hide: Array[NodePath] = []
@export var nodes_to_toggle: Array[NodePath] = []

@export_category("Legacy: Notification")
@export var show_notification: bool = false
@export var notification_title: String = ""
@export_multiline var notification_message: String = ""

@export_category("Legacy: Alert")
@export var show_alert: bool = false
@export var alert_title: String = ""
@export_multiline var alert_message: String = ""
@export var alert_animation: UniversalAlerts.AlertAnimation = UniversalAlerts.AlertAnimation.POP

var _motion_player: UiMotionPlayer


func _ready() -> void:
	_motion_player = UiMotionPlayer.new()
	_motion_player.name = "SiteActionMotionPlayer"
	_motion_player.profile = motion_profile
	add_child(_motion_player)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	_validate_action_data()
	_apply_condition_visual_state()


func refresh_action_state() -> void:
	_apply_condition_visual_state()


func _on_pressed() -> void:
	if action_data != null:
		_execute_resource_action()
		return
	_execute_legacy_action()


func _execute_resource_action() -> void:
	var context := _create_action_context()
	if not action_data.is_available(context):
		_motion_player.reject_control(self)
		_apply_failed_condition_feedback()
		return

	_motion_player.confirm_control(self)
	var failed_effects := action_data.apply_effects(context)
	if not failed_effects.is_empty():
		push_error(
			"SiteActionButton '%s' failed effects: %s" % [
				name,
				", ".join(failed_effects)
			]
		)
		return

	if action_data.show_notification:
		UniversalNotifications.push(
			action_data.notification_title,
			action_data.notification_message
		)
	if action_data.show_alert:
		UniversalAlerts.show_alert(
			action_data.alert_title,
			action_data.alert_message,
			action_data.alert_animation
		)
	var clean_url := action_data.target_url.strip_edges()
	if not clean_url.is_empty():
		browser_navigation_requested.emit(clean_url)


func _execute_legacy_action() -> void:
	if not _is_legacy_condition_met():
		_motion_player.reject_control(self)
		_apply_failed_condition_feedback()
		return
	_motion_player.confirm_control(self)
	_apply_legacy_flag_action()
	_apply_legacy_number_action()
	_apply_single_visibility_action()
	_apply_multiple_visibility_actions()
	_apply_legacy_notification_action()
	_apply_legacy_alert_action()
	_apply_legacy_navigation_action()


func _on_mouse_entered() -> void:
	if disabled:
		return
	_motion_player.flash_control(self, Color(1.07, 1.1, 1.14, 1.0), 0.08)


func _validate_action_data() -> void:
	if action_data == null:
		return
	for error: String in action_data.validate_data():
		push_error("SiteActionButton '%s': %s" % [name, error])


func _create_action_context() -> GameEffectContext:
	var target := ""
	if action_data != null:
		target = action_data.target_url
	elif not target_url.is_empty():
		target = target_url
	return GameEffectContext.create(
		"site_action:%s" % String(name),
		target
	)


func _is_condition_met() -> bool:
	if action_data != null:
		return action_data.is_available(_create_action_context())
	return _is_legacy_condition_met()


func _is_legacy_condition_met() -> bool:
	var clean_required_flag := required_flag_name.strip_edges()
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


func _apply_failed_condition_feedback() -> void:
	if action_data != null:
		if not action_data.show_failed_alert:
			return
		UniversalAlerts.show_alert(
			action_data.failed_alert_title,
			action_data.failed_alert_message,
			action_data.failed_alert_animation
		)
		return
	if show_alert_on_failed_condition:
		UniversalAlerts.show_alert(
			failed_alert_title,
			failed_alert_message,
			failed_alert_animation
		)


func _apply_legacy_flag_action() -> void:
	var clean_flag_name := flag_name.strip_edges()
	if clean_flag_name.is_empty():
		return
	match flag_mode:
		FlagMode.SET:
			GameState.set_flag(clean_flag_name, flag_value)
		FlagMode.TOGGLE:
			GameState.toggle_flag(clean_flag_name)
		FlagMode.NONE:
			return


func _apply_legacy_number_action() -> void:
	var clean_var_name := number_var_name.strip_edges()
	if clean_var_name.is_empty():
		return
	match number_mode:
		NumberMode.SET:
			GameState.set_number(clean_var_name, number_value)
		NumberMode.ADD:
			GameState.set_number(
				clean_var_name,
				GameState.get_number(clean_var_name) + number_value
			)
		NumberMode.NONE:
			return


func _apply_single_visibility_action() -> void:
	if visibility_mode == VisibilityMode.NONE or target_node_path.is_empty():
		return
	_apply_visibility_to_node_path(target_node_path, visibility_mode)


func _apply_multiple_visibility_actions() -> void:
	for node_path: NodePath in nodes_to_show:
		_apply_visibility_to_node_path(node_path, VisibilityMode.SHOW)
	for node_path: NodePath in nodes_to_hide:
		_apply_visibility_to_node_path(node_path, VisibilityMode.HIDE)
	for node_path: NodePath in nodes_to_toggle:
		_apply_visibility_to_node_path(node_path, VisibilityMode.TOGGLE)


func _apply_visibility_to_node_path(node_path: NodePath, mode: VisibilityMode) -> void:
	if node_path.is_empty():
		return
	var target_node := get_node_or_null(node_path)
	if target_node == null:
		push_warning("SiteActionButton: invalid node_path: %s" % str(node_path))
		return
	if not target_node is CanvasItem:
		push_warning("SiteActionButton target must inherit CanvasItem for visibility actions.")
		return
	var canvas_item := target_node as CanvasItem
	match mode:
		VisibilityMode.SHOW:
			canvas_item.visible = true
		VisibilityMode.HIDE:
			canvas_item.visible = false
		VisibilityMode.TOGGLE:
			canvas_item.visible = not canvas_item.visible
		VisibilityMode.NONE:
			return


func _apply_legacy_notification_action() -> void:
	if show_notification:
		UniversalNotifications.push(notification_title, notification_message)


func _apply_legacy_alert_action() -> void:
	if show_alert:
		UniversalAlerts.show_alert(alert_title, alert_message, alert_animation)


func _apply_legacy_navigation_action() -> void:
	var clean_url := target_url.strip_edges()
	if not clean_url.is_empty():
		browser_navigation_requested.emit(clean_url)
