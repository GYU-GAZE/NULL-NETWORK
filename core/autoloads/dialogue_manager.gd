extends Node


signal dialogue_started(dialogue_id: String, node_id: String)
signal dialogue_resumed(dialogue_id: String, node_id: String)
signal node_changed(dialogue_id: String, node_id: String)
signal choice_resolution_started(dialogue_id: String, node_id: String, choice_id: String)
signal choice_resolution_cancelled(dialogue_id: String, choice_id: String, reason: String)
signal dialogue_completed(dialogue_id: String)
signal dialogue_failed(dialogue_id: String, node_id: String, reason: String)


const SAVE_DATA_VERSION: int = 1
const SOURCE_PREFIX: String = "dialogue"
const NAVIGATOR_APP_ID: String = "navigator"

var active_dialogue_id: String = ""
var current_node_id: String = ""
var executed_node_effects: PackedStringArray = PackedStringArray()
var selected_choices: PackedStringArray = PackedStringArray()
var source_story_event_id: String = ""
var source_story_step_id: String = ""

var _pending_activity_request_id: String = ""
var _pending_choice_id: String = ""
var _is_resolving: bool = false


func _ready() -> void:
	_connect_signals()

	var registration_errors := SaveManager.register_save_section(self)

	for error: String in registration_errors:
		push_error("DialogueManager save registration: %s" % error)


func _connect_signals() -> void:
	if not GlobalSignals.request_story_dialogue.is_connected(
		_on_story_dialogue_requested
	):
		GlobalSignals.request_story_dialogue.connect(
			_on_story_dialogue_requested
		)

	if not ActivityManager.activity_started.is_connected(_on_activity_started):
		ActivityManager.activity_started.connect(_on_activity_started)

	if not ActivityManager.activity_rejected.is_connected(_on_activity_rejected):
		ActivityManager.activity_rejected.connect(_on_activity_rejected)

	if not ActivityManager.activity_cancelled.is_connected(_on_activity_cancelled):
		ActivityManager.activity_cancelled.connect(_on_activity_cancelled)

	if not CampaignState.campaign_reset.is_connected(_on_campaign_reset):
		CampaignState.campaign_reset.connect(_on_campaign_reset)

	if not SaveManager.campaign_loaded.is_connected(_on_campaign_loaded):
		SaveManager.campaign_loaded.connect(_on_campaign_loaded)


func get_save_section_id() -> String:
	return str(SaveConstants.SECTION_DIALOGUE_SESSION)


func export_save_data() -> Dictionary:
	return {
		"version": SAVE_DATA_VERSION,
		"dialogue_id": active_dialogue_id,
		"current_node_id": current_node_id,
		"executed_node_effects": _string_array_to_array(executed_node_effects),
		"selected_choices": _string_array_to_array(selected_choices),
		"source_story_event_id": source_story_event_id,
		"source_story_step_id": source_story_step_id
	}


func import_save_data(data: Dictionary) -> void:
	var errors: PackedStringArray = validate_save_data(data)

	if not errors.is_empty():
		for error: String in errors:
			push_error("DialogueManager import: %s" % error)
		return

	_reset_runtime_only()
	active_dialogue_id = str(data.get("dialogue_id", "")).strip_edges()
	current_node_id = str(data.get("current_node_id", "")).strip_edges()
	executed_node_effects = _read_id_array(data.get("executed_node_effects", []))
	selected_choices = _read_id_array(data.get("selected_choices", []))
	source_story_event_id = str(
		data.get("source_story_event_id", "")
	).strip_edges()
	source_story_step_id = str(
		data.get("source_story_step_id", "")
	).strip_edges()


func reset_save_data() -> void:
	var previous_dialogue_id: String = active_dialogue_id
	_clear_session()

	if not previous_dialogue_id.is_empty():
		dialogue_failed.emit(previous_dialogue_id, "", "Dialogue session reset.")


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if int(data.get("version", -1)) != SAVE_DATA_VERSION:
		errors.append("Unsupported DialogueManager save version.")

	var dialogue_id: String = str(data.get("dialogue_id", "")).strip_edges()
	var node_id: String = str(data.get("current_node_id", "")).strip_edges()
	var event_id: String = str(
		data.get("source_story_event_id", "")
	).strip_edges()
	var step_id: String = str(
		data.get("source_story_step_id", "")
	).strip_edges()

	if dialogue_id.is_empty() and not node_id.is_empty():
		errors.append("current_node_id requires an active dialogue_id.")

	if not dialogue_id.is_empty():
		if node_id.is_empty():
			errors.append("An active dialogue requires current_node_id.")
		else:
			var dialogue: DialogueData = ContentRegistry.get_dialogue(dialogue_id)

			if dialogue == null:
				errors.append("Active dialogue_id is not registered.")
			elif dialogue.get_node_data(node_id) == null:
				errors.append("current_node_id is not part of the active dialogue.")

	if event_id.is_empty() != step_id.is_empty():
		errors.append("StoryEvent dialogue source requires both event and step IDs.")

	_validate_id_array(errors, data.get("executed_node_effects", []), "executed_node_effects")
	_validate_id_array(errors, data.get("selected_choices", []), "selected_choices")
	return errors


