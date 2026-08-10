extends Node
class_name KubuFontScope


@export var typography: KubuTypographyData
@export var target_path: NodePath = NodePath("..")

var _target: Node
var _font: Font


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

	_apply_to_subtree(_target)

	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)


func _exit_tree() -> void:
	if get_tree() == null:
		return

	if get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.disconnect(_on_tree_node_added)


func _on_tree_node_added(node: Node) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	if node == _target or _target.is_ancestor_of(node):
		_apply_to_subtree(node)


func _apply_to_subtree(root: Node) -> void:
	if root is Control:
		_apply_to_control(root as Control)

	for child: Node in root.get_children():
		_apply_to_subtree(child)


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
