extends Control
class_name ForumApp

signal browser_navigation_requested(url: String)

enum ForumViewFilter {
	TRENDING,
	GUIDES,
	RUMORS,
	HELP,
	SOCIAL,
	ARCHIVED
}

@export_category("Forum Database")
@export var thread_list: Array[ThreadButtonData] = []
@export var post_ui_scene: PackedScene
@export var thread_row_scene: PackedScene

@onready var master_scroll: ScrollContainer = %MasterScroll
@onready var thread_list_container: VBoxContainer = %ThreadList
@onready var reader_container: VBoxContainer = %ReaderContainer
@onready var reader_title_label: Label = %ReaderTitleLabel
@onready var post_list: VBoxContainer = %PostList
@onready var threads_btn: Button = %ThreadsBtn

var current_mode: String = "thread_list"
var current_thread_id: String = ""
var current_filter: ForumViewFilter = ForumViewFilter.TRENDING
var current_search_query: String = ""
var search_input_ref: LineEdit


func _ready() -> void:
	reader_container.hide()
	thread_list_container.show()

	threads_btn.pressed.connect(_on_threads_btn_pressed)
	_generate_thread_list()

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)


func _generate_thread_list() -> void:
	for child in thread_list_container.get_children():
		child.queue_free()

	_build_forum_header()
	_build_filter_tabs()
	_build_search_bar()
	_build_thread_list_header()

	var visible_threads: Array[ThreadButtonData] = _get_visible_threads()

	if visible_threads.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Nenhuma thread encontrada."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		thread_list_container.add_child(empty_label)
		return

	for data in visible_threads:
		_add_thread_row(data)


func _build_forum_header() -> void:
	var title: Label = Label.new()
	title.text = "NULL CHANNEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	thread_list_container.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Rumores, guias, pedidos de ajuda, social e lixo radioativo da comunidade."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thread_list_container.add_child(subtitle)

	thread_list_container.add_child(HSeparator.new())


func _build_filter_tabs() -> void:
	var tab_bar: HBoxContainer = HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_add_filter_button(tab_bar, "TRENDING", ForumViewFilter.TRENDING)
	_add_filter_button(tab_bar, "GUIDES", ForumViewFilter.GUIDES)
	_add_filter_button(tab_bar, "RUMORS", ForumViewFilter.RUMORS)
	_add_filter_button(tab_bar, "HELP", ForumViewFilter.HELP)
	_add_filter_button(tab_bar, "SOCIAL", ForumViewFilter.SOCIAL)
	_add_filter_button(tab_bar, "ARCHIVED", ForumViewFilter.ARCHIVED)

	thread_list_container.add_child(tab_bar)


func _add_filter_button(parent: Control, label: String, filter: ForumViewFilter) -> void:
	var btn: Button = Button.new()
	btn.text = label
	btn.toggle_mode = true
	btn.button_pressed = current_filter == filter
	btn.pressed.connect(_on_filter_pressed.bind(filter))
	parent.add_child(btn)


func _build_search_bar() -> void:
	var search_box: HBoxContainer = HBoxContainer.new()
	search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var search_label: Label = Label.new()
	search_label.text = "Search:"
	search_box.add_child(search_label)

	var search_input: LineEdit = LineEdit.new()
	search_input_ref = search_input
	search_input.placeholder_text = "título, tag, autor ou conteúdo..."
	search_input.text = current_search_query
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.text_changed.connect(_on_search_changed)
	search_box.add_child(search_input)

	var clear_btn: Button = Button.new()
	clear_btn.text = "X"
	clear_btn.pressed.connect(_on_clear_search_pressed)
	search_box.add_child(clear_btn)

	thread_list_container.add_child(search_box)
	thread_list_container.add_child(HSeparator.new())


