extends Resource
class_name CombatAnimationData


@export_category("Identity")
@export var animation_id: StringName = &"combat_animation"
@export var display_name: String = "Combat Animation"
@export_multiline var description: String = ""

@export_category("Visual Asset")
@export var effect_scene: PackedScene


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if animation_id.is_empty():
		errors.append(
			"CombatAnimationData has an empty animation_id."
		)

	if effect_scene == null:
		errors.append(
			"Combat animation '%s' has no effect_scene."
			% animation_id
		)

	return errors
