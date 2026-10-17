extends RichTextLabel
class_name SiteRichTextLabel

signal browser_navigation_requested(url: String)
signal local_reference_requested(reference: String)

@export var actions: Dictionary[String, SiteActionData] = {}

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
	if meta_text.begins_with("action:"):
		var key := meta_text.trim_prefix("action:")
		if actions.has(key):
			SiteActionRunner.execute(actions[key], self)
		return
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
	_run_navigation(meta_text)

func _run_local_reference(reference: String) -> void:
	var clean_reference := reference.strip_edges()
	if not clean_reference.is_empty():
		local_reference_requested.emit(clean_reference)

func _run_navigation(url: String) -> void:
	var clean_url := url.strip_edges()
	if not clean_url.is_empty():
		if not BrowserPageContext.navigate(self, clean_url):
			browser_navigation_requested.emit(clean_url)

func _run_dialogue(dialogue_id: String) -> void:
	var clean_dialogue_id := dialogue_id.strip_edges()
	if clean_dialogue_id.is_empty():
		return
	if DialogueManager.start_dialogue(clean_dialogue_id):
		return
	UniversalNotifications.push("DIALOGUE UNAVAILABLE", "The requested dialogue could not be started.")
