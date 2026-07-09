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
@export var alert_card_scene: PackedScene

@export_category("Routing")
@export var forum_home_url: String = "null.net/forums"
@export var thread_url_prefix: String = "null.net/forums/thread/"

@export_category("Feed Configuration")
@export var visible_categories: Array[ForumThread.ThreadCategory] = [
	ForumThread.ThreadCategory.GUIDE,
	ForumThread.ThreadCategory.RUMOR,
	ForumThread.ThreadCategory.HELP,
	ForumThread.ThreadCategory.SOCIAL
]
@export var auto_watch_visible_threads: bool = false
@export var mark_threads_as_read_when_opened: bool = true

@export_category("Feature Visibility")
@export var show_main_nav: bool = true
@export var show_filter_bar: bool = true
@export var show_search_bar: bool = true
@export var show_alerts_navigation: bool = true
@export var show_updates_navigation: bool = true
@export var show_rankings_navigation: bool = true
@export var show_watch_button: bool = true

@export_category("Compact Layout")
@export var type_column_width: float = 48.0
@export var replies_column_width: float = 42.0
@export var last_reply_column_width: float = 86.0
@export var author_column_width: float = 80.0

@onready var master_scroll: ScrollContainer = %MasterScroll

@onready var thread_list_page: VBoxContainer = %ThreadListPage
@onready var alerts_page: VBoxContainer = %AlertsPage
@onready var reader_container: VBoxContainer = %ReaderContainer

@onready var thread_list_container: VBoxContainer = %ThreadList
@onready var reader_title_label: Label = %ReaderTitleLabel
@onready var watch_thread_btn: Button = %WatchThreadBtn
@onready var post_list: VBoxContainer = %PostList

@onready var site_header: NullChannelHeader = %SiteHeader

@onready var trending_btn: Button = %TrendingBtn
@onready var social_btn: Button = %SocialBtn
@onready var rumors_btn: Button = %RumorsBtn
@onready var guides_btn: Button = %GuidesBtn
@onready var help_btn: Button = %HelpBtn
@onready var archived_btn: Button = %ArchivedBtn

@onready var search_input: LineEdit = %SearchInput
@onready var search_btn: Button = %SearchBtn
@onready var clear_search_btn: Button = %ClearSearchBtn

@onready var type_header_label: Label = %TypeHeaderLabel
@onready var replies_header_label: Label = %RepliesHeaderLabel
@onready var last_reply_header_label: Label = %LastReplyHeaderLabel
@onready var author_header_label: Label = %AuthorHeaderLabel

var current_mode: String = "thread_list"
var current_thread_id: String = ""
var current_filter: ForumViewFilter = ForumViewFilter.TRENDING
var current_search_query: String = ""


func _ready() -> void:
	_reload_folder_threads()
	_apply_compact_layout()
	_apply_feature_visibility()

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

	if not GameState.game_state_changed.is_connected(_on_game_state_changed):
		GameState.game_state_changed.connect(_on_game_state_changed)
		
	if not ForumThreadWatcher.watched_alerts_changed.is_connected(_on_watched_alerts_changed):
		ForumThreadWatcher.watched_alerts_changed.connect(_on_watched_alerts_changed)


func _reload_folder_threads() -> void:
	ForumThreadDatabase.reload_threads()


func _get_all_thread_data() -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []
	var seen_thread_ids: Dictionary = {}

	for data in thread_list:
		_append_unique_thread_data(result, seen_thread_ids, data)

	for data in ForumThreadDatabase.get_all_thread_data():
		_append_unique_thread_data(result, seen_thread_ids, data)

	return result


func _append_unique_thread_data(result: Array[ThreadButtonData], seen_thread_ids: Dictionary, data: ThreadButtonData) -> void:
	if data == null:
		return

	if data.thread_ref == null:
		return

	var thread_id: String = data.thread_ref.thread_id.strip_edges()

	if thread_id.is_empty():
		result.append(data)
		return

	if seen_thread_ids.has(thread_id):
		return

	seen_thread_ids[thread_id] = true
	result.append(data)


