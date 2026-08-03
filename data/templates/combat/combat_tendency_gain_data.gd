extends Resource
class_name CombatTendencyGainData


@export var tendency: TendencyStateData.Tendency = TendencyStateData.Tendency.VALOUR
@export_range(-100, 100, 1) var amount: int = 1
@export var condition: ConditionSetData


func is_available() -> bool:
	return condition == null or condition.is_met()


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if amount == 0:
		errors.append("Combat tendency gain amount cannot be zero.")

	return errors
