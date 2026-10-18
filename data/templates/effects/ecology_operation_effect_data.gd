extends GameEffectData
class_name EcologyOperationEffectData

@export var ecology_zone_id: String = ""
@export var species_line_id: String = ""
@export var infestation_delta: int = 0
@export var danger_delta: int = 0
@export_enum("PURGE", "PURIFY", "CONTAIN_SWARM", "WORLD_PRESSURE") var operation: String = "PURIFY"

func _apply_effect(context: GameEffectContext) -> bool:
	var zone := EcologyService.definition(ecology_zone_id)
	if zone == null: return false
	var cycle := int(CampaignState.get_story_event_repeat_state(context.event_id).get("completion_count", 0))
	var id := "story.%s.%s.%d" % [context.source_id, effect_id, cycle]
	var state := EcologyService.ensure_zone(zone)
	if state.applied_effect_receipts.has(id): return true
	if bool(state.collapsed) or (operation == "PURGE" and EcologyService.total(state) <= 1): return true
	return EcologyService.apply_operation({"operation_id": id, "zone_id": ecology_zone_id, "species_line_id": species_line_id, "operation": operation, "source": "narrative", "target_id": context.target_id, "formal_result": true, "provenance": resource_path, "infestation_delta": infestation_delta, "danger_delta": danger_delta})

func _validate_effect() -> PackedStringArray:
	return PackedStringArray(["Ecological effect requires a zone ID."]) if ecology_zone_id.is_empty() else PackedStringArray()
