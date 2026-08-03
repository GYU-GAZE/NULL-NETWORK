extends Resource
class_name EvolutionWindowData


enum WindowKind {
	END_OF_CYCLE,
	BOSS_PHASE,
	HP_CRITICAL,
	UNSTABILITY_CHANGED,
	ALLY_DEFEATED,
	ENEMY_DEFEATED,
	NARRATIVE_EVENT,
	MODULE_USED
}

@export var window_id: String = "end_of_cycle"
@export var window_kind: WindowKind = WindowKind.END_OF_CYCLE
@export var required_tag: StringName = &""


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if window_id.strip_edges().is_empty():
		errors.append("EvolutionWindowData has an empty window_id.")

	return errors
