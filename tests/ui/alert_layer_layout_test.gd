extends Control

const BROWSER_SCENE: PackedScene = preload("res://apps/browser/app_browser.tscn")

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var browser := BROWSER_SCENE.instantiate() as BrowserApp
	_check(browser != null, "Browser scene failed to instantiate for AlertLayer test.")
	if browser == null:
		_finish_test()
		return

	browser.set_anchors_preset(Control.PRESET_TOP_LEFT)
	browser.size = Vector2(600, 400)
	add_child(browser)
	await _wait_frames(3)

	var layer := browser.find_child("AlertLayer", true, false) as AlertLayer
	_check(layer != null, "Browser lost its AlertLayer.")
	if layer == null:
		browser.queue_free()
		_finish_test()
		return

	await layer.show_alert(
		"ACCOUNT REQUIRED",
		"You must have an account to access this area.",
		UniversalAlerts.AlertAnimation.NONE
	)
	await _wait_frames(2)
	_check_alert_is_centered(layer, "default browser size")

	await layer.close_alert()
	browser.size = Vector2(420, 280)
	await _wait_frames(3)
	await layer.show_alert(
		"ACCOUNT REQUIRED",
		"You must have an account to access this area.",
		UniversalAlerts.AlertAnimation.NONE
	)
	await _wait_frames(2)
	_check_alert_is_centered(layer, "resized browser")

	browser.queue_free()
	await _wait_frames(2)
	_finish_test()


func _check_alert_is_centered(layer: AlertLayer, phase: String) -> void:
	var box := layer.current_box
	_check(box != null and is_instance_valid(box), "%s: AlertBox was not created." % phase)
	if box == null or not is_instance_valid(box):
		return

	var expected_center := layer.get_global_rect().get_center()
	var actual_center := box.get_global_rect().get_center()
	_check(
		actual_center.distance_to(expected_center) <= 1.0,
		"%s: AlertBox center %s diverged from AlertLayer center %s." % [
			phase,
			actual_center,
			expected_center,
		]
	)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("ALERT_LAYER_LAYOUT_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("ALERT_LAYER_LAYOUT_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
