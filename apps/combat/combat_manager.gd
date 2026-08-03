extends Node


enum TimelineActionKind {
	MODULE,
	PLAYER_ACTION,
	EMPTY
}


signal encounter_started(encounter: CombatEncounter)
signal combat_victory
signal combat_defeat
signal cycle_ended_ready_for_next
signal cycle_completed(cycle_index: int)
signal escape_attempted(success: bool)
signal combat_log_added(message: String)
signal floating_text_requested(
	actor: Dictionary,
	text: String,
	color: Color
)
signal timeline_generated(actions: Array)
signal stats_updated
signal runtime_slots_changed
signal action_executed(
	index: int,
	action_data: Dictionary
)
signal presentation_event_emitted(
	event: CombatPresentationEvent
)
signal player_action_progressed(
	action_id: String,
	target_uid: int,
	progress: int,
	completed: bool
)
signal player_action_choice_requested(
	action_id: String,
	target_uid: int,
	module_ids: PackedStringArray
)
signal evolution_prompt_requested(branch: EvolutionBranchData)
signal combat_resolution_applied(outcome: CombatResult.Outcome, metadata: Dictionary)


const TEAM_SIZE: int = 4
const MAX_EVENT_DEPTH: int = 16
const SAVE_DATA_VERSION: int = 2
const MIN_SAVE_DATA_VERSION: int = 1
const UNSTABILITY_STATUS: StatusEffectData = preload(
	"res://data/content/combat/status_effects/unstability.tres"
)


var ally_team: Array = [null, null, null, null]
var enemy_team: Array = [null, null, null, null]
var ally_position_slots: Array[CombatRuntimeSlot] = []
var enemy_position_slots: Array[CombatRuntimeSlot] = []
var action_slots: Array[CombatRuntimeSlot] = []
var current_cycle_actions: Array = []
var current_cycle: int = 0
var player_action_progress: Array[PlayerActionProgressData] = []
var combat_tendency_log: CombatTendencyLog = CombatTendencyLog.new()


var _current_encounter: CombatEncounter
var _encounter_active: bool = false
var _next_uid: int = 1
var _next_event_id: int = 1
var _next_dynamic_action_id: int = 1
var _is_executing_cycle: bool = false
var _session_activity_transaction_id: String = ""
var _session_activity_id: String = ""
var _partner_state_committed: bool = false
var _resolved_enemy_records: Array[Dictionary] = []
var _player_resolution_record: Dictionary = {}
var _pending_player_action_choice: Dictionary = {}
var _pending_evolution_branch_id: String = ""
var _completed_evolution_branch_ids: PackedStringArray = PackedStringArray()
var _awaiting_resolution: bool = false
var _pending_outcome: CombatResult.Outcome = CombatResult.Outcome.CANCELLED
var _resolution_applied: bool = false
var _resolution_metadata: Dictionary = {}


func load_encounter(
	encounter: CombatEncounter
) -> bool:
	reset_encounter()

	if encounter == null:
		push_error(
			"CombatManager: cannot load a null encounter."
		)
		return false

	var validation_errors := encounter.validate_data()

	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error(
				"Combat content validation: %s"
				% error
			)
		return false

	_current_encounter = encounter
	_encounter_active = true
	_initialize_runtime_slots()

	_load_team_from_slots(
		encounter.ally_slots,
		ally_team,
		true
	)
	_load_team_from_slots(
		encounter.enemy_slots,
		enemy_team,
		false
	)

	if _get_player_actor() == null:
		push_error("CombatManager: encounter has no available player actor.")
		reset_encounter()
		return false

	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.ENCOUNTER_START
		)
	)
	stats_updated.emit()
	rebuild_timeline()
	encounter_started.emit(encounter)
	return true


func reset_encounter() -> void:
	ally_team = [null, null, null, null]
	enemy_team = [null, null, null, null]
	ally_position_slots.clear()
	enemy_position_slots.clear()
	action_slots.clear()
	current_cycle_actions.clear()
	current_cycle = 0
	player_action_progress.clear()
	combat_tendency_log = CombatTendencyLog.new()
	_current_encounter = null
	_encounter_active = false
	_next_uid = 1
	_next_event_id = 1
	_next_dynamic_action_id = 1
	_is_executing_cycle = false
	_session_activity_transaction_id = ""
	_session_activity_id = ""
	_partner_state_committed = false
	_resolved_enemy_records.clear()
	_player_resolution_record.clear()
	_pending_player_action_choice.clear()
	_pending_evolution_branch_id = ""
	_completed_evolution_branch_ids.clear()
	_awaiting_resolution = false
	_pending_outcome = CombatResult.Outcome.CANCELLED
	_resolution_applied = false
	_resolution_metadata.clear()
	EvolutionManager.reset()


func is_encounter_active() -> bool:
	return _encounter_active


func is_awaiting_resolution() -> bool:
	return _awaiting_resolution


func is_resolution_applied() -> bool:
	return _resolution_applied


func get_pending_outcome() -> CombatResult.Outcome:
	return _pending_outcome


func get_pending_player_action_choice() -> Dictionary:
	return _pending_player_action_choice.duplicate(true)


func get_pending_evolution_branch() -> EvolutionBranchData:
	return EvolutionManager.get_pending_branch()


func get_current_encounter() -> CombatEncounter:
	return _current_encounter


func set_session_activity_context(
	transaction_id: String,
	activity_id: String
) -> void:
	_session_activity_transaction_id = transaction_id.strip_edges()
	_session_activity_id = activity_id.strip_edges()


func get_session_activity_context() -> Dictionary:
	return {
		"activity_transaction_id": _session_activity_transaction_id,
		"activity_id": _session_activity_id
	}


func get_save_section_id() -> String:
	return str(SaveConstants.SECTION_COMBAT_SESSION)


func can_save_now() -> bool:
	return not _is_executing_cycle


func export_save_data() -> Dictionary:
	if not _encounter_active or _current_encounter == null:
		return {
			"version": SAVE_DATA_VERSION,
			"active": false
		}

	return {
		"version": SAVE_DATA_VERSION,
		"active": true,
		"encounter_id": _current_encounter.encounter_id,
		"activity_transaction_id": _session_activity_transaction_id,
		"activity_id": _session_activity_id,
		"cycle_index": current_cycle,
		"next_uid": _next_uid,
		"next_event_id": _next_event_id,
		"next_dynamic_action_id": _next_dynamic_action_id,
		"awaiting_resolution": _awaiting_resolution,
		"pending_outcome": int(_pending_outcome),
		"resolution_applied": _resolution_applied,
		"resolution_metadata": _plain_copy(_resolution_metadata),
		"player_action_progress": PlayerActionService.serialize_states(player_action_progress),
		"combat_tendency_log": combat_tendency_log.to_save_data(),
		"resolved_enemy_records": _serialize_team_records(_resolved_enemy_records),
		"player_resolution_record": (
			_serialize_actor(_player_resolution_record)
			if not _player_resolution_record.is_empty()
			else {}
		),
		"pending_player_action_choice": _plain_copy(_pending_player_action_choice),
		"pending_evolution_branch_id": _pending_evolution_branch_id,
		"completed_evolution_branch_ids": Array(_completed_evolution_branch_ids),
		"ally_team": _serialize_team(ally_team),
		"enemy_team": _serialize_team(enemy_team),
		"ally_position_slots": _serialize_slots(ally_position_slots),
		"enemy_position_slots": _serialize_slots(enemy_position_slots),
		"action_slots": _serialize_slots(action_slots)
	}


func import_save_data(data: Dictionary) -> void:
	reset_encounter()

	var version: int = int(data.get("version", -1))

	if version < MIN_SAVE_DATA_VERSION or version > SAVE_DATA_VERSION \
		or not bool(data.get("active", false)):
		return

	var encounter_id: String = str(data.get("encounter_id", "")).strip_edges()
	var encounter: CombatEncounter = ContentRegistry.get_combat_encounter(
		encounter_id
	)

	if encounter == null or not load_encounter(encounter):
		push_error(
			"CombatManager: could not restore encounter '%s'." % encounter_id
		)
		reset_encounter()
		return

	ally_team = _deserialize_team(data.get("ally_team", []))
	enemy_team = _deserialize_team(data.get("enemy_team", []))
	ally_position_slots = _deserialize_slots(
		data.get("ally_position_slots", [])
	)
	enemy_position_slots = _deserialize_slots(
		data.get("enemy_position_slots", [])
	)
	action_slots = _deserialize_slots(data.get("action_slots", []))
	current_cycle = maxi(0, int(data.get("cycle_index", 0)))
	_next_uid = maxi(1, int(data.get("next_uid", 1)))
	_next_event_id = maxi(1, int(data.get("next_event_id", 1)))
	_next_dynamic_action_id = maxi(
		1,
		int(data.get("next_dynamic_action_id", 1))
	)
	_session_activity_transaction_id = str(
		data.get("activity_transaction_id", "")
	).strip_edges()
	_session_activity_id = str(data.get("activity_id", "")).strip_edges()
	_awaiting_resolution = bool(data.get("awaiting_resolution", false))
	_pending_outcome = clampi(
		int(data.get("pending_outcome", CombatResult.Outcome.CANCELLED)),
		CombatResult.Outcome.VICTORY,
		CombatResult.Outcome.CANCELLED
	)
	_resolution_applied = bool(data.get("resolution_applied", false))
	_resolution_metadata = _read_dictionary(data.get("resolution_metadata", {}))
	player_action_progress = PlayerActionService.deserialize_states(
		data.get("player_action_progress", [])
	)
	combat_tendency_log.load_save_data(
		_read_dictionary(data.get("combat_tendency_log", {}))
	)
	_resolved_enemy_records = _deserialize_team_records(
		data.get("resolved_enemy_records", [])
	)
	var raw_player_record: Variant = data.get("player_resolution_record", {})

	if raw_player_record is Dictionary and not (raw_player_record as Dictionary).is_empty():
		_player_resolution_record = _deserialize_actor(raw_player_record as Dictionary)
	_pending_player_action_choice = _read_dictionary(
		data.get("pending_player_action_choice", {})
	)
	_pending_evolution_branch_id = str(
		data.get("pending_evolution_branch_id", "")
	).strip_edges()
	_completed_evolution_branch_ids = _read_string_array(
		data.get("completed_evolution_branch_ids", [])
	)
	_encounter_active = true
	_is_executing_cycle = false
	runtime_slots_changed.emit()
	stats_updated.emit()

	if _resolution_applied:
		_emit_restored_resolution.call_deferred()
	elif not _pending_evolution_branch_id.is_empty():
		EvolutionManager.restore_offer(_pending_evolution_branch_id)
	elif not _pending_player_action_choice.is_empty():
		_emit_pending_player_action_choice.call_deferred()
	elif not _awaiting_resolution:
		rebuild_timeline()


func reset_save_data() -> void:
	reset_encounter()


func _emit_restored_resolution() -> void:
	if _resolution_applied:
		combat_resolution_applied.emit(
			_pending_outcome,
			_resolution_metadata.duplicate(true)
		)


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	var version: int = int(data.get("version", -1))

	if version < MIN_SAVE_DATA_VERSION or version > SAVE_DATA_VERSION:
		errors.append("Unsupported CombatSession save version.")
		return errors

	if not bool(data.get("active", false)):
		return errors

	var encounter_id: String = str(data.get("encounter_id", "")).strip_edges()

	if ContentRegistry.get_combat_encounter(encounter_id) == null:
		errors.append("CombatSession encounter_id is not registered.")

	for team_key: String in ["ally_team", "enemy_team"]:
		var raw_team: Variant = data.get(team_key, [])

		if raw_team is not Array or raw_team.size() != TEAM_SIZE:
			errors.append("CombatSession %s must contain four slots." % team_key)

	return errors


func get_player_actions() -> Array[PlayerActionData]:
	if _current_encounter == null or _current_encounter.resolution == null:
		var empty: Array[PlayerActionData] = []
		return empty

	return _current_encounter.resolution.player_actions.duplicate()


