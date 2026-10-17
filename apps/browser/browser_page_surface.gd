extends Container
class_name BrowserPageSurface

## Layout owns the page's rect. Browser motion owns ONLY this surface's X/alpha.
## A scriptless Control page is allowed for viewport policies; documents must
## propagate their natural height through Containers.
var page: Control
var document: bool = false


func mount(content: Control, is_document: bool) -> void:
	page = content
	document = is_document
	page.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.size = size.max(page.get_combined_minimum_size())
	page.minimum_size_changed.connect(_page_minimum_changed)
	add_child(page)
	_page_minimum_changed()


func _get_minimum_size() -> Vector2:
	return page.get_combined_minimum_size() if is_instance_valid(page) and document else Vector2.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and is_instance_valid(page):
		page.position = Vector2.ZERO
		page.size = size.round().max(page.get_combined_minimum_size())


func _page_minimum_changed() -> void:
	update_minimum_size()
	queue_sort()
