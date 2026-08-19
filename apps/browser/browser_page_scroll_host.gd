extends VBoxContainer
class_name BrowserPageScrollHost

## ScrollContainer recalculates its internal child transform after minimum-size
## and child-list changes. Browser navigation can add a page, reset scroll to
## zero, then cause another container sort in the same frame; the old transform
## can survive until the next resize. This host makes the post-layout origin
## authoritative whenever page content changes.

var _origin_reset_revision: int = 0


func _ready() -> void:
	if not child_entered_tree.is_connected(_on_child_structure_changed):
		child_entered_tree.connect(_on_child_structure_changed)
	if not child_exiting_tree.is_connected(_on_child_structure_changed):
		child_exiting_tree.connect(_on_child_structure_changed)
	if not child_order_changed.is_connected(_on_child_order_changed):
		child_order_changed.connect(_on_child_order_changed)
	_queue_origin_reset()


func _on_child_structure_changed(_child: Node) -> void:
	_queue_origin_reset()


func _on_child_order_changed() -> void:
	_queue_origin_reset()


func _queue_origin_reset() -> void:
	_origin_reset_revision += 1
	var revision := _origin_reset_revision
	call_deferred("_settle_origin_after_layout", revision)


func _settle_origin_after_layout(revision: int) -> void:
	# One frame lets the VBoxContainer consume the new child's minimum size.
	# The second lets ScrollContainer rebuild its scroll range from that result.
	await get_tree().process_frame
	await get_tree().process_frame
	if revision != _origin_reset_revision or not is_inside_tree():
		return
	var scroll := get_parent() as ScrollContainer
	if scroll == null:
		return
	queue_sort()
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
	await get_tree().process_frame
	if revision != _origin_reset_revision or not is_instance_valid(scroll):
		return
	# Reassert after the queued sort. This is what prevents the stale translated
	# page that previously corrected itself only after resize/maximize.
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
