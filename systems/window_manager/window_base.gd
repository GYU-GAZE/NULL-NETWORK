extends Control
class_name WindowBase

signal window_closed
signal window_focused
signal window_moved
signal window_resized

enum ResizeMode {
	NONE,
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

@export var tween_duration: float = 0.25
@export var border_size: float = 8.0

@export_category("Window Buttons")
@export var maximize_button_text: String = "□"
@export var restore_button_text: String = "❐"
@export var maximize_button_icon: Texture2D
@export var restore_button_icon: Texture2D

var app_id: String = ""

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var can_resize: bool = false
var min_window_size: Vector2 = Vector2(400, 300)

var is_resizing: bool = false
var resize_mode: ResizeMode = ResizeMode.NONE
var resize_start_mouse: Vector2 = Vector2.ZERO
var resize_start_size: Vector2 = Vector2.ZERO
var resize_start_position: Vector2 = Vector2.ZERO

var is_maximized: bool = false
var restore_position: Vector2 = Vector2.ZERO
var restore_size: Vector2 = Vector2.ZERO

@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var maximize_button: Button = %MaximizeButton
@onready var content_container: MarginContainer = %ContentContainer
@onready var top_bar: Control = %TopBar
@onready var resize_border: ResizeBorder = %ResizeBorder


func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_LEFT

	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0

	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, tween_duration)
	tween.tween_property(self, "modulate:a", 1.0, tween_duration)

	close_button.pressed.connect(close)
	maximize_button.pressed.connect(toggle_maximized)

	top_bar.gui_input.connect(_on_top_bar_gui_input)
	resize_border.gui_input.connect(_on_resize_border_gui_input)

	_refresh_maximize_button()


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

	resize_border.visible = can_resize
	resize_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resize_border.border_size = border_size

	_refresh_maximize_button()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		window_focused.emit()


func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			toggle_maximized()
			accept_event()
			return

		if event.pressed:
			if is_maximized:
				return

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


func toggle_maximized() -> void:
	if is_maximized:
		restore_from_maximized()
	else:
		maximize()


func maximize() -> void:
	if is_maximized:
		return

	window_focused.emit()

	restore_position = position
	restore_size = size

	is_dragging = false
	is_resizing = false
	resize_mode = ResizeMode.NONE
	resize_border.force_capture = false

	is_maximized = true

	position = _get_maximized_position()
	size = _get_maximized_size()

	_refresh_maximize_button()
	window_moved.emit()
	window_resized.emit()


func restore_from_maximized() -> void:
	if not is_maximized:
		return

	window_focused.emit()

	is_maximized = false

	position = restore_position
	size = Vector2(
		max(restore_size.x, min_window_size.x),
		max(restore_size.y, min_window_size.y)
	)

	_refresh_maximize_button()
	window_moved.emit()
	window_resized.emit()


func _get_maximized_position() -> Vector2:
	return Vector2.ZERO


func _get_maximized_size() -> Vector2:
	var parent_control: Control = get_parent() as Control

	if parent_control != null and parent_control.size.x > 0.0 and parent_control.size.y > 0.0:
		return parent_control.size

	return get_viewport_rect().size


func _refresh_maximize_button() -> void:
	if not is_instance_valid(maximize_button):
		return

	maximize_button.visible = can_resize
	maximize_button.disabled = not can_resize

	if is_maximized:
		maximize_button.text = restore_button_text
		maximize_button.icon = restore_button_icon
		maximize_button.tooltip_text = "Restore"
	else:
		maximize_button.text = maximize_button_text
		maximize_button.icon = maximize_button_icon
		maximize_button.tooltip_text = "Maximize"

	resize_border.visible = can_resize and not is_maximized


func _get_resize_mode(border_mouse_pos: Vector2) -> ResizeMode:
	var total_size: Vector2 = resize_border.size

	var left: bool = border_mouse_pos.x <= border_size
	var right: bool = border_mouse_pos.x >= total_size.x - border_size
	var top: bool = border_mouse_pos.y <= border_size
	var bottom: bool = border_mouse_pos.y >= total_size.y - border_size

	if left and top:
		return ResizeMode.TOP_LEFT

	if right and top:
		return ResizeMode.TOP_RIGHT

	if left and bottom:
		return ResizeMode.BOTTOM_LEFT

	if right and bottom:
		return ResizeMode.BOTTOM_RIGHT

	if left:
		return ResizeMode.LEFT

	if right:
		return ResizeMode.RIGHT

	if top:
		return ResizeMode.TOP

	if bottom:
		return ResizeMode.BOTTOM

	return ResizeMode.NONE


func _on_resize_border_gui_input(event: InputEvent) -> void:
	if not can_resize:
		return

	if is_maximized:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			resize_mode = _get_resize_mode(resize_border.get_local_mouse_position())

			if resize_mode == ResizeMode.NONE:
				return

			is_resizing = true
			resize_border.force_capture = true

			resize_start_mouse = get_global_mouse_position()
			resize_start_size = size
			resize_start_position = position

			window_focused.emit()
			accept_event()


func pulse() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func close() -> void:
	close_button.disabled = true
	maximize_button.disabled = true

	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), tween_duration)
	tween.tween_property(self, "modulate:a", 0.0, tween_duration)

	tween.chain().tween_callback(window_closed.emit)


func _input(event: InputEvent) -> void:
	if not is_resizing:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			is_resizing = false
			resize_mode = ResizeMode.NONE
			resize_border.force_capture = false
			window_resized.emit()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		_apply_resize_from_mouse()
		get_viewport().set_input_as_handled()


func _apply_resize_from_mouse() -> void:
	if is_maximized:
		return

	var delta: Vector2 = get_global_mouse_position() - resize_start_mouse

	match resize_mode:
		ResizeMode.RIGHT:
			size.x = max(min_window_size.x, resize_start_size.x + delta.x)

		ResizeMode.BOTTOM:
			size.y = max(min_window_size.y, resize_start_size.y + delta.y)

		ResizeMode.BOTTOM_RIGHT:
			size.x = max(min_window_size.x, resize_start_size.x + delta.x)
			size.y = max(min_window_size.y, resize_start_size.y + delta.y)

		ResizeMode.LEFT:
			var new_width: float = max(min_window_size.x, resize_start_size.x - delta.x)
			position.x = resize_start_position.x + (resize_start_size.x - new_width)
			size.x = new_width

		ResizeMode.TOP:
			var new_height: float = max(min_window_size.y, resize_start_size.y - delta.y)
			position.y = resize_start_position.y + (resize_start_size.y - new_height)
			size.y = new_height

		ResizeMode.TOP_LEFT:
			var new_width: float = max(min_window_size.x, resize_start_size.x - delta.x)
			var new_height: float = max(min_window_size.y, resize_start_size.y - delta.y)

			position.x = resize_start_position.x + (resize_start_size.x - new_width)
			position.y = resize_start_position.y + (resize_start_size.y - new_height)

			size.x = new_width
			size.y = new_height

		ResizeMode.TOP_RIGHT:
			size.x = max(min_window_size.x, resize_start_size.x + delta.x)

			var new_height: float = max(min_window_size.y, resize_start_size.y - delta.y)
			position.y = resize_start_position.y + (resize_start_size.y - new_height)
			size.y = new_height

		ResizeMode.BOTTOM_LEFT:
			var new_width: float = max(min_window_size.x, resize_start_size.x - delta.x)

			position.x = resize_start_position.x + (resize_start_size.x - new_width)
			size.x = new_width
			size.y = max(min_window_size.y, resize_start_size.y + delta.y)

	window_resized.emit()
