extends GameEffectData
class_name ModifyNumberEffectData


enum Operation {
	ADD,
	SET
}

@export var variable_name: String = ""
@export var operation: Operation = Operation.ADD
@export var value: int = 0


func _apply_effect(_context: GameEffectContext) -> bool:
	var clean_name: String = variable_name.strip_edges()

	if clean_name.is_empty():
		return false

	match operation:
		Operation.ADD:
			GameState.add_number(clean_name, value)
		Operation.SET:
			GameState.set_number(clean_name, value)
	return true


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()

	if variable_name.strip_edges().is_empty():
		errors.append("variable_name cannot be empty.")

	return errors
