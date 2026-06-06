extends PanelContainer
class_name BrowserTabButton

signal tab_selected(tab_index: int)
signal tab_close_requested(tab_index: int)

@onready var title_button: Button = %TitleButton
@onready var close_button: Button = %CloseButton

var tab_index: int = -1
var is_active: bool = false


func _ready() -> void:
	title_button.pressed.connect(_on_title_pressed)
	close_button.pressed.connect(_on_close_pressed)


func setup(index: int, title: String, active: bool, can_close: bool, tab_width: float) -> void:
	tab_index = index
	is_active = active

	custom_minimum_size.x = tab_width
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	title_button.text = title
	title_button.disabled = active
	title_button.clip_text = true
	title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	close_button.text = "x"
	close_button.disabled = not can_close
	close_button.custom_minimum_size.x = 24
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END

	modulate = Color.WHITE if active else Color(0.75, 0.75, 0.75, 1.0)


func _on_title_pressed() -> void:
	tab_selected.emit(tab_index)


func _on_close_pressed() -> void:
	tab_close_requested.emit(tab_index)