func get_available_player_action_targets(action_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var action: PlayerActionData = _get_player_action(action_id)

	for actor: Variant in enemy_team:
		if actor is not Dictionary:
			continue

		if PlayerActionService.validate_assignment(
			action,
			actor as Dictionary,
			player_action_progress
		).is_empty():
			result.append(actor as Dictionary)

	return result


func set_player_action(slot_index: int, action_id: String, target_uid: int) -> PackedStringArray:
	var errors := PackedStringArray()
	var player: Variant = _get_player_actor()

	if player is not Dictionary or slot_index < 0 or slot_index >= TEAM_SIZE:
		errors.append("Player Action slot index is invalid.")
		return errors

	var action: PlayerActionData = _get_player_action(action_id)
	var target: Variant = _find_combatant_by_uid(target_uid)

	if target is not Dictionary:
		errors.append("Player Action target is unavailable.")
		return errors

	errors.append_array(PlayerActionService.validate_assignment(
		action,
		target as Dictionary,
		player_action_progress
	))

	if not errors.is_empty():
		return errors

	var assignments: Array = player.get("player_action_assignments", [])
	assignments.resize(TEAM_SIZE)
	assignments[slot_index] = {
		"action_id": action.action_id,
		"target_uid": target_uid
	}
	player["player_action_assignments"] = assignments
	rebuild_timeline()
	return errors


func clear_player_action(slot_index: int) -> bool:
	var player: Variant = _get_player_actor()

	if player is not Dictionary or slot_index < 0 or slot_index >= TEAM_SIZE:
		return false

	var assignments: Array = player.get("player_action_assignments", [])
	assignments.resize(TEAM_SIZE)
	assignments[slot_index] = null
	player["player_action_assignments"] = assignments
	rebuild_timeline()
	return true


func select_player_action_reward(module_id: String) -> PackedStringArray:
	var errors := PackedStringArray()

	if _pending_player_action_choice.is_empty():
		errors.append("No Player Action reward choice is pending.")
		return errors

	var clean_id: String = module_id.strip_edges()
	var candidates: PackedStringArray = _read_string_array(
		_pending_player_action_choice.get("module_ids", [])
	)

	if not candidates.has(clean_id):
		errors.append("Selected Module is not available for this Player Action.")
		return errors

	var state: PlayerActionProgressData = PlayerActionService.get_progress(
		player_action_progress,
		str(_pending_player_action_choice.get("action_id", "")),
		int(_pending_player_action_choice.get("target_uid", -1))
	)

	if state == null or not state.completed:
		errors.append("Pending Player Action progress could not be restored.")
		return errors

	state.selected_reward_id = clean_id
	_pending_player_action_choice.clear()

	if _awaiting_resolution:
		_emit_terminal_outcome()
	else:
		_continue_after_cycle_boundary()

	return errors


func accept_pending_evolution() -> PackedStringArray:
	var branch: EvolutionBranchData = EvolutionManager.get_pending_branch()
	var branch_id: String = branch.branch_id if branch != null else ""
	var errors: PackedStringArray = EvolutionManager.accept_pending()

	if not errors.is_empty():
		return errors

	_pending_evolution_branch_id = ""

	if not branch_id.is_empty() and not _completed_evolution_branch_ids.has(branch_id):
		_completed_evolution_branch_ids.append(branch_id)

	_refresh_player_actor_from_partner()
	SaveManager.request_checkpoint(&"combat_evolution", true)
	_continue_after_cycle_boundary()
	return errors


func decline_pending_evolution() -> bool:
	var branch_id: String = EvolutionManager.decline_pending()

	if branch_id.is_empty():
		return false

	_pending_evolution_branch_id = ""

	if not _completed_evolution_branch_ids.has(branch_id):
		_completed_evolution_branch_ids.append(branch_id)

	_continue_after_cycle_boundary()
	return true


func resolve_encounter(outcome: CombatResult.Outcome) -> PackedStringArray:
	var errors := PackedStringArray()

	if _resolution_applied:
		return errors

	if not _encounter_active or _current_encounter == null:
		errors.append("No active encounter is available for resolution.")
		return errors

	if not _awaiting_resolution:
		errors.append("Combat has not reached a terminal resolution boundary.")
		return errors

	if outcome != _pending_outcome:
		errors.append("Combat outcome does not match the pending terminal state.")
		return errors

	var player: Variant = _get_player_resolution_actor()

	if player is not Dictionary:
		errors.append("Combat has no player actor to resolve.")
		return errors

	var result: Dictionary = CombatResolutionService.resolve(
		outcome,
		_current_encounter,
		player as Dictionary,
		_get_enemy_resolution_records(),
		player_action_progress,
		combat_tendency_log
	)
	errors.append_array(result.get("errors", PackedStringArray()))

	if not errors.is_empty():
		return errors

	_resolution_metadata = result.get("metadata", {}).duplicate(true)
	_resolution_applied = true
	_partner_state_committed = true
	_awaiting_resolution = false
	_pending_outcome = outcome
	SaveManager.request_checkpoint(
		StringName("combat_resolved.%s" % _current_encounter.encounter_id),
		not str(_resolution_metadata.get("tamed_apk_id", "")).is_empty()
	)
	combat_resolution_applied.emit(outcome, _resolution_metadata.duplicate(true))
	return errors


func finalize_resolved_encounter() -> bool:
	if not _encounter_active or not _resolution_applied:
		return false

	_encounter_active = false
	return true


func get_player_actor() -> Variant:
	return _get_player_actor()


func commit_player_partner_state(experience_gain: int = 0) -> PackedStringArray:
	var errors := PackedStringArray()

	if _partner_state_committed:
		return errors

	var player: Variant = _get_player_actor()

	if player is not Dictionary:
		errors.append("Combat has no player actor to commit.")
		return errors

	if int(player.get("source_kind", -1)) != CombatSlotData.ParticipantSource.PLAYER_PARTNER:
		_partner_state_committed = true
		return errors

	errors = APKProgressionService.commit_combat_snapshot(
		player as Dictionary,
		experience_gain
	)

	if errors.is_empty():
		_partner_state_committed = true

	return errors


func rebuild_timeline() -> void:
	current_cycle_actions.clear()

	if not _encounter_active \
		or _awaiting_resolution \
		or not _pending_player_action_choice.is_empty() \
		or not _pending_evolution_branch_id.is_empty():
		timeline_generated.emit(
			current_cycle_actions
		)
		return

	var ally_actors := _get_timeline_actors(
		ally_team
	)
	var enemy_actors := _get_timeline_actors(
		enemy_team
	)

	for runtime_slot in action_slots:
		if runtime_slot == null or not runtime_slot.enabled:
			continue

		var actors := (
			ally_actors
			if runtime_slot.is_ally
			else enemy_actors
		)
		_append_timeline_action(
			actors,
			runtime_slot
		)

	timeline_generated.emit(current_cycle_actions)


func execute_cycle(
	animated: bool = true
) -> void:
	if not _encounter_active \
		or _awaiting_resolution \
		or not _pending_player_action_choice.is_empty() \
		or not _pending_evolution_branch_id.is_empty():
		return

	if animated:
		_execute_cycle_animated()
	else:
		_execute_cycle_immediate()


func try_escape() -> bool:
	if (
		not _encounter_active
		or _current_encounter == null
	):
		return false

	if not _current_encounter.can_escape:
		combat_log_added.emit(
			"> Escape is blocked in this encounter."
		)
		escape_attempted.emit(false)
		return false

	var player: Variant = _get_player_actor()

	if player == null:
		escape_attempted.emit(false)
		return false

	combat_tendency_log.run_attempts += 1

	if _current_encounter.resolution != null:
		for gain: CombatTendencyGainData in _current_encounter.resolution.escape_attempt_tendency_gains:
			if gain != null and gain.is_available():
				combat_tendency_log.add_tendency(gain.tendency, gain.amount)

	var dodge := get_effective_stat(
		player,
		CombatConstants.Stat.DODGE
	)
	var chance := clampf(
		_current_encounter.base_escape_chance
		+ dodge,
		0.05,
		0.95
	)
	var success := randf() <= chance

	if success:
		_awaiting_resolution = true
		_pending_outcome = CombatResult.Outcome.ESCAPED
		combat_log_added.emit(
			"> Escape successful."
		)
	else:
		combat_log_added.emit(
			"> Escape failed."
		)

	escape_attempted.emit(success)
	return success


func swap_ally_slots(
	source_index: int,
	target_index: int
) -> bool:
	if (
		source_index < 0
		or source_index >= TEAM_SIZE
		or target_index < 0
		or target_index >= TEAM_SIZE
	):
		return false

	if (
		not ally_position_slots[target_index].enabled
	):
		return false

	var temporary: Variant = ally_team[target_index]

	if (
		not ally_position_slots[source_index].enabled
		and temporary != null
	):
		return false

	ally_team[target_index] = ally_team[source_index]
	ally_team[source_index] = temporary
	rebuild_timeline()
	stats_updated.emit()
	return true


func get_position_slots(
	is_ally: bool
) -> Array[CombatRuntimeSlot]:
	return (
		ally_position_slots
		if is_ally
		else enemy_position_slots
	)


func get_position_slot(
	is_ally: bool,
	slot_index: int
) -> CombatRuntimeSlot:
	var slots := get_position_slots(is_ally)

	if slot_index < 0 or slot_index >= slots.size():
		return null

	return slots[slot_index]


func get_runtime_slot(
	slot_id: StringName
) -> CombatRuntimeSlot:
	for slot in (
		ally_position_slots
		+ enemy_position_slots
		+ action_slots
	):
		if slot != null and slot.slot_id == slot_id:
			return slot

	return null


func set_runtime_slot_enabled(
	slot_id: StringName,
	enabled: bool
) -> bool:
	var slot := get_runtime_slot(slot_id)

	if slot == null:
		return false

	slot.enabled = enabled
	runtime_slots_changed.emit()
	stats_updated.emit()
	_refresh_timeline_after_slot_change()
	return true


func move_actor_to_position(
	actor_uid: int,
	destination_slot_id: StringName,
	swap_occupants: bool = true
) -> bool:
	var destination := get_runtime_slot(
		destination_slot_id
	)
	var actor: Variant = _find_combatant_by_uid(actor_uid)

	if (
		destination == null
		or destination.slot_kind
		!= CombatRuntimeSlot.SlotKind.POSITION
		or not destination.enabled
		or not (actor is Dictionary)
		or bool(actor.get("is_ally", false))
		!= destination.is_ally
	):
		return false

	var team := (
		ally_team
		if destination.is_ally
		else enemy_team
	)
	var source_index := team.find(actor)

	if source_index < 0:
		return false

	var destination_index := destination.logical_index
	var occupant: Variant = team[destination_index]
	var source_slot := get_position_slot(
		destination.is_ally,
		source_index
	)

	if occupant != null and not swap_occupants:
		return false

	if (
		source_slot != null
		and not source_slot.enabled
		and occupant != null
	):
		return false

	team[destination_index] = actor
	team[source_index] = occupant
	runtime_slots_changed.emit()
	stats_updated.emit()
	_refresh_timeline_after_slot_change()
	return true


func add_action_slot(
	is_ally: bool,
	actor_index: int,
	insert_index: int = -1
) -> StringName:
	var team_name := "ally" if is_ally else "enemy"
	var slot_id := StringName(
		"%s.action.extra.%d"
		% [team_name, _next_dynamic_action_id]
	)
	_next_dynamic_action_id += 1

	var target_index := insert_index

	if target_index < 0:
		target_index = action_slots.size()

	target_index = clampi(
		target_index,
		0,
		action_slots.size()
	)
	var slot := CombatRuntimeSlot.create(
		slot_id,
		CombatRuntimeSlot.SlotKind.ACTION,
		is_ally,
		clampi(actor_index, 0, TEAM_SIZE - 1),
		target_index,
		true
	)
	action_slots.insert(target_index, slot)
	_normalize_action_slot_order()
	runtime_slots_changed.emit()
	_refresh_timeline_after_slot_change()
	return slot_id


func move_action_slot(
	slot_id: StringName,
	destination_order: int
) -> bool:
	var slot := get_runtime_slot(slot_id)

	if (
		slot == null
		or slot.slot_kind
		!= CombatRuntimeSlot.SlotKind.ACTION
	):
		return false

	var source_index := action_slots.find(slot)

	if source_index < 0:
		return false

	action_slots.remove_at(source_index)
	action_slots.insert(
		clampi(
			destination_order,
			0,
			action_slots.size()
		),
		slot
	)
	_normalize_action_slot_order()
	runtime_slots_changed.emit()
	_refresh_timeline_after_slot_change()
	return true


func _refresh_timeline_after_slot_change() -> void:
	if _is_executing_cycle:
		return

	rebuild_timeline()


func set_player_module(
	slot_index: int,
	module: ModuleData
) -> bool:
	var player: Variant = _get_player_actor()

	if (
		player == null
		or slot_index < 0
		or slot_index >= TEAM_SIZE
	):
		return false

	player["modules"][slot_index] = module
	clear_player_action(slot_index)
	rebuild_timeline()
	return true


func get_effective_stat(
	actor: Dictionary,
	stat: CombatConstants.Stat
) -> float:
	return _get_effective_stat(
		actor,
		stat,
		0
	)


func get_barrier_stacks(
	actor: Dictionary
) -> int:
	var total: int = 0

	for instance in actor.get("active_statuses", []):
		if (
			instance is CombatStatusInstance
			and instance.data != null
			and instance.data.damage_rule
			== StatusEffectData.DamageRule.BARRIER
		):
			total += instance.stacks

	return total


func was_targeted_by_classification(
	actor: Dictionary,
	classification: StringName,
	cycles_ago: int = 1
) -> bool:
	var expected_cycle := current_cycle - cycles_ago

	for entry in actor.get(
		"module_targeting_history",
		[]
	):
		if (
			int(entry.get("cycle", -1))
			== expected_cycle
			and entry.get("classification", &"")
			== classification
		):
			return true

	return false


func preview_action(
	action: Dictionary
) -> Dictionary:
	var preview := {
		"entries": [],
		"lines": PackedStringArray()
	}
	var actor: Variant = action.get("actor")
	var module: ModuleData = action.get("module")

	if not (actor is Dictionary) or module == null:
		return preview

	var context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.MODULE_USED
	)

	var virtual_barriers: Dictionary = {}

	for execution_index in range(module.execution_count):
		context.execution_index = execution_index
		context.execution_count = module.execution_count

		for effect in module.combat_effects:
			if effect == null:
				continue

			if (
				effect.effect_type
				== CombatEffectData.EffectType.SPAWN_DUMMY
			):
				preview["lines"].append(
					effect.describe()
				)
				continue

			if effect.effect_type in [
				CombatEffectData.EffectType.SET_SLOT_ENABLED,
				CombatEffectData.EffectType.MOVE_ACTOR,
				CombatEffectData.EffectType.ADD_ACTION_SLOT,
				CombatEffectData.EffectType.MOVE_ACTION_SLOT
			]:
				preview["lines"].append(
					effect.describe()
				)
				continue

			var targets := resolve_targets(
				effect.target_selector,
				actor,
				context,
				actor
			)

			if targets.is_empty():
				preview["lines"].append(
					"%s: no valid target."
					% effect.describe()
				)
				continue

			for target in targets:
				var entry := _preview_effect(
					actor,
					target,
					module,
					effect,
					context,
					virtual_barriers
				)

				if not entry.is_empty():
					_merge_preview_entry(
						preview["entries"],
						entry
					)

	return preview


func get_module_tooltip(
	module: ModuleData,
	action: Dictionary = {}
) -> String:
	if module == null:
		return "EMPTY"

	var lines := PackedStringArray([
		"[%s]" % module.module_name
	])

	if not module.description.strip_edges().is_empty():
		lines.append(module.description)

	lines.append(
		"Cost: %d STB"
		% module.stability_cost
	)

	if module.execution_count > 1:
		lines.append(
			"Executions: %d"
			% module.execution_count
		)

	if not module.classification.is_empty():
		lines.append(
			"Classification: %s"
			% module.classification
		)

	lines.append_array(module.describe_effects())

	if not action.is_empty():
		var preview := preview_action(action)

		for entry in preview.get("entries", []):
			lines.append(
				str(entry.get("summary", ""))
			)

		for line in preview.get(
			"lines",
			PackedStringArray()
		):
			lines.append(line)

	return "\n".join(lines)


