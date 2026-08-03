extends GameEffectData
class_name SetFlagEffectData


@export var flag_name: String = ""
@export var value: bool = true


func _apply_effect(_context: GameEffectContext) -> bool:
	var clean_name: String = flag_name.strip_edges()

	if clean_name.is_empty():
		return false

	GameState.set_flag(clean_name, value)
	return true


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()

	if flag_name.strip_edges().is_empty():
		errors.append("flag_name cannot be empty.")

	return errors
