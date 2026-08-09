extends Node


const BROWSER_SCENE: PackedScene = preload(
	"res://apps/browser/app_browser.tscn"
)

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var browser := BROWSER_SCENE.instantiate() as BrowserApp
	_check(browser != null, "Browser scene failed to instantiate.")

	if browser != null:
		add_child(browser)
		browser.size = Vector2(900, 600)
		await get_tree().process_frame

		browser._load_page("kubuchan.net")
		await get_tree().process_frame

		_check(
			browser.site_container.get_child_count() == 1,
			"Kubuchan did not render into Browser SiteContainer."
		)

		var page: Control = null
		if browser.site_container.get_child_count() > 0:
			page = browser.site_container.get_child(0) as Control

		_check(page != null, "Rendered Kubuchan root is not a Control.")

		if page != null:
			_check(
				is_equal_approx(page.anchor_left, 0.0)
				and is_equal_approx(page.anchor_top, 0.0)
				and is_equal_approx(page.anchor_right, 1.0)
				and is_equal_approx(page.anchor_bottom, 1.0),
				"Website root is not anchored to the full Browser viewport."
			)
			_check(
				page.custom_minimum_size == Vector2.ZERO,
				"Website root retained the legacy fixed 600x320 minimum canvas."
			)
			_check(
				page.size_flags_horizontal == Control.SIZE_EXPAND_FILL
				and page.size_flags_vertical == Control.SIZE_EXPAND_FILL,
				"Website root does not expand with Browser content area."
			)

		browser.queue_free()

	await get_tree().process_frame
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("BROWSER_RESPONSIVE_SITE_LAYOUT_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"BROWSER_RESPONSIVE_SITE_LAYOUT_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)
