extends Resource
class_name PlayerActionData


enum ActionKind {
	SCAN,
	PURGE,
	PURIFY,
	TAME
}

@export_category("Identity")
@export var action_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var action_kind: ActionKind = ActionKind.SCAN

@export_category("Progress")
@export_range(1, 100, 1) var progress_amount: int = 25
@export_range(1, 100, 1) var required_progress: int = 100
@export var once_per_encounter: bool = false
@export var once_per_target: bool = true

@export_category("Completion")
@export var completion_tendency_gains: Array[CombatTendencyGainData] = []
@export var permanent_tendency_gains: Array[CombatTendencyGainData] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if action_id.strip_edges().is_empty():
		errors.append("PlayerActionData has an empty action_id.")

	if display_name.strip_edges().is_empty():
		errors.append("Player Action '%s' has no display name." % action_id)

	if required_progress % progress_amount != 0:
		errors.append("Player Action '%s' cannot reach its threshold in whole slots." % action_id)

	for gain: CombatTendencyGainData in completion_tendency_gains:
		if gain == null:
			errors.append("Player Action '%s' contains a null tendency gain." % action_id)
		else:
			errors.append_array(gain.validate_data())

	for gain: CombatTendencyGainData in permanent_tendency_gains:
		if gain == null:
			errors.append("Player Action '%s' contains a null permanent tendency gain." % action_id)
		else:
			errors.append_array(gain.validate_data())

	return errors
