extends Control
class_name ResizeBorder

@export var border_size: float = 8.0
var force_capture: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if force_capture:
		mouse_filter = Control.MOUSE_FILTER_STOP
		return

	var mouse_pos: Vector2 = get_local_mouse_position()

	if _is_mouse_inside_control(mouse_pos) and _is_on_resize_border(mouse_pos):
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _has_point(point: Vector2) -> bool:
	return _is_on_resize_border(point)


func _is_mouse_inside_control(point: Vector2) -> bool:
	return (
		point.x >= 0.0
		and point.y >= 0.0
		and point.x <= size.x
		and point.y <= size.y
	)


func _is_on_resize_border(point: Vector2) -> bool:
	if size.x <= 0.0 or size.y <= 0.0:
		return false

	var left: bool = point.x <= border_size
	var right: bool = point.x >= size.x - border_size
	var top: bool = point.y <= border_size
	var bottom: bool = point.y >= size.y - border_size

	return left or right or top or bottom
