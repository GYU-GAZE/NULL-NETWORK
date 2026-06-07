extends Control
class_name ForumApp

signal browser_navigation_requested(url: String)

enum ForumViewFilter {
	TRENDING,
	SOCIAL,
	RUMORS,
	GUIDES,
	HELP,
	ARCHIVED
}

@export_category("Forum Database")
@export var thread_list: Array[ThreadButtonData] = []
@export var post_ui_scene: PackedScene
@export var thread_row_scene: PackedScene

@export_category("External URLs")
@export var updates_url: String = "null.net/updates"
@export var rankings_url: String = "null.net/rankings"
@export var forums_url: String = "null.net/forums"

@onready var master_scroll: ScrollContainer = %MasterScroll

@onready var thread_list_page: VBoxContainer = %ThreadListPage
@onready var alerts_page: VBoxContainer = %AlertsPage
@onready var reader_container: VBoxContainer = %ReaderContainer

@onready var thread_list_container: VBoxContainer = %ThreadList
@onready var reader_title_label: Label = %ReaderTitleLabel
@onready var watch_thread_btn: Button = %WatchThreadBtn
@onready var post_list: VBoxContainer = %PostList

@onready var threads_btn: Button = %ThreadsBtn
@onready var updates_btn: Button = %UpdatesBtn
@onready var rankings_btn: Button = %RankingsBtn
@onready var alerts_btn: Button = %AlertsBtn
@onready var alerts_notification_badge: Control = %AlertsNotificationBadge

@onready var trending_btn: Button = %TrendingBtn
@onready var social_btn: Button = %SocialBtn
@onready var rumors_btn: Button = %RumorsBtn
@onready var guides_btn: Button = %GuidesBtn
@onready var help_btn: Button = %HelpBtn
@onready var archived_btn: Button = %ArchivedBtn

@onready var search_input: LineEdit = %SearchInput
@onready var search_btn: Button = %SearchBtn
@onready var clear_search_btn: Button = %ClearSearchBtn

var current_mode: String = "thread_list"
var current_thread_id: String = ""
var current_filter: ForumViewFilter = ForumViewFilter.TRENDING
var current_search_query: String = ""


func _ready() -> void:
	_connect_main_nav()
	_connect_filter_tabs()
	_connect_search_bar()
	_connect_reader_actions()

	_show_thread_list_page()
	_refresh_filter_buttons()
	_refresh_thread_list()
	_refresh_alerts_badge()
	_refresh_watch_button()

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)


func _connect_main_nav() -> void:
	if not threads_btn.pressed.is_connected(_on_threads_btn_pressed):
		threads_btn.pressed.connect(_on_threads_btn_pressed)

	if not updates_btn.pressed.is_connected(_on_updates_btn_pressed):
		updates_btn.pressed.connect(_on_updates_btn_pressed)

	if not rankings_btn.pressed.is_connected(_on_rankings_btn_pressed):
		rankings_btn.pressed.connect(_on_rankings_btn_pressed)

	if not alerts_btn.pressed.is_connected(_on_alerts_btn_pressed):
		alerts_btn.pressed.connect(_on_alerts_btn_pressed)


func _connect_filter_tabs() -> void:
	_connect_filter_button(trending_btn, ForumViewFilter.TRENDING)
	_connect_filter_button(social_btn, ForumViewFilter.SOCIAL)
	_connect_filter_button(rumors_btn, ForumViewFilter.RUMORS)
	_connect_filter_button(guides_btn, ForumViewFilter.GUIDES)
	_connect_filter_button(help_btn, ForumViewFilter.HELP)
	_connect_filter_button(archived_btn, ForumViewFilter.ARCHIVED)


func _connect_filter_button(button: Button, filter: ForumViewFilter) -> void:
	button.toggle_mode = true

	if not button.pressed.is_connected(_on_filter_pressed.bind(filter)):
		button.pressed.connect(_on_filter_pressed.bind(filter))


