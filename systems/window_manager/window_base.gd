extends Control
class_name WindowBase

signal window_closed
signal window_focused
signal window_moved
signal window_resized

@export var tween_duration: float = 0.25

var app_id: String = ""
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var can_resize: bool = false
var min_window_size: Vector2 = Vector2(400, 300)

@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var content_container: MarginContainer = %ContentContainer
@onready var top_bar: Control = %TopBar


func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_LEFT

	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, tween_duration)
	tween.tween_property(self, "modulate:a", 1.0, tween_duration)

	close_button.pressed.connect(close)
	top_bar.gui_input.connect(_on_top_bar_gui_input)


func setup(id: String, window_name: String, window_size: Vector2, minimum_size: Vector2, resize_enabled: bool) -> void:
	app_id = id
	title_label.text = window_name

	min_window_size = minimum_size
	can_resize = resize_enabled

	custom_minimum_size = Vector2.ZERO
	anchors_preset = Control.PRESET_TOP_LEFT

	size = Vector2(
		max(window_size.x, min_window_size.x),
		max(window_size.y, min_window_size.y)
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		window_focused.emit()


func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			window_focused.emit()
			accept_event()
		else:
			is_dragging = false
			window_moved.emit()
			accept_event()

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset
		window_moved.emit()
		accept_event()


func pulse() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func close() -> void:
	close_button.disabled = true

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), tween_duration)
	tween.tween_property(self, "modulate:a", 0.0, tween_duration)

	tween.chain().tween_callback(window_closed.emit)