func get_player_action_tooltip(
	action: PlayerActionData,
	target_uid: int = -1
) -> String:
	if action == null:
		return "UNAVAILABLE"

	var lines := PackedStringArray([
		"[%s]" % action.display_name,
		action.description,
		"Progress per slot: %d%%" % action.progress_amount
	])

	if target_uid >= 0:
		var state: PlayerActionProgressData = PlayerActionService.get_progress(
			player_action_progress,
			action.action_id,
			target_uid
		)
		lines.append("Current progress: %d%%" % (state.progress if state != null else 0))

	return "\n".join(lines)


func get_result_metadata() -> Dictionary:
	var metadata: Dictionary = {
		"cycles": current_cycle,
		"allies": _team_snapshot(ally_team),
		"enemies": _team_snapshot(enemy_team),
		"runtime_slots": _runtime_slot_snapshot()
	}

	for key: Variant in _resolution_metadata:
		metadata[str(key)] = _resolution_metadata[key]

	return metadata


func resolve_targets(
	selector: CombatTargetSelector,
	caster: Dictionary,
	context: CombatEventContext = null,
	holder: Dictionary = {}
) -> Array:
	if selector == null:
		return []

	var allies := (
		ally_team
		if bool(caster.get("is_ally", false))
		else enemy_team
	)
	var enemies := (
		enemy_team
		if bool(caster.get("is_ally", false))
		else ally_team
	)
	var caster_index := allies.find(caster)
	var result: Array = []

	match selector.target_kind:
		CombatTargetSelector.TargetKind.USER:
			result = [caster]

		CombatTargetSelector.TargetKind.DIRECT_ENEMY:
			var direct_target: Variant = (
				_get_direct_enemy_target(
					caster_index,
					enemies
				)
			)
			if direct_target != null:
				result = [direct_target]

		CombatTargetSelector.TargetKind.ALL_ENEMIES:
			result = _get_valid_targets(
				enemies,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.ENEMY_SLOT:
			result = _target_from_slot(
				enemies,
				selector.slot_index,
				selector
			)

		CombatTargetSelector.TargetKind.ADJACENT_ALLY:
			var adjacent: Variant = _get_adjacent_ally(
				caster_index,
				allies
			)
			if adjacent != null:
				result = [adjacent]

		CombatTargetSelector.TargetKind.ALL_ALLIES:
			result = _get_valid_targets(
				allies,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.ALLY_SLOT:
			result = _target_from_slot(
				allies,
				selector.slot_index,
				selector
			)

		CombatTargetSelector.TargetKind.EVENT_SOURCE:
			result = _variant_as_target_array(
				context.source if context != null else null,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.EVENT_TARGET:
			result = _variant_as_target_array(
				context.target if context != null else null,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.STATUS_HOLDER:
			result = _variant_as_target_array(
				holder,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.DUMMY_CREATOR:
			var creator_uid := int(
				holder.get(
					"creator_uid",
					caster.get("creator_uid", -1)
				)
			)
			var creator: Variant = _find_combatant_by_uid(
				creator_uid
			)
			result = _variant_as_target_array(
				creator,
				selector.include_defeated
			)

	return result


func resolve_runtime_slots(
	selector: CombatSlotSelector,
	caster: Dictionary,
	context: CombatEventContext = null
) -> Array[CombatRuntimeSlot]:
	var result: Array[CombatRuntimeSlot] = []

	if selector == null:
		return result

	if selector.use_context_slot and context != null:
		var context_id := (
			context.position_slot_id
			if selector.slot_kind
			== CombatSlotSelector.SlotKind.POSITION
			else context.action_slot_id
		)
		var context_slot := get_runtime_slot(context_id)

		if (
			context_slot != null
			and (
				selector.include_disabled
				or context_slot.enabled
			)
		):
			result.append(context_slot)

		return result

	var expected_kind := (
		CombatRuntimeSlot.SlotKind.POSITION
		if selector.slot_kind
		== CombatSlotSelector.SlotKind.POSITION
		else CombatRuntimeSlot.SlotKind.ACTION
	)
	var candidates: Array[CombatRuntimeSlot] = []

	if expected_kind == CombatRuntimeSlot.SlotKind.POSITION:
		candidates.append_array(ally_position_slots)
		candidates.append_array(enemy_position_slots)
	else:
		candidates.append_array(action_slots)

	for slot in candidates:
		if (
			slot == null
			or slot.slot_kind != expected_kind
			or (
				not selector.include_disabled
				and not slot.enabled
			)
		):
			continue

		if (
			not selector.slot_id.is_empty()
			and slot.slot_id != selector.slot_id
		):
			continue

		if (
			selector.slot_index >= 0
			and slot.logical_index
			!= selector.slot_index
		):
			continue

		if not _slot_matches_team_relation(
			slot,
			selector.team_relation,
			caster
		):
			continue

		result.append(slot)

	return result


func _slot_matches_team_relation(
	slot: CombatRuntimeSlot,
	relation: CombatSlotSelector.TeamRelation,
	caster: Dictionary
) -> bool:
	var caster_is_ally := bool(
		caster.get("is_ally", false)
	)

	match relation:
		CombatSlotSelector.TeamRelation.CASTER_TEAM:
			return slot.is_ally == caster_is_ally
		CombatSlotSelector.TeamRelation.OPPOSING_TEAM:
			return slot.is_ally != caster_is_ally
		CombatSlotSelector.TeamRelation.ALLY_TEAM:
			return slot.is_ally
		CombatSlotSelector.TeamRelation.ENEMY_TEAM:
			return not slot.is_ally
		CombatSlotSelector.TeamRelation.ANY_TEAM:
			return true

	return false


func _load_team_from_slots(
	slot_data_list: Array[CombatSlotData],
	target_team: Array,
	is_ally: bool
) -> void:
	for slot_data in slot_data_list:
		if (
			slot_data == null
			or not slot_data.is_available()
		):
			continue

		var index := clampi(
			slot_data.slot_index,
			0,
			TEAM_SIZE - 1
		)
		var loadout: CharacterLoadout = _resolve_slot_loadout(slot_data)

		if loadout == null:
			continue

		target_team[index] = _create_combatant(
			loadout,
			is_ally,
			is_ally and index == 0,
			slot_data.participant_source,
			slot_data.slot_index,
			slot_data.reward_profile
		)


func _resolve_slot_loadout(slot_data: CombatSlotData) -> CharacterLoadout:
	match slot_data.participant_source:
		CombatSlotData.ParticipantSource.FIXED_LOADOUT:
			return slot_data.character
		CombatSlotData.ParticipantSource.PLAYER_PARTNER:
			return APKProgressionService.create_combat_snapshot()
		CombatSlotData.ParticipantSource.PARTY_MEMBER:
			return null

	return null


func _initialize_runtime_slots() -> void:
	ally_position_slots.clear()
	enemy_position_slots.clear()
	action_slots.clear()

	for index in range(TEAM_SIZE):
		ally_position_slots.append(
			CombatRuntimeSlot.create(
				StringName("ally.position.%d" % index),
				CombatRuntimeSlot.SlotKind.POSITION,
				true,
				index,
				index
			)
		)
		enemy_position_slots.append(
			CombatRuntimeSlot.create(
				StringName("enemy.position.%d" % index),
				CombatRuntimeSlot.SlotKind.POSITION,
				false,
				index,
				index
			)
		)
		action_slots.append(
			CombatRuntimeSlot.create(
				StringName("ally.action.%d" % index),
				CombatRuntimeSlot.SlotKind.ACTION,
				true,
				index,
				index * 2
			)
		)
		action_slots.append(
			CombatRuntimeSlot.create(
				StringName("enemy.action.%d" % index),
				CombatRuntimeSlot.SlotKind.ACTION,
				false,
				index,
				(index * 2) + 1
			)
		)

	_normalize_action_slot_order()
	runtime_slots_changed.emit()


func _normalize_action_slot_order() -> void:
	for index in range(action_slots.size()):
		action_slots[index].order_index = index


func _create_combatant(
	data: CharacterLoadout,
	is_ally: bool,
	is_player: bool = false,
	source_kind: CombatSlotData.ParticipantSource = CombatSlotData.ParticipantSource.FIXED_LOADOUT,
	encounter_slot_index: int = -1,
	reward_profile: CombatRewardData = null
) -> Dictionary:
	var modules: Array = data.equipped_modules.duplicate()
	modules.resize(TEAM_SIZE)
	var actor := {
		"uid": _consume_uid(),
		"character_id": data.character_id,
		"source_kind": int(source_kind),
		"encounter_slot_index": encounter_slot_index,
		"reward_profile": reward_profile,
		"name": data.char_name,
		"icon": data.combat_icon,
		"level": data.level,
		"type": data.apk_type,
		"hp": float(data.starting_hp if data.starting_hp >= 0 else data.max_hp),
		"max_hp": float(data.max_hp),
		"stability": float(data.starting_stability if data.starting_stability >= 0 else data.max_stability),
		"max_stability": float(data.max_stability),
		"stability_recovery": float(
			data.stability_recovery
		),
		"atk": float(data.base_atk),
		"def": float(data.base_def),
		"matk": float(data.base_matk),
		"mdef": float(data.base_mdef),
		"dodge": data.dodge_chance,
		"crit": data.crit_chance,
		"modules": modules,
		"player_action_assignments": [null, null, null, null],
		"purged": false,
		"purified": false,
		"tamed": false,
		"is_ally": is_ally,
		"is_player": is_player,
		"is_dummy": false,
		"dummy_data": null,
		"creator_uid": -1,
		"remaining_cycles": -1,
		"spawned_cycle": -1,
		"active_statuses": [],
		"runtime_effects": [],
		"module_targeting_history": []
	}
	return actor


func _create_dummy(
	data: DummyData,
	creator: Dictionary
) -> Dictionary:
	var actor := {
		"uid": _consume_uid(),
		"character_id": data.dummy_id,
		"name": data.display_name,
		"icon": data.combat_icon,
		"level": creator.get("level", 1),
		"type": data.apk_type,
		"hp": 1.0,
		"max_hp": 1.0,
		"stability": 0.0,
		"max_stability": 0.0,
		"stability_recovery": 0.0,
		"atk": 0.0,
		"def": 0.0,
		"matk": 0.0,
		"mdef": 0.0,
		"dodge": 0.0,
		"crit": 0.0,
		"modules": [null, null, null, null],
		"is_ally": creator.get("is_ally", false),
		"is_player": false,
		"is_dummy": true,
		"dummy_data": data,
		"creator_uid": creator.get("uid", -1),
		"remaining_cycles": data.duration_cycles,
		"spawned_cycle": current_cycle,
		"active_statuses": [],
		"runtime_effects": [],
		"module_targeting_history": []
	}
	var context := _make_context(
		CombatConstants.TriggerTiming.DUMMY_CREATED,
		creator,
		actor
	)

	for stat_formula in data.stat_formulas:
		if (
			stat_formula == null
			or stat_formula.formula == null
		):
			continue

		var value := _evaluate_formula(
			stat_formula.formula,
			creator,
			actor,
			actor,
			null,
			context
		)
		var key := CombatConstants.stat_key(
			stat_formula.stat
		)

		if not key.is_empty():
			actor[key] = value

	actor["max_hp"] = maxf(
		1.0,
		float(actor.get("max_hp", 1.0))
	)
	actor["hp"] = actor["max_hp"]
	actor["max_stability"] = maxf(
		0.0,
		float(actor.get("max_stability", 0.0))
	)
	actor["stability"] = actor["max_stability"]

	for status in data.initial_statuses:
		if status != null:
			_apply_status(
				creator,
				actor,
				status,
				status.default_stacks,
				context
			)

	return actor


func _append_timeline_action(
	actors: Array,
	runtime_slot: CombatRuntimeSlot
) -> void:
	var action_slot := runtime_slot.logical_index

	if action_slot >= actors.size():
		return

	var actor: Variant = actors[action_slot]

	if not (actor is Dictionary):
		return

	var modules: Array = actor.get("modules", [])
	var assignments: Array = actor.get("player_action_assignments", [])

	if bool(actor.get("is_player", false)) and action_slot < assignments.size():
		var assignment: Variant = assignments[action_slot]

		if assignment is Dictionary and not (assignment as Dictionary).is_empty():
			var player_action: PlayerActionData = _get_player_action(
				str(assignment.get("action_id", ""))
			)
			var target: Variant = _find_combatant_by_uid(
				int(assignment.get("target_uid", -1))
			)

			if player_action != null and target is Dictionary:
				current_cycle_actions.append({
					"action_kind": int(TimelineActionKind.PLAYER_ACTION),
					"actor": actor,
					"module": null,
					"player_action": player_action,
					"action_slot": action_slot,
					"action_slot_id": runtime_slot.slot_id,
					"position_slot_id": _get_actor_position_slot_id(actor),
					"target": target,
					"target_uid": int(target.get("uid", -1))
				})
				return

	if action_slot >= modules.size():
		return

	var module: ModuleData = modules[action_slot]

	if module == null:
		return

	var action := {
		"action_kind": int(TimelineActionKind.MODULE),
		"actor": actor,
		"module": module,
		"action_slot": action_slot,
		"action_slot_id": runtime_slot.slot_id,
		"position_slot_id": _get_actor_position_slot_id(
			actor
		),
		"target": null
	}
	action["target"] = _get_action_primary_target(
		action
	)
	current_cycle_actions.append(action)


func _get_action_primary_target(
	action: Dictionary
) -> Variant:
	var actor: Dictionary = action.get("actor", {})
	var module: ModuleData = action.get("module")

	if actor.is_empty() or module == null:
		return null

	var context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.MODULE_USED
	)

	for effect in module.combat_effects:
		if (
			effect == null
			or effect.target_selector == null
		):
			continue

		var targets := resolve_targets(
			effect.target_selector,
			actor,
			context,
			actor
		)

		if targets.size() == 1:
			return targets[0]

		if targets.size() > 1:
			return targets

	return null


func _execute_cycle_immediate() -> void:
	_begin_cycle()

	for index in range(
		current_cycle_actions.size()
	):
		_execute_action(
			index,
			current_cycle_actions[index]
		)

		if _has_terminal_state():
			_finish_terminal_cycle()
			return

	_finish_non_terminal_cycle()


func _execute_cycle_animated() -> void:
	_begin_cycle()
	var wait_time: float = 1.0

	for index in range(
		current_cycle_actions.size()
	):
		_execute_action(
			index,
			current_cycle_actions[index]
		)

		if _has_terminal_state():
			_finish_terminal_cycle()
			return

		await get_tree().create_timer(
			wait_time
		).timeout
		wait_time = maxf(
			0.15,
			wait_time * 0.70
		)

	_finish_non_terminal_cycle()


func _begin_cycle() -> void:
	_is_executing_cycle = true
	current_cycle += 1
	combat_tendency_log.begin_cycle()
	combat_log_added.emit(
		"\n[color=yellow]--- CYCLE %d ---[/color]"
		% current_cycle
	)
	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.CYCLE_START
		)
	)


func _execute_action(
	timeline_index: int,
	action: Dictionary
) -> void:
	var actor: Variant = action.get("actor")
	var module: ModuleData = action.get("module")
	var action_kind: int = int(action.get("action_kind", TimelineActionKind.MODULE))

	if (
		not (actor is Dictionary)
		or float(actor.get("hp", 0.0)) <= 0.0
	):
		return

	if action_kind == TimelineActionKind.PLAYER_ACTION:
		_execute_player_action(timeline_index, action)
		return

	if module == null:
		return

	var before_context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.BEFORE_ACTION,
		timeline_index
	)
	_dispatch_event(before_context)

	if float(actor.get("hp", 0.0)) <= 0.0:
		return

	var stability := float(
		actor.get("stability", 0.0)
	)

	if stability < module.stability_cost:
		combat_log_added.emit(
			"> %s lacks Stability for %s."
			% [
				actor.get("name", "Entity"),
				module.module_name
			]
		)
		floating_text_requested.emit(
			actor,
			"NO STB!",
			Color.GRAY
		)
	else:
		actor["stability"] = maxf(
			0.0,
			stability - module.stability_cost
		)

		if (
			module.stability_cost > 0
			and is_zero_approx(
				float(actor["stability"])
			)
		):
			_apply_status(
				actor,
				actor,
				UNSTABILITY_STATUS,
				1,
				before_context
			)

		combat_log_added.emit(
			"[color=cyan]%s[/color] activated [b]%s[/b]."
			% [
				actor.get("name", "Entity"),
				module.module_name
			]
		)

		var module_context := _context_from_action(
			action,
			CombatConstants.TriggerTiming.MODULE_USED,
			timeline_index
		)
		module_context.execution_count = (
			module.execution_count
		)
		_emit_module_presentation(
			CombatPresentationEvent.EventKind.MODULE_ACTION_STARTED,
			module_context,
			action.get("target")
		)
		_dispatch_event(module_context)

		for execution_index in range(
			module.execution_count
		):
			if float(actor.get("hp", 0.0)) <= 0.0:
				break

			var execution_context := (
				_context_from_action(
					action,
					CombatConstants.TriggerTiming.MODULE_USED,
					timeline_index
				)
			)
			execution_context.execution_index = (
				execution_index
			)
			execution_context.execution_count = (
				module.execution_count
			)
			_emit_module_presentation(
				CombatPresentationEvent.EventKind.MODULE_EXECUTION_STARTED,
				execution_context,
				action.get("target")
			)
			_execute_effects(
				actor,
				module.combat_effects,
				module,
				execution_context,
				actor
			)

		if bool(actor.get("is_player", false)):
			combat_tendency_log.record_module(module)

	action_executed.emit(
		timeline_index,
		action
	)
	stats_updated.emit()

	var after_context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.AFTER_ACTION,
		timeline_index
	)
	_dispatch_event(after_context)


