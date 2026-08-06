extends Node


const DIALOGUE_SCENE: PackedScene = preload(
	"res://apps/navigator/dialogue/dialogue_player.tscn"
)
const SHOWCASE_DIALOGUE_ID: String = (
	"dialogue.prologue.null_network_welcome"
)


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_check(
		catalog_errors.is_empty(),
		"Default catalog failed: %s" % catalog_errors
	)

	DialogueManager.reset_save_data()
	CampaignState.reset_campaign()
	_check(
		CampaignState.create_campaign(
			"dialogue_player_layout_input",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Could not create the dialogue fixture campaign."
	)
	GameState.set_flag(
		"dialogue.phase7.special_unlocked",
		true
	)

	var player := DIALOGUE_SCENE.instantiate() as DialoguePlayer
	_check(
		player != null,
		"DialoguePlayer scene did not instantiate."
	)

	if player == null:
		_finish_test()
		return

	add_child(player)
	player.size = Vector2(640.0, 377.0)
	await get_tree().process_frame
	GlobalSignals.workspace_activated.emit("navigator")
	_check(
		DialogueManager.start_dialogue(
			SHOWCASE_DIALOGUE_ID
		),
		"Showcase dialogue failed to start."
	)
	await get_tree().process_frame
	await get_tree().process_frame

	var panel := player.get_node_or_null(
		"DialoguePanel"
	) as PanelContainer
	_check(
		panel != null \
		and is_equal_approx(panel.size.y, 148.0),
		"Dialogue panel did not preserve its fixed 148 px height."
	)
	_check(
		player.get_node_or_null(
			"DialoguePanel/Margin/Content/AdvanceButton"
		) == null,
		"Legacy ADVANCE button still exists."
	)
	_check(
		not player.dialogue_text.fit_content \
		and player.dialogue_text.scroll_active,
		"Dialogue text is not constrained to a scrollable region."
	)
	_check(
		player.dialogue_text.text.count("\n") + 1 == 6,
		"Showcase intro no longer demonstrates six text lines."
	)

	GlobalSignals.app_focused.emit("browser")
	_check(
		not player.try_advance_from_navigator_input() \
		and DialogueManager.current_node_id == "intro",
		"Browser focus did not block Navigator dialogue advancement."
	)

	GlobalSignals.app_focused.emit("")
	_check(
		player.try_advance_from_navigator_input(),
		"Navigator-owned input did not advance a choice-free node."
	)
	await get_tree().process_frame
	await get_tree().process_frame

	_check(
		DialogueManager.current_node_id == "decision" \
		and player.get_rendered_choice_ids().size() == 5,
		"Decision node did not render its complete choice set."
	)
	_check(
		panel != null \
		and is_equal_approx(panel.size.y, 148.0),
		"Choices changed the fixed dialogue panel height."
	)
	_check(
		player.is_text_scroll_visible(),
		"Choice overflow did not move the main text into scrolling."
	)
	_check(
		not player.try_advance_from_navigator_input() \
		and DialogueManager.current_node_id == "decision",
		"A node with choices advanced without a selection."
	)

	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	DialogueManager.reset_save_data()
	CampaignState.reset_campaign()

	if _failures.is_empty():
		print("DIALOGUE_PLAYER_LAYOUT_INPUT_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"DIALOGUE_PLAYER_LAYOUT_INPUT_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)
