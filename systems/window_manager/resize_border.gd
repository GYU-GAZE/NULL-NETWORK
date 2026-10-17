extends Control
class_name ResizeBorder


@export var border_size: float = 8.0

var force_capture: bool = false
var excluded_controls: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _has_point(point: Vector2) -> bool:
	if force_capture:
		return true
	var canvas_point := get_global_transform() * point
	for control: Control in excluded_controls:
		if is_instance_valid(control) and control.is_visible_in_tree() and control.get_global_rect().has_point(canvas_point):
			return false

	return (
		_is_mouse_inside_control(point)
		and _is_on_resize_border(point)
	)


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