func _connect_search_bar() -> void:
	search_input.text = current_search_query

	if not search_input.text_changed.is_connected(_on_search_changed):
		search_input.text_changed.connect(_on_search_changed)

	if not search_input.text_submitted.is_connected(_on_search_submitted):
		search_input.text_submitted.connect(_on_search_submitted)

	if not search_btn.pressed.is_connected(_on_search_btn_pressed):
		search_btn.pressed.connect(_on_search_btn_pressed)

	if not clear_search_btn.pressed.is_connected(_on_clear_search_pressed):
		clear_search_btn.pressed.connect(_on_clear_search_pressed)


func _connect_reader_actions() -> void:
	if not watch_thread_btn.pressed.is_connected(_on_watch_thread_pressed):
		watch_thread_btn.pressed.connect(_on_watch_thread_pressed)


func _show_thread_list_page() -> void:
	current_mode = "thread_list"
	current_thread_id = ""

	thread_list_page.show()
	alerts_page.hide()
	reader_container.hide()

	_refresh_watch_button()
	master_scroll.scroll_vertical = 0


func _show_alerts_page() -> void:
	current_mode = "alerts"
	current_thread_id = ""

	thread_list_page.hide()
	alerts_page.show()
	reader_container.hide()

	_refresh_watch_button()
	_rebuild_alerts_page()

	master_scroll.scroll_vertical = 0


func _show_reader_page() -> void:
	thread_list_page.hide()
	alerts_page.hide()
	reader_container.show()

	_refresh_watch_button()
	master_scroll.scroll_vertical = 0


func _refresh_thread_list() -> void:
	for child in thread_list_container.get_children():
		child.queue_free()

	var visible_threads: Array[ThreadButtonData] = _get_visible_threads()

	if visible_threads.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Nenhuma thread encontrada."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		thread_list_container.add_child(empty_label)
		return

	for data in visible_threads:
		if data.thread_ref != null:
			GameState.sync_thread_read_state(
				data.thread_ref.thread_id,
				data.thread_ref.get_visibility_signature()
			)

		_add_thread_row(data)


func _get_visible_threads() -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []

	for data in thread_list:
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		if data.thread_ref.get_visible_posts().is_empty():
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

		ForumViewFilter.SOCIAL:
			return (
				not data.is_archived()
				and thread.thread_category == ForumThread.ThreadCategory.SOCIAL
			)

		ForumViewFilter.RUMORS:
			return (
				not data.is_archived()
				and thread.thread_category == ForumThread.ThreadCategory.RUMOR
			)

		ForumViewFilter.GUIDES:
			return (
				not data.is_archived()
				and thread.thread_category == ForumThread.ThreadCategory.GUIDE
			)

		ForumViewFilter.HELP:
			return (
				not data.is_archived()
				and thread.thread_category == ForumThread.ThreadCategory.HELP
			)

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

	var separator: HSeparator = HSeparator.new()
	thread_list_container.add_child(separator)


func _refresh_filter_buttons() -> void:
	trending_btn.button_pressed = current_filter == ForumViewFilter.TRENDING
	social_btn.button_pressed = current_filter == ForumViewFilter.SOCIAL
	rumors_btn.button_pressed = current_filter == ForumViewFilter.RUMORS
	guides_btn.button_pressed = current_filter == ForumViewFilter.GUIDES
	help_btn.button_pressed = current_filter == ForumViewFilter.HELP
	archived_btn.button_pressed = current_filter == ForumViewFilter.ARCHIVED


func _on_filter_pressed(filter: ForumViewFilter) -> void:
	current_filter = filter
	_refresh_filter_buttons()
	_refresh_thread_list()


func _on_search_changed(new_text: String) -> void:
	current_search_query = new_text

	var caret_column: int = search_input.caret_column

	_refresh_thread_list()
	call_deferred("_restore_search_focus", caret_column)