func can_save_now() -> Variant:
	if _is_resolving:
		return "Dialogue is resolving a node or choice."

	return true


func is_dialogue_active() -> bool:
	return not active_dialogue_id.is_empty()


func get_active_dialogue() -> DialogueData:
	return ContentRegistry.get_dialogue(active_dialogue_id)


func get_current_node_data() -> DialogueNodeData:
	var dialogue: DialogueData = get_active_dialogue()

	if dialogue == null:
		return null

	return dialogue.get_node_data(current_node_id)


func get_current_speaker() -> DialogueSpeakerData:
	var dialogue: DialogueData = get_active_dialogue()
	var node: DialogueNodeData = get_current_node_data()

	if dialogue == null or node == null:
		return null

	return dialogue.get_speaker(node.speaker_id)


func get_available_choices() -> Array[DialogueChoiceData]:
	var result: Array[DialogueChoiceData] = []
	var node: DialogueNodeData = get_current_node_data()

	if node == null:
		return result

	var context: GameEffectContext = _create_context(
		"node.%s" % node.get_display_id()
	)

	for choice: DialogueChoiceData in node.choices:
		if choice != null and choice.is_available(context):
			result.append(choice)

	return result


func start_dialogue(
	dialogue_id: String,
	story_event_id: String = "",
	story_step_id: String = ""
) -> bool:
	var clean_dialogue_id: String = dialogue_id.strip_edges()
	var clean_event_id: String = story_event_id.strip_edges()
	var clean_step_id: String = story_step_id.strip_edges()

	if clean_event_id.is_empty() != clean_step_id.is_empty():
		return false

	if is_dialogue_active():
		return (
			active_dialogue_id == clean_dialogue_id
			and source_story_event_id == clean_event_id
			and source_story_step_id == clean_step_id
		)

	var dialogue: DialogueData = ContentRegistry.get_dialogue(clean_dialogue_id)

	if dialogue == null or not dialogue.validate_data().is_empty():
		return false

	active_dialogue_id = clean_dialogue_id
	source_story_event_id = clean_event_id
	source_story_step_id = clean_step_id
	executed_node_effects.clear()
	selected_choices.clear()
	_reset_runtime_only()

	var first_node_id: String = _resolve_available_node_id(
		dialogue.initial_node_id
	)

	if first_node_id.is_empty() or not _enter_node(first_node_id, true):
		var failed_dialogue_id: String = active_dialogue_id
		_clear_session()
		dialogue_failed.emit(
			failed_dialogue_id,
			first_node_id,
			"Dialogue has no available initial node."
		)
		return false

	_request_navigator_workspace()
	dialogue_started.emit(active_dialogue_id, current_node_id)
	return true


func advance() -> bool:
	if _is_resolving or not _pending_activity_request_id.is_empty():
		return false

	var node: DialogueNodeData = get_current_node_data()

	if node == null or not get_available_choices().is_empty():
		return false

	var next_node_id: String = _resolve_available_node_id(node.next_node_id)

	if next_node_id.is_empty():
		_finish_dialogue()
		return true

	return _enter_node(next_node_id, false)


func select_choice(choice_id: String) -> bool:
	if _is_resolving or not _pending_activity_request_id.is_empty():
		return false

	var node: DialogueNodeData = get_current_node_data()

	if node == null:
		return false

	var choice: DialogueChoiceData = node.get_choice(choice_id)
	var context: GameEffectContext = _create_context(
		"choice.%s" % choice_id.strip_edges()
	)

	if choice == null or not choice.is_available(context):
		return false

	var selection_key: String = _choice_key(node, choice)

	if selected_choices.has(selection_key):
		return false

	choice_resolution_started.emit(
		active_dialogue_id,
		current_node_id,
		choice.get_display_id()
	)

	if choice.activity_definition != null:
		_pending_choice_id = choice.get_display_id()
		_pending_activity_request_id = ActivityManager.request_activity(
			choice.activity_definition,
			_get_activity_source_id()
		)
		return not _pending_activity_request_id.is_empty()

	return _resolve_choice(choice, "", "")


