extends Node


const KUBUCHAN_SCENE: PackedScene = preload(
	"res://apps/browser/sites/kubuchan/kubuchan.tscn"
)
const THREAD_DATA: KubuchanThreadData = preload(
	"res://apps/browser/sites/kubuchan/kubuchan_thread.tres"
)
const SILVER_BASE_SIZE: int = 19

var _failures := PackedStringArray()
var _navigated_url: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_check(THREAD_DATA.posts.size() >= 10, "Kubuchan prologue thread lost its authored conversation.")

	var human_uids := {}
	var spam_posts: Array[KubuchanPostData] = []
	var human_mentions_wewere: bool = false
	var human_mentions_missing_people: bool = false
	var human_mentions_scrapped_origin: bool = false
	var human_calls_it_admin_bot: bool = false

	for post: KubuchanPostData in THREAD_DATA.posts:
		if post == null:
			continue

		var lowered: String = post.body_text.to_lower()

		if post.is_system_spam:
			spam_posts.append(post)
			continue

		human_uids[post.uid] = true
		human_mentions_wewere = human_mentions_wewere or lowered.contains("wewere")
		human_mentions_missing_people = human_mentions_missing_people or lowered.contains("missing")
		human_mentions_scrapped_origin = (
			human_mentions_scrapped_origin
			or lowered.contains("cancelled")
			or lowered.contains("scrap")
		)
		human_calls_it_admin_bot = (
			human_calls_it_admin_bot
			or (lowered.contains("admin") and lowered.contains("bot"))
		)

	_check(human_uids.size() == 6, "Kubuchan thread must keep six recurring human UIDs.")
	_check(spam_posts.size() == 1, "Kubuchan thread must contain exactly one Null Network system spam post.")

	if spam_posts.size() == 1:
		_check(spam_posts[0].link_url == "null.net", "System spam must route only to null.net.")
		_check(
			not spam_posts[0].body_text.to_lower().contains("admin")
			and not spam_posts[0].body_text.to_lower().contains("wewere")
			and not spam_posts[0].body_text.to_lower().contains("missing"),
			"System spam must remain an ambiguous lure; human posters own the Null Network rumors."
		)

	_check(human_mentions_wewere, "Human posters must surface the WEWERE rumor.")
	_check(human_mentions_missing_people, "Human posters must surface the recent disappearances rumor.")
	_check(human_mentions_scrapped_origin, "Human posters must discuss the patched/scrapped Kubu project origin.")
	_check(human_calls_it_admin_bot, "Human posters must explain the public assumption that the spammer is an admin bot.")

	var site := KUBUCHAN_SCENE.instantiate() as KubuchanSite
	_check(site != null, "Kubuchan scene failed to instantiate as KubuchanSite.")

	if site != null:
		add_child(site)

		if not site.browser_navigation_requested.is_connected(_on_navigation_requested):
			site.browser_navigation_requested.connect(_on_navigation_requested)

		await get_tree().process_frame
		await get_tree().process_frame

		_check(
			site.theme != null and site.theme.default_font_size == SILVER_BASE_SIZE,
			"Kubuchan must use Silver on its native 19 px grid."
		)

		var board_title := site.find_child("BoardTitleLabel", true, false) as Label
		_check(board_title != null, "Kubuchan lost its centered imageboard title.")

		if board_title != null:
			_check(
				board_title.get_theme_font_size(&"font_size") == SILVER_BASE_SIZE * 2,
				"Kubuchan board title must use a clean 38 px Silver multiple."
			)
			_check(
				board_title.get_theme_color(&"font_shadow_color").a == 0.0,
				"Kubuchan's light theme must not inherit the dark KubuOS Silver shadow."
			)

		_check(
			site.find_child("PostReplyLabel", true, false) != null,
			"Kubuchan must retain the classic centered [Post a Reply] imageboard affordance."
		)
		_check(
			site.find_child("ThreadBar", true, false) == null,
			"Kubuchan must not regress to a forum-style separate thread title bar."
		)

		var cards: Array[KubuchanPostCard] = []
		_collect_cards(site, cards)
		_check(cards.size() == THREAD_DATA.posts.size(), "Kubuchan did not render every authored post.")

		if cards.size() >= 2:
			var op_panel := cards[0].find_child("PostPanel", true, false) as PanelContainer
			var reply_panel := cards[1].find_child("PostPanel", true, false) as PanelContainer
			var reply_indent := cards[1].find_child("Indent", true, false) as Control
			var op_style := (
				op_panel.get_theme_stylebox(&"panel") as StyleBoxFlat
				if op_panel != null
				else null
			)
			var reply_style := (
				reply_panel.get_theme_stylebox(&"panel") as StyleBoxFlat
				if reply_panel != null
				else null
			)

			_check(
				op_style != null and op_style.bg_color.a == 0.0,
				"Classic imageboard OP must sit directly on the page instead of inside a forum card."
			)
			_check(
				reply_style != null and reply_style.bg_color.a > 0.0,
				"Imageboard replies must use compact tinted reply boxes."
			)
			_check(
				reply_indent != null and reply_indent.custom_minimum_size.x > 0.0,
				"Imageboard replies must be indented relative to the OP."
			)

		var visible_clickables: Array[BaseButton] = []
		_collect_visible_clickables(site, visible_clickables)

		_check(
			visible_clickables.size() == 1,
			"Kubuchan must expose exactly one clickable control in the prologue thread."
		)

		if visible_clickables.size() == 1:
			_check(
				visible_clickables[0] is LinkButton,
				"Kubuchan's only interaction must look like a normal imageboard hyperlink."
			)
			visible_clickables[0].pressed.emit()
			_check(_navigated_url == "null.net", "Kubuchan's only interaction did not navigate to null.net.")

		site.queue_free()

	_finish_test()


func _collect_cards(root: Node, output: Array[KubuchanPostCard]) -> void:
	if root is KubuchanPostCard:
		output.append(root as KubuchanPostCard)

	for child: Node in root.get_children():
		_collect_cards(child, output)


func _collect_visible_clickables(root: Node, output: Array[BaseButton]) -> void:
	if root is BaseButton:
		var button := root as BaseButton
		if button.visible and not button.disabled:
			output.append(button)

	for child: Node in root.get_children():
		_collect_visible_clickables(child, output)


func _on_navigation_requested(url: String) -> void:
	_navigated_url = url


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("KUBUCHAN_THREAD_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("KUBUCHAN_THREAD_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
