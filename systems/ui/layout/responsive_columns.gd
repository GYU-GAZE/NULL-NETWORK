@tool
extends Container
class_name ResponsiveColumns

## Horizontal when the sum of child minimum widths fits; stacked otherwise.
## Unlike HBoxContainer, the reported X minimum permits the parent to shrink.
@export_range(0, 128, 1) var separation: int = 8:
	set(value):
		separation = value
		queue_sort()
		update_minimum_size()
@export_range(0, 4096, 1) var horizontal_minimum_width: int = 0:
	set(value):
		horizontal_minimum_width = value
		queue_sort()
		update_minimum_size()
var compact: bool = false


func _visible_children() -> Array[Control]:
	var result: Array[Control] = []
	for child: Node in get_children():
		if child is Control and (child as Control).visible and not (child as Control).is_set_as_top_level():
			result.append(child)
	return result


func _needs_compact(children: Array[Control]) -> bool:
	var needed := float(separation * maxi(0, children.size() - 1))
	for child: Control in children:
		needed += child.get_combined_minimum_size().x
	return size.x < maxf(needed, horizontal_minimum_width)


func _get_minimum_size() -> Vector2:
	var children := _visible_children()
	var stacked := _needs_compact(children)
	var result := Vector2.ZERO
	for child: Control in children:
		var extent := child.get_combined_minimum_size()
		result.x = maxf(result.x, extent.x)
		result.y = result.y + extent.y if stacked else maxf(result.y, extent.y)
	if stacked:
		result.y += separation * maxi(0, children.size() - 1)
	return result.ceil()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_minimum_size()
		queue_sort()
	elif what == NOTIFICATION_SORT_CHILDREN:
		_sort_columns()


func _sort_columns() -> void:
	var children := _visible_children()
	var next_compact := _needs_compact(children)
	if compact != next_compact:
		compact = next_compact
		update_minimum_size()
	var remaining := size.x - separation * maxi(0, children.size() - 1)
	var expand_count := 0
	for child: Control in children:
		remaining -= child.get_combined_minimum_size().x
		if child.size_flags_horizontal & Control.SIZE_EXPAND:
			expand_count += 1
	var cursor := Vector2.ZERO
	for child: Control in children:
		var extent := child.get_combined_minimum_size().ceil()
		if compact:
			extent.x = maxf(extent.x, floorf(size.x))
		else:
			if child.size_flags_horizontal & Control.SIZE_EXPAND and expand_count > 0:
				var extra := floorf(maxf(0, remaining) / expand_count)
				extent.x += extra
				remaining -= extra
				expand_count -= 1
			extent.y = maxf(extent.y, floorf(size.y))
		# No scale/pivot writes: layout never normalizes a child's animation.
		child.position = cursor
		child.size = extent
		if compact:
			cursor.y += extent.y + separation
		else:
			cursor.x += extent.x + separation
