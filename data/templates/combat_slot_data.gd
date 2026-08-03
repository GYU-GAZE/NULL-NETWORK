extends Resource
class_name CombatSlotData


@export_range(0, 3) var slot_index: int = 0
@export var character: CharacterLoadout
@export var availability_conditions: ConditionSetData


func is_available() -> bool:
	if character == null:
		return false

	return (
		availability_conditions == null
		or availability_conditions.is_met()
	)
