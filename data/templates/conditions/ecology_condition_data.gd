@tool
extends ConditionRuleData
class_name EcologyConditionData

@export var ecology_zone_id: String = ""
@export var species_line_id: String = ""
@export var require_collapsed: bool = false
@export var require_absent: bool = false
@export_range(0, 3) var minimum_resonance: int = 0
@export_range(0, 1000) var minimum_collapses: int = 0

func _evaluate_rule(_context: Dictionary, _active_path: Dictionary) -> bool:
	var state: Dictionary = CampaignState.world_state.ecology_zones.get(ecology_zone_id, {})
	if state.is_empty(): return false
	var population: Dictionary = state.get("species", {}).get(species_line_id, {})
	return (not require_collapsed or bool(state.get("collapsed", false))) and (not require_absent or int(population.get("population_current", -1)) == 0) and int(population.get("purify_resonance", 0)) >= minimum_resonance and int(CampaignState.world_state.ecology_route.get("collapse_count", 0)) >= minimum_collapses

func get_change_dependencies(_active_path: Dictionary = {}) -> Dictionary:
	return {"sections": PackedStringArray(["ecology"])}

func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	return PackedStringArray(["Ecology condition needs a zone ID."]) if ecology_zone_id.is_empty() else PackedStringArray()
