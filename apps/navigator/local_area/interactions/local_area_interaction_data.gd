extends Resource
class_name LocalAreaInteractionData


enum InteractionKind {
	EXAMINE,
	ENCOUNTER,
	DIALOGUE,
	TRANSITION,
	CUSTOM
}


@export_category("Identity")
@export var interaction_id: String = ""
@export var display_name: String = ""

@export_category("Prompt")
@export var kind: InteractionKind = InteractionKind.EXAMINE
@export var prompt_verb: String = "EXAMINE"
@export_multiline var response_text: String = ""

@export_category("Activity")
@export var activity: ActivityDefinitionData

@export_category("Dialogue")
@export var dialogue: DialogueData


func get_display_id() -> String:
	if not interaction_id.strip_edges().is_empty():
		return interaction_id.strip_edges()

	return display_name.to_lower().replace(" ", "_")


func get_prompt_verb() -> String:
	var clean_verb: String = prompt_verb.strip_edges()

	if clean_verb.is_empty():
		return "INTERACT"

	return clean_verb.to_upper()
