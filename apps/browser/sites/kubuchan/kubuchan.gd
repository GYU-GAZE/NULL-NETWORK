extends Control
class_name KubuchanSite


signal browser_navigation_requested(url: String)

@export var thread_data: KubuchanThreadData
@export var post_card_scene: PackedScene

@onready var board_title_label: Label = %BoardTitleLabel
@onready var board_tagline_label: Label = %BoardTaglineLabel
@onready var thread_scroll: ScrollContainer = %ThreadScroll
@onready var thread_vbox: VBoxContainer = %ThreadVBox
@onready var archived_notice_label: Label = %ArchivedNoticeLabel


func _ready() -> void:
	_render_thread()


func _render_thread() -> void:
	for child in thread_vbox.get_children():
		child.queue_free()

	if thread_data == null:
		push_error("KubuchanSite requires thread_data.")
		return

	if post_card_scene == null:
		push_error("KubuchanSite requires post_card_scene.")
		return

	for error: String in thread_data.validate_data():
		push_error("Kubuchan thread: %s" % error)

	board_title_label.text = "%s - %s" % [
		thread_data.board_code,
		thread_data.board_name
	]
	board_tagline_label.text = thread_data.board_tagline
	archived_notice_label.text = thread_data.archived_notice
	archived_notice_label.visible = not thread_data.archived_notice.strip_edges().is_empty()

	for post_data: KubuchanPostData in thread_data.posts:
		if post_data == null:
			continue

		var card := post_card_scene.instantiate() as KubuchanPostCard

		if card == null:
			push_error("Kubuchan post_card_scene must instantiate KubuchanPostCard.")
			continue

		thread_vbox.add_child(card)
		card.configure(post_data)
		card.link_requested.connect(_on_link_requested)


func _on_link_requested(url: String) -> void:
	var clean_url: String = url.strip_edges()

	if clean_url.is_empty():
		return

	browser_navigation_requested.emit(clean_url)


func get_browser_state() -> Dictionary:
	return {
		"scroll_y": thread_scroll.scroll_vertical
	}


func restore_browser_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	thread_scroll.scroll_vertical = maxi(0, int(state.get("scroll_y", 0)))