func _execute_player_action(timeline_index: int, action: Dictionary) -> void:
	var actor: Dictionary = action.get("actor", {})
	var target: Variant = action.get("target")
	var player_action: PlayerActionData = action.get("player_action") as PlayerActionData

	if actor.is_empty() or target is not Dictionary or player_action == null:
		return

	var result: Dictionary = PlayerActionService.apply_slot(
		player_action,
		target as Dictionary,
		player_action_progress,
		combat_tendency_log
	)
	var errors: PackedStringArray = result.get("errors", PackedStringArray())

	if not errors.is_empty():
		for error: String in errors:
			combat_log_added.emit("> PLAYER ACTION FAILED: %s" % error)
		return

	var state: PlayerActionProgressData = result.get("state") as PlayerActionProgressData
	combat_log_added.emit(
		"[color=cyan]OPERATOR[/color] used [b]%s[/b] on %s (+%d%%)."
		% [player_action.display_name, target.get("name", "Entity"), player_action.progress_amount]
	)
	action_executed.emit(timeline_index, action)

	if state != null:
		player_action_progressed.emit(
			state.action_id,
			state.target_uid,
			state.progress,
			state.completed
		)

	if bool(result.get("completed_now", false)):
		combat_log_added.emit(
			"> %s reached 100%% on %s."
			% [player_action.display_name, target.get("name", "Entity")]
		)
		var choice_ids: PackedStringArray = result.get("choice_ids", PackedStringArray())

		if not choice_ids.is_empty():
			_pending_player_action_choice = {
				"action_id": player_action.action_id,
				"target_uid": int(target.get("uid", -1)),
				"module_ids": Array(choice_ids)
			}

		if bool(result.get("remove_target", false)):
			_record_resolved_enemy(target as Dictionary, false, true)
			_remove_actor_from_grid(target as Dictionary)

	stats_updated.emit()


func _execute_effects(
	caster: Dictionary,
	effects: Array[CombatEffectData],
	module: ModuleData,
	context: CombatEventContext,
	holder: Dictionary,
	status_instance: CombatStatusInstance = null
) -> void:
	for effect in effects:
		if effect == null:
			continue

		if (
			effect.effect_type
			== CombatEffectData.EffectType.SPAWN_DUMMY
		):
			_spawn_dummy(caster, effect, context)
			continue

		if effect.effect_type in [
			CombatEffectData.EffectType.SET_SLOT_ENABLED,
			CombatEffectData.EffectType.MOVE_ACTOR,
			CombatEffectData.EffectType.ADD_ACTION_SLOT,
			CombatEffectData.EffectType.MOVE_ACTION_SLOT
		]:
			_execute_slot_effect(
				caster,
				effect,
				context,
				holder
			)
			continue

		if effect.effect_type in [
			CombatEffectData.EffectType.MODIFY_DAMAGE_TAKEN,
			CombatEffectData.EffectType.MODIFY_DAMAGE_DEALT
		]:
			continue

		var targets := resolve_targets(
			effect.target_selector,
			caster,
			context,
			holder
		)

		if targets.is_empty():
			_fail_effect(
				caster,
				"No valid target for %s."
				% effect.describe()
			)
			continue

		for target in targets:
			_execute_effect_on_target(
				caster,
				target,
				module,
				effect,
				context,
				holder,
				status_instance
			)


func _execute_slot_effect(
	caster: Dictionary,
	effect: CombatEffectData,
	context: CombatEventContext,
	holder: Dictionary
) -> void:
	var slots := resolve_runtime_slots(
		effect.slot_selector,
		caster,
		context
	)

	match effect.effect_type:
		CombatEffectData.EffectType.SET_SLOT_ENABLED:
			if slots.is_empty():
				_fail_effect(
					caster,
					"No runtime slot matched."
				)
				return

			for slot in slots:
				slot.enabled = effect.slot_enabled
				combat_log_added.emit(
					"> %s was %s."
					% [
						slot.describe(),
						"enabled"
							if effect.slot_enabled
							else "disabled"
					]
				)

			runtime_slots_changed.emit()
			stats_updated.emit()
			_refresh_timeline_after_slot_change()

		CombatEffectData.EffectType.MOVE_ACTOR:
			if slots.is_empty():
				_fail_effect(
					caster,
					"No destination position matched."
				)
				return

			var targets := resolve_targets(
				effect.target_selector,
				caster,
				context,
				holder
			)

			if targets.is_empty():
				_fail_effect(
					caster,
					"No actor matched the move effect."
				)
				return

			var destination: CombatRuntimeSlot = slots[0]
			var moved: bool = move_actor_to_position(
				int(targets[0].get("uid", -1)),
				destination.slot_id,
				effect.swap_occupants_when_moving
			)

			if not moved:
				_fail_effect(
					caster,
					"Actor could not move to %s."
					% destination.describe()
				)

		CombatEffectData.EffectType.ADD_ACTION_SLOT:
			var add_for_ally := bool(
				caster.get("is_ally", false)
			)

			if not effect.add_action_for_caster_team:
				add_for_ally = not add_for_ally

			var insertion_index := action_slots.size()

			if not slots.is_empty():
				insertion_index = action_slots.find(
					slots[0]
				)

				if effect.insert_action_after_selection:
					insertion_index += 1

			var created_id := add_action_slot(
				add_for_ally,
				effect.added_action_actor_index,
				insertion_index
			)
			combat_log_added.emit(
				"> Added action slot %s."
				% created_id
			)

		CombatEffectData.EffectType.MOVE_ACTION_SLOT:
			if slots.is_empty():
				_fail_effect(
					caster,
					"No action slot matched."
				)
				return

			for slot in slots:
				move_action_slot(
					slot.slot_id,
					effect.destination_action_order
				)


func _execute_effect_on_target(
	caster: Dictionary,
	target: Dictionary,
	module: ModuleData,
	effect: CombatEffectData,
	context: CombatEventContext,
	holder: Dictionary,
	status_instance: CombatStatusInstance
) -> void:
	var amount := _evaluate_formula(
		effect.value_formula,
		caster,
		target,
		holder,
		status_instance,
		context
	)

	if status_instance == null:
		_emit_module_presentation(
			CombatPresentationEvent.EventKind.MODULE_TARGET_RESOLVED,
			context,
			target
		)

	match effect.effect_type:
		CombatEffectData.EffectType.DAMAGE:
			_apply_damage(
				caster,
				target,
				module,
				effect,
				amount,
				context,
				status_instance
			)

		CombatEffectData.EffectType.HEAL:
			_apply_heal(
				caster,
				target,
				amount
			)

		CombatEffectData.EffectType.MODIFY_STABILITY:
			_modify_stability(
				target,
				amount
			)

		CombatEffectData.EffectType.APPLY_STATUS:
			var stacks := maxi(
				1,
				int(amount)
			)
			var status_critical := (
				effect.can_crit
				and _roll_crit(caster)
			)

			if status_critical:
				stacks = maxi(
					1,
					int(roundf(
						stacks
						* effect.crit_multiplier
					))
				)

				if (
					effect.applies_unstability_on_crit
				):
					_apply_status(
						caster,
						target,
						UNSTABILITY_STATUS,
						1,
						context
					)

			_apply_status(
				caster,
				target,
				effect.status_effect,
				stacks,
				context
			)

		CombatEffectData.EffectType.REMOVE_STATUS:
			_remove_status(
				target,
				effect.status_id_to_remove,
				effect.remove_all_stacks,
				maxi(1, absi(int(amount))),
				context
			)

		CombatEffectData.EffectType.MODIFY_STAT:
			_modify_actor_stat(
				target,
				effect.target_stat,
				amount
			)

		CombatEffectData.EffectType.REDIRECT_NEXT_DAMAGE:
			_apply_redirect(
				caster,
				target,
				effect.redirect_duration_actions
			)


func _apply_damage(
	caster: Dictionary,
	original_target: Dictionary,
	module: ModuleData,
	effect: CombatEffectData,
	raw_amount: float,
	parent_context: CombatEventContext,
	status_instance: CombatStatusInstance = null
) -> void:
	var target: Variant = _resolve_redirect_target(
		original_target
	)

	if target == null:
		return

	_record_module_targeting(
		caster,
		target,
		module,
		parent_context
	)

	var accuracy := (
		effect.accuracy_override
		if effect.accuracy_override >= 0.0
		else (
			module.accuracy
			if module != null
			else 1.0
		)
	)

	if not _roll_accuracy(target, accuracy):
		combat_log_added.emit(
			"> %s missed %s."
			% [
				caster.get("name", "Entity"),
				target.get("name", "Entity")
			]
		)
		floating_text_requested.emit(
			target,
			"MISS!",
			Color.GRAY
		)

		if status_instance == null:
			_emit_module_presentation(
				CombatPresentationEvent.EventKind.MODULE_MISSED,
				parent_context,
				target
			)
		return

	if _consume_barrier_stack(
		caster,
		target,
		module,
		parent_context,
		status_instance
	):
		return

	var damage := _calculate_damage(
		caster,
		target,
		effect,
		raw_amount
	)
	var did_crit := (
		effect.can_crit
		and _roll_crit(caster)
	)

	if did_crit:
		damage = maxi(
			1,
			int(roundf(
				damage * effect.crit_multiplier
			))
		)

		if effect.applies_unstability_on_crit:
			_apply_status(
				caster,
				target,
				UNSTABILITY_STATUS,
				1,
				parent_context
			)

	target["hp"] = maxf(
		0.0,
		float(target.get("hp", 0.0))
		- damage
	)

	if bool(caster.get("is_player", false)) and not bool(target.get("is_ally", true)):
		combat_tendency_log.record_damage(damage, did_crit)

	if status_instance == null:
		_emit_module_presentation(
			CombatPresentationEvent.EventKind.MODULE_HIT,
			parent_context,
			target
		)

	var floating_text := "-%d" % damage
	var floating_color := Color.CRIMSON

	if did_crit:
		floating_text = "CRIT! -%d" % damage
		floating_color = Color.ORANGE_RED

	floating_text_requested.emit(
		target,
		floating_text,
		floating_color
	)
	combat_log_added.emit(
		"> %s took %d damage."
		% [
			target.get("name", "Entity"),
			damage
		]
	)

	var dealt_context := _make_context(
		CombatConstants.TriggerTiming.DAMAGE_DEALT,
		caster,
		target,
		module,
		parent_context.action_slot,
		parent_context.timeline_index,
		damage,
		parent_context.event_depth + 1,
		parent_context.action_slot_id,
		parent_context.position_slot_id,
		parent_context.execution_index,
		parent_context.execution_count
	)
	_dispatch_event(dealt_context)

	var received_context := _make_context(
		CombatConstants.TriggerTiming.DAMAGE_RECEIVED,
		caster,
		target,
		module,
		parent_context.action_slot,
		parent_context.timeline_index,
		damage,
		parent_context.event_depth + 1,
		parent_context.action_slot_id,
		parent_context.position_slot_id,
		parent_context.execution_index,
		parent_context.execution_count
	)
	_dispatch_event(received_context)

	if float(target.get("hp", 0.0)) <= 0.0:
		_defeat_actor(target, received_context)


