extends Resource
class_name SilverTypographyData

@export_category("Native Silver 14 Grid")
@export_range(14, 14, 1) var body_size: int = 14
@export_range(28, 28, 1) var title_size: int = 28
@export_range(42, 42, 1) var hero_size: int = 42
@export_range(84, 84, 1) var splash_size: int = 84


func is_native_size(font_size: int) -> bool:
	return font_size >= body_size and font_size % body_size == 0


func snap_size(font_size: int) -> int:
	return maxi(body_size, int(round(float(font_size) / body_size)) * body_size)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	for font_size: int in [body_size, title_size, hero_size, splash_size]:
		if not is_native_size(font_size):
			errors.append("Silver font size %d is outside the native 14 px grid." % font_size)
	return errors