func _build_thread_list_header() -> void:
	var header: HBoxContainer = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.custom_minimum_size.x = 0

	var topic: Label = _make_header_label("THREAD", Control.SIZE_EXPAND_FILL)
	var author: Label = _make_header_label("AUTHOR", Control.SIZE_SHRINK_CENTER)
	var replies: Label = _make_header_label("REPLIES", Control.SIZE_SHRINK_CENTER)
	var last_reply: Label = _make_header_label("LAST REPLY", Control.SIZE_SHRINK_CENTER)

	topic.custom_minimum_size.x = 0
	author.custom_minimum_size.x = 110
	replies.custom_minimum_size.x = 60
	last_reply.custom_minimum_size.x = 130

	header.add_child(topic)
	header.add_child(author)
	header.add_child(replies)
	header.add_child(last_reply)

	thread_list_container.add_child(header)
	thread_list_container.add_child(HSeparator.new())


func _make_header_label(text: String, horizontal_flags: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.size_flags_horizontal = horizontal_flags
	return label


func _get_visible_threads() -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []

	for data in thread_list:
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		if not _passes_filter(data):
			continue

		if not data.matches_search(current_search_query):
			continue

		result.append(data)

	result.sort_custom(_sort_threads)

	return result


func _passes_filter(data: ThreadButtonData) -> bool:
	var thread: ForumThread = data.thread_ref

	match current_filter:
		ForumViewFilter.TRENDING:
			return not data.is_archived()

		ForumViewFilter.GUIDES:
			return not data.is_archived() and thread.thread_category == ForumThread.ThreadCategory.GUIDE

		ForumViewFilter.RUMORS:
			return not data.is_archived() and thread.thread_category == ForumThread.ThreadCategory.RUMOR

		ForumViewFilter.HELP:
			return not data.is_archived() and thread.thread_category == ForumThread.ThreadCategory.HELP

		ForumViewFilter.SOCIAL:
			return not data.is_archived() and thread.thread_category == ForumThread.ThreadCategory.SOCIAL

		ForumViewFilter.ARCHIVED:
			return data.is_archived()

	return true


func _sort_threads(a: ThreadButtonData, b: ThreadButtonData) -> bool:
	if a == null or a.thread_ref == null:
		return false

	if b == null or b.thread_ref == null:
		return true

	if a.is_pinned() != b.is_pinned():
		return a.is_pinned()

	if a.thread_ref.popularity_score != b.thread_ref.popularity_score:
		return a.thread_ref.popularity_score > b.thread_ref.popularity_score

	return a.get_release_action_index() > b.get_release_action_index()


func _add_thread_row(data: ThreadButtonData) -> void:
	if thread_row_scene == null:
		push_error("ForumApp: thread_row_scene não configurada.")
		return

	var instance: Node = thread_row_scene.instantiate()

	if instance == null:
		push_error("ForumApp: thread_row_scene.instantiate() retornou null.")
		return

	if not instance is ForumThreadRowUI:
		push_error("ForumApp: thread_row_scene precisa ter root ForumThreadRowUI.")
		instance.queue_free()
		return

	var row: ForumThreadRowUI = instance as ForumThreadRowUI
	thread_list_container.add_child(row)

	row.setup(data)
	row.thread_selected.connect(_open_thread)

	thread_list_container.add_child(HSeparator.new())


func _on_filter_pressed(filter: ForumViewFilter) -> void:
	current_filter = filter
	_generate_thread_list()


func _on_search_changed(new_text: String) -> void:
	current_search_query = new_text

	var caret_column: int = new_text.length()

	if is_instance_valid(search_input_ref):
		caret_column = search_input_ref.caret_column

	_generate_thread_list()
	call_deferred("_restore_search_focus", caret_column)


func _restore_search_focus(caret_column: int) -> void:
	if not is_instance_valid(search_input_ref):
		return

	search_input_ref.grab_focus()
	search_input_ref.caret_column = caret_column


func _on_clear_search_pressed() -> void:
	current_search_query = ""
	_generate_thread_list()


func _on_time_advanced(_period: int, _days_passed: int, _cal_day: int, _cal_month: String) -> void:
	_generate_thread_list()


func _open_thread(thread: ForumThread) -> void:
	if thread == null:
		return

	current_mode = "thread"
	current_thread_id = thread.thread_id

	GameState.mark_thread_as_read(thread.thread_id)
	_generate_thread_list()

	reader_title_label.text = "[%s] %s" % [
		thread.get_category_label(),
		thread.thread_title
	]

	for child in post_list.get_children():
		child.queue_free()

	_build_thread_reader_header(thread)

	for post in thread.posts:
		if post == null:
			continue

		var post_instance: ForumPostUI = post_ui_scene.instantiate() as ForumPostUI
		post_list.add_child(post_instance)
		post_instance.link_clicked.connect(_on_post_link_clicked)
		post_instance.setup(post)

	thread_list_container.hide()
	reader_container.show()

	master_scroll.scroll_vertical = 0


func _build_thread_reader_header(thread: ForumThread) -> void:
	var meta_label: RichTextLabel = RichTextLabel.new()
	meta_label.bbcode_enabled = true
	meta_label.fit_content = true
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	meta_label.text = "[b]Autor:[/b] %s\n[b]Tags:[/b] %s\n[b]Replies:[/b] %d\n[b]Status:[/b] %s" % [
		thread.get_thread_author(),
		_format_tags(thread.thread_tags),
		thread.get_reply_count(),
		_get_thread_status_text(thread)
	]

	post_list.add_child(meta_label)
	post_list.add_child(HSeparator.new())


func _format_tags(tags: Array[String]) -> String:
	if tags.is_empty():
		return "—"

	var output: String = ""

	for tag in tags:
		var clean_tag: String = tag.strip_edges()

		if clean_tag.is_empty():
			continue

		output += "#%s " % clean_tag

	if output.is_empty():
		return "—"

	return output.strip_edges()


func _get_thread_status_text(thread: ForumThread) -> String:
	var status_parts: Array[String] = []

	if thread.is_pinned:
		status_parts.append("PINNED")

	if thread.is_locked:
		status_parts.append("LOCKED")

	if thread.is_archived:
		status_parts.append("ARCHIVED")

	if status_parts.is_empty():
		return "ACTIVE"

	return ", ".join(status_parts)


func _open_thread_by_id(thread_id: String) -> void:
	var thread: ForumThread = _find_thread_by_id(thread_id)

	if thread == null:
		_show_thread_list()
		return

	_open_thread(thread)


func _find_thread_by_id(thread_id: String) -> ForumThread:
	for data in thread_list:
		if data == null or data.thread_ref == null:
			continue

		if data.thread_ref.thread_id == thread_id:
			return data.thread_ref

	return null


func _show_thread_list() -> void:
	current_mode = "thread_list"
	current_thread_id = ""

	reader_container.hide()
	thread_list_container.show()

	master_scroll.scroll_vertical = 0


func _on_threads_btn_pressed() -> void:
	_show_thread_list()


func handle_browser_back() -> bool:
	if reader_container.visible:
		_show_thread_list()
		return true

	return false


func get_browser_state() -> Dictionary:
	return {
		"mode": current_mode,
		"thread_id": current_thread_id,
		"scroll_vertical": master_scroll.scroll_vertical,
		"filter": int(current_filter),
		"search": current_search_query
	}


func restore_browser_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	var mode: String = str(state.get("mode", "thread_list"))
	var thread_id: String = str(state.get("thread_id", ""))
	var scroll_vertical: int = int(state.get("scroll_vertical", 0))
	var filter_value: int = int(state.get("filter", ForumViewFilter.TRENDING))
	var search_value: String = str(state.get("search", ""))

	current_filter = filter_value as ForumViewFilter
	current_search_query = search_value

	if mode == "thread" and not thread_id.is_empty():
		_open_thread_by_id(thread_id)
	else:
		_show_thread_list()
		_generate_thread_list()

	await get_tree().process_frame
	master_scroll.scroll_vertical = scroll_vertical


func _on_post_link_clicked(url: String) -> void:
	browser_navigation_requested.emit(url)
