extends Resource
class_name StoryEventTriggerData


enum TriggerType {
	CAMPAIGN_CREATED,
	CAMPAIGN_LOADED,
	TIME_ADVANCED,
	FLAG_CHANGED,
	LOCATION_CHANGED,
	MANUAL
}

@export var trigger_type: TriggerType = TriggerType.MANUAL

@export_category("Optional Trigger Filters")
@export var watched_flag_name: String = ""
@export var watched_flag_value: bool = true
@export var watched_location_id: String = ""
@export var manual_trigger_id: String = ""


func matches(trigger_context: Dictionary) -> bool:
	if int(trigger_context.get("trigger_type", -1)) != int(trigger_type):
		return false

	match trigger_type:
		TriggerType.FLAG_CHANGED:
			var clean_flag: String = watched_flag_name.strip_edges()

			if not clean_flag.is_empty() and str(
				trigger_context.get("flag_name", "")
			).strip_edges() != clean_flag:
				return false

			return bool(
				trigger_context.get("flag_value", false)
			) == watched_flag_value

		TriggerType.LOCATION_CHANGED:
			var clean_location: String = watched_location_id.strip_edges()

			return (
				clean_location.is_empty()
				or str(trigger_context.get("location_id", "")).strip_edges()
				== clean_location
			)

		TriggerType.MANUAL:
			return str(
				trigger_context.get("manual_trigger_id", "")
			).strip_edges() == manual_trigger_id.strip_edges()

	return true


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if (
		trigger_type == TriggerType.MANUAL
		and manual_trigger_id.strip_edges().is_empty()
	):
		errors.append("manual_trigger_id cannot be empty for a MANUAL trigger.")

	return errors
