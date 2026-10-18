@tool
extends Resource
class_name FieldPresentationData

## Shared species/form presentation contract; consumers such as Profile can
## use the same frames/origin without depending on a field actor.
@export var field_idle: Texture2D
@export var field_step: Texture2D
@export var sprite_origin: Vector2 = Vector2(12, 20)
@export_range(0.1, 8.0, 0.1) var visual_scale: float = 1.0
@export_range(0.1, 30.0, 0.1) var frames_per_second: float = 6.0
@export var faces_right: bool = true
@export var tint: Color = Color.WHITE
@export var digital_effect: bool = true

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if visual_scale <= 0 or frames_per_second <= 0 or not sprite_origin.is_finite():
		errors.append("Field presentation requires finite origin and positive scale/FPS.")
	return errors
