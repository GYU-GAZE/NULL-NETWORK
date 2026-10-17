extends Button
class_name SiteActionButton

## Standalone/non-Browser consumers may still observe this signal. Inside a
## page, scoped context dispatch replaces manual scene wiring.
signal browser_navigation_requested(url: String)
enum FailedConditionBehavior { DO_NOTHING, DISABLE_BUTTON, HIDE_BUTTON }
@export_category("Action")
@export var action_data: SiteActionData
@export var failed_condition_behavior: FailedConditionBehavior = FailedConditionBehavior.DO_NOTHING
@export_category("Motion")
@export var motion_profile: UiMotionProfileData = preload("res://data/content/ui/motion/null_network_motion.tres")
var _motion_player: UiMotionPlayer
var action_binding: SiteActionBinding


func _ready() -> void:
	_motion_player = UiMotionPlayer.new()
	_motion_player.profile = motion_profile
	add_child(_motion_player)
	action_binding = SiteActionBinding.new()
	action_binding.action_data = action_data
	action_binding.failed_condition_behavior = failed_condition_behavior as SiteActionBinding.FailedConditionBehavior
	action_binding.connect_input = false
	add_child(action_binding)
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	if action_data == null:
		push_error("SiteActionButton '%s' requires SiteActionData." % name)
	else:
		for error: String in action_data.validate_data():
			push_error("SiteActionButton '%s': %s" % [name, error])


func refresh_action_state() -> void:
	if is_instance_valid(action_binding):
		action_binding.refresh()


func get_target_url() -> String:
	return action_data.target_url.strip_edges() if action_data != null else ""


func _on_pressed() -> void:
	var result := action_binding.trigger()
	if result.status == "success":
		_motion_player.confirm_control(self)
	elif result.status in ["blocked", "failed"]:
		_motion_player.reject_control(self)


func _on_mouse_entered() -> void:
	if not disabled:
		_motion_player.flash_control(self, Color(1.07, 1.1, 1.14, 1.0), 0.08)
