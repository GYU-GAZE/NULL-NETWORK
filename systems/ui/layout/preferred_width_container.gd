@tool
extends Container
class_name PreferredWidthContainer

## Hug authored content on wide pages without turning that preference into a
## minimum that prevents the surrounding document from shrinking later.
@export_range(0, 4096, 1) var preferred_width: float = 0:
	set(value):
		preferred_width = value
		queue_sort()


func _get_minimum_size() -> Vector2:
	var result := Vector2.ZERO
	for child: Node in get_children():
		if child is Control and child.visible:
			result = result.max(child.get_combined_minimum_size())
	return result


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_sort()
	elif what == NOTIFICATION_SORT_CHILDREN:
		for child: Node in get_children():
			if child is Control and child.visible:
				var minimum: Vector2 = child.get_combined_minimum_size()
				var width := minf(size.x, preferred_width) if preferred_width > 0 else size.x
				child.position = Vector2.ZERO
				child.size = Vector2(maxf(minimum.x, floorf(width)), maxf(minimum.y, size.y))
