@tool
extends Resource
class_name FieldCallResponseRule

enum Response { JOIN, IGNORE, HESITATE, FLEE, INTERCEPT, OBSERVE }
@export var response: Response = Response.JOIN
@export var conditions: ConditionRuleData
@export var same_species_only: bool = false
@export var variant_node_ids: PackedStringArray = PackedStringArray()
@export_range(0.0, 2000.0) var minimum_distance: float = 0.0
@export_range(0.0, 2000.0) var maximum_distance: float = 200.0
## Negative thresholds are absent, not universal assumed world values.
@export var minimum_danger: int = -1
@export var minimum_infestation: int = -1
@export_range(0.0, 1.0) var probability: float = 1.0
@export_range(0.0, 3.0) var hesitation_seconds: float = 0.4

func matches(context: Dictionary) -> bool:
	var distance := float(context.get("distance", INF))
	return distance >= minimum_distance and distance <= maximum_distance \
		and (not same_species_only or bool(context.get("same_species", false))) \
		and (variant_node_ids.is_empty() or str(context.get("variant_node_id", "")) in variant_node_ids) \
		and (minimum_danger < 0 or (context.has("danger") and int(context.danger) >= minimum_danger)) \
		and (minimum_infestation < 0 or (context.has("infestation") and int(context.infestation) >= minimum_infestation)) \
		and (conditions == null or conditions.is_met(context))

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if minimum_distance < 0 or maximum_distance < minimum_distance or probability < 0 or probability > 1:
		errors.append("Invalid field response distances/probability.")
	if conditions != null:
		errors.append_array(conditions.validate_data())
	return errors
