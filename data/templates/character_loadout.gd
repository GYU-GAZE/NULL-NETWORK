extends Resource
class_name CharacterLoadout


@export_category("Identity")
@export var character_id: StringName = &"character"
@export var char_name: String = "Entity"
@export var combat_icon: Texture2D
@export var level: int = 1
@export_enum(
	"INIT",
	"VALOUR",
	"LOGIC",
	"SYNC",
	"SELF",
	"BALANCED",
	"NULL",
	"XVALOUR",
	"XLOGIC",
	"XSYNC",
	"XSELF"
) var apk_type: String = "INIT"

@export_category("Stats")
@export var max_hp: int = 100
@export var starting_hp: int = -1
@export var max_stability: int = 100
@export var starting_stability: int = -1
@export var stability_recovery: int = 20
@export var base_atk: int = 10
@export var base_def: int = 5
@export var base_matk: int = 10
@export var base_mdef: int = 5
@export_range(0.0, 1.0, 0.01) var dodge_chance: float = 0.05
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.05

@export_category("Loadout")
@export var equipped_modules: Array[ModuleData] = [
	null,
	null,
	null,
	null
]
@export var module_pool: Array[ModuleData] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if character_id.is_empty():
		errors.append(
			"Character '%s' has an empty character_id."
			% char_name
		)

	if equipped_modules.size() != 4:
		errors.append(
			"Character '%s' must equip exactly four modules."
			% char_name
		)

	if starting_hp > max_hp:
		errors.append("Character '%s' starts above max HP." % char_name)

	if starting_stability > max_stability:
		errors.append("Character '%s' starts above max Stability." % char_name)

	for module in equipped_modules:
		if module == null:
			errors.append(
				"Character '%s' has an empty equipped slot."
				% char_name
			)
			continue

		errors.append_array(module.validate_data())

	return errors