func _consume_barrier_stack(
	caster: Dictionary,
	target: Dictionary,
	module: ModuleData,
	parent_context: CombatEventContext,
	status_instance: CombatStatusInstance = null
) -> bool:
	for instance in target.get(
		"active_statuses",
		[]
	).duplicate():
		if (
			not (instance is CombatStatusInstance)
			or instance.data == null
			or instance.data.damage_rule
			!= StatusEffectData.DamageRule.BARRIER
			or instance.stacks <= 0
		):
			continue

		var consumed := mini(
			instance.stacks,
			instance.data.stacks_consumed_per_hit
		)
		instance.stacks -= consumed
		floating_text_requested.emit(
			target,
			"BLOCKED!",
			Color.CYAN
		)
		combat_log_added.emit(
			"> %s's %s blocked the hit (%d left)."
			% [
				target.get("name", "Entity"),
				instance.data.display_name,
				instance.stacks
			]
		)

		if status_instance == null:
			_emit_module_presentation(
				CombatPresentationEvent.EventKind.MODULE_BLOCKED,
				parent_context,
				target
			)

		_emit_status_presentation(
			parent_context,
			target,
			target,
			instance.data
		)

		var blocked_context := _make_context(
			CombatConstants.TriggerTiming.DAMAGE_BLOCKED,
			caster,
			target,
			module,
			parent_context.action_slot,
			parent_context.timeline_index,
			0.0,
			parent_context.event_depth + 1,
			parent_context.action_slot_id,
			parent_context.position_slot_id,
			parent_context.execution_index,
			parent_context.execution_count
		)
		_dispatch_event(blocked_context)

		if instance.stacks <= 0:
			_expire_status(
				target,
				instance,
				blocked_context
			)

		stats_updated.emit()
		return true

	return false


func _record_module_targeting(
	caster: Dictionary,
	target: Dictionary,
	module: ModuleData,
	context: CombatEventContext
) -> void:
	if module == null:
		return

	var history: Array = target.get(
		"module_targeting_history",
		[]
	)
	history.append({
		"cycle": current_cycle,
		"source_uid": caster.get("uid", -1),
		"module_id": module.module_id,
		"classification": module.classification,
		"action_slot_id": context.action_slot_id
	})

	while history.size() > 32:
		history.pop_front()

	target["module_targeting_history"] = history


func _apply_heal(
	_caster: Dictionary,
	target: Dictionary,
	raw_amount: float
) -> void:
	var maximum := get_effective_stat(
		target,
		CombatConstants.Stat.MAX_HP
	)
	var previous := float(
		target.get("hp", 0.0)
	)
	target["hp"] = clampf(
		previous + maxf(0.0, raw_amount),
		0.0,
		maximum
	)
	var healed := int(roundf(
		float(target["hp"]) - previous
	))

	floating_text_requested.emit(
		target,
		"+%d" % healed,
		Color.LIME_GREEN
	)
	combat_log_added.emit(
		"> %s recovered %d HP."
		% [
			target.get("name", "Entity"),
			healed
		]
	)


func _modify_stability(
	target: Dictionary,
	amount: float
) -> void:
	var maximum := get_effective_stat(
		target,
		CombatConstants.Stat.MAX_STABILITY
	)
	target["stability"] = clampf(
		float(target.get("stability", 0.0))
		+ amount,
		0.0,
		maximum
	)
	var sign_text := "+" if amount >= 0.0 else ""
	floating_text_requested.emit(
		target,
		"%s%d STB"
		% [sign_text, int(roundf(amount))],
		Color.DODGER_BLUE
	)


func _modify_actor_stat(
	target: Dictionary,
	stat: CombatConstants.Stat,
	amount: float
) -> void:
	var key := CombatConstants.stat_key(stat)

	if key.is_empty() or stat in [
		CombatConstants.Stat.HP,
		CombatConstants.Stat.STABILITY
	]:
		return

	target[key] = float(
		target.get(key, 0.0)
	) + amount


func _apply_status(
	caster: Dictionary,
	target: Dictionary,
	status: StatusEffectData,
	stacks: int,
	parent_context: CombatEventContext
) -> void:
	if status == null:
		return

	var existing := _find_status_instance(
		target,
		status.status_id
	)

	if existing == null:
		existing = CombatStatusInstance.create(
			status,
			stacks,
			int(caster.get("uid", -1)),
			current_cycle
		)
		target["active_statuses"].append(
			existing
		)
	else:
		_stack_status(
			existing,
			status,
			stacks
		)

	combat_log_added.emit(
		"> %s gained %s (%d)."
		% [
			target.get("name", "Entity"),
			status.display_name,
			existing.stacks
		]
	)

	var applied_context := _make_context(
		CombatConstants.TriggerTiming.STATUS_APPLIED,
		caster,
		target,
		parent_context.module,
		parent_context.action_slot,
		parent_context.timeline_index,
		stacks,
		parent_context.event_depth + 1,
		parent_context.action_slot_id,
		parent_context.position_slot_id,
		parent_context.execution_index,
		parent_context.execution_count
	)
	applied_context.status = status
	_dispatch_event(applied_context)


func _stack_status(
	instance: CombatStatusInstance,
	status: StatusEffectData,
	added_stacks: int
) -> void:
	match status.stack_mode:
		StatusEffectData.StackMode.ADD:
			instance.stacks = clampi(
				instance.stacks + added_stacks,
				1,
				status.max_stacks
			)
		StatusEffectData.StackMode.REFRESH:
			pass
		StatusEffectData.StackMode.REPLACE:
			instance.stacks = clampi(
				added_stacks,
				1,
				status.max_stacks
			)
		StatusEffectData.StackMode.KEEP_HIGHEST:
			instance.stacks = clampi(
				maxi(
					instance.stacks,
					added_stacks
				),
				1,
				status.max_stacks
			)

	if status.refresh_duration_when_stacked:
		instance.remaining_cycles = (
			status.duration_cycles
		)
		instance.applied_cycle = current_cycle


func _remove_status(
	target: Dictionary,
	status_id: StringName,
	remove_all: bool,
	stack_amount: int,
	context: CombatEventContext
) -> void:
	var instance := _find_status_instance(
		target,
		status_id
	)

	if instance == null:
		return

	if remove_all:
		_expire_status(
			target,
			instance,
			context
		)
		return

	var remaining_stacks := (
		instance.stacks - stack_amount
	)

	if remaining_stacks <= 0:
		_expire_status(
			target,
			instance,
			context
		)
	else:
		instance.stacks = remaining_stacks


func _spawn_dummy(
	caster: Dictionary,
	effect: CombatEffectData,
	context: CombatEventContext
) -> void:
	if effect.dummy_data == null:
		_fail_effect(
			caster,
			"SPAWN_DUMMY has no DummyData."
		)
		return

	var team := (
		ally_team
		if bool(caster.get("is_ally", false))
		else enemy_team
	)
	var spawn_index := _find_dummy_spawn_slot(
		caster,
		team,
		effect
	)

	if spawn_index < 0:
		_fail_effect(
			caster,
			"No free slot for %s."
			% effect.dummy_data.display_name
		)
		return

	var dummy := _create_dummy(
		effect.dummy_data,
		caster
	)
	team[spawn_index] = dummy
	combat_log_added.emit(
		"> %s created %s in slot %d."
		% [
			caster.get("name", "Entity"),
			dummy.get("name", "Dummy"),
			spawn_index + 1
		]
	)
	stats_updated.emit()
	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.DUMMY_CREATED,
			caster,
			dummy,
			context.module,
			context.action_slot,
			context.timeline_index,
			0.0,
			context.event_depth + 1
		)
	)


func _apply_redirect(
	caster: Dictionary,
	target: Dictionary,
	duration_actions: int
) -> void:
	target["runtime_effects"].append({
		"type": &"redirect_next_damage",
		"redirect_to_uid": caster.get("uid", -1),
		"remaining_actions": maxi(
			1,
			duration_actions
		)
	})


func _dispatch_event(
	context: CombatEventContext
) -> void:
	if (
		context == null
		or context.event_depth > MAX_EVENT_DEPTH
	):
		if (
			context != null
			and context.event_depth > MAX_EVENT_DEPTH
		):
			push_error(
				"CombatManager: maximum event recursion reached."
			)
		return

	var actors := _all_combatants()

	for holder in actors:
		if holder == null:
			continue

		if (
			float(holder.get("hp", 0.0)) <= 0.0
			and context.timing not in [
				CombatConstants.TriggerTiming.DUMMY_DESTROYED,
				CombatConstants.TriggerTiming.DUMMY_EXPIRED,
				CombatConstants.TriggerTiming.STATUS_EXPIRED
			]
		):
			continue

		_process_status_triggers(
			holder,
			context
		)
		_process_dummy_triggers(
			holder,
			context
		)


func _process_status_triggers(
	holder: Dictionary,
	context: CombatEventContext
) -> void:
	var statuses: Array = holder.get(
		"active_statuses",
		[]
	).duplicate()

	for instance in statuses:
		if (
			not (instance is CombatStatusInstance)
			or instance.data == null
			or (
				instance.expiring
				and context.timing
				!= CombatConstants.TriggerTiming.STATUS_EXPIRED
			)
		):
			continue

		for triggered_effect in (
			instance.data.triggered_effects
		):
			if (
				triggered_effect == null
				or triggered_effect.trigger == null
				or triggered_effect.trigger.timing
				== CombatConstants.TriggerTiming.CONTINUOUS
				or not triggered_effect.trigger.matches(
					context,
					holder
				)
			):
				continue

			var trigger_key: int = (
				triggered_effect.get_instance_id()
			)

			if (
				triggered_effect.trigger_once_per_cycle
				and int(instance.last_triggered_cycle.get(
					trigger_key,
					-1
				)) == current_cycle
			):
				continue

			instance.last_triggered_cycle[
				trigger_key
			] = current_cycle
			var source: Variant = _find_combatant_by_uid(
				instance.source_uid
			)

			if source == null:
				source = holder

			_emit_status_presentation(
				context,
				source,
				holder,
				instance.data,
				triggered_effect
			)
			_execute_effects(
				source,
				triggered_effect.effects,
				context.module,
				context,
				holder,
				instance
			)

			if (
				triggered_effect.stack_delta_after_trigger
				!= 0
			):
				var resulting_stacks := clampi(
					instance.stacks
					+ triggered_effect.stack_delta_after_trigger,
					0,
					instance.data.max_stacks
				)

				if resulting_stacks <= 0:
					_expire_status(
						holder,
						instance,
						context
					)
					break
				else:
					instance.stacks = resulting_stacks


func _process_dummy_triggers(
	holder: Dictionary,
	context: CombatEventContext
) -> void:
	if not bool(holder.get("is_dummy", false)):
		return

	var data: DummyData = holder.get("dummy_data")

	if data == null:
		return

	for triggered_effect in data.triggered_effects:
		if (
			triggered_effect == null
			or triggered_effect.trigger == null
			or triggered_effect.trigger.timing
			== CombatConstants.TriggerTiming.CONTINUOUS
			or not triggered_effect.trigger.matches(
				context,
				holder
			)
		):
			continue

		_execute_effects(
			holder,
			triggered_effect.effects,
			context.module,
			context,
			holder
		)


func _finish_non_terminal_cycle() -> void:
	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.CYCLE_END
		)
	)

	if _has_terminal_state():
		_finish_terminal_cycle()
		return

	_recover_stability()
	_tick_status_durations()
	_tick_dummy_durations()
	_desfragment_enemies()
	stats_updated.emit()
	_is_executing_cycle = false
	_close_tendency_cycle()

	if _has_terminal_state():
		_finish_terminal_cycle()
		return

	cycle_completed.emit(current_cycle)
	_continue_after_cycle_boundary()


func _finish_terminal_cycle() -> void:
	if _awaiting_resolution:
		return

	_is_executing_cycle = false
	_close_tendency_cycle()
	_awaiting_resolution = true
	stats_updated.emit()
	cycle_completed.emit(current_cycle)

	if not _pending_player_action_choice.is_empty():
		_emit_pending_player_action_choice()
		return

	_emit_terminal_outcome()


func _emit_terminal_outcome() -> void:
	if _all_defeated(enemy_team):
		_pending_outcome = CombatResult.Outcome.VICTORY
		combat_log_added.emit(
			"\n[color=lime]>>> VICTORY <<<[/color]"
		)
		combat_victory.emit()
	elif _all_defeated(ally_team):
		_pending_outcome = CombatResult.Outcome.DEFEAT
		combat_log_added.emit(
			"\n[color=red]>>> DEFEAT <<<[/color]"
		)
		combat_defeat.emit()


func _close_tendency_cycle() -> void:
	if combat_tendency_log.cycles_elapsed < current_cycle:
		combat_tendency_log.finish_cycle()


func _continue_after_cycle_boundary() -> void:
	if _awaiting_resolution or not _encounter_active:
		return

	if not _pending_player_action_choice.is_empty():
		_emit_pending_player_action_choice()
		return

	var branch: EvolutionBranchData = EvolutionManager.find_valid_branch(
		combat_tendency_log,
		_completed_evolution_branch_ids
	)

	if branch != null:
		_pending_evolution_branch_id = branch.branch_id
		EvolutionManager.offer(branch)
		evolution_prompt_requested.emit(branch)

		if branch.forced_if_valid and not branch.prompt_player:
			accept_pending_evolution()

		return

	rebuild_timeline()
	cycle_ended_ready_for_next.emit()


func _emit_pending_player_action_choice() -> void:
	if _pending_player_action_choice.is_empty():
		return

	player_action_choice_requested.emit(
		str(_pending_player_action_choice.get("action_id", "")),
		int(_pending_player_action_choice.get("target_uid", -1)),
		_read_string_array(_pending_player_action_choice.get("module_ids", []))
	)


