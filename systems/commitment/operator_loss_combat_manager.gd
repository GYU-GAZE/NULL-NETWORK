extends "res://systems/combat/combat_campaign_manager.gd"


## Final Phase 14 combat policy. The inherited manager keeps tactical combat,
## party injection, Partner Loss and serialization. This layer replaces only
## the temporary one-HP TURD compatibility rule with definitive Operator Loss.


func resolve_encounter(
	outcome: CombatResult.Outcome
) -> PackedStringArray:
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

	var defeated_primary_snapshot: PartnerStateData = (
		_capture_defeated_primary_snapshot(outcome)
	)
	var defeated_turd_snapshot: PartnerStateData = (
		_capture_defeated_turd_snapshot(outcome)
	)
	var active_turd_snapshot: PartnerStateData = (
		null
		if defeated_turd_snapshot != null
		else _capture_active_turd_snapshot()
	)
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
		combat_tendency_log,
		_get_ally_resolution_records()
	)
	errors.append_array(result.get("errors", PackedStringArray()))

	if not errors.is_empty():
		return errors

	_resolution_metadata = result.get("metadata", {}).duplicate(true)
	var tamed_apk_id: String = str(
		_resolution_metadata.get("tamed_apk_id", "")
	).strip_edges()

	if not tamed_apk_id.is_empty() and active_turd_snapshot != null:
		if not PartnerContinuityService.stash_turd_snapshot(
			active_turd_snapshot
		):
			errors.append("TAME could not preserve the active TURD state.")

	if defeated_primary_snapshot != null:
		var loss_result: Dictionary = (
			PartnerLossService.resolve_captured_primary_loss(
				defeated_primary_snapshot,
				tamed_apk_id.is_empty(),
				_current_encounter.encounter_id,
				_current_encounter.resolution.partner_loss_infestation_increase
			)
		)
		errors.append_array(
			loss_result.get("errors", PackedStringArray())
		)
		_merge_resolution_metadata(
			loss_result.get("metadata", {}) as Dictionary
		)

	if defeated_turd_snapshot != null:
		var operator_loss_result: Dictionary = (
			OperatorLossService.resolve_after_combat(
				defeated_turd_snapshot,
				_current_encounter.encounter_id,
				_current_encounter.resolution.operator_loss_infestation_increase
			)
		)
		errors.append_array(
			operator_loss_result.get("errors", PackedStringArray())
		)
		_merge_resolution_metadata(
			operator_loss_result.get("metadata", {}) as Dictionary
		)

	if not errors.is_empty():
		return errors

	_resolution_applied = true
	_partner_state_committed = true
	_awaiting_resolution = false
	_pending_outcome = outcome
	var irreversible: bool = (
		not tamed_apk_id.is_empty()
		or bool(_resolution_metadata.get("irreversible", false))
	)
	SaveManager.request_checkpoint(
		StringName("combat_resolved.%s" % _current_encounter.encounter_id),
		irreversible
	)
	combat_resolution_applied.emit(
		outcome,
		_resolution_metadata.duplicate(true)
	)
	return errors


func _capture_defeated_turd_snapshot(
	outcome: CombatResult.Outcome
) -> PartnerStateData:
	if not PartnerContinuityService.is_turd_active() \
		or _current_encounter == null \
		or _current_encounter.resolution == null:
		return null

	var player_actor: Variant = _get_player_resolution_actor()

	if player_actor is not Dictionary:
		return null

	var actor := player_actor as Dictionary
	var actor_hp: float = float(actor.get("hp", 0.0))

	if int(actor.get("source_kind", -1)) \
		!= CombatSlotData.ParticipantSource.PLAYER_PARTNER \
		or not _current_encounter.resolution.should_resolve_partner_loss(
			outcome,
			actor_hp
		):
		return null

	var snapshot: PartnerStateData = CampaignState.partner.duplicate_state()
	_apply_actor_runtime_to_snapshot(snapshot, actor)
	snapshot.current_hp = 0
	return snapshot


func _prepare_recoverable_turd_snapshot(
	_outcome: CombatResult.Outcome
) -> void:
	# Phase 14.2 removes the temporary one-HP compatibility repair.
	pass


func _repair_loaded_recoverable_turd() -> void:
	if not CampaignState.has_campaign() \
		or CampaignState.campaign_phase == CampaignState.CampaignPhase.OPERATOR_LOSS \
		or not PartnerContinuityService.is_turd_active() \
		or CampaignState.partner.current_hp > 0:
		return

	var result: Dictionary = OperatorLossService.resolve_after_combat(
		CampaignState.partner.duplicate_state(),
		"loaded_defeated_turd",
		OperatorLossService.DEFAULT_INFESTATION_INCREASE
	)
	var errors: PackedStringArray = result.get(
		"errors",
		PackedStringArray()
	)

	if not errors.is_empty():
		for error: String in errors:
			push_error("Loaded TURD Operator Loss: %s" % error)
		return

	SaveManager.request_checkpoint(
		&"operator_loss.loaded_defeated_turd",
		true
	)


func _merge_resolution_metadata(additional: Dictionary) -> void:
	for raw_key: Variant in additional:
		_resolution_metadata[str(raw_key)] = additional[raw_key]
