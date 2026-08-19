@tool
extends Resource
class_name SiteActionData

## Data-driven interaction definition for Browser site controls.
##
## Browser UI owns presentation/navigation, while game-state conditions and
## effects reuse the same ConditionSetData/GameEffectData pipeline used by
## dialogues, incidents and story content.

@export_category("Availability")
@export var conditions: ConditionSetData

@export_category("Effects")
@export var effects: Array[GameEffectData] = []

@export_category("Navigation")
@export var target_url: String = ""

@export_category("Failed Condition Feedback")
@export var show_failed_alert: bool = false
@export var failed_alert_title: String = "Access denied"
@export_multiline var failed_alert_message: String = "You cannot do that yet."
@export var failed_alert_animation: UniversalAlerts.AlertAnimation = (
	UniversalAlerts.AlertAnimation.SHAKE
)

@export_category("Success Feedback")
@export var show_notification: bool = false
@export var notification_title: String = ""
@export_multiline var notification_message: String = ""
@export var show_alert: bool = false
@export var alert_title: String = ""
@export_multiline var alert_message: String = ""
@export var alert_animation: UniversalAlerts.AlertAnimation = (
	UniversalAlerts.AlertAnimation.POP
)


func is_available(context: GameEffectContext) -> bool:
	if context == null:
		return false
	return conditions == null or conditions.is_met(context.to_condition_context())


func apply_effects(context: GameEffectContext) -> PackedStringArray:
	return GameEffectData.apply_all(effects, context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)
	for index: int in range(effects.size()):
		var effect: GameEffectData = effects[index]
		if effect == null:
			errors.append("Effect %d is null." % index)
			continue
		for error: String in effect.validate_data():
			errors.append("Effect %d: %s" % [index, error])
	if show_failed_alert and failed_alert_title.strip_edges().is_empty() \
		and failed_alert_message.strip_edges().is_empty():
		errors.append("Failed-condition alert requires a title or message.")
	if show_notification and notification_title.strip_edges().is_empty() \
		and notification_message.strip_edges().is_empty():
		errors.append("Notification requires a title or message.")
	if show_alert and alert_title.strip_edges().is_empty() \
		and alert_message.strip_edges().is_empty():
		errors.append("Alert requires a title or message.")
	return errors