func _recover_stability() -> void:
	for actor in _all_combatants():
		if (
			actor == null
			or float(actor.get("hp", 0.0)) <= 0.0
		):
			continue

		var recovery := get_effective_stat(
			actor,
			CombatConstants.Stat.STABILITY_RECOVERY
		)
		var maximum := get_effective_stat(
			actor,
			CombatConstants.Stat.MAX_STABILITY
		)
		actor["stability"] = clampf(
			float(actor.get("stability", 0.0))
			+ recovery,
			0.0,
			maximum
		)


func _tick_status_durations() -> void:
	for actor in _all_combatants():
		if actor == null:
			continue

		var statuses: Array = actor.get(
			"active_statuses",
			[]
		).duplicate()

		for instance in statuses:
			if (
				not (instance is CombatStatusInstance)
				or instance.data == null
				or instance.remaining_cycles < 0
			):
				continue

			if (
				instance.applied_cycle == current_cycle
				and not instance.data.tick_on_application_cycle
			):
				continue

			instance.remaining_cycles -= 1

			if instance.remaining_cycles <= 0:
				_expire_status(
					actor,
					instance,
					_make_context(
						CombatConstants.TriggerTiming.STATUS_EXPIRED,
						actor,
						actor
					)
				)


func _tick_dummy_durations() -> void:
	var actors := _all_combatants()

	for actor in actors:
		if (
			actor == null
			or not bool(actor.get("is_dummy", false))
			or int(actor.get("remaining_cycles", -1)) < 0
			or int(actor.get("spawned_cycle", -1))
			== current_cycle
		):
			continue

		actor["remaining_cycles"] = int(
			actor["remaining_cycles"]
		) - 1

		if int(actor["remaining_cycles"]) <= 0:
			var context := _make_context(
				CombatConstants.TriggerTiming.DUMMY_EXPIRED,
				actor,
				actor
			)
			_dispatch_event(context)
			_remove_actor_from_grid(actor)


func _expire_status(
	holder: Dictionary,
	instance: CombatStatusInstance,
	parent_context: CombatEventContext
) -> void:
	var statuses: Array = holder.get(
		"active_statuses",
		[]
	)

	if not statuses.has(instance):
		return

	if instance.expiring:
		return

	instance.expiring = true
	var expired_context := _make_context(
		CombatConstants.TriggerTiming.STATUS_EXPIRED,
		holder,
		holder,
		parent_context.module,
		parent_context.action_slot,
		parent_context.timeline_index,
		0.0,
		parent_context.event_depth + 1,
		parent_context.action_slot_id,
		parent_context.position_slot_id,
		parent_context.execution_index,
		parent_context.execution_count
	)
	expired_context.status = instance.data
	_dispatch_event(expired_context)
	statuses.erase(instance)


func _defeat_actor(
	actor: Dictionary,
	parent_context: CombatEventContext
) -> void:
	if not bool(actor.get("is_dummy", false)):
		if bool(actor.get("is_player", false)):
			_player_resolution_record = actor.duplicate(true)
		elif bool(actor.get("is_ally", false)):
			combat_tendency_log.allies_defeated += 1
		elif not bool(actor.get("is_ally", true)):
			combat_tendency_log.enemies_defeated += 1
			_record_resolved_enemy(actor, true, false)

	if bool(actor.get("is_dummy", false)):
		_dispatch_event(
			_make_context(
				CombatConstants.TriggerTiming.DUMMY_DESTROYED,
				parent_context.source,
				actor,
				parent_context.module,
				parent_context.action_slot,
				parent_context.timeline_index,
				0.0,
				parent_context.event_depth + 1
			)
		)

	_remove_actor_from_grid(actor)


func _remove_actor_from_grid(
	actor: Dictionary
) -> void:
	for team in [ally_team, enemy_team]:
		for index in range(team.size()):
			if team[index] == actor:
				team[index] = null
				stats_updated.emit()
				return


func _calculate_damage(
	caster: Dictionary,
	target: Dictionary,
	effect: CombatEffectData,
	raw_amount: float
) -> int:
	var damage := maxf(
		0.0,
		raw_amount
	)

	if not effect.ignore_defense:
		damage -= get_effective_stat(
			target,
			effect.defense_stat
		)

	damage = maxf(1.0, damage)
	damage *= _continuous_multiplier(
		caster,
		CombatEffectData.EffectType.MODIFY_DAMAGE_DEALT
	)
	damage *= _continuous_multiplier(
		target,
		CombatEffectData.EffectType.MODIFY_DAMAGE_TAKEN
	)
	return maxi(
		1,
		int(roundf(damage))
	)


func _continuous_multiplier(
	actor: Dictionary,
	effect_type: CombatEffectData.EffectType
) -> float:
	var multiplier: float = 1.0

	for binding in _continuous_bindings():
		var holder: Dictionary = binding["holder"]
		var source: Dictionary = binding["source"]
		var instance: CombatStatusInstance = (
			binding["status_instance"]
		)
		var triggered_effect: CombatTriggeredEffectData = (
			binding["triggered_effect"]
		)

		for effect in triggered_effect.effects:
			if (
				effect == null
				or effect.effect_type != effect_type
				or not _effect_targets_actor(
					effect,
					holder,
					actor
				)
			):
				continue

			multiplier *= maxf(
				0.0,
				_evaluate_formula(
					effect.value_formula,
					source,
					actor,
					holder,
					instance,
					null
				)
			)

	return multiplier


func _get_effective_stat(
	actor: Dictionary,
	stat: CombatConstants.Stat,
	depth: int
) -> float:
	var key := CombatConstants.stat_key(stat)
	var value := float(actor.get(key, 0.0))

	if depth > 8:
		return value

	for binding in _continuous_bindings():
		var holder: Dictionary = binding["holder"]
		var source: Dictionary = binding["source"]
		var instance: CombatStatusInstance = (
			binding["status_instance"]
		)
		var triggered_effect: CombatTriggeredEffectData = (
			binding["triggered_effect"]
		)

		for effect in triggered_effect.effects:
			if (
				effect == null
				or effect.effect_type
				!= CombatEffectData.EffectType.MODIFY_STAT
				or effect.target_stat != stat
				or not _effect_targets_actor(
					effect,
					holder,
					actor
				)
			):
				continue

			value += _evaluate_formula(
				effect.value_formula,
				source,
				actor,
				holder,
				instance,
				null,
				depth + 1
			)

	return maxf(0.0, value)


func _evaluate_formula(
	formula: CombatValueFormula,
	caster: Dictionary,
	target: Dictionary,
	holder: Dictionary,
	status_instance: CombatStatusInstance,
	context: CombatEventContext,
	stat_depth: int = 0
) -> float:
	if formula == null:
		return 0.0

	var value := formula.base_value
	var reference_actor: Variant = _resolve_formula_actor(
		formula.stat_reference,
		caster,
		target,
		holder,
		context
	)

	if (
		reference_actor != null
		and not is_zero_approx(
			formula.stat_multiplier
		)
	):
		var stat_value := _base_stat(
			reference_actor,
			formula.stat
		)

		if formula.use_effective_stat:
			stat_value = _get_effective_stat(
				reference_actor,
				formula.stat,
				stat_depth + 1
			)

		value += (
			stat_value
			* formula.stat_multiplier
		)

	if (
		status_instance != null
		and not is_zero_approx(
			formula.stack_multiplier
		)
	):
		value += (
			status_instance.stacks
			* formula.stack_multiplier
		)

	if formula.use_minimum:
		value = maxf(
			value,
			formula.minimum_value
		)

	if formula.use_maximum:
		value = minf(
			value,
			formula.maximum_value
		)

	match formula.round_mode:
		CombatValueFormula.RoundMode.ROUND:
			return roundf(value)
		CombatValueFormula.RoundMode.FLOOR:
			return floorf(value)
		CombatValueFormula.RoundMode.CEIL:
			return ceilf(value)

	return value


func _resolve_formula_actor(
	reference: CombatValueFormula.ReferenceActor,
	caster: Dictionary,
	target: Dictionary,
	holder: Dictionary,
	context: CombatEventContext
) -> Variant:
	match reference:
		CombatValueFormula.ReferenceActor.CASTER:
			return caster
		CombatValueFormula.ReferenceActor.TARGET:
			return target
		CombatValueFormula.ReferenceActor.STATUS_HOLDER:
			return holder
		CombatValueFormula.ReferenceActor.EVENT_SOURCE:
			return (
				context.source
				if context != null
				else null
			)
		CombatValueFormula.ReferenceActor.EVENT_TARGET:
			return (
				context.target
				if context != null
				else null
			)
		CombatValueFormula.ReferenceActor.DUMMY_CREATOR:
			var creator_uid := int(
				holder.get(
					"creator_uid",
					caster.get("creator_uid", -1)
				)
			)
			return _find_combatant_by_uid(
				creator_uid
			)

	return null


func _preview_effect(
	caster: Dictionary,
	target: Dictionary,
	module: ModuleData,
	effect: CombatEffectData,
	context: CombatEventContext,
	virtual_barriers: Dictionary
) -> Dictionary:
	var amount := _evaluate_formula(
		effect.value_formula,
		caster,
		target,
		caster,
		null,
		context
	)
	var entry := {
		"target_uid": target.get("uid", -1),
		"target_name": target.get("name", "Entity"),
		"hp_delta": 0,
		"stability_delta": 0,
		"summary": effect.describe()
	}

	match effect.effect_type:
		CombatEffectData.EffectType.DAMAGE:
			var target_uid := int(
				target.get("uid", -1)
			)

			if not virtual_barriers.has(target_uid):
				virtual_barriers[target_uid] = (
					get_barrier_stacks(target)
				)

			var barrier_stacks := int(
				virtual_barriers[target_uid]
			)

			if barrier_stacks > 0:
				var consumption := (
					_get_barrier_consumption(target)
				)
				virtual_barriers[target_uid] = maxi(
					0,
					barrier_stacks - consumption
				)
				entry["summary"] = (
					"%s: BLOCKED (%d barrier left)"
					% [
						target.get("name", "Entity"),
						virtual_barriers[target_uid]
					]
				)
				return entry

			var damage := _calculate_damage(
				caster,
				target,
				effect,
				amount
			)
			entry["hp_delta"] = -damage
			entry["summary"] = "%s: -%d HP" % [
				target.get("name", "Entity"),
				damage
			]

		CombatEffectData.EffectType.HEAL:
			var missing_hp := maxi(
				0,
				int(roundf(
					get_effective_stat(
						target,
						CombatConstants.Stat.MAX_HP
					)
					- float(target.get("hp", 0.0))
				))
			)
			var healing := mini(
				missing_hp,
				maxi(0, int(amount))
			)
			entry["hp_delta"] = healing
			entry["summary"] = "%s: +%d HP" % [
				target.get("name", "Entity"),
				healing
			]

		CombatEffectData.EffectType.MODIFY_STABILITY:
			entry["stability_delta"] = int(amount)
			entry["summary"] = "%s: %+d STB" % [
				target.get("name", "Entity"),
				int(amount)
			]

	return entry


func _merge_preview_entry(
	entries: Array,
	entry: Dictionary
) -> void:
	for existing in entries:
		if (
			int(existing.get("target_uid", -1))
			!= int(entry.get("target_uid", -1))
		):
			continue

		existing["hp_delta"] = int(
			existing.get("hp_delta", 0)
		) + int(entry.get("hp_delta", 0))
		existing["stability_delta"] = int(
			existing.get("stability_delta", 0)
		) + int(entry.get("stability_delta", 0))
		existing["summary"] = "%s | %s" % [
			existing.get("summary", ""),
			entry.get("summary", "")
		]
		return

	entries.append(entry)


func _get_barrier_consumption(
	actor: Dictionary
) -> int:
	for instance in actor.get("active_statuses", []):
		if (
			instance is CombatStatusInstance
			and instance.data != null
			and instance.data.damage_rule
			== StatusEffectData.DamageRule.BARRIER
		):
			return maxi(
				1,
				instance.data.stacks_consumed_per_hit
			)

	return 1


func _base_stat(
	actor: Dictionary,
	stat: CombatConstants.Stat
) -> float:
	return float(
		actor.get(
			CombatConstants.stat_key(stat),
			0.0
		)
	)


func _effect_targets_actor(
	effect: CombatEffectData,
	holder: Dictionary,
	target_actor: Dictionary
) -> bool:
	if effect.target_selector == null:
		return false

	var targets := resolve_targets(
		effect.target_selector,
		holder,
		null,
		holder
	)

	for target in targets:
		if (
			int(target.get("uid", -1))
			== int(target_actor.get("uid", -1))
		):
			return true

	return false


func _continuous_bindings() -> Array[Dictionary]:
	var bindings: Array[Dictionary] = []

	for holder in _all_combatants():
		for instance in holder.get(
			"active_statuses",
			[]
		):
			if (
				not (instance is CombatStatusInstance)
				or instance.data == null
			):
				continue

			var source: Variant = _find_combatant_by_uid(
				instance.source_uid
			)

			if source == null:
				source = holder

			for triggered_effect in (
				instance.data.triggered_effects
			):
				if (
					triggered_effect != null
					and triggered_effect.trigger != null
					and triggered_effect.trigger.timing
					== CombatConstants.TriggerTiming.CONTINUOUS
				):
					bindings.append({
						"holder": holder,
						"source": source,
						"status_instance": instance,
						"triggered_effect": triggered_effect
					})

		if bool(holder.get("is_dummy", false)):
			var data: DummyData = holder.get(
				"dummy_data"
			)

			if data == null:
				continue

			for triggered_effect in data.triggered_effects:
				if (
					triggered_effect != null
					and triggered_effect.trigger != null
					and triggered_effect.trigger.timing
					== CombatConstants.TriggerTiming.CONTINUOUS
				):
					bindings.append({
						"holder": holder,
						"source": holder,
						"status_instance": null,
						"triggered_effect": triggered_effect
					})

	return bindings


