extends Resource
class_name CombatSlotData

@export_range(0, 3) var slot_index: int = 0
@export var character: CharacterLoadout
@export var conditions: Array[ConditionData] = []


func is_available() -> bool:
	if character == null:
		return false

	for condition in conditions:
		if condition == null:
			continue

		if not condition.is_met():
			return false

	return true