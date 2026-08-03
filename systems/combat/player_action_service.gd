extends RefCounted
class_name PlayerActionService


static func get_progress(
	states: Array[PlayerActionProgressData],
	action_id: String,
	target_uid: int
) -> PlayerActionProgressData:
	var clean_id: String = action_id.strip_edges()

	for state: PlayerActionProgressData in states:
		if state != null and state.action_id == clean_id and state.target_uid == target_uid:
			return state

	return null


static func validate_assignment(
	action: PlayerActionData,
	target: Dictionary,
	states: Array[PlayerActionProgressData]
) -> PackedStringArray:
	var errors := PackedStringArray()

	if action == null:
		errors.append("Player Action is not available in this encounter.")
		return errors

	if target.is_empty() or bool(target.get("is_ally", true)):
		errors.append("Player Actions require an enemy target.")
		return errors

	if float(target.get("hp", 0.0)) <= 0.0 or bool(target.get("tamed", false)):
		errors.append("Player Action target is no longer available.")

	var reward: CombatRewardData = target.get("reward_profile") as CombatRewardData

	if reward == null:
		errors.append("Player Action target has no campaign reward profile.")
		return errors

	var existing: PlayerActionProgressData = get_progress(
		states,
		action.action_id,
		int(target.get("uid", -1))
	)

	if existing != null and existing.completed and action.once_per_target:
		errors.append("Player Action is already complete for this target.")

	if action.once_per_encounter:
		for state: PlayerActionProgressData in states:
			if state != null and state.action_id == action.action_id and state.completed:
				errors.append("Player Action is already complete in this encounter.")
				break

	var purge_state: PlayerActionProgressData = _completed_kind_state(
		states,
		target,
		PlayerActionData.ActionKind.PURGE
	)
	var purify_state: PlayerActionProgressData = _completed_kind_state(
		states,
		target,
		PlayerActionData.ActionKind.PURIFY
	)

	match action.action_kind:
		PlayerActionData.ActionKind.SCAN:
			if reward.active_module_ids.is_empty():
				errors.append("This target exposes no active Module to SCAN.")
		PlayerActionData.ActionKind.PURGE:
			if purify_state != null or bool(target.get("purified", false)):
				errors.append("PURGE is blocked after PURIFY.")
		PlayerActionData.ActionKind.PURIFY:
			if purge_state != null or bool(target.get("purged", false)):
				errors.append("PURIFY is blocked after PURGE.")
			elif reward.purification_passive_module_ids.is_empty():
				errors.append("This target exposes no purification passive.")
		PlayerActionData.ActionKind.TAME:
			if purge_state != null or bool(target.get("purged", false)):
				errors.append("TAME is blocked after PURGE.")
			elif reward.tame_apk_id.strip_edges().is_empty():
				errors.append("This target cannot become a partner.")

	return errors


static func apply_slot(
	action: PlayerActionData,
	target: Dictionary,
	states: Array[PlayerActionProgressData],
	log: CombatTendencyLog
) -> Dictionary:
	var errors: PackedStringArray = validate_assignment(action, target, states)

	if not errors.is_empty():
		return {"errors": errors}

	var target_uid: int = int(target.get("uid", -1))
	var state: PlayerActionProgressData = get_progress(states, action.action_id, target_uid)

	if state == null:
		state = PlayerActionProgressData.create(action, target)
		states.append(state)

	state.progress = mini(action.required_progress, state.progress + action.progress_amount)
	var completed_now: bool = state.progress >= action.required_progress and not state.completed
	var choice_ids := PackedStringArray()

	if completed_now:
		state.completed = true
		log.record_player_action(action)

		match action.action_kind:
			PlayerActionData.ActionKind.SCAN:
				var reward: CombatRewardData = target.get("reward_profile") as CombatRewardData
				choice_ids = reward.active_module_ids.duplicate()
			PlayerActionData.ActionKind.PURGE:
				target["purged"] = true
			PlayerActionData.ActionKind.PURIFY:
				target["purified"] = true
			PlayerActionData.ActionKind.TAME:
				target["tamed"] = true

	return {
		"errors": PackedStringArray(),
		"state": state,
		"completed_now": completed_now,
		"choice_ids": choice_ids,
		"remove_target": completed_now and action.action_kind == PlayerActionData.ActionKind.TAME
	}


static func serialize_states(states: Array[PlayerActionProgressData]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for state: PlayerActionProgressData in states:
		if state != null:
			result.append(state.to_save_data())

	return result


static func deserialize_states(raw_states: Variant) -> Array[PlayerActionProgressData]:
	var result: Array[PlayerActionProgressData] = []

	if raw_states is not Array:
		return result

	for raw_state: Variant in raw_states:
		if raw_state is not Dictionary:
			continue

		var state := PlayerActionProgressData.new()
		state.load_save_data(raw_state as Dictionary)
		result.append(state)

	return result


static func _completed_kind_state(
	states: Array[PlayerActionProgressData],
	target: Dictionary,
	kind: PlayerActionData.ActionKind
) -> PlayerActionProgressData:
	var encounter: CombatEncounter = CombatManager.get_current_encounter()

	if encounter == null or encounter.resolution == null:
		return null

	for state: PlayerActionProgressData in states:
		if state == null or not state.completed or state.target_uid != int(target.get("uid", -1)):
			continue

		var state_action: PlayerActionData = encounter.resolution.get_player_action(state.action_id)

		if state_action != null and state_action.action_kind == kind:
			return state

	return null
