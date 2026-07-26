extends Resource
class_name CombatTriggeredEffectData


@export var trigger: CombatTriggerData
@export var effects: Array[CombatEffectData] = []
@export var stack_delta_after_trigger: int = 0
@export var trigger_once_per_cycle: bool = false
@export var presentation_override: CombatPresentationData


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if trigger == null:
		errors.append("Triggered effect has no CombatTriggerData.")

	if effects.is_empty():
		errors.append("Triggered effect has no CombatEffectData.")

	for effect in effects:
		if effect == null:
			errors.append("Triggered effect contains a null effect.")
			continue

		errors.append_array(effect.validate_data())

		if (
			trigger != null
			and trigger.timing
			== CombatConstants.TriggerTiming.CONTINUOUS
			and effect.effect_type not in [
				CombatEffectData.EffectType.MODIFY_STAT,
				CombatEffectData.EffectType.MODIFY_DAMAGE_TAKEN,
				CombatEffectData.EffectType.MODIFY_DAMAGE_DEALT
			]
		):
			errors.append(
				"CONTINUOUS triggers only accept passive stat "
				+ "or damage modifiers."
			)

	if presentation_override != null:
		errors.append_array(
			presentation_override.validate_data(
				"Triggered Status effect"
			)
		)

	return errors
