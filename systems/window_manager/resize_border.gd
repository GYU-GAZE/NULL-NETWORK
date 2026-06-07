extends Control
class_name ResizeBorder

@export var border_size: float = 8.0


func _has_point(point: Vector2) -> bool:
	var left: bool = point.x <= border_size
	var right: bool = point.x >= size.x - border_size
	var top: bool = point.y <= border_size
	var bottom: bool = point.y >= size.y - border_size

	return left or right or top or bottom