func _enter_node(node_id: String, irreversible: bool) -> bool:
	var dialogue: DialogueData = get_active_dialogue()
	var node: DialogueNodeData = (
		dialogue.get_node_data(node_id) if dialogue != null else null
	)

	if node == null:
		return false

	_is_resolving = true
	current_node_id = node.get_display_id()

	if not _apply_node_enter_effects(node):
		_is_resolving = false
		dialogue_failed.emit(
			active_dialogue_id,
			current_node_id,
			"One or more node entry effects failed."
		)
		return false

	_is_resolving = false
	node_changed.emit(active_dialogue_id, current_node_id)
	SaveManager.request_checkpoint(
		StringName("dialogue.%s.node.%s" % [active_dialogue_id, current_node_id]),
		irreversible
	)
	return true


func _apply_node_enter_effects(node: DialogueNodeData) -> bool:
	var context: GameEffectContext = _create_context(
		"node.%s" % node.get_display_id()
	)

	for index: int in range(node.effects_on_enter.size()):
		var effect: GameEffectData = node.effects_on_enter[index]

		if effect == null:
			return false

		var effect_key: String = "%s::%s" % [
			node.get_display_id(),
			effect.effect_id.strip_edges()
		]

		if executed_node_effects.has(effect_key):
			continue

		executed_node_effects.append(effect_key)

		if not effect.apply(context):
			executed_node_effects.erase(effect_key)
			return false

	return true


func _resolve_choice(
	choice: DialogueChoiceData,
	transaction_id: String,
	activity_id: String
) -> bool:
	var node: DialogueNodeData = get_current_node_data()

	if node == null or choice == null:
		return false

	_is_resolving = true
	var selection_key: String = _choice_key(node, choice)
	selected_choices.append(selection_key)
	var context: GameEffectContext = _create_context(
		"choice.%s" % choice.get_display_id(),
		transaction_id
	)
	var failed_effects: PackedStringArray = GameEffectData.apply_all(
		choice.effects,
		context
	)

	if not failed_effects.is_empty():
		_is_resolving = false
		dialogue_failed.emit(
			active_dialogue_id,
			current_node_id,
			"Choice effects failed: %s" % failed_effects
		)
		return false

	for tendency_index: int in range(
		mini(choice.tendency_changes.size(), DialogueChoiceData.TENDENCY_COUNT)
	):
		var amount: int = choice.tendency_changes[tendency_index]

		if amount != 0:
			CampaignState.modify_tendency(tendency_index, amount)

	var next_node_id: String = _resolve_available_node_id(choice.next_node_id)
	_is_resolving = false

	if next_node_id.is_empty():
		_finish_dialogue()
	else:
		_enter_node(next_node_id, true)

	if not transaction_id.is_empty():
		ActivityManager.complete_activity(transaction_id, activity_id)

	return true


func _finish_dialogue() -> void:
	var completed_dialogue_id: String = active_dialogue_id
	var event_id: String = source_story_event_id
	var step_id: String = source_story_step_id
	_clear_session()
	dialogue_completed.emit(completed_dialogue_id)

	if not event_id.is_empty() and not step_id.is_empty():
		GlobalSignals.story_event_step_completed.emit(event_id, step_id, true)

	SaveManager.request_checkpoint(
		StringName("dialogue.%s.completed" % completed_dialogue_id),
		true
	)


func _resolve_available_node_id(start_node_id: String) -> String:
	var dialogue: DialogueData = get_active_dialogue()

	if dialogue == null:
		return ""

	var candidate_id: String = start_node_id.strip_edges()
	var visited: Dictionary = {}
	var context: GameEffectContext = _create_context("node_resolution")

	while not candidate_id.is_empty() and not visited.has(candidate_id):
		visited[candidate_id] = true
		var candidate: DialogueNodeData = dialogue.get_node_data(candidate_id)

		if candidate == null:
			return ""

		if candidate.is_available(context):
			return candidate_id

		candidate_id = candidate.next_node_id.strip_edges()

	return ""


