extends Resource
class_name AppearanceOptionData

enum Category {
	BODY,
	FACE,
	EYES,
	OUTER,
	MIDDLE,
	LOWER,
	HAT,
	FACIAL_ACCESSORY
}

@export var option_id: String = ""
@export var display_name: String = ""
@export var category: Category = Category.BODY
@export var thumbnail: Texture2D
@export var portrait_layer: Texture2D
@export var overworld_front: Texture2D
@export var overworld_right: Texture2D
@export var overworld_back: Texture2D
@export var overworld_left: Texture2D

func get_overworld_texture(direction: int) -> Texture2D:
	match posmod(direction, 4):
		0: return overworld_front
		1: return overworld_right
		2: return overworld_back
		3: return overworld_left
	return overworld_front

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if option_id.strip_edges().is_empty():
		errors.append("Appearance option requires an id.")
	if display_name.strip_edges().is_empty():
		errors.append("Appearance option '%s' requires a display name." % option_id)
	return errors
