extends Node


const KUBUCHAN_SCENE: PackedScene = preload(
	"res://apps/browser/sites/kubuchan/kubuchan.tscn"
)
const THREAD_DATA: KubuchanThreadData = preload(
	"res://apps/browser/sites/kubuchan/kubuchan_thread.tres"
)

var _failures := PackedStringArray()
var _navigated_url: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_check(THREAD_DATA.posts.size() >= 10, "Kubuchan prologue thread lost its authored conversation.")

	var human_uids := {}
	var spam_posts: Array[KubuchanPostData] = []
	var mentions_wewere: bool = false
	var mentions_missing_people: bool = false
	var mentions_scrapped_origin: bool = false

	for post: KubuchanPostData in THREAD_DATA.posts:
		if post == null:
			continue
		if post.is_system_spam:
			spam_posts.append(post)
		else:
			human_uids[post.uid] = true

		var lowered: String = post.body_text.to_lower()
		mentions_wewere = mentions_wewere or lowered.contains("wewere")
		mentions_missing_people = mentions_missing_people or lowered.contains("missing")
		mentions_scrapped_origin = (
			mentions_scrapped_origin
			or lowered.contains("cancelled")
			or lowered.contains("scrap")
		)

	_check(human_uids.size() == 6, "Kubuchan thread must keep six recurring human UIDs.")
	_check(spam_posts.size() == 1, "Kubuchan thread must contain exactly one Null Network system spam post.")
	if spam_posts.size() == 1:
		_check(spam_posts[0].link_url == "null.net", "System spam must route only to null.net.")
		_check(
			not spam_posts[0].body_text.to_lower().contains("admin"),
			"System spam itself must not explain that users think it is an admin bot."
		)

	_check(mentions_wewere, "Human posters must surface the WEWERE rumor.")
	_check(mentions_missing_people, "Human posters must surface the recent disappearances rumor.")
	_check(mentions_scrapped_origin, "Human posters must discuss the patched/scrapped Kubu project origin.")

	var site := KUBUCHAN_SCENE.instantiate() as KubuchanSite
	_check(site != null, "Kubuchan scene failed to instantiate as KubuchanSite.")

	if site != null:
		add_child(site)
		if not site.browser_navigation_requested.is_connected(_on_navigation_requested):
			site.browser_navigation_requested.connect(_on_navigation_requested)
		await get_tree().process_frame

		var visible_buttons: Array[Button] = []
		for node: Node in site.find_children("*", "Button", true, false):
			var button := node as Button
			if button != null and button.visible and not button.disabled:
				visible_buttons.append(button)

		_check(
			visible_buttons.size() == 1,
			"Kubuchan must expose exactly one clickable button in the prologue thread."
		)

		if visible_buttons.size() == 1:
			visible_buttons[0].pressed.emit()
			_check(_navigated_url == "null.net", "Kubuchan's only interaction did not navigate to null.net.")

		site.queue_free()

	_finish_test()


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
