extends Control
class_name KubuchanSite


signal browser_navigation_requested(url: String)

@export var thread_data: KubuchanThreadData
@export var post_card_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var post_reveal_seconds: float = 0.18
@export_range(0.0, 0.25, 0.01) var post_stagger_seconds: float = 0.045

@onready var page_root: Control = %PageRoot
@onready var brand_block: Control = %BrandBlock
@onready var board_code_label: Label = %BoardCodeLabel
@onready var board_name_label: Label = %BoardNameLabel
@onready var board_tagline_label: Label = %BoardTaglineLabel
@onready var thread_title_label: Label = %ThreadTitleLabel
@onready var thread_id_label: Label = %ThreadIdLabel
@onready var thread_scroll: ScrollContainer = %ThreadScroll
@onready var thread_vbox: VBoxContainer = %ThreadVBox
@onready var archived_notice_label: Label = %ArchivedNoticeLabel

var _rendered_cards: Array[KubuchanPostCard] = []


func _ready() -> void:
	_render_thread()
	call_deferred("_play_initial_reveal")


func _render_thread() -> void:
	for child in thread_vbox.get_children():
		child.queue_free()
	_rendered_cards.clear()

	if thread_data == null:
		push_error("KubuchanSite requires thread_data.")
		return
	if post_card_scene == null:
		push_error("KubuchanSite requires post_card_scene.")
		return

	for error: String in thread_data.validate_data():
		push_error("Kubuchan thread: %s" % error)

	board_code_label.text = thread_data.board_code
	board_name_label.text = thread_data.board_name
	board_tagline_label.text = thread_data.board_tagline
	thread_title_label.text = thread_data.thread_title
	thread_id_label.text = "Thread No.%d" % thread_data.thread_id
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
		_rendered_cards.append(card)


func _play_initial_reveal() -> void:
	if not is_inside_tree():
		return

	brand_block.modulate.a = 0.0
	var header_tween := create_tween()
	header_tween.set_trans(Tween.TRANS_QUAD)
	header_tween.set_ease(Tween.EASE_OUT)
	header_tween.tween_property(brand_block, "modulate:a", 1.0, 0.2)

	for index in range(_rendered_cards.size()):
		var card: KubuchanPostCard = _rendered_cards[index]
		if not is_instance_valid(card):
			continue

		card.modulate.a = 0.0
		var delay: float = float(index) * post_stagger_seconds
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, post_reveal_seconds).set_delay(delay)


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
