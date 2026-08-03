extends Resource
class_name StoryEventStepData


enum StepType {
	SHOW_ALERT,
	SHOW_NOTIFICATION,
	OPEN_APP,
	NAVIGATE_BROWSER,
	START_DIALOGUE,
	START_ENCOUNTER,
	DISCOVER_LOCATION,
	INSTALL_APP,
	ADD_LEAD,
	APPLY_EFFECTS,
	START_ACTIVITY,
	ADVANCE_EVENT
}

enum CompletionMode {
	AUTO,
	EXTERNAL_ACKNOWLEDGEMENT
}

@export_category("Identity")
@export var step_id: String = ""
@export var step_type: StepType = StepType.SHOW_ALERT
@export var completion_mode: CompletionMode = CompletionMode.AUTO

@export_category("Presentation")
@export var title: String = ""
@export_multiline var message: String = ""
@export var alert_animation: UniversalAlerts.AlertAnimation = (
	UniversalAlerts.AlertAnimation.POP
)
@export var notification_type: KubuNotificationData.NotificationType = (
	KubuNotificationData.NotificationType.SYSTEM
)
@export var notification_priority: KubuNotificationData.NotificationPriority = (
	KubuNotificationData.NotificationPriority.NORMAL
)

@export_category("Stable Content IDs")
@export var app_id: String = ""
@export var browser_url: String = ""
@export var dialogue_id: String = ""
@export var encounter_id: String = ""
@export var location_id: String = ""
@export var lead_id: String = ""
@export var target_event_id: String = ""

@export_category("Notification Routing")
@export var target_url: String = ""
@export var source_app_id: String = ""
@export var source_thread_id: String = ""

@export_category("Rules")
@export var effects: Array[GameEffectData] = []
@export var activity: ActivityDefinitionData


func get_display_id() -> String:
	return step_id.strip_edges()


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("step_id cannot be empty.")

	match step_type:
		StepType.SHOW_ALERT:
			if title.strip_edges().is_empty() and message.strip_edges().is_empty():
				errors.append("SHOW_ALERT requires a title or message.")

		StepType.SHOW_NOTIFICATION:
			if title.strip_edges().is_empty() and message.strip_edges().is_empty():
				errors.append("SHOW_NOTIFICATION requires a title or message.")

		StepType.OPEN_APP, StepType.INSTALL_APP:
			_validate_registered_id(
				errors,
				ContentRegistry.CATEGORY_APPS,
				app_id,
				"app_id"
			)

		StepType.NAVIGATE_BROWSER:
			if browser_url.strip_edges().is_empty():
				errors.append("NAVIGATE_BROWSER requires browser_url.")

		StepType.START_DIALOGUE:
			if dialogue_id.strip_edges().is_empty():
				errors.append("START_DIALOGUE requires dialogue_id.")

		StepType.START_ENCOUNTER:
			_validate_registered_id(
				errors,
				ContentRegistry.CATEGORY_COMBAT_ENCOUNTERS,
				encounter_id,
				"encounter_id"
			)

		StepType.DISCOVER_LOCATION:
			_validate_registered_id(
				errors,
				ContentRegistry.CATEGORY_LOCATIONS,
				location_id,
				"location_id"
			)

		StepType.ADD_LEAD:
			if lead_id.strip_edges().is_empty():
				errors.append("ADD_LEAD requires lead_id.")

		StepType.APPLY_EFFECTS:
			if effects.is_empty():
				errors.append("APPLY_EFFECTS requires at least one effect.")

		StepType.START_ACTIVITY:
			if activity == null:
				errors.append("START_ACTIVITY requires an ActivityDefinitionData.")
			elif not activity.validate_data().is_empty():
				for error: String in activity.validate_data():
					errors.append("Activity: %s" % error)

		StepType.ADVANCE_EVENT:
			if target_event_id.strip_edges().is_empty():
				errors.append("ADVANCE_EVENT requires target_event_id.")

	for index: int in range(effects.size()):
		var effect: GameEffectData = effects[index]

		if effect == null:
			errors.append("Effect %d is null." % index)
			continue

		for error: String in effect.validate_data():
			errors.append("Effect %d: %s" % [index, error])

	return errors


func _validate_registered_id(
	errors: PackedStringArray,
	_category: StringName,
	raw_id: String,
	field_name: String
) -> void:
	var clean_id: String = raw_id.strip_edges()

	if clean_id.is_empty():
		errors.append("%s cannot be empty." % field_name)