func _apply_feature_visibility() -> void:
	site_header.configure_navigation(
		show_main_nav,
		show_updates_navigation,
		show_rankings_navigation,
		show_alerts_navigation
	)

	site_header.set_alerts_badge_visible(false)

	trending_btn.visible = show_filter_bar
	social_btn.visible = show_filter_bar and visible_categories.has(ForumThread.ThreadCategory.SOCIAL)
	rumors_btn.visible = show_filter_bar and visible_categories.has(ForumThread.ThreadCategory.RUMOR)
	guides_btn.visible = show_filter_bar and visible_categories.has(ForumThread.ThreadCategory.GUIDE)
	help_btn.visible = show_filter_bar and visible_categories.has(ForumThread.ThreadCategory.HELP)
	archived_btn.visible = show_filter_bar

	search_input.visible = show_search_bar
	search_btn.visible = show_search_bar
	clear_search_btn.visible = show_search_bar

func _apply_compact_layout() -> void:
	_set_column_width(type_header_label, type_column_width)
	_set_column_width(replies_header_label, replies_column_width)
	_set_column_width(last_reply_header_label, last_reply_column_width)
	_set_column_width(author_header_label, author_column_width)


func _set_column_width(control: Control, width: float) -> void:
	if not is_instance_valid(control):
		return

	control.custom_minimum_size.x = width
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	if control is Label:
		var label := control as Label
		label.clip_text = true

func _connect_main_nav() -> void:
	if not site_header.navigation_requested.is_connected(_on_site_header_navigation_requested):
		site_header.navigation_requested.connect(_on_site_header_navigation_requested)

	if not site_header.alerts_requested.is_connected(_on_site_header_alerts_requested):
		site_header.alerts_requested.connect(_on_site_header_alerts_requested)


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

	if auto_watch_visible_threads:
		_auto_watch_visible_threads()

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

	for data in _get_all_thread_data():
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		if data.thread_ref.get_visible_posts().is_empty():
			continue

		if not _is_category_visible(data.thread_ref.thread_category):
			continue

		if not _passes_filter(data):
			continue

		if not data.matches_search(current_search_query):
			continue

		result.append(data)

	result.sort_custom(_sort_threads)
	return result


func _is_category_visible(category: ForumThread.ThreadCategory) -> bool:
	if visible_categories.is_empty():
		return true

	return visible_categories.has(category)


func _passes_filter(data: ThreadButtonData) -> bool:
	if not show_filter_bar:
		return not data.is_archived()

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

	row.apply_layout_widths(
		type_column_width,
		replies_column_width,
		last_reply_column_width,
		author_column_width
	)

	row.setup(data)
	row.thread_selected.connect(_open_thread)

	var separator: HSeparator = HSeparator.new()
	thread_list_container.add_child(separator)

func _add_alert_card(data: ThreadButtonData) -> void:
	if alert_card_scene == null:
		push_error("ForumApp: alert_card_scene não configurada.")
		return

	var instance: Node = alert_card_scene.instantiate()

	if instance == null:
		push_error("ForumApp: alert_card_scene.instantiate() retornou null.")
		return

	if not instance is ForumAlertCard:
		push_error("ForumApp: alert_card_scene precisa ter root ForumAlertCard.")
		instance.queue_free()
		return

	var card: ForumAlertCard = instance as ForumAlertCard
	alerts_page.add_child(card)

	card.setup(data)
	card.alert_selected.connect(_open_thread)

	alerts_page.add_child(HSeparator.new())

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

	if mark_threads_as_read_when_opened:
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


func _on_post_link_clicked(url: String) -> void:
	browser_navigation_requested.emit(url)


func _open_thread_by_id(thread_id: String) -> void:
	var thread: ForumThread = _find_thread_by_id(thread_id)

	if thread == null:
		_show_thread_list_page()
		return

	_open_thread(thread)


