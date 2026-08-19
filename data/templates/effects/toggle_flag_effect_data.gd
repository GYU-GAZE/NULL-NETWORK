extends GameEffectData
class_name ToggleFlagEffectData

@export var flag_name: String = ""


func _apply_effect(_context: GameEffectContext) -> bool:
	var clean_name := flag_name.strip_edges()
	if clean_name.is_empty():
		return false
	GameState.toggle_flag(clean_name)
	return true


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()
	if flag_name.strip_edges().is_empty():
		errors.append("flag_name cannot be empty.")
	return errors
