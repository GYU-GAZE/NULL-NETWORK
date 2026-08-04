extends Node
class_name AdaptiveBrowserPageLayout


@export var page_path: NodePath = NodePath("..")


func _ready() -> void:
	call_deferred("_apply_adaptive_layout")


func _apply_adaptive_layout() -> void:
	var page := get_node_or_null(page_path) as Control

	if page == null:
		push_warning(
			"AdaptiveBrowserPageLayout: page_path must resolve to a Control."
		)
		return

	var host := page.get_parent() as Control

	if host == null:
		push_warning(
			"AdaptiveBrowserPageLayout: adaptive page requires a Control host."
		)
		return

	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 0.0
	page.offset_top = 0.0
	page.offset_right = 0.0
	page.offset_bottom = 0.0
	page.custom_minimum_size = Vector2.ZERO
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
