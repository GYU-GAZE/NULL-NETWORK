extends Node

const BROWSER_SCENE: PackedScene = preload("res://apps/browser/app_browser.tscn")

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var browser := BROWSER_SCENE.instantiate() as BrowserApp
	_check(browser != null, "Browser scene failed to instantiate.")
	if browser == null:
		_finish_test()
		return

	browser.set_anchors_preset(Control.PRESET_TOP_LEFT)
	browser.size = Vector2(600, 400)
	add_child(browser)
	await get_tree().create_timer(0.30).timeout
	_check_tab_order(browser, 1, "initial tab")

	browser._create_tab("kubus://home")
	await get_tree().create_timer(0.30).timeout
	_check_tab_order(browser, 2, "second tab")

	browser._create_tab("kubus://home")
	await get_tree().create_timer(0.30).timeout
	_check_tab_order(browser, 3, "third tab")

	await browser._close_tab(1)
	await get_tree().create_timer(0.12).timeout
	_check_tab_order(browser, 2, "middle tab closed")

	browser.queue_free()
	await get_tree().process_frame
	_finish_test()


func _check_tab_order(browser: BrowserApp, expected_count: int, phase: String) -> void:
	var container := browser.tab_button_container
	_check(
		container.get_child_count() == expected_count,
		"%s: expected %d tab buttons, got %d." % [
			phase,
			expected_count,
			container.get_child_count(),
		]
	)
	if container.get_child_count() != expected_count:
		return

	var previous_right := -INF
	for index in range(container.get_child_count()):
		var tab := container.get_child(index) as BrowserTabButton
		_check(tab != null, "%s: child %d is not BrowserTabButton." % [phase, index])
		if tab == null:
			continue
		var rect := tab.get_rect()
		_check(
			rect.position.x >= previous_right - 0.5,
			"%s: tab %d overlaps or moved before the previous tab (x=%.1f, previous_right=%.1f)." % [
				phase,
				index,
				rect.position.x,
				previous_right,
			]
		)
		previous_right = rect.end.x


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("BROWSER_TAB_ORDER_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("BROWSER_TAB_ORDER_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
