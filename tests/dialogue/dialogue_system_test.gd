extends Node


const MAIN_SCENE: PackedScene = preload("res://core/main.tscn")
const EVENT_ID: String = "story.prologue.null_network_welcome"
const DIALOGUE_ID: String = "dialogue.prologue.null_network_welcome"
const DIALOGUE_STEP_ID: String = "start_welcome_dialogue"

var _failures := PackedStringArray()
var _test_root: String
var _activity_confirmation_count: int = 0
var _confirmed_activity_cost: int = -1


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/dialogue_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	_connect_confirmation_observer()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"dialogue_gate",
		CampaignState.SaveMode.SAFE,
		"Dialogue Gate"
	)
	_check(create_errors.is_empty(), "Campaign creation failed: %s" % create_errors)

	var first_main: Node = MAIN_SCENE.instantiate()
	add_child(first_main)
	await _wait_frames(6)
	GameState.set_flag("story.prologue.account_ready", true)
	await _wait_frames(30)

	_check(
		DialogueManager.active_dialogue_id == DIALOGUE_ID
		and DialogueManager.current_node_id == "intro",
		"StoryEvent did not start the cataloged dialogue at its initial node."
	)
	_check(
		CampaignState.active_story_event_id == EVENT_ID
		and CampaignState.active_story_event_step_id == DIALOGUE_STEP_ID
		and CampaignState.active_story_event_waiting,
		"Dialogue did not preserve the external StoryEvent boundary."
	)
	_check(
		GameState.get_number("dialogue.phase7.intro_entries") == 1,
		"Initial node effect did not execute exactly once."
	)
	_check_dialogue_player(first_main, "Initial DialoguePlayer")

	_check(DialogueManager.advance(), "Linear dialogue could not advance.")
	await _wait_frames(4)
	_check(
		DialogueManager.current_node_id == "decision",
		"Linear dialogue did not enter the decision node."
	)
	_check(
		DialogueManager.get_available_choices().size() == 4,
		"The locked conditional choice was not hidden."
	)

	_check(
		SaveManager.save_checkpoint(&"phase7.decision", true),
		"Could not save the dialogue at its decision node."
	)
	first_main.queue_free()
	await _wait_frames(6)

	var load_errors: PackedStringArray = SaveManager.load_campaign("dialogue_gate")
	_check(load_errors.is_empty(), "Decision-node reload failed: %s" % load_errors)
	var second_main: Node = MAIN_SCENE.instantiate()
	add_child(second_main)
	await _wait_frames(14)

	_check(
		DialogueManager.active_dialogue_id == DIALOGUE_ID
		and DialogueManager.current_node_id == "decision",
		"Reload did not restore the exact dialogue node."
	)
	_check(
		GameState.get_number("dialogue.phase7.intro_entries") == 1,
		"Reload reapplied an already executed node effect."
	)
	_check(
		DialogueManager.executed_node_effects.has(
			"intro::dialogue.prologue.count_intro_entry"
		),
		"Executed node-effect IDs were not restored."
	)
	_check_dialogue_player(second_main, "Reloaded DialoguePlayer")

	GameState.set_flag("dialogue.phase7.special_unlocked", true)
	await _wait_frames(3)
	_check(
		DialogueManager.get_available_choices().size() == 5,
		"Changing authoritative state did not reveal the conditional choice."
	)

	var initial_action_index: int = TimeManager.get_total_action_index()
	_check(
		DialogueManager.select_choice("logic_paid"),
		"Paid dialogue choice was rejected before ActivityManager."
	)
	await _wait_frames(14)

	_check(
		_activity_confirmation_count == 1 and _confirmed_activity_cost == 1,
		"Paid choice did not expose one transparent one-block confirmation."
	)
	_check(
		TimeManager.get_total_action_index() == initial_action_index + 1,
		"Paid choice did not charge exactly one action."
	)
	_check(
		DialogueManager.current_node_id == "outro",
		"Confirmed paid choice did not enter its target node."
	)
	_check(
		CampaignState.tendencies.logic == 2
		and GameState.get_flag("dialogue.phase7.logic_selected"),
		"Choice effects and tendency changes were not applied by the service."
	)
	_check(
		DialogueManager.selected_choices.has("decision::logic_paid"),
		"Selected choice was not recorded by stable node and choice IDs."
	)

	_check(
		SaveManager.save_checkpoint(&"phase7.outro", true),
		"Could not save after resolving the paid choice."
	)
	second_main.queue_free()
	await _wait_frames(6)
	load_errors = SaveManager.load_campaign("dialogue_gate")
	_check(load_errors.is_empty(), "Post-choice reload failed: %s" % load_errors)
	var third_main: Node = MAIN_SCENE.instantiate()
	add_child(third_main)
	await _wait_frames(14)

	_check(
		DialogueManager.current_node_id == "outro"
		and DialogueManager.selected_choices.has("decision::logic_paid"),
		"Choice history and target node did not survive reload."
	)
	_check(
		CampaignState.tendencies.logic == 2
		and TimeManager.get_total_action_index() == initial_action_index + 1,
		"Reload duplicated the paid choice cost or tendency change."
	)
	_check_dialogue_player(third_main, "Post-choice DialoguePlayer")

	_check(DialogueManager.advance(), "Final linear node could not complete.")
	await _wait_frames(30)
	_check(
		not DialogueManager.is_dialogue_active(),
		"Dialogue session did not clear after its final node."
	)
	_check(
		CampaignState.has_completed_story_event(EVENT_ID)
		and GameState.get_flag("story.prologue.welcome_sequence_applied")
		and GameState.get_flag("story.prologue.welcome_complete"),
		"Dialogue completion did not acknowledge and resume the StoryEvent."
	)

	third_main.queue_free()
	await _wait_frames(4)
	_finish_test()


func _connect_confirmation_observer() -> void:
	if not GlobalSignals.activity_confirmation_requested.is_connected(
		_on_activity_confirmation_requested
	):
		GlobalSignals.activity_confirmation_requested.connect(
			_on_activity_confirmation_requested
		)


func _on_activity_confirmation_requested(
	request_id: String,
	definition: ActivityDefinitionData,
	preview: ActivityPreviewData,
	source_id: String
) -> void:
	if source_id != "dialogue.%s" % DIALOGUE_ID:
		return

	_activity_confirmation_count += 1
	_confirmed_activity_cost = preview.charged_action_cost
	_check(
		definition != null
		and definition.get_display_id() == "dialogue.prologue.consider_signal",
		"Paid choice requested the wrong ActivityDefinitionData."
	)
	call_deferred("_confirm_activity", request_id)


func _confirm_activity(request_id: String) -> void:
	GlobalSignals.activity_confirmation_resolved.emit(request_id, true)


func _check_dialogue_player(main: Node, label: String) -> void:
	var player := main.find_child("DialoguePlayer", true, false) as DialoguePlayer
	_check(player != null, "%s was not instantiated inside Navigator." % label)

	if player == null:
		return

	_check(player.visible, "%s is not visible in DIALOGUE mode." % label)
	_check(
		player.get_visible_portrait_count() == 6,
		"%s did not render all six GDD portrait slots." % label
	)


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("DIALOGUE_SYSTEM_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("DIALOGUE_SYSTEM_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _remove_directory_recursive(path: String) -> void:
	var directory := DirAccess.open(path)

	if directory == null:
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()

	while not entry.is_empty():
		var child_path: String = "%s/%s" % [path, entry]

		if directory.current_is_dir():
			_remove_directory_recursive(child_path)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child_path))

		entry = directory.get_next()

	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
