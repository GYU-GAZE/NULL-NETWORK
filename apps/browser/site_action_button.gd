extends Button
class_name SiteActionButton

signal browser_navigation_requested(url: String)

enum FailedConditionBehavior {
	DO_NOTHING,
	DISABLE_BUTTON,
	HIDE_BUTTON
}

@export_category("Action")
## All gameplay-aware site interactions are authored through this Resource.
## Conditions/effects are shared with the rest of the game's data pipeline.
@export var action_data: SiteActionData
@export var failed_condition_behavior: FailedConditionBehavior = FailedConditionBehavior.DO_NOTHING

@export_category("Motion")
@export var motion_profile: UiMotionProfileData = preload(
	"res://data/content/ui/motion/null_network_motion.tres"
)

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


func get_target_url() -> String:
	if action_data == null:
		return ""
	return action_data.target_url.strip_edges()


func _on_pressed() -> void:
	if action_data == null:
		push_error("SiteActionButton '%s' requires SiteActionData." % name)
		return

	var context := _create_action_context()
	if not action_data.is_available(context):
		_motion_player.reject_control(self)
		_show_failed_condition_feedback()
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

	var clean_url := get_target_url()
	if not clean_url.is_empty():
		browser_navigation_requested.emit(clean_url)


func _on_mouse_entered() -> void:
	if disabled:
		return
	_motion_player.flash_control(self, Color(1.07, 1.1, 1.14, 1.0), 0.08)


func _validate_action_data() -> void:
	if action_data == null:
		push_error("SiteActionButton '%s' requires SiteActionData." % name)
		return
	for error: String in action_data.validate_data():
		push_error("SiteActionButton '%s': %s" % [name, error])


func _create_action_context() -> GameEffectContext:
	return GameEffectContext.create(
		"site_action:%s" % String(name),
		get_target_url()
	)


func _is_condition_met() -> bool:
	return (
		action_data != null
		and action_data.is_available(_create_action_context())
	)


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


func _show_failed_condition_feedback() -> void:
	if action_data == null or not action_data.show_failed_alert:
		return
	UniversalAlerts.show_alert(
		action_data.failed_alert_title,
		action_data.failed_alert_message,
		action_data.failed_alert_animation
	)
