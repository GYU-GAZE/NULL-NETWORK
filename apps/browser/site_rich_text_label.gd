extends RichTextLabel
class_name SiteRichTextLabel

signal browser_navigation_requested(url: String)
signal local_reference_requested(reference: String)

@export_category("Rich Text")
@export var force_bbcode_enabled: bool = true
@export var force_fit_content: bool = true
@export var force_word_wrap: bool = true

func _ready() -> void:
	if force_bbcode_enabled:
		bbcode_enabled = true
	if force_fit_content:
		fit_content = true
	if force_word_wrap:
		autowrap_mode = TextServer.AUTOWRAP_WORD
	if not meta_clicked.is_connected(_on_meta_clicked):
		meta_clicked.connect(_on_meta_clicked)

func _on_meta_clicked(meta: Variant) -> void:
	var meta_text := str(meta).strip_edges()
	if meta_text.is_empty():
		return
	_run_meta_action(meta_text)

func _run_meta_action(meta_text: String) -> void:
	if meta_text.begins_with("ref:"):
		_run_local_reference(meta_text.trim_prefix("ref:"))
		return
	if meta_text.begins_with("scroll_y:"):
		_run_local_reference(meta_text)
		return
	if meta_text.begins_with("nav:"):
		_run_navigation(meta_text.trim_prefix("nav:"))
		return
	if meta_text.begins_with("dialogue:"):
		_run_dialogue(meta_text.trim_prefix("dialogue:"))
		return
	if meta_text.begins_with("flag:"):
		_run_flag_set(meta_text.trim_prefix("flag:"))
		return
	if meta_text.begins_with("toggle_flag:"):
		_run_flag_toggle(meta_text.trim_prefix("toggle_flag:"))
		return
	if meta_text.begins_with("num:"):
		_run_number_action(meta_text.trim_prefix("num:"))
		return
	if meta_text.begins_with("show:"):
		_run_visibility_action(meta_text.trim_prefix("show:"), true)
		return
	if meta_text.begins_with("hide:"):
		_run_visibility_action(meta_text.trim_prefix("hide:"), false)
		return
	if meta_text.begins_with("toggle_node:"):
		_run_visibility_toggle(meta_text.trim_prefix("toggle_node:"))
		return
	if meta_text.begins_with("notify:"):
		_run_notification(meta_text.trim_prefix("notify:"))
		return
	if meta_text.begins_with("alert:"):
		_run_alert(meta_text.trim_prefix("alert:"))
		return
	_run_navigation(meta_text)

func _run_local_reference(reference: String) -> void:
	var clean_reference := reference.strip_edges()
	if not clean_reference.is_empty():
		local_reference_requested.emit(clean_reference)

func _run_navigation(url: String) -> void:
	var clean_url := url.strip_edges()
	if not clean_url.is_empty():
		browser_navigation_requested.emit(clean_url)

func _run_dialogue(dialogue_id: String) -> void:
	var clean_dialogue_id := dialogue_id.strip_edges()
	if clean_dialogue_id.is_empty():
		return
	if DialogueManager.start_dialogue(clean_dialogue_id):
		return
	UniversalNotifications.push("DIALOGUE UNAVAILABLE", "The requested dialogue could not be started.")

func _run_flag_set(payload: String) -> void:
	var parts := payload.split(":", false)
	if parts.size() < 2:
		return
	var flag_name := parts[0].strip_edges()
	var value_text := parts[1].strip_edges().to_lower()
	if flag_name.is_empty():
		return
	GameState.set_flag(flag_name, value_text in ["true", "1", "yes", "on"])

func _run_flag_toggle(flag_name: String) -> void:
	var clean_flag_name := flag_name.strip_edges()
	if not clean_flag_name.is_empty():
		GameState.toggle_flag(clean_flag_name)

func _run_number_action(payload: String) -> void:
	var parts := payload.split(":", false)
	if parts.size() < 3:
		return
	var mode := parts[0].strip_edges().to_lower()
	var var_name := parts[1].strip_edges()
	var value := int(parts[2].strip_edges())
	if var_name.is_empty():
		return
	if mode == "set":
		GameState.set_number(var_name, value)
	elif mode == "add":
		GameState.add_number(var_name, value)

func _run_visibility_action(path_text: String, target_visibility: bool) -> void:
	var target_node := get_node_or_null(NodePath(path_text.strip_edges()))
	if target_node == null:
		push_warning("SiteRichTextLabel: node inválido: %s" % path_text)
		return
	if not target_node is CanvasItem:
		push_warning("SiteRichTextLabel: node precisa herdar CanvasItem para usar visible.")
		return
	(target_node as CanvasItem).visible = target_visibility

func _run_visibility_toggle(path_text: String) -> void:
	var target_node := get_node_or_null(NodePath(path_text.strip_edges()))
	if target_node == null:
		push_warning("SiteRichTextLabel: node inválido: %s" % path_text)
		return
	if not target_node is CanvasItem:
		push_warning("SiteRichTextLabel: node precisa herdar CanvasItem para usar visible.")
		return
	var canvas_item := target_node as CanvasItem
	canvas_item.visible = not canvas_item.visible

func _run_notification(payload: String) -> void:
	var parts := payload.split("|", false)
	if parts.is_empty():
		return
	UniversalNotifications.push(parts[0].strip_edges(), parts[1].strip_edges() if parts.size() >= 2 else "")

func _run_alert(payload: String) -> void:
	var parts := payload.split("|", false)
	if parts.is_empty():
		return
	var title := parts[0].strip_edges()
	var message := parts[1].strip_edges() if parts.size() >= 2 else ""
	var animation := UniversalAlerts.AlertAnimation.POP
	if parts.size() >= 3:
		animation = UniversalAlerts.get_animation_from_text(parts[2])
	UniversalAlerts.show_alert(title, message, animation)