func _on_search_submitted(new_text: String) -> void:
	current_search_query = new_text
	_refresh_thread_list()


func _on_search_btn_pressed() -> void:
	current_search_query = search_input.text
	_refresh_thread_list()


func _restore_search_focus(caret_column: int) -> void:
	if not is_instance_valid(search_input):
		return

	search_input.grab_focus()
	search_input.caret_column = caret_column


func _on_clear_search_pressed() -> void:
	current_search_query = ""
	search_input.text = ""
	_refresh_thread_list()
	search_input.grab_focus()


func _open_thread(thread: ForumThread) -> void:
	if thread == null:
		return

	current_mode = "thread"
	current_thread_id = thread.thread_id

	GameState.mark_thread_as_read(
		thread.thread_id,
		thread.get_visibility_signature()
	)

	reader_title_label.text = "%s %s" % [
		thread.get_thread_label_text(),
		thread.thread_title
	]

	for child in post_list.get_children():
		child.queue_free()

	_build_thread_reader_header(thread)

	for post in thread.get_visible_posts():
		if post == null:
			continue

		var post_instance: ForumPostUI = post_ui_scene.instantiate() as ForumPostUI
		post_list.add_child(post_instance)
		post_instance.link_clicked.connect(_on_post_link_clicked)
		post_instance.setup(post)

	_refresh_thread_list()
	_refresh_alerts_badge()
	_refresh_watch_button()
	_show_reader_page()


