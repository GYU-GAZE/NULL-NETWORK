extends Resource
class_name CombatResult


enum Outcome {
	VICTORY,
	DEFEAT,
	ESCAPED,
	CANCELLED
}


var outcome: Outcome = Outcome.CANCELLED
var encounter_id: String = ""
var metadata: Dictionary = {}


static func create(
	result_outcome: Outcome,
	result_encounter_id: String = "",
	result_metadata: Dictionary = {}
) -> CombatResult:
	var result := CombatResult.new()
	result.outcome = result_outcome
	result.encounter_id = result_encounter_id.strip_edges()
	result.metadata = result_metadata.duplicate(true)
	return result


func is_victory() -> bool:
	return outcome == Outcome.VICTORY