func _get_direct_enemy_target(
	attacker_index: int,
	opposing_team: Array
) -> Variant:
	var alive_targets := _get_valid_targets(
		opposing_team,
		false
	)

	if alive_targets.is_empty():
		return null

	if alive_targets.size() == 1:
		return alive_targets[0]

	if alive_targets.size() == 2:
		return (
			alive_targets[0]
			if attacker_index <= 1
			else alive_targets[1]
		)

	if alive_targets.size() == 3:
		return _get_closest_target_by_slot(
			attacker_index,
			opposing_team
		)

	if (
		attacker_index >= 0
		and attacker_index < opposing_team.size()
		and _is_valid_target(
			opposing_team[attacker_index],
			false
		)
	):
		return opposing_team[attacker_index]

	return _get_closest_target_by_slot(
		attacker_index,
		opposing_team
	)


func _get_adjacent_ally(
	actor_index: int,
	team: Array
) -> Variant:
	if actor_index < 0:
		return null

	for index in [
		actor_index + 1,
		actor_index - 1
	]:
		if (
			index >= 0
			and index < team.size()
			and _is_valid_target(
				team[index],
				false
			)
		):
			return team[index]

	return _get_closest_target_by_slot(
		actor_index,
		team
	)


func _get_closest_target_by_slot(
	origin_index: int,
	team: Array
) -> Variant:
	var closest: Variant = null
	var closest_distance: int = 999

	for index in range(team.size()):
		if not _is_valid_target(
			team[index],
			false
		):
			continue

		var distance := absi(
			origin_index - index
		)

		if distance < closest_distance:
			closest_distance = distance
			closest = team[index]

	return closest


func _target_from_slot(
	team: Array,
	slot_index: int,
	selector: CombatTargetSelector
) -> Array:
	var target: Variant = team[slot_index]

	if _is_valid_target(
		target,
		selector.include_defeated
	):
		return [target]

	if selector.fallback_to_closest:
		var fallback: Variant = _get_closest_target_by_slot(
			slot_index,
			team
		)
		if fallback != null:
			return [fallback]

	return []


func _variant_as_target_array(
	value: Variant,
	include_defeated: bool
) -> Array:
	var result: Array = []

	if value is Array:
		for target in value:
			if _is_valid_target(
				target,
				include_defeated
			):
				result.append(target)
	elif _is_valid_target(value, include_defeated):
		result.append(value)

	return result


func _get_valid_targets(
	team: Array,
	include_defeated: bool
) -> Array:
	var result: Array = []

	for actor in team:
		if _is_valid_target(
			actor,
			include_defeated
		):
			result.append(actor)

	return result


func _is_valid_target(
	actor: Variant,
	include_defeated: bool
) -> bool:
	return (
		actor is Dictionary
		and (
			include_defeated
			or float(actor.get("hp", 0.0)) > 0.0
		)
	)


func _get_timeline_actors(
	team: Array
) -> Array:
	var secondary: Array = []
	var main_actor: Variant = null

	if (
		_is_valid_target(team[1], false)
		and not bool(team[1].get("is_dummy", false))
	):
		main_actor = team[1]

	for actor in team:
		if (
			_is_valid_target(actor, false)
			and actor != main_actor
			and not bool(actor.get("is_dummy", false))
		):
			secondary.append(actor)

	if main_actor == null and not secondary.is_empty():
		main_actor = secondary.pop_front()

	var actor_count := secondary.size() + (
		1 if main_actor != null else 0
	)

	match actor_count:
		0:
			return []
		1:
			return [
				main_actor,
				main_actor,
				main_actor,
				main_actor
			]
		2:
			return [
				main_actor,
				main_actor,
				secondary[0],
				secondary[0]
			]
		3:
			return [
				main_actor,
				main_actor,
				secondary[0],
				secondary[1]
			]
		4:
			return [
				main_actor,
				secondary[0],
				secondary[1],
				secondary[2]
			]

	return []


func _find_dummy_spawn_slot(
	caster: Dictionary,
	team: Array,
	effect: CombatEffectData
) -> int:
	var caster_index := team.find(caster)

	match effect.spawn_slot_rule:
		CombatEffectData.SpawnSlotRule.FIRST_EMPTY, CombatEffectData.SpawnSlotRule.LEFTMOST_EMPTY:
			for index in range(team.size()):
				if (
					team[index] == null
					and _position_accepts_new_actor(
						team,
						index
					)
				):
					return index

		CombatEffectData.SpawnSlotRule.RIGHTMOST_EMPTY:
			for index in range(
				team.size() - 1,
				-1,
				-1
			):
				if (
					team[index] == null
					and _position_accepts_new_actor(
						team,
						index
					)
				):
					return index

		CombatEffectData.SpawnSlotRule.ADJACENT_LEFT:
			var left := caster_index - 1
			if (
				left >= 0
				and team[left] == null
				and _position_accepts_new_actor(
					team,
					left
				)
			):
				return left

		CombatEffectData.SpawnSlotRule.ADJACENT_RIGHT:
			var right := caster_index + 1
			if (
				right < team.size()
				and team[right] == null
				and _position_accepts_new_actor(
					team,
					right
				)
			):
				return right

		CombatEffectData.SpawnSlotRule.SPECIFIC_SLOT:
			if (
				team[effect.specific_spawn_slot]
				== null
				and _position_accepts_new_actor(
					team,
					effect.specific_spawn_slot
				)
			):
				return effect.specific_spawn_slot

	return -1


func _position_accepts_new_actor(
	team: Array,
	slot_index: int
) -> bool:
	var is_ally_team := is_same(team, ally_team)
	var slot := get_position_slot(
		is_ally_team,
		slot_index
	)
	return slot != null and slot.enabled


func _resolve_redirect_target(
	original_target: Dictionary
) -> Variant:
	var effects: Array = original_target.get(
		"runtime_effects",
		[]
	)

	for index in range(
		effects.size() - 1,
		-1,
		-1
	):
		var effect: Dictionary = effects[index]

		if (
			effect.get("type")
			!= &"redirect_next_damage"
		):
			continue

		var redirect_target: Variant = _find_combatant_by_uid(
			int(effect.get("redirect_to_uid", -1))
		)
		effect["remaining_actions"] = int(
			effect.get("remaining_actions", 1)
		) - 1

		if int(effect["remaining_actions"]) <= 0:
			effects.remove_at(index)

		if (
			redirect_target != null
			and float(redirect_target.get("hp", 0.0))
			> 0.0
		):
			return redirect_target

	return original_target


func _find_status_instance(
	actor: Dictionary,
	status_id: StringName
) -> CombatStatusInstance:
	for instance in actor.get(
		"active_statuses",
		[]
	):
		if (
			instance is CombatStatusInstance
			and instance.data != null
			and instance.data.status_id == status_id
		):
			return instance

	return null


func _find_combatant_by_uid(
	uid: int
) -> Variant:
	if uid < 0:
		return null

	for actor in _all_combatants():
		if (
			actor != null
			and int(actor.get("uid", -1)) == uid
		):
			return actor

	return null


func _get_player_actor() -> Variant:
	for actor in ally_team:
		if (
			actor != null
			and bool(actor.get("is_player", false))
		):
			return actor

	return null


func _get_player_resolution_actor() -> Variant:
	var active_player: Variant = _get_player_actor()

	if active_player is Dictionary:
		return active_player

	return _player_resolution_record if not _player_resolution_record.is_empty() else null


func _get_player_action(action_id: String) -> PlayerActionData:
	if _current_encounter == null or _current_encounter.resolution == null:
		return null

	return _current_encounter.resolution.get_player_action(action_id)


func _record_resolved_enemy(
	actor: Dictionary,
	defeated: bool,
	tamed: bool
) -> void:
	var uid: int = int(actor.get("uid", -1))
	var record: Dictionary = actor.duplicate(true)
	record["defeated"] = defeated
	record["tamed"] = tamed

	for index: int in range(_resolved_enemy_records.size()):
		if int(_resolved_enemy_records[index].get("uid", -1)) == uid:
			_resolved_enemy_records[index] = record
			return

	_resolved_enemy_records.append(record)


func _get_enemy_resolution_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_uids: Array[int] = []

	for record: Dictionary in _resolved_enemy_records:
		result.append(record.duplicate(true))
		seen_uids.append(int(record.get("uid", -1)))

	for actor: Variant in enemy_team:
		if actor is not Dictionary:
			continue

		var uid: int = int(actor.get("uid", -1))

		if seen_uids.has(uid):
			continue

		var living_record: Dictionary = (actor as Dictionary).duplicate(true)
		living_record["defeated"] = false
		result.append(living_record)

	return result


func _refresh_player_actor_from_partner() -> void:
	var player: Variant = _get_player_actor()
	var snapshot: CharacterLoadout = APKProgressionService.create_combat_snapshot()

	if player is not Dictionary or snapshot == null:
		return

	var assignments: Array = player.get("player_action_assignments", []).duplicate(true)
	var statuses: Array = player.get("active_statuses", []).duplicate()
	var refreshed: Dictionary = _create_combatant(
		snapshot,
		true,
		true,
		CombatSlotData.ParticipantSource.PLAYER_PARTNER,
		int(player.get("encounter_slot_index", 0)),
		null
	)
	refreshed["uid"] = int(player.get("uid", -1))
	refreshed["player_action_assignments"] = assignments
	refreshed["active_statuses"] = statuses

	for key: Variant in refreshed:
		player[key] = refreshed[key]

	stats_updated.emit()


func _reward_profile_for_actor(
	is_ally: bool,
	encounter_slot_index: int
) -> CombatRewardData:
	if _current_encounter == null:
		return null

	var slots: Array[CombatSlotData] = (
		_current_encounter.ally_slots
		if is_ally
		else _current_encounter.enemy_slots
	)

	for slot: CombatSlotData in slots:
		if slot != null and slot.slot_index == encounter_slot_index:
			return slot.reward_profile

	return null


func _all_combatants() -> Array:
	var actors: Array = []

	for actor in ally_team + enemy_team:
		if actor != null:
			actors.append(actor)

	return actors


func _serialize_team(team: Array) -> Array:
	var serialized: Array = []

	for index in range(TEAM_SIZE):
		var actor: Variant = team[index] if index < team.size() else null
		serialized.append(
			_serialize_actor(actor)
			if actor is Dictionary
			else null
		)

	return serialized


func _deserialize_team(raw_team: Variant) -> Array:
	var team: Array = [null, null, null, null]

	if raw_team is not Array:
		return team

	for index in range(mini(TEAM_SIZE, raw_team.size())):
		if raw_team[index] is Dictionary:
			team[index] = _deserialize_actor(raw_team[index])

	return team


func _serialize_actor(actor: Dictionary) -> Dictionary:
	var module_ids: Array[String] = []

	for raw_module: Variant in actor.get("modules", []):
		var module := raw_module as ModuleData
		module_ids.append(str(module.module_id) if module != null else "")

	while module_ids.size() < TEAM_SIZE:
		module_ids.append("")

	var statuses: Array[Dictionary] = []

	for raw_instance: Variant in actor.get("active_statuses", []):
		if raw_instance is CombatStatusInstance:
			statuses.append(_serialize_status_instance(
				raw_instance as CombatStatusInstance
			))

	var dummy := actor.get("dummy_data") as DummyData
	return {
		"uid": int(actor.get("uid", -1)),
		"character_id": str(actor.get("character_id", "")),
		"source_kind": int(actor.get("source_kind", CombatSlotData.ParticipantSource.FIXED_LOADOUT)),
		"encounter_slot_index": int(actor.get("encounter_slot_index", -1)),
		"name": str(actor.get("name", "Entity")),
		"level": int(actor.get("level", 1)),
		"type": int(actor.get("type", 0)),
		"hp": float(actor.get("hp", 0.0)),
		"max_hp": float(actor.get("max_hp", 1.0)),
		"stability": float(actor.get("stability", 0.0)),
		"max_stability": float(actor.get("max_stability", 0.0)),
		"stability_recovery": float(actor.get("stability_recovery", 0.0)),
		"atk": float(actor.get("atk", 0.0)),
		"def": float(actor.get("def", 0.0)),
		"matk": float(actor.get("matk", 0.0)),
		"mdef": float(actor.get("mdef", 0.0)),
		"dodge": float(actor.get("dodge", 0.0)),
		"crit": float(actor.get("crit", 0.0)),
		"modules": module_ids,
		"player_action_assignments": _plain_copy(actor.get("player_action_assignments", [])),
		"purged": bool(actor.get("purged", false)),
		"purified": bool(actor.get("purified", false)),
		"tamed": bool(actor.get("tamed", false)),
		"defeated": bool(actor.get("defeated", false)),
		"is_ally": bool(actor.get("is_ally", false)),
		"is_player": bool(actor.get("is_player", false)),
		"is_dummy": bool(actor.get("is_dummy", false)),
		"dummy_id": str(dummy.dummy_id) if dummy != null else "",
		"creator_uid": int(actor.get("creator_uid", -1)),
		"remaining_cycles": int(actor.get("remaining_cycles", -1)),
		"spawned_cycle": int(actor.get("spawned_cycle", -1)),
		"active_statuses": statuses,
		"runtime_effects": _plain_copy(actor.get("runtime_effects", [])),
		"module_targeting_history": _plain_copy(
			actor.get("module_targeting_history", [])
		)
	}


