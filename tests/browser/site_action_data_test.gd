extends Node

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	const REQUIRED_FLAG := "test.site_action.allowed"
	const EFFECT_FLAG := "test.site_action.effect_applied"
	GameState.set_flag(REQUIRED_FLAG, false)
	GameState.set_flag(EFFECT_FLAG, false)

	var condition := FlagConditionData.new()
	condition.flag_name = REQUIRED_FLAG
	condition.expected_value = true

	var effect := SetFlagEffectData.new()
	effect.effect_id = "test.site_action.set_effect_flag"
	effect.flag_name = EFFECT_FLAG
	effect.value = true

	var action := SiteActionData.new()
	action.conditions = condition
	var effects: Array[GameEffectData] = [effect]
	action.effects = effects
	action.target_url = "test.local/next"

	_check(action.validate_data().is_empty(), "SiteActionData rejected a valid shared condition/effect setup.")
	_check(not action.is_available(GameEffectContext.create("test")), "SiteActionData ignored its FlagConditionData gate.")

	var button := SiteActionButton.new()
	button.action_data = action
	add_child(button)
	await get_tree().process_frame

	var navigation := {"url": ""}
	button.browser_navigation_requested.connect(
		func(url: String) -> void: navigation["url"] = url
	)

	button.pressed.emit()
	await get_tree().process_frame
	_check(str(navigation["url"]).is_empty(), "Blocked site action navigated despite a failed condition.")
	_check(not GameState.get_flag(EFFECT_FLAG), "Blocked site action applied gameplay effects.")

	GameState.set_flag(REQUIRED_FLAG, true)
	button.refresh_action_state()
	button.pressed.emit()
	await get_tree().process_frame
	_check(GameState.get_flag(EFFECT_FLAG), "Available site action did not reuse GameEffectData.")
	_check(navigation["url"] == "test.local/next", "Available site action did not emit its authored Browser route.")

	button.queue_free()
	await get_tree().process_frame
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("SITE_ACTION_DATA_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("SITE_ACTION_DATA_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
