extends Resource
class_name DummyData


@export_category("Identity")
@export var dummy_id: StringName = &"dummy"
@export var display_name: String = "Dummy"
@export var combat_icon: Texture2D
@export var apk_type: String = "INIT"

@export_category("Stats")
@export var stat_formulas: Array[CombatStatFormulaData] = []

@export_category("Lifetime")
@export var duration_cycles: int = -1

@export_category("Initial Statuses")
@export var initial_statuses: Array[StatusEffectData] = []

@export_category("Behavior")
@export var triggered_effects: Array[CombatTriggeredEffectData] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if dummy_id.is_empty():
		errors.append("DummyData has an empty dummy_id.")

	for stat_formula in stat_formulas:
		if stat_formula == null or stat_formula.formula == null:
			errors.append(
				"Dummy '%s' contains an invalid stat formula."
				% dummy_id
			)

	for status in initial_statuses:
		if status == null:
			errors.append(
				"Dummy '%s' contains a null initial status."
				% dummy_id
			)
			continue

		errors.append_array(status.validate_data())

	for triggered_effect in triggered_effects:
		if triggered_effect == null:
			errors.append(
				"Dummy '%s' contains a null triggered effect."
				% dummy_id
			)
			continue

		errors.append_array(
			triggered_effect.validate_data()
		)

	return errors
