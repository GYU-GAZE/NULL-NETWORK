@tool
extends Resource
class_name FieldPopulationData

## Presentation budget scoped to an authored subarea. Visible field identities
## are separate from the finite ecological Population Units defined by the GDD.
@export_range(0, 16) var minimum_units: int = 2
@export_range(0, 16) var maximum_units: int = 5
@export var conditions: ConditionRuleData
@export var guaranteed_spawn_ids: PackedStringArray = PackedStringArray()
@export_range(24.0, 200.0) var spawn_separation: float = 42.0
## Optional existing GameState number. No Danger authority is fabricated.
@export var danger_number_key: String = ""

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if minimum_units < 0 or maximum_units < minimum_units or spawn_separation < 24:
		errors.append("Invalid field population budget/separation.")
	if conditions != null:
		errors.append_array(conditions.validate_data())
	return errors