func _build_thread_reader_header(thread: ForumThread) -> void:
	var meta_label: RichTextLabel = RichTextLabel.new()
	meta_label.bbcode_enabled = true
	meta_label.fit_content = true
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.text = "[b]Author:[/b] %s\n[b]Type:[/b] %s\n[b]Tags:[/b] %s\n[b]Replies:[/b] %d\n[b]Status:[/b] %s" % [
		thread.get_thread_author(),
		thread.get_category_label(),
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

	if GameState.is_thread_watched(thread.thread_id):
		status_parts.append("WATCHED")

	if status_parts.is_empty():
		return "ACTIVE"

	return ", ".join(status_parts)


func _open_thread_by_id(thread_id: String) -> void:
	var thread: ForumThread = _find_thread_by_id(thread_id)

	if thread == null:
		_show_thread_list_page()
		return

	_open_thread(thread)


func _find_thread_by_id(thread_id: String) -> ForumThread:
	for data in thread_list:
		if data == null or data.thread_ref == null:
			continue

		if data.thread_ref.thread_id == thread_id:
			return data.thread_ref

	return null


func _rebuild_alerts_page() -> void:
	for child in alerts_page.get_children():
		child.queue_free()

	var title_label: Label = Label.new()
	title_label.text = "ALERTS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	alerts_page.add_child(title_label)

	var description_label: Label = Label.new()
	description_label.text = "Watched threads with unread updates."
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alerts_page.add_child(description_label)

	alerts_page.add_child(HSeparator.new())

	var alert_threads: Array[ThreadButtonData] = _get_alert_threads()

	if alert_threads.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Nenhum alerta novo."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		alerts_page.add_child(empty_label)
		return

	for data in alert_threads:
		var thread: ForumThread = data.thread_ref

		var alert_btn: Button = Button.new()
		alert_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		alert_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		alert_btn.text = "! %s %s\nLast reply: %s — %s" % [
			thread.get_thread_label_text(),
			thread.thread_title,
			thread.get_last_reply_author(),
			thread.get_last_reply_time_label()
		]
		alert_btn.pressed.connect(_open_thread.bind(thread))
		alerts_page.add_child(alert_btn)

		alerts_page.add_child(HSeparator.new())


func _get_alert_threads() -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []

	for data in thread_list:
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		if data.is_archived():
			continue

		GameState.sync_thread_read_state(
			data.thread_ref.thread_id,
			data.thread_ref.get_visibility_signature()
		)

		if _thread_has_pending_watch_alert(data.thread_ref):
			result.append(data)

	result.sort_custom(_sort_threads)

	return result


func _thread_has_pending_watch_alert(thread: ForumThread) -> bool:
	if thread == null:
		return false

	if not thread.has_unread_content():
		return false

	return GameState.is_thread_watched(thread.thread_id)


func _refresh_alerts_badge() -> void:
	var has_alerts: bool = not _get_alert_threads().is_empty()
	alerts_notification_badge.visible = has_alerts

	if not has_alerts:
		return

	alerts_notification_badge.scale = Vector2(0.75, 0.75)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(alerts_notification_badge, "scale", Vector2.ONE, 0.18)


func _refresh_watch_button() -> void:
	if current_mode != "thread" or current_thread_id.is_empty():
		watch_thread_btn.hide()
		return

	watch_thread_btn.show()

	if GameState.is_thread_watched(current_thread_id):
		watch_thread_btn.text = "Watching"
		watch_thread_btn.tooltip_text = "Click to stop watching this thread."
	else:
		watch_thread_btn.text = "Watch Thread"
		watch_thread_btn.tooltip_text = "Click to receive alerts when this thread gets new replies."


func _on_watch_thread_pressed() -> void:
	if current_thread_id.is_empty():
		return

	GameState.toggle_thread_watch(current_thread_id)

	_refresh_watch_button()
	_refresh_alerts_badge()

	if current_mode == "thread":
		var thread: ForumThread = _find_thread_by_id(current_thread_id)

		if thread != null:
			reader_title_label.text = "%s %s" % [
				thread.get_thread_label_text(),
				thread.thread_title
			]


func _on_time_advanced(_period: int, _days_passed: int, _cal_day: int, _cal_month: String) -> void:
	_refresh_thread_list()
	_refresh_alerts_badge()

	if current_mode == "alerts":
		_rebuild_alerts_page()

	if current_mode == "thread" and not current_thread_id.is_empty():
		var current_thread: ForumThread = _find_thread_by_id(current_thread_id)

		if current_thread != null:
			_rebuild_current_thread_reader(current_thread)


func _rebuild_current_thread_reader(thread: ForumThread) -> void:
	for child in post_list.get_children():
		child.queue_free()

	_build_thread_reader_header(thread)

	for post in thread.get_visible_posts():
		if post == null:
			continue

		var post_instance: ForumPostUI = post_ui_scene.instantiate() as ForumPostUI
		post_list.add_child(post_instance)
		post_instance.link_clicked.connect(_on_post_link_clicked)
		post_instance.setup(post)


func _on_threads_btn_pressed() -> void:
	_show_thread_list_page()
	_refresh_thread_list()
	_refresh_alerts_badge()


func _on_updates_btn_pressed() -> void:
	browser_navigation_requested.emit(updates_url)


func _on_rankings_btn_pressed() -> void:
	browser_navigation_requested.emit(rankings_url)


func _on_alerts_btn_pressed() -> void:
	_show_alerts_page()
	_refresh_alerts_badge()


func handle_browser_back() -> bool:
	if reader_container.visible:
		_show_thread_list_page()
		_refresh_thread_list()
		_refresh_alerts_badge()
		return true

	if alerts_page.visible:
		_show_thread_list_page()
		_refresh_thread_list()
		_refresh_alerts_badge()
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
	search_input.text = current_search_query

	_refresh_filter_buttons()

	if mode == "thread" and not thread_id.is_empty():
		_open_thread_by_id(thread_id)
	elif mode == "alerts":
		_show_alerts_page()
	else:
		_show_thread_list_page()
		_refresh_thread_list()

	_refresh_alerts_badge()
	_refresh_watch_button()

	await get_tree().process_frame
	master_scroll.scroll_vertical = scroll_vertical


func _on_post_link_clicked(url: String) -> void:
	browser_navigation_requested.emit(url)