func _create_context(
	source_suffix: String,
	transaction_id: String = ""
) -> GameEffectContext:
	return GameEffectContext.create(
		"%s.%s.%s" % [SOURCE_PREFIX, active_dialogue_id, source_suffix],
		"",
		CampaignState.current_location_id,
		transaction_id,
		source_story_event_id
	)


func _choice_key(node: DialogueNodeData, choice: DialogueChoiceData) -> String:
	return "%s::%s" % [node.get_display_id(), choice.get_display_id()]


func _get_activity_source_id() -> String:
	return "%s.%s" % [SOURCE_PREFIX, active_dialogue_id]


func _request_navigator_workspace() -> void:
	if not CampaignState.has_installed_app(NAVIGATOR_APP_ID):
		return

	var navigator: AppResource = ContentRegistry.get_app(NAVIGATOR_APP_ID)

	if navigator != null:
		GlobalSignals.request_activate_workspace.emit(navigator)


func _clear_session() -> void:
	active_dialogue_id = ""
	current_node_id = ""
	executed_node_effects.clear()
	selected_choices.clear()
	source_story_event_id = ""
	source_story_step_id = ""
	_reset_runtime_only()


func _reset_runtime_only() -> void:
	_pending_activity_request_id = ""
	_pending_choice_id = ""
	_is_resolving = false


func _on_story_dialogue_requested(
	dialogue_id: String,
	event_id: String,
	step_id: String
) -> void:
	if not start_dialogue(dialogue_id, event_id, step_id):
		GlobalSignals.story_event_step_completed.emit(event_id, step_id, false)


func _on_activity_started(
	transaction_id: String,
	activity_id: String,
	source_id: String,
	request_id: String
) -> void:
	if source_id != _get_activity_source_id() \
		or request_id != _pending_activity_request_id:
		return

	var node: DialogueNodeData = get_current_node_data()
	var choice: DialogueChoiceData = (
		node.get_choice(_pending_choice_id) if node != null else null
	)
	_pending_activity_request_id = ""
	_pending_choice_id = ""

	if not _resolve_choice(choice, transaction_id, activity_id):
		ActivityManager.fail_activity(
			transaction_id,
			"Dialogue choice failed to resolve.",
			activity_id
		)


func _on_activity_rejected(
	request_id: String,
	_activity_id: String,
	source_id: String,
	reason: String
) -> void:
	_handle_activity_cancellation(request_id, source_id, reason)


func _on_activity_cancelled(
	request_id: String,
	_activity_id: String,
	source_id: String,
	reason: String
) -> void:
	_handle_activity_cancellation(request_id, source_id, reason)


func _handle_activity_cancellation(
	request_id: String,
	source_id: String,
	reason: String
) -> void:
	if source_id != _get_activity_source_id() \
		or request_id != _pending_activity_request_id:
		return

	var cancelled_choice_id: String = _pending_choice_id
	_pending_activity_request_id = ""
	_pending_choice_id = ""
	choice_resolution_cancelled.emit(
		active_dialogue_id,
		cancelled_choice_id,
		reason.strip_edges()
	)


func _on_campaign_reset() -> void:
	_clear_session()


func _on_campaign_loaded(
	_campaign_id: String,
	_recovered_from_backup: bool
) -> void:
	if not is_dialogue_active():
		return

	call_deferred("_resume_loaded_dialogue")


func _resume_loaded_dialogue() -> void:
	if not is_dialogue_active():
		return

	_request_navigator_workspace()
	dialogue_resumed.emit(active_dialogue_id, current_node_id)
	node_changed.emit(active_dialogue_id, current_node_id)


func _validate_id_array(
	errors: PackedStringArray,
	value: Variant,
	field_name: String
) -> void:
	if value is not Array and value is not PackedStringArray:
		errors.append("%s must be an array." % field_name)
		return

	var seen: Dictionary = {}

	for raw_value: Variant in value:
		var clean_value: String = str(raw_value).strip_edges()

		if clean_value.is_empty():
			errors.append("%s contains an empty ID." % field_name)
		elif seen.has(clean_value):
			errors.append("%s contains duplicate ID '%s'." % [field_name, clean_value])
		else:
			seen[clean_value] = true


func _read_id_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()

	if value is not Array and value is not PackedStringArray:
		return result

	for raw_value: Variant in value:
		var clean_value: String = str(raw_value).strip_edges()

		if not clean_value.is_empty() and not result.has(clean_value):
			result.append(clean_value)

	return result


func _string_array_to_array(value: PackedStringArray) -> Array[String]:
	var result: Array[String] = []

	for entry: String in value:
		result.append(entry)

	return result
