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
		and is_equal_approx(panel.size.y, 126.0),
		"Dialogue panel did not preserve its fixed 126 px height."
	)
	_check(
		player.get_node_or_null(
			"DialoguePanel/Margin/Content/AdvanceButton"
		) == null,
		"Legacy ADVANCE button still exists."
	)
	_check(
		player.speaker_label.get_theme_font_size(
			"font_size"
		) == 14 \
		and player.dialogue_text.get_theme_font_size(
			"normal_font_size"
		) == 14,
		"Dialogue typography is not locked to the native 14 px Silver grid."
	)
	_check(
		not player.dialogue_text.fit_content \
		and player.dialogue_text.scroll_active,
		"Dialogue text is not constrained to a scrollable region."
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
		"Navigator-owned input did not complete the active typewriter."
	)
	_check(
		DialogueManager.current_node_id == "intro",
		"Completing the typewriter also advanced the dialogue node."
	)
	await get_tree().process_frame
	_check(
		player.try_advance_from_navigator_input(),
		"Second Navigator input did not advance the revealed node."
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
		and is_equal_approx(panel.size.y, 126.0),
		"Choices changed the fixed dialogue panel height."
	)
	_check(
		player.get_choice_column_count() == 2,
		"Large choice sets did not compact into two columns."
	)
	_check(
		player.choice_container.get_theme_constant(
			"h_separation"
		) == 0 \
		and player.choice_container.get_theme_constant(
			"v_separation"
		) == 0,
		"Choice separators were not removed."
	)
	_check(
		player.try_advance_from_navigator_input(),
		"Navigator input did not complete the decision prompt typewriter."
	)
	await get_tree().process_frame
	_check(
		player.is_text_scroll_visible(),
		"Choice overflow did not move the main text into scrolling."
	)

	var first_choice := (
		player.choice_container.get_child(0) as Button
		if player.choice_container.get_child_count() > 0
		else null
	)
	var first_choice_style := (
		first_choice.get_theme_stylebox("normal") as StyleBoxFlat
		if first_choice != null
		else null
	)
	_check(
		first_choice != null \
		and first_choice.get_theme_font_size("font_size") == 14 \
		and is_equal_approx(
			first_choice.custom_minimum_size.y,
			21.0
		) \
		and first_choice_style != null \
		and first_choice_style.border_width_left == 1 \
		and first_choice_style.border_width_top == 1 \
		and first_choice_style.border_width_right == 1 \
		and first_choice_style.border_width_bottom == 1,
		"Choice buttons do not use the native 14 px / 1 px-border specification."
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
