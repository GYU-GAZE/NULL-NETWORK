extends Node
class_name VisibilityToggle

## Local presentation, configured in the scene. Persistent game changes belong
## in GameEffectData. Add the target to BrowserFormState to remember expansion.
@export var target_path: NodePath


func _ready() -> void:
	var button := get_parent() as BaseButton
	if button != null:
		button.pressed.connect(_toggle)


func _toggle() -> void:
	var target := get_node_or_null(target_path) as CanvasItem
	if target != null:
		target.visible = not target.visible
