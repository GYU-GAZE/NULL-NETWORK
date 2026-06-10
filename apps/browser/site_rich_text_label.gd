extends RichTextLabel
class_name SiteRichTextLabel

signal browser_navigation_requested(url: String)

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
	var meta_text: String = str(meta).strip_edges()

	if meta_text.is_empty():
		return

	_run_meta_action(meta_text)


func _run_meta_action(meta_text: String) -> void:
	# Formatos:
	# [url=nav:null.net/forums]Forums[/url]
	# [url=flag:read_intro:true]Set true[/url]
	# [url=flag:read_intro:false]Set false[/url]
	# [url=toggle_flag:read_intro]Toggle flag[/url]
	# [url=num:set:intro_clicks:5]Set number[/url]
	# [url=num:add:intro_clicks:1]Add number[/url]
	# [url=show:../SecretPanel]Show node[/url]
	# [url=hide:../SecretPanel]Hide node[/url]
	# [url=toggle_node:../SecretPanel]Toggle node[/url]

	if meta_text.begins_with("notify:"):
		_run_notification(meta_text.trim_prefix("notify:"))
		return
	
	if meta_text.begins_with("nav:"):
		_run_navigation(meta_text.trim_prefix("nav:"))
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

	# Fallback: se não tiver prefixo, trata como URL normal.
	_run_navigation(meta_text)


func _run_navigation(url: String) -> void:
	var clean_url: String = url.strip_edges()

	if clean_url.is_empty():
		return

	browser_navigation_requested.emit(clean_url)


func _run_flag_set(payload: String) -> void:
	var parts: PackedStringArray = payload.split(":", false)

	if parts.size() < 2:
		return

	var flag_name: String = parts[0].strip_edges()
	var value_text: String = parts[1].strip_edges().to_lower()

	if flag_name.is_empty():
		return

	var value: bool = (
		value_text == "true"
		or value_text == "1"
		or value_text == "yes"
		or value_text == "on"
	)

	GameState.set_flag(flag_name, value)


func _run_flag_toggle(flag_name: String) -> void:
	var clean_flag_name: String = flag_name.strip_edges()

	if clean_flag_name.is_empty():
		return

	GameState.toggle_flag(clean_flag_name)


func _run_number_action(payload: String) -> void:
	var parts: PackedStringArray = payload.split(":", false)

	if parts.size() < 3:
		return

	var mode: String = parts[0].strip_edges().to_lower()
	var var_name: String = parts[1].strip_edges()
	var value: int = int(parts[2].strip_edges())

	if var_name.is_empty():
		return

	match mode:
		"set":
			GameState.set_number(var_name, value)

		"add":
			GameState.add_number(var_name, value)


func _run_visibility_action(path_text: String, target_visibility: bool) -> void:
	var target_node: Node = get_node_or_null(NodePath(path_text.strip_edges()))

	if target_node == null:
		push_warning("SiteRichTextLabel: node inválido: %s" % path_text)
		return

	if not target_node is CanvasItem:
		push_warning("SiteRichTextLabel: node precisa herdar CanvasItem para usar visible.")
		return

	var canvas_item: CanvasItem = target_node as CanvasItem
	canvas_item.visible = target_visibility


func _run_visibility_toggle(path_text: String) -> void:
	var target_node: Node = get_node_or_null(NodePath(path_text.strip_edges()))

	if target_node == null:
		push_warning("SiteRichTextLabel: node inválido: %s" % path_text)
		return

	if not target_node is CanvasItem:
		push_warning("SiteRichTextLabel: node precisa herdar CanvasItem para usar visible.")
		return

	var canvas_item: CanvasItem = target_node as CanvasItem
	canvas_item.visible = not canvas_item.visible

func _run_notification(payload: String) -> void:
	var parts: PackedStringArray = payload.split("|", false)

	if parts.size() <= 0:
		return

	var title: String = parts[0].strip_edges()
	var message: String = ""

	if parts.size() >= 2:
		message = parts[1].strip_edges()

	UniversalNotifications.push(title, message)
