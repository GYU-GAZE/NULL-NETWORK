extends Control
class_name KubuchanSite

signal browser_navigation_requested(url: String)

@export var thread_data: KubuchanThreadData
@export var post_card_scene: PackedScene

@export_category("Thread Navigation")
@export_range(0, 320, 1) var quote_scroll_offset: int = 72
@export_range(0.05, 0.6, 0.01) var quote_scroll_seconds: float = 0.22

@onready var board_title_label: Label = %BoardTitleLabel
@onready var board_tagline_label: Label = %BoardTaglineLabel
@onready var page_scroll: ScrollContainer = %PageScroll
@onready var thread_vbox: VBoxContainer = %ThreadVBox
@onready var archived_notice_label: Label = %ArchivedNoticeLabel

var _post_anchor_map: Dictionary = {}
var _scroll_tween: Tween

func _ready() -> void:
	_render_thread()

func _render_thread() -> void:
	for child in thread_vbox.get_children():
		child.queue_free()

	_post_anchor_map.clear()

	if thread_data == null:
		push_error("KubuchanSite requires thread_data.")
		return

	if post_card_scene == null:
		push_error("KubuchanSite requires post_card_scene.")
		return

	for error: String in thread_data.validate_data():
		push_error("Kubuchan thread: %s" % error)

	board_title_label.text = "%s - %s" % [thread_data.board_code, thread_data.board_name]
	board_tagline_label.text = thread_data.board_tagline
	archived_notice_label.text = thread_data.archived_notice
	archived_notice_label.visible = not thread_data.archived_notice.strip_edges().is_empty()

	var runtime_timestamps: Array[String] = _build_runtime_timestamps(thread_data.posts.size())

	for index in range(thread_data.posts.size()):
		var post_data := thread_data.posts[index] as KubuchanPostData
		if post_data == null:
			continue

		var card := post_card_scene.instantiate() as KubuchanPostCard
		if card == null:
			push_error("Kubuchan post_card_scene must instantiate KubuchanPostCard.")
			continue

		thread_vbox.add_child(card)
		var timestamp := runtime_timestamps[index] if index < runtime_timestamps.size() else post_data.timestamp
		card.configure(post_data, timestamp)
		card.link_requested.connect(_on_link_requested)
		card.local_reference_requested.connect(_on_local_reference_requested)
		_post_anchor_map[str(post_data.post_number)] = card

func _build_runtime_timestamps(post_count: int) -> Array[String]:
	var timestamps: Array[String] = []
	if post_count <= 0:
		return timestamps

	var current_hour: int = TimeManager.get_action_block_hour(
		TimeManager.current_period,
		TimeManager.current_action_block
	)
	var rng := RandomNumberGenerator.new()
	var seed_text := "%d:%d:%d:%d:%d" % [
		thread_data.thread_id,
		TimeManager.days_passed,
		TimeManager.current_period,
		TimeManager.current_action_block,
		post_count
	]
	rng.seed = seed_text.hash()

	var anchor_minutes: int = (current_hour * 60) + rng.randi_range(20, 59)
	var gap_count: int = maxi(1, post_count - 1)
	var available_gap: int = int(anchor_minutes / gap_count)
	var maximum_gap: int = maxi(1, mini(8, available_gap))
	var post_minutes: Array[int] = []
	post_minutes.resize(post_count)
	var cursor_minutes: int = anchor_minutes

	for index in range(post_count - 1, -1, -1):
		post_minutes[index] = cursor_minutes
		if index > 0:
			cursor_minutes = maxi(0, cursor_minutes - rng.randi_range(1, maximum_gap))

	var weekday: String = TimeManager.get_current_weekday_name().to_lower().capitalize()
	var year_short: int = posmod(TimeManager.current_year, 100)
	var month: int = TimeManager.current_month_index + 1
	var day: int = TimeManager.current_calendar_day

	for minutes_since_midnight: int in post_minutes:
		var hour: int = int(minutes_since_midnight / 60)
		var minute: int = minutes_since_midnight % 60
		var second: int = rng.randi_range(0, 59)
		timestamps.append(
			"%02d/%02d/%02d(%s)%02d:%02d:%02d" % [
				month,
				day,
				year_short,
				weekday,
				hour,
				minute,
				second
			]
		)

	return timestamps

func _on_local_reference_requested(reference: String) -> void:
	var clean_reference := reference.strip_edges()
	if clean_reference.begins_with("post:"):
		var post_number := clean_reference.trim_prefix("post:")
		var target := _post_anchor_map.get(post_number) as Control
		if target != null:
			_scroll_to_control(target)
		return

	if clean_reference.begins_with("scroll_y:"):
		_scroll_to_y(int(clean_reference.trim_prefix("scroll_y:")))

func _scroll_to_control(target: Control) -> void:
	var relative_y: float = (
		target.get_global_rect().position.y
		- page_scroll.get_global_rect().position.y
		+ float(page_scroll.scroll_vertical)
	)
	_scroll_to_y(int(relative_y) - quote_scroll_offset)

func _scroll_to_y(target_y: int) -> void:
	var vertical_bar := page_scroll.get_v_scroll_bar()
	var maximum_scroll: int = maxi(0, int(vertical_bar.max_value - page_scroll.size.y))
	var clamped_target: int = clampi(target_y, 0, maximum_scroll)

	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()

	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_CUBIC)
	_scroll_tween.set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_property(page_scroll, "scroll_vertical", clamped_target, quote_scroll_seconds)

func _on_link_requested(url: String) -> void:
	var clean_url: String = url.strip_edges()
	if not clean_url.is_empty():
		browser_navigation_requested.emit(clean_url)

func get_browser_state() -> Dictionary:
	return {"scroll_y": page_scroll.scroll_vertical}

func restore_browser_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	var restored_scroll: int = maxi(0, int(state.get("scroll_y", 0)))
	page_scroll.set_deferred("scroll_vertical", restored_scroll)
