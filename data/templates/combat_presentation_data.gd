extends Resource
class_name CombatPresentationData


enum RepeatMode {
	ONCE_PER_ACTION,
	ONCE_PER_EXECUTION,
	ONCE_PER_TARGET
}


@export_category("Source")
@export var animate_source: bool = false
@export var source_animation: CombatAnimationData
@export var source_repeat_mode: RepeatMode = (
	RepeatMode.ONCE_PER_ACTION
)

@export_category("Targets")
@export var animate_targets: bool = false
@export var target_animation: CombatAnimationData
@export var target_repeat_mode: RepeatMode = (
	RepeatMode.ONCE_PER_EXECUTION
)


func has_visuals() -> bool:
	return (
		animate_source
		and source_animation != null
	) or (
		animate_targets
		and target_animation != null
	)


func validate_data(
	owner_label: String = "Combat presentation"
) -> PackedStringArray:
	var errors := PackedStringArray()

	if animate_source:
		if source_animation == null:
			errors.append(
				"%s enables the source animation but has no "
				% owner_label
				+ "source_animation."
			)
		else:
			errors.append_array(
				source_animation.validate_data()
			)

	if animate_targets:
		if target_animation == null:
			errors.append(
				"%s enables target animations but has no "
				% owner_label
				+ "target_animation."
			)
		else:
			errors.append_array(
				target_animation.validate_data()
			)

	return errors
