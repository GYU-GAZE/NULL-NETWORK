extends Resource
class_name StatusEffectData


enum StackMode {
	ADD,
	REFRESH,
	REPLACE,
	KEEP_HIGHEST
}


@export_category("Identity")
@export var status_id: StringName = &"status"
@export var display_name: String = "Status"
@export_multiline var description: String = ""

@export_category("Stacks")
@export_range(1, 999) var default_stacks: int = 1
@export_range(1, 999) var max_stacks: int = 1
@export var stack_mode: StackMode = StackMode.ADD

@export_category("Duration")
@export var duration_cycles: int = -1
@export var refresh_duration_when_stacked: bool = true
@export var tick_on_application_cycle: bool = false

@export_category("Behavior")
@export var triggered_effects: Array[CombatTriggeredEffectData] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if status_id.is_empty():
		errors.append("StatusEffectData has an empty status_id.")

	if max_stacks < 1:
		errors.append(
			"Status '%s' must allow at least one stack."
			% status_id
		)

	if default_stacks < 1 or default_stacks > max_stacks:
		errors.append(
			"Status '%s' has invalid default_stacks."
			% status_id
		)

	for triggered_effect in triggered_effects:
		if triggered_effect == null:
			errors.append(
				"Status '%s' contains a null triggered effect."
				% status_id
			)
			continue

		errors.append_array(
			triggered_effect.validate_data()
		)

	return errors
