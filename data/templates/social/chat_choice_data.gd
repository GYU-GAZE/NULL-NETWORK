extends Resource
class_name ChatChoiceData


@export_category("Identity")
@export var choice_id: String = ""
@export var interaction_id: String = ""

@export_category("Presentation")
@export var display_text: String = ""
@export var sort_order: int = 0
@export var availability_conditions: ConditionSetData


func get_display_id() -> String:
	return choice_id.strip_edges()


func get_interaction_id() -> String:
	return interaction_id.strip_edges()


func get_display_text() -> String:
	var clean_text: String = display_text.strip_edges()

	if not clean_text.is_empty():
		return clean_text

	return get_display_id()


func is_available(context: Dictionary = {}) -> bool:
	return availability_conditions == null \
		or availability_conditions.is_met(context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("choice_id cannot be empty.")

	if get_interaction_id().is_empty():
		errors.append("interaction_id cannot be empty.")

	if get_display_text().is_empty():
		errors.append("display_text cannot be empty.")

	if availability_conditions != null:
		for error: String in availability_conditions.validate_data():
			errors.append("Availability condition: %s" % error)

	return errors
