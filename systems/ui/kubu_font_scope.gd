extends Node
class_name KubuFontScope


@export var typography: KubuTypographyData
@export var target_path: NodePath = NodePath("..")

var _target: Node
var _font: Font
var _observed_nodes: Array[Node] = []


func _ready() -> void:
	_target = get_node_or_null(target_path)

	if _target == null:
		push_error("KubuFontScope: target_path does not resolve to a Node.")
		return

	if typography == null:
		push_error("KubuFontScope: typography is not configured.")
		return

	for error: String in typography.validate_data():
		push_error("KubuFontScope typography: %s" % error)

	_font = typography.get_font()

	if _font == null:
		push_error("KubuFontScope: typography did not resolve a Font.")
		return

	_observe_subtree(_target)


func _exit_tree() -> void:
	for observed: Node in _observed_nodes:
		if not is_instance_valid(observed):
			continue

		if observed.child_entered_tree.is_connected(_on_child_entered_tree):
			observed.child_entered_tree.disconnect(_on_child_entered_tree)

	_observed_nodes.clear()


func _on_child_entered_tree(child: Node) -> void:
	_observe_subtree(child)


func _observe_subtree(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return

	if root is Control:
		_apply_to_control(root as Control)

	if not root.child_entered_tree.is_connected(_on_child_entered_tree):
		root.child_entered_tree.connect(_on_child_entered_tree)
		_observed_nodes.append(root)

	for child: Node in root.get_children():
		_observe_subtree(child)


func _apply_to_control(control: Control) -> void:
	# Most Godot text controls expose their primary face through the generic
	# `font` / `font_size` theme items. Local overrides preserve all existing
	# DAY/NIGHT colors and StyleBoxes instead of replacing the active Theme.
	var generic_size: int = _resolve_font_size(control, &"font_size")
	control.add_theme_font_override(&"font", _font)
	control.add_theme_font_size_override(&"font_size", generic_size)

	if control is RichTextLabel:
		_apply_rich_text_overrides(control as RichTextLabel)


func _apply_rich_text_overrides(label: RichTextLabel) -> void:
	# RichTextLabel owns separate faces for BBCode variants. Keep them all on the
	# same pixel font so combat logs and system notifications cannot silently fall
	# back to Silver for bold/italic/monospace spans.
	var font_keys: Array[StringName] = [
		&"normal_font",
		&"bold_font",
		&"italics_font",
		&"bold_italics_font",
		&"mono_font"
	]
	var size_keys: Array[StringName] = [
		&"normal_font_size",
		&"bold_font_size",
		&"italics_font_size",
		&"bold_italics_font_size",
		&"mono_font_size"
	]

	for key: StringName in font_keys:
		label.add_theme_font_override(key, _font)

	for key: StringName in size_keys:
		label.add_theme_font_size_override(
			key,
			_resolve_font_size(label, key)
		)


func _resolve_font_size(control: Control, key: StringName) -> int:
	var requested_size: int = typography.font_size

	if (
		typography.preserve_explicit_size_hierarchy
		and control.has_theme_font_size_override(key)
	):
		requested_size = control.get_theme_font_size(key)

	return typography.get_pixel_aligned_size(requested_size)
