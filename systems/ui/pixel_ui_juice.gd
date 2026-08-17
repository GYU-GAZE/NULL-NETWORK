extends Node
class_name PixelUIJuice

@export_range(0.04, 0.4, 0.01) var entrance_seconds: float = 0.16
@export_range(0.04, 0.3, 0.01) var hover_seconds: float = 0.09
@export_range(0.0, 0.08, 0.005) var hover_scale: float = 0.025

var _root: Control
var _entrance_index: int = 0


func install(root: Control) -> void:
	_root = root
	_process_branch(root)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if _root == null or node == self or not _root.is_ancestor_of(node):
		return
	call_deferred("_process_branch", node)


func _process_branch(node: Node) -> void:
	if node is Control:
		_prepare_control(node as Control)
	for child: Node in node.get_children():
		_process_branch(child)


func _prepare_control(control: Control) -> void:
	if control.has_meta(&"pixel_ui_juice"):
		return
	control.set_meta(&"pixel_ui_juice", true)
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Containers and stretched anchors own their children's geometry. Snapping
	# those Controls by assignment fights Godot's layout pass and produces
	# sub-frame size churn; their final draw is already snapped by the 2x canvas.
	if control.get_parent() is not Container:
		control.position = KubuOSMetrics.snap_vector(control.position)
		if is_equal_approx(control.anchor_left, control.anchor_right) \
		and is_equal_approx(control.anchor_top, control.anchor_bottom):
			control.size = KubuOSMetrics.snap_vector(control.size)
	if control is BaseButton:
		_prepare_button(control as BaseButton)
	elif control is PanelContainer and control != _root:
		_play_panel_entrance(control)


func _prepare_button(button: BaseButton) -> void:
	button.resized.connect(_refresh_button_pivot.bind(button))
	button.mouse_entered.connect(_animate_button.bind(button, true))
	button.mouse_exited.connect(_animate_button.bind(button, false))
	button.button_down.connect(_animate_button_press.bind(button))
	button.button_up.connect(_on_button_up.bind(button))
	_refresh_button_pivot(button)


func _refresh_button_pivot(button: BaseButton) -> void:
	if is_instance_valid(button):
		button.pivot_offset = KubuOSMetrics.snap_vector(button.size * 0.5)


func _animate_button(button: BaseButton, hovered: bool) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	var target_scale := Vector2.ONE * (1.0 + hover_scale if hovered else 1.0)
	var tween := button.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, hover_seconds)
	tween.tween_property(button, "modulate:a", 1.0 if hovered else 0.94, hover_seconds)


func _animate_button_press(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	var tween := button.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.96, 0.92), 0.045)


func _on_button_up(button: BaseButton) -> void:
	_animate_button(button, button.is_hovered())


func _play_panel_entrance(panel: Control) -> void:
	if not panel.is_visible_in_tree():
		return
	_entrance_index += 1
	panel.pivot_offset = KubuOSMetrics.snap_vector(panel.size * 0.5)
	panel.scale = Vector2(0.985, 0.94)
	panel.modulate.a = 0.0
	var delay := minf(0.18, float(_entrance_index - 1) * 0.018)
	var tween := panel.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, entrance_seconds).set_delay(delay)
	tween.tween_property(panel, "modulate:a", 1.0, entrance_seconds * 0.72).set_delay(delay)
