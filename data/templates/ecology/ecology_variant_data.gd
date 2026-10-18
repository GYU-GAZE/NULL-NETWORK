@tool
extends Resource
class_name EcologyVariantData

@export var node_id: String = ""
@export var species_line_ids: PackedStringArray = PackedStringArray()
@export var zone_ids: PackedStringArray = PackedStringArray()
@export_range(0, 3) var minimum_resonance: int = 0
@export_range(0.0, 100.0) var weight: float = 1.0
@export_range(0.0, 100.0) var resonance_weight_bonus: float = 0.0
@export var conditions: ConditionRuleData
@export var field_tint: Color = Color.WHITE
## Combat effects of unresolved Nodes are intentionally not fabricated.
func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if node_id not in ["COMBUSTIVE", "CRYOSIVE", "CONDUCTIVE", "CORROSIVE", "DEFENSIVE", "DESTRUCTIVE", "DEPLETIVE", "DECEPTIVE"]:
		errors.append("Ecological Node must reference an existing canonical Variant key.")
	if species_line_ids.is_empty() or weight < 0 or minimum_resonance < 0 or minimum_resonance > 3:
		errors.append("Variant requires compatible species and valid weight/resonance.")
	if conditions != null: errors.append_array(conditions.validate_data())
	return errors
