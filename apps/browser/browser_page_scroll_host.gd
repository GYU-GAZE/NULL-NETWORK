extends Container
class_name BrowserPageScrollHost

## PAGE_SCROLL owns one logical document at a time. Browser navigation keeps the
## outgoing and incoming page roots alive together while the horizontal page
## transition plays, so this host must overlay those roots instead of stacking
## them like a VBoxContainer.
##
## The host also exposes the largest page minimum size to ScrollContainer. That
## lets authored page content determine the real scroll range instead of relying
## on a fixed canvas height that can clip the first or last part of a document.

var _tracked_pages: Array[Control] = []


func _ready() -> void:
	if not child_entered_tree.is_connected(_on_child_entered):
		child_entered_tree.connect(_on_child_entered)
	if not child_exiting_tree.is_connected(_on_child_exiting):
		child_exiting_tree.connect(_on_child_exiting)

	for child: Node in get_children():
		_track_page(child as Control)

	_refresh_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_page_roots()


func _get_minimum_size() -> Vector2:
	var resolved := Vector2.ZERO

	for child: Node in get_children():
		if not child is Control:
			continue

		var page := child as Control
		if not page.visible:
			continue

		var page_minimum := page.get_combined_minimum_size()
		resolved.x = maxf(resolved.x, page_minimum.x)
		resolved.y = maxf(resolved.y, page_minimum.y)

	return resolved


func _on_child_entered(child: Node) -> void:
	_track_page(child as Control)
	call_deferred("_refresh_layout")


func _on_child_exiting(child: Node) -> void:
	_untrack_page(child as Control)
	call_deferred("_refresh_layout")


func _track_page(page: Control) -> void:
	if page == null or _tracked_pages.has(page):
		return

	_tracked_pages.append(page)
	if not page.minimum_size_changed.is_connected(_on_page_minimum_size_changed):
		page.minimum_size_changed.connect(_on_page_minimum_size_changed)

	# Navigation motion is horizontal. Vertical placement belongs entirely to
	# ScrollContainer and must always start at the document origin.
	page.position.y = 0.0


func _untrack_page(page: Control) -> void:
	if page == null:
		return

	_tracked_pages.erase(page)
	if page.minimum_size_changed.is_connected(_on_page_minimum_size_changed):
		page.minimum_size_changed.disconnect(_on_page_minimum_size_changed)


func _on_page_minimum_size_changed() -> void:
	_refresh_layout()


func _refresh_layout() -> void:
	if not is_inside_tree():
		return

	update_minimum_size()
	queue_sort()


func _layout_page_roots() -> void:
	for child: Node in get_children():
		if not child is Control:
			continue

		var page := child as Control
		var animated_x := page.position.x

		# Do not touch X: UiMotionPlayer owns that axis while navigating.
		# The host owns the shared document width/height and vertical origin.
		page.size = size
		page.position.y = 0.0
		page.position.x = animated_x