func _find_thread_by_id(thread_id: String) -> ForumThread:
	for data in _get_all_thread_data():
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
		_add_alert_card(data)

func _get_alert_threads() -> Array[ThreadButtonData]:
	return ForumThreadWatcher.get_alert_thread_data()

func _refresh_alerts_badge() -> void:
	if not show_alerts_navigation:
		site_header.set_alerts_badge_visible(false)
		return

	site_header.set_alerts_badge_visible(ForumThreadWatcher.has_pending_alerts())


func _refresh_watch_button() -> void:
	if not show_watch_button:
		watch_thread_btn.hide()
		return

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


func _auto_watch_visible_threads() -> void:
	for data in _get_all_thread_data():
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		if data.is_archived():
			continue

		if not _is_category_visible(data.thread_ref.thread_category):
			continue

		GameState.watch_thread(data.thread_ref.thread_id)


func _notify_new_watched_thread_alerts() -> void:
	for data in _get_all_thread_data():
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		if data.is_archived():
			continue

		if not _is_category_visible(data.thread_ref.thread_category):
			continue

		var thread: ForumThread = data.thread_ref

		GameState.sync_thread_read_state(
			thread.thread_id,
			thread.get_visibility_signature()
		)

		var notification_key: String = _get_watch_notification_key(thread)

		UniversalNotifications.push(
			thread.get_watched_notification_title(),
			thread.get_watched_notification_message()
		)


func _get_watch_notification_key(thread: ForumThread) -> String:
	if thread == null:
		return ""

	return "%s::%s" % [
		thread.thread_id,
		thread.get_visibility_signature()
	]


func _on_time_advanced(_period: int, _days_passed: int, _cal_day: int, _cal_month: String) -> void:
	_reload_folder_threads()

	if auto_watch_visible_threads:
		_auto_watch_visible_threads()

	_refresh_thread_list()
	_refresh_alerts_badge()

	if current_mode == "alerts":
		_rebuild_alerts_page()

	if current_mode == "thread" and not current_thread_id.is_empty():
		var current_thread: ForumThread = _find_thread_by_id(current_thread_id)

		if current_thread != null:
			_rebuild_current_thread_reader(current_thread)


func _on_game_state_changed() -> void:
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


func _on_alerts_btn_pressed() -> void:
	_show_alerts_page()
	_refresh_alerts_badge()

func set_browser_url(url: String) -> void:
	var thread_id: String = _extract_thread_id_from_url(url)

	if thread_id.is_empty():
		return

	_open_thread_by_id(thread_id)


func _extract_thread_id_from_url(url: String) -> String:
	var clean_url: String = url.strip_edges()

	if clean_url.begins_with(thread_url_prefix):
		return clean_url.trim_prefix(thread_url_prefix).strip_edges()

	return ""

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
		"filter": current_filter,
		"search": current_search_query
	}


func restore_browser_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	current_filter = int(state.get("filter", ForumViewFilter.TRENDING)) as ForumViewFilter
	current_search_query = str(state.get("search", ""))

	search_input.text = current_search_query
	_refresh_filter_buttons()

	var mode: String = str(state.get("mode", "thread_list"))
	var thread_id: String = str(state.get("thread_id", ""))

	if mode == "thread" and not thread_id.is_empty():
		_open_thread_by_id(thread_id)
		return

	if mode == "alerts":
		_show_alerts_page()
		return

	_show_thread_list_page()
	_refresh_thread_list()
	_refresh_alerts_badge()

func _on_watched_alerts_changed() -> void:
	_refresh_alerts_badge()

	if current_mode == "alerts":
		_rebuild_alerts_page()

func _on_site_header_navigation_requested(url: String) -> void:
	var target_url: String = url.strip_edges()

	if target_url == forum_home_url:
		_show_thread_list_page()
		_refresh_filter_buttons()
		_refresh_thread_list()
		return

	browser_navigation_requested.emit(target_url)


func _on_site_header_alerts_requested() -> void:
	_show_alerts_page()
