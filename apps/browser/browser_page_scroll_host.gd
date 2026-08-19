extends VBoxContainer
class_name BrowserPageScrollHost

## PAGE_SCROLL is semantically a single-page viewport even though Browser keeps
## the outgoing and incoming page alive together for a short transition. A
## VBoxContainer would normally stack those temporary siblings vertically,
## which lets the incoming page capture a stale Y position and remain displaced
## after the transition. Keep every page root pinned to local Y=0 while the host
## still owns the shared width/minimum-size negotiation.

var _origin_reset_revision: int = 0


func _ready() -> void:
	if not child_entered_tree.is_connected(_on_child_structure_changed):
		child_entered_tree.connect(_on_child_structure_changed)
	if not child_exiting_tree.is_connected(_on_child_structure_changed):
		child_exiting_tree.connect(_on_child_structure_changed)
	if not child_order_changed.is_connected(_on_child_order_changed):
		child_order_changed.connect(_on_child_order_changed)
	set_process(true)
	_queue_origin_reset()


func _process(_delta: float) -> void:
	_enforce_page_root_origin()


func _on_child_structure_changed(child: Node) -> void:
	if child is Control:
		var control := child as Control
		control.position.y = 0.0
	_queue_origin_reset()


func _on_child_order_changed() -> void:
	_enforce_page_root_origin()
	_queue_origin_reset()


func _enforce_page_root_origin() -> void:
	# Browser page motion is horizontal. Y belongs exclusively to the page-scroll
	# viewport and must never be inherited from VBox sibling stacking.
	for child: Node in get_children():
		if child is Control:
			var control := child as Control
			if not is_zero_approx(control.position.y):
				control.position.y = 0.0


func _queue_origin_reset() -> void:
	_origin_reset_revision += 1
	var revision := _origin_reset_revision
	call_deferred("_settle_origin_after_layout", revision)


func _settle_origin_after_layout(revision: int) -> void:
	# Let the Container and ScrollContainer consume the new minimum size, then
	# reassert the one-page origin. The page root itself is already held at y=0
	# during these frames, so presentation motion cannot capture a stacked offset.
	await get_tree().process_frame
	await get_tree().process_frame
	if revision != _origin_reset_revision or not is_inside_tree():
		return
	var scroll := get_parent() as ScrollContainer
	if scroll == null:
		return
	queue_sort()
	_enforce_page_root_origin()
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
	await get_tree().process_frame
	if revision != _origin_reset_revision or not is_instance_valid(scroll):
		return
	_enforce_page_root_origin()
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
