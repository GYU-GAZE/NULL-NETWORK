extends Resource
class_name StatusEffectData


enum StackMode {
	ADD,
	REFRESH,
	REPLACE,
	KEEP_HIGHEST
}


enum DamageRule {
	NONE,
	BARRIER
}


@export_category("Identity")
@export var status_id: StringName = &"status"
@export var display_name: String = "Status"
@export var icon: Texture2D
@export var classification: StringName = &""
@export_multiline var description: String = ""

@export_category("Stacks")
@export_range(1, 999) var default_stacks: int = 1
@export_range(1, 999) var max_stacks: int = 1
@export var stack_mode: StackMode = StackMode.ADD

@export_category("Duration")
@export var duration_cycles: int = -1
@export var refresh_duration_when_stacked: bool = true
@export var tick_on_application_cycle: bool = false

@export_category("Damage")
@export var damage_rule: DamageRule = DamageRule.NONE
@export_range(1, 99) var stacks_consumed_per_hit: int = 1

@export_category("Behavior")
@export var triggered_effects: Array[CombatTriggeredEffectData] = []

@export_category("Presentation")
@export var activation_presentation: CombatPresentationData


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

	if (
		damage_rule == DamageRule.BARRIER
		and stacks_consumed_per_hit < 1
	):
		errors.append(
			"Barrier status '%s' must consume at least "
			% status_id
			+ "one stack per hit."
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

	if activation_presentation != null:
		errors.append_array(
			activation_presentation.validate_data(
				"Status '%s'" % display_name
			)
		)

	return errors


func get_runtime_tooltip(
	instance: CombatStatusInstance
) -> String:
	var lines := PackedStringArray([
		"[%s]" % display_name
	])

	if not description.strip_edges().is_empty():
		lines.append(description)

	if instance != null:
		lines.append(
			"Stacks: %d/%d"
			% [instance.stacks, max_stacks]
		)

	lines.append("Stack rule: %s" % _stack_mode_label())

	if damage_rule == DamageRule.BARRIER:
		lines.append(
			"Blocks one hit and consumes %d stack(s) "
			% stacks_consumed_per_hit
			+ "each time damage would be received."
		)

	if instance != null:
		if instance.remaining_cycles < 0:
			lines.append("Duration: permanent")
		else:
			lines.append(
				"Duration: %d cycle(s) remaining"
				% instance.remaining_cycles
			)

	for triggered_effect in triggered_effects:
		if (
			triggered_effect != null
			and triggered_effect.stack_delta_after_trigger
			!= 0
		):
			lines.append(
				"After %s: stacks %+d"
				% [
					triggered_effect.trigger.describe()
						if triggered_effect.trigger != null
						else "trigger",
					triggered_effect.stack_delta_after_trigger
				]
			)

	return "\n".join(lines)


func _stack_mode_label() -> String:
	match stack_mode:
		StackMode.ADD:
			return "add new stacks"
		StackMode.REFRESH:
			return "refresh without adding stacks"
		StackMode.REPLACE:
			return "replace current stacks"
		StackMode.KEEP_HIGHEST:
			return "keep the highest stack value"

	return "unknown"