func _deserialize_actor(data: Dictionary) -> Dictionary:
	var is_dummy: bool = bool(data.get("is_dummy", false))
	var character_id: String = str(data.get("character_id", ""))
	var source_kind: int = int(data.get("source_kind", CombatSlotData.ParticipantSource.FIXED_LOADOUT))
	var encounter_slot_index: int = int(data.get("encounter_slot_index", -1))
	var dummy: DummyData = null
	var loadout: CharacterLoadout = null

	if is_dummy:
		dummy = ContentRegistry.get_dummy(str(data.get("dummy_id", character_id)))
	elif source_kind == CombatSlotData.ParticipantSource.FIXED_LOADOUT:
		loadout = ContentRegistry.get_character_loadout(character_id)

	var modules: Array = []
	var raw_modules: Variant = data.get("modules", [])

	if raw_modules is Array:
		for raw_module_id: Variant in raw_modules:
			modules.append(ContentRegistry.get_module(str(raw_module_id)))

	modules.resize(TEAM_SIZE)
	var statuses: Array = []
	var raw_statuses: Variant = data.get("active_statuses", [])

	if raw_statuses is Array:
		for raw_status: Variant in raw_statuses:
			if raw_status is Dictionary:
				var instance := _deserialize_status_instance(raw_status)

				if instance != null:
					statuses.append(instance)

	var actor_icon: Texture2D = null

	if dummy != null:
		actor_icon = dummy.combat_icon
	elif source_kind == CombatSlotData.ParticipantSource.PLAYER_PARTNER:
		var apk: APKData = ContentRegistry.get_apk(character_id)

		if apk != null:
			actor_icon = apk.combat_icon
	elif loadout != null:
		actor_icon = loadout.combat_icon

	return {
		"uid": int(data.get("uid", -1)),
		"character_id": character_id,
		"source_kind": source_kind,
		"encounter_slot_index": encounter_slot_index,
		"reward_profile": _reward_profile_for_actor(bool(data.get("is_ally", false)), encounter_slot_index),
		"name": str(data.get("name", "Entity")),
		"icon": actor_icon,
		"level": int(data.get("level", 1)),
		"type": int(data.get("type", 0)),
		"hp": float(data.get("hp", 0.0)),
		"max_hp": float(data.get("max_hp", 1.0)),
		"stability": float(data.get("stability", 0.0)),
		"max_stability": float(data.get("max_stability", 0.0)),
		"stability_recovery": float(data.get("stability_recovery", 0.0)),
		"atk": float(data.get("atk", 0.0)),
		"def": float(data.get("def", 0.0)),
		"matk": float(data.get("matk", 0.0)),
		"mdef": float(data.get("mdef", 0.0)),
		"dodge": float(data.get("dodge", 0.0)),
		"crit": float(data.get("crit", 0.0)),
		"modules": modules,
		"player_action_assignments": _read_action_assignments(data.get("player_action_assignments", [])),
		"purged": bool(data.get("purged", false)),
		"purified": bool(data.get("purified", false)),
		"tamed": bool(data.get("tamed", false)),
		"defeated": bool(data.get("defeated", false)),
		"is_ally": bool(data.get("is_ally", false)),
		"is_player": bool(data.get("is_player", false)),
		"is_dummy": is_dummy,
		"dummy_data": dummy,
		"creator_uid": int(data.get("creator_uid", -1)),
		"remaining_cycles": int(data.get("remaining_cycles", -1)),
		"spawned_cycle": int(data.get("spawned_cycle", -1)),
		"active_statuses": statuses,
		"runtime_effects": _deserialize_runtime_effects(
			data.get("runtime_effects", [])
		),
		"module_targeting_history": _deserialize_targeting_history(
			data.get("module_targeting_history", [])
		)
	}


func _serialize_status_instance(instance: CombatStatusInstance) -> Dictionary:
	var trigger_cycles: Array[int] = []

	for triggered_effect: CombatTriggeredEffectData in instance.data.triggered_effects:
		if triggered_effect == null:
			trigger_cycles.append(-1)
			continue

		trigger_cycles.append(
			int(instance.last_triggered_cycle.get(
				triggered_effect.get_instance_id(),
				-1
			))
		)

	return {
		"status_id": str(instance.data.status_id),
		"stacks": instance.stacks,
		"remaining_cycles": instance.remaining_cycles,
		"source_uid": instance.source_uid,
		"applied_cycle": instance.applied_cycle,
		"trigger_cycles": trigger_cycles,
		"expiring": instance.expiring
	}


func _deserialize_status_instance(data: Dictionary) -> CombatStatusInstance:
	var status := ContentRegistry.get_status_effect(str(data.get("status_id", "")))

	if status == null:
		return null

	var instance := CombatStatusInstance.create(
		status,
		maxi(1, int(data.get("stacks", 1))),
		int(data.get("source_uid", -1)),
		int(data.get("applied_cycle", 0))
	)
	instance.remaining_cycles = int(data.get("remaining_cycles", -1))
	instance.expiring = bool(data.get("expiring", false))
	var trigger_cycles: Variant = data.get("trigger_cycles", [])

	if trigger_cycles is Array:
		for index in range(mini(
			trigger_cycles.size(),
			status.triggered_effects.size()
		)):
			var triggered_effect := status.triggered_effects[index]

			if triggered_effect != null:
				instance.last_triggered_cycle[
					triggered_effect.get_instance_id()
				] = int(trigger_cycles[index])

	return instance


func _serialize_slots(slots: Array[CombatRuntimeSlot]) -> Array[Dictionary]:
	var serialized: Array[Dictionary] = []

	for slot: CombatRuntimeSlot in slots:
		serialized.append({
			"slot_id": str(slot.slot_id),
			"slot_kind": int(slot.slot_kind),
			"is_ally": slot.is_ally,
			"logical_index": slot.logical_index,
			"order_index": slot.order_index,
			"enabled": slot.enabled,
			"is_dynamic": slot.is_dynamic
		})

	return serialized


func _deserialize_slots(raw_slots: Variant) -> Array[CombatRuntimeSlot]:
	var slots: Array[CombatRuntimeSlot] = []

	if raw_slots is not Array:
		return slots

	for raw_slot: Variant in raw_slots:
		if raw_slot is not Dictionary:
			continue

		var slot := CombatRuntimeSlot.create(
			StringName(str(raw_slot.get("slot_id", ""))),
			int(raw_slot.get("slot_kind", CombatRuntimeSlot.SlotKind.POSITION)),
			bool(raw_slot.get("is_ally", true)),
			int(raw_slot.get("logical_index", 0)),
			int(raw_slot.get("order_index", 0)),
			bool(raw_slot.get("is_dynamic", false))
		)
		slot.enabled = bool(raw_slot.get("enabled", true))
		slots.append(slot)

	return slots


func _plain_copy(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}

		for key: Variant in value.keys():
			result[str(key)] = _plain_copy(value[key])

		return result

	if value is Array:
		var result: Array = []

		for entry: Variant in value:
			result.append(_plain_copy(entry))

		return result

	if value is StringName:
		return str(value)

	return value


func _deserialize_runtime_effects(raw_effects: Variant) -> Array:
	var effects: Array = []

	if raw_effects is not Array:
		return effects

	for raw_effect: Variant in raw_effects:
		if raw_effect is not Dictionary:
			continue

		var effect := (raw_effect as Dictionary).duplicate(true)
		effect["type"] = StringName(str(effect.get("type", "")))

		if effect.has("redirect_to_uid"):
			effect["redirect_to_uid"] = int(effect["redirect_to_uid"])

		if effect.has("remaining_actions"):
			effect["remaining_actions"] = int(effect["remaining_actions"])

		effects.append(effect)

	return effects


func _deserialize_targeting_history(raw_history: Variant) -> Array:
	var history: Array = []

	if raw_history is not Array:
		return history

	for raw_entry: Variant in raw_history:
		if raw_entry is not Dictionary:
			continue

		var entry := raw_entry as Dictionary
		history.append({
			"cycle": int(entry.get("cycle", -1)),
			"source_uid": int(entry.get("source_uid", -1)),
			"module_id": str(entry.get("module_id", "")),
			"classification": StringName(str(
				entry.get("classification", "")
			)),
			"action_slot_id": StringName(str(
				entry.get("action_slot_id", "")
			))
		})

	return history


func _serialize_team_records(records: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for record: Dictionary in records:
		result.append(_serialize_actor(record))

	return result


func _deserialize_team_records(raw_records: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if raw_records is not Array:
		return result

	for raw_record: Variant in raw_records:
		if raw_record is Dictionary:
			result.append(_deserialize_actor(raw_record as Dictionary))

	return result


func _read_action_assignments(value: Variant) -> Array:
	var result: Array = [null, null, null, null]

	if value is not Array:
		return result

	for index: int in range(mini(TEAM_SIZE, value.size())):
		if value[index] is Dictionary:
			result[index] = {
				"action_id": str(value[index].get("action_id", "")).strip_edges(),
				"target_uid": int(value[index].get("target_uid", -1))
			}

	return result


func _read_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _read_string_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()

	if value is not Array and value is not PackedStringArray:
		return result

	for raw_value: Variant in value:
		var clean_value: String = str(raw_value).strip_edges()

		if not clean_value.is_empty() and not result.has(clean_value):
			result.append(clean_value)

	return result


func _all_defeated(
	team: Array
) -> bool:
	for actor in team:
		if (
			actor != null
			and float(actor.get("hp", 0.0)) > 0.0
			and not bool(actor.get("is_dummy", false))
		):
			return false

	return true


func _has_terminal_state() -> bool:
	return (
		_all_defeated(enemy_team)
		or _all_defeated(ally_team)
	)


func _desfragment_enemies() -> void:
	var gravity_slots := [1, 0, 2, 3]
	var movable_survivors: Array = []
	var next_team: Array = [null, null, null, null]

	for index in range(TEAM_SIZE):
		var actor: Variant = enemy_team[index]

		if not _is_valid_target(actor, false):
			continue

		if not enemy_position_slots[index].enabled:
			next_team[index] = actor
		else:
			movable_survivors.append(actor)

	var available_gravity_slots: Array[int] = []

	for slot_index in gravity_slots:
		if (
			enemy_position_slots[slot_index].enabled
			and next_team[slot_index] == null
		):
			available_gravity_slots.append(slot_index)

	for index in range(
		mini(
			movable_survivors.size(),
			available_gravity_slots.size()
		)
	):
		next_team[available_gravity_slots[index]] = (
			movable_survivors[index]
		)

	enemy_team = next_team


func _roll_accuracy(
	target: Dictionary,
	accuracy: float
) -> bool:
	var dodge := clampf(
		get_effective_stat(
			target,
			CombatConstants.Stat.DODGE
		),
		0.0,
		1.0
	)
	var chance := clampf(
		accuracy - (dodge * 0.5),
		0.05,
		1.0
	)
	return randf() <= chance


func _roll_crit(
	caster: Dictionary
) -> bool:
	var chance := clampf(
		get_effective_stat(
			caster,
			CombatConstants.Stat.CRIT
		),
		0.0,
		1.0
	)
	return randf() <= chance


func _fail_effect(
	actor: Dictionary,
	message: String
) -> void:
	combat_log_added.emit(
		"> EFFECT FAILED: %s" % message
	)
	floating_text_requested.emit(
		actor,
		"FAIL!",
		Color.GRAY
	)


func _emit_module_presentation(
	event_kind: CombatPresentationEvent.EventKind,
	context: CombatEventContext,
	target: Variant = null
) -> void:
	if (
		context == null
		or context.module == null
		or context.module.presentation == null
		or not context.module.presentation.has_visuals()
	):
		return

	presentation_event_emitted.emit(
		CombatPresentationEvent.create(
			event_kind,
			context.module.presentation,
			context,
			context.source,
			target,
			context.module
		)
	)


func _emit_status_presentation(
	context: CombatEventContext,
	source: Variant,
	target: Variant,
	status: StatusEffectData,
	triggered_effect: CombatTriggeredEffectData = null
) -> void:
	if status == null:
		return

	var presentation := status.activation_presentation

	if (
		triggered_effect != null
		and triggered_effect.presentation_override != null
	):
		presentation = (
			triggered_effect.presentation_override
		)

	if presentation == null or not presentation.has_visuals():
		return

	presentation_event_emitted.emit(
		CombatPresentationEvent.create(
			CombatPresentationEvent.EventKind.STATUS_ACTIVATED,
			presentation,
			context,
			source,
			target,
			context.module if context != null else null,
			status,
			triggered_effect
		)
	)


func _context_from_action(
	action: Dictionary,
	timing: CombatConstants.TriggerTiming,
	timeline_index: int = -1
) -> CombatEventContext:
	return _make_context(
		timing,
		action.get("actor"),
		action.get("target"),
		action.get("module"),
		int(action.get("action_slot", -1)),
		timeline_index,
		0.0,
		0,
		StringName(action.get(
			"action_slot_id",
			&""
		)),
		StringName(action.get(
			"position_slot_id",
			&""
		))
	)


func _make_context(
	timing: CombatConstants.TriggerTiming,
	source: Variant = null,
	target: Variant = null,
	module: ModuleData = null,
	action_slot: int = -1,
	timeline_index: int = -1,
	amount: float = 0.0,
	depth: int = 0,
	action_slot_id: StringName = &"",
	position_slot_id: StringName = &"",
	execution_index: int = 0,
	execution_count: int = 1
) -> CombatEventContext:
	var context := CombatEventContext.create(
		timing,
		current_cycle,
		source,
		target,
		module,
		action_slot,
		timeline_index,
		amount,
		depth,
		_next_event_id,
		action_slot_id,
		position_slot_id,
		execution_index,
		execution_count
	)
	_next_event_id += 1
	return context


func _get_actor_position_slot_id(
	actor: Dictionary
) -> StringName:
	var team := (
		ally_team
		if bool(actor.get("is_ally", false))
		else enemy_team
	)
	var index := team.find(actor)

	if index < 0:
		return &""

	var slot := get_position_slot(
		bool(actor.get("is_ally", false)),
		index
	)
	return slot.slot_id if slot != null else &""


func _consume_uid() -> int:
	var uid := _next_uid
	_next_uid += 1
	return uid


func _team_snapshot(
	team: Array
) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []

	for actor in team:
		if actor == null:
			continue

		snapshot.append({
			"uid": actor.get("uid", -1),
			"character_id": actor.get(
				"character_id",
				&""
			),
			"hp": actor.get("hp", 0.0),
			"stability": actor.get(
				"stability",
				0.0
			),
			"is_dummy": actor.get(
				"is_dummy",
				false
			),
			"position_slot_id": (
				_get_actor_position_slot_id(actor)
			)
		})

	return snapshot


func _runtime_slot_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []

	for slot in (
		ally_position_slots
		+ enemy_position_slots
		+ action_slots
	):
		if slot == null:
			continue

		snapshot.append({
			"slot_id": slot.slot_id,
			"slot_kind": slot.slot_kind,
			"is_ally": slot.is_ally,
			"logical_index": slot.logical_index,
			"order_index": slot.order_index,
			"enabled": slot.enabled,
			"is_dynamic": slot.is_dynamic
		})

	return snapshot
