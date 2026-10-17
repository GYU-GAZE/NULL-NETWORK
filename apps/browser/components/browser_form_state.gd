@tool
extends Node
class_name BrowserFormState

## Reusable form persistence. Paths are relative to this node; add fields in
## the Inspector. Custom page scripts can still own get/restore_browser_state.
@export var fields: Array[NodePath] = []


func capture() -> Dictionary:
	var result := {}
	for path: NodePath in fields:
		var control := get_node_or_null(path)
		if control is LineEdit or control is TextEdit:
			result[str(path)] = control.text
		elif control is OptionButton:
			result[str(path)] = control.selected
		elif control is BaseButton:
			result[str(path)] = control.button_pressed
		elif control is Range:
			result[str(path)] = control.value
		elif control is Control:
			result[str(path)] = control.visible
	return result


func restore(data: Dictionary) -> void:
	for path: NodePath in fields:
		if not data.has(str(path)):
			continue
		var control := get_node_or_null(path)
		var value: Variant = data[str(path)]
		if control is LineEdit or control is TextEdit:
			control.text = str(value)
		elif control is OptionButton:
			control.select(clampi(int(value), -1, control.item_count - 1))
		elif control is BaseButton:
			control.set_pressed_no_signal(bool(value))
		elif control is Range:
			control.set_value_no_signal(float(value))
		elif control is Control:
			control.visible = bool(value)
