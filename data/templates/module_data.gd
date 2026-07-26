extends Resource
class_name ModuleData


@export_category("Identity")
@export var module_id: StringName = &"module"
@export var module_name: String = "New Module"
@export var module_icon: Texture2D
@export_multiline var description: String = ""

@export_category("Execution")
@export var stability_cost: int = 10
@export_range(0.0, 1.0, 0.01) var accuracy: float = 1.0
@export_flags(
	"Damage",
	"Heal",
	"Status",
	"Dummy",
	"Defense",
	"Utility"
) var module_tags: int = 0

@export_category("Combat Effects")
@export var combat_effects: Array[CombatEffectData] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if module_id.is_empty():
		errors.append(
			"Module '%s' has an empty module_id."
			% module_name
		)

	if stability_cost < 0:
		errors.append(
			"Module '%s' has a negative stability cost. "
			% module_name
			+ "Use MODIFY_STABILITY instead."
		)

	if combat_effects.is_empty():
		errors.append(
			"Module '%s' has no combat effects."
			% module_name
		)

	for effect in combat_effects:
		if effect == null:
			errors.append(
				"Module '%s' contains a null effect."
				% module_name
			)
			continue

		errors.append_array(effect.validate_data())

	return errors


func describe_effects() -> PackedStringArray:
	var lines := PackedStringArray()

	for effect in combat_effects:
		if effect != null:
			lines.append(effect.describe())

	return lines
