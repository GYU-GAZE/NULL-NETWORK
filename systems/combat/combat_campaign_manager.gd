extends "res://apps/combat/combat_manager.gd"


## System-level policy boundary for combat outcomes that affect the campaign.
##
## The inherited combat runtime owns turn execution and the tactical grid.
## This layer owns campaign-facing combat policies and resolves reusable
## catalog APK and Social party participants.

const RECOVERABLE_PARTNER_MIN_HP: int = 1


func _ready() -> void:
	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_state_changed
	):
		CampaignState.campaign_changed.connect(
			_on_campaign_state_changed
		)

	call_deferred("_repair_loaded_recoverable_partner")


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

	_prepare_recoverable_partner_snapshot(outcome)
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
	_resolution_applied = true
	_partner_state_committed = true
	_awaiting_resolution = false
	_pending_outcome = outcome
	SaveManager.request_checkpoint(
		StringName("combat_resolved.%s" % _current_encounter.encounter_id),
		not str(_resolution_metadata.get("tamed_apk_id", "")).is_empty()
	)
	combat_resolution_applied.emit(
		outcome,
		_resolution_metadata.duplicate(true)
	)
	return errors


func _load_team_from_slots(
	slot_data_list: Array[CombatSlotData],
	target_team: Array,
	is_ally: bool
) -> void:
	super._load_team_from_slots(
		slot_data_list,
		target_team,
		is_ally
	)

	for slot_data: CombatSlotData in slot_data_list:
		if slot_data == null \
			or slot_data.participant_source \
			!= CombatSlotData.ParticipantSource.PARTY_MEMBER \
			or slot_data.slot_index < 0 \
			or slot_data.slot_index >= target_team.size() \
			or target_team[slot_data.slot_index] is not Dictionary:
			continue

		(target_team[slot_data.slot_index] as Dictionary)[
			"party_member_id"
		] = slot_data.party_member_id.strip_edges()

	if not is_ally \
		or _current_encounter == null \
		or _current_encounter.active_party_slots <= 0:
		return

	_inject_active_party_members(
		target_team,
		_current_encounter.active_party_slots
	)


func _inject_active_party_members(
	target_team: Array,
	maximum_party_members: int
) -> void:
	var loaded_character_ids: Dictionary = {}
	var loaded_party_count: int = 0

	for actor_value: Variant in target_team:
		if actor_value is not Dictionary:
			continue

		var actor := actor_value as Dictionary

		if int(actor.get("source_kind", -1)) \
			!= CombatSlotData.ParticipantSource.PARTY_MEMBER:
			continue

		loaded_party_count += 1
		loaded_character_ids[str(actor.get("character_id", ""))] = true

	var remaining_slots: int = maxi(
		0,
		maximum_party_members - loaded_party_count
	)

	if remaining_slots == 0:
		return

	for npc_id: String in SocialService.get_party_member_ids():
		if remaining_slots == 0:
			break

		var npc: NPCData = SocialService.get_npc(npc_id)
		var loadout: CharacterLoadout = (
			SocialService.create_party_partner_combat_loadout(npc_id)
		)

		if npc == null \
			or not SocialService.is_friend(npc_id) \
			or not npc.can_join_party \
			or loadout == null:
			continue

		var character_id: String = str(
			loadout.character_id
		).strip_edges()

		if loaded_character_ids.has(character_id):
			continue

		var free_slot: int = _find_free_party_slot(target_team)

		if free_slot < 0:
			break

		var actor: Dictionary = _create_combatant(
			loadout,
			true,
			false,
			CombatSlotData.ParticipantSource.PARTY_MEMBER,
			free_slot,
			null
		)
		actor["party_member_id"] = npc.get_display_id()
		target_team[free_slot] = actor
		loaded_character_ids[character_id] = true
		remaining_slots -= 1


func _find_free_party_slot(target_team: Array) -> int:
	for slot_index: int in range(1, TEAM_SIZE):
		if target_team[slot_index] == null:
			return slot_index

	return -1


func _resolve_slot_loadout(
	slot_data: CombatSlotData
) -> CharacterLoadout:
	if slot_data == null:
		return null

	match slot_data.participant_source:
		CombatSlotData.ParticipantSource.CATALOG_APK:
			return APKCombatLoadoutFactory.create_loadout(
				slot_data.apk_id,
				slot_data.apk_level,
				slot_data.apk_integrity_state
			)

		CombatSlotData.ParticipantSource.PARTY_MEMBER:
			return SocialService.create_party_partner_combat_loadout(
				slot_data.party_member_id
			)

	return super._resolve_slot_loadout(slot_data)


func _serialize_actor(actor: Dictionary) -> Dictionary:
	var data: Dictionary = super._serialize_actor(actor)
	data["party_member_id"] = str(
		actor.get("party_member_id", "")
	).strip_edges()
	data["defeated_in_combat"] = bool(
		actor.get("defeated_in_combat", false)
	)
	return data


func _deserialize_actor(data: Dictionary) -> Dictionary:
	var actor: Dictionary = super._deserialize_actor(data)
	actor["defeated_in_combat"] = bool(
		data.get("defeated_in_combat", false)
	)

	if int(data.get("source_kind", -1)) \
		!= CombatSlotData.ParticipantSource.PARTY_MEMBER:
		return actor

	var npc_id: String = str(
		data.get("party_member_id", "")
	).strip_edges()
	var npc: NPCData = SocialService.get_npc(npc_id)

	if npc == null:
		var character_id: String = str(
			data.get("character_id", "")
		).strip_edges()
		npc = _find_party_npc_by_character_id(character_id)

	if npc != null:
		var loadout: CharacterLoadout = (
			SocialService.create_party_partner_combat_loadout(
				npc.get_display_id()
			)
		)

		if loadout != null:
			actor["icon"] = loadout.combat_icon

		actor["party_member_id"] = npc.get_display_id()

	return actor


func _find_party_npc_by_character_id(
	character_id: String
) -> NPCData:
	for npc_id: String in SocialService.get_party_member_ids():
		var npc: NPCData = SocialService.get_npc(npc_id)

		if npc != null \
			and npc.party_loadout != null \
			and str(npc.party_loadout.character_id) == character_id:
			return npc

	return null


func _get_ally_resolution_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_uids: Dictionary = {}

	for actor_value: Variant in ally_team:
		if actor_value is not Dictionary:
			continue

		var actor := actor_value as Dictionary
		var uid: int = int(actor.get("uid", -1))
		result.append(actor.duplicate(true))

		if uid >= 0:
			seen_uids[uid] = true

	var player: Variant = _get_player_resolution_actor()

	if player is Dictionary:
		var player_uid: int = int((player as Dictionary).get("uid", -1))

		if player_uid < 0 or not seen_uids.has(player_uid):
			result.append((player as Dictionary).duplicate(true))

	return result


func _emit_terminal_outcome() -> void:
	var allies_defeated: bool = _all_defeated(ally_team)
	var enemies_defeated: bool = _all_defeated(enemy_team)

	# Defeat has priority. The previous implementation checked enemies
	# first, so a simultaneous knockout emitted VICTORY while persisting
	# the defeated partner at 0 HP.
	if allies_defeated:
		_pending_outcome = CombatResult.Outcome.DEFEAT

		if enemies_defeated:
			combat_log_added.emit(
				"\n[color=red]>>> MUTUAL COLLAPSE: DEFEAT <<<[/color]"
			)
		else:
			combat_log_added.emit(
				"\n[color=red]>>> DEFEAT <<<[/color]"
			)

		combat_defeat.emit()
		return

	if enemies_defeated:
		_pending_outcome = CombatResult.Outcome.VICTORY
		combat_log_added.emit(
			"\n[color=lime]>>> VICTORY <<<[/color]"
		)
		combat_victory.emit()


func _prepare_recoverable_partner_snapshot(
	outcome: CombatResult.Outcome
) -> void:
	if not _uses_recoverable_partner_policy(outcome):
		return

	var player_actor: Variant = _get_player_resolution_actor()

	if player_actor is not Dictionary:
		return

	var actor: Dictionary = player_actor as Dictionary

	if int(actor.get("source_kind", -1)) \
		!= CombatSlotData.ParticipantSource.PLAYER_PARTNER:
		return

	if float(actor.get("hp", 0.0)) > 0.0:
		return

	# Phase 10 still keeps the Operator partner recoverable until the Phase 14
	# loss lifecycle lands. Preserve the actual defeat marker so EXP splitting
	# never rewards a partner that reached 0 HP before this compatibility repair.
	actor["defeated_in_combat"] = true
	var maximum_hp: int = maxi(
		RECOVERABLE_PARTNER_MIN_HP,
		roundi(float(actor.get("max_hp", 1.0)))
	)
	actor["hp"] = float(mini(
		RECOVERABLE_PARTNER_MIN_HP,
		maximum_hp
	))


func _uses_recoverable_partner_policy(
	outcome: CombatResult.Outcome
) -> bool:
	if outcome not in [
		CombatResult.Outcome.VICTORY,
		CombatResult.Outcome.DEFEAT,
		CombatResult.Outcome.ESCAPED
	]:
		return false

	return CampaignState.campaign_phase not in [
		CampaignState.CampaignPhase.NO_CAMPAIGN,
		CampaignState.CampaignPhase.OPERATOR_LOSS
	]


func _on_campaign_state_changed(section: StringName) -> void:
	if section != &"campaign":
		return

	call_deferred("_repair_loaded_recoverable_partner")


func _repair_loaded_recoverable_partner() -> void:
	if not CampaignState.has_campaign():
		return

	if CampaignState.partner == null \
		or CampaignState.partner.is_empty() \
		or CampaignState.partner.current_hp > 0:
		return

	if CampaignState.campaign_phase in [
		CampaignState.CampaignPhase.NO_CAMPAIGN,
		CampaignState.CampaignPhase.OPERATOR_LOSS
	]:
		return

	var stats: Dictionary = APKProgressionService.calculate_partner_stats(
		CampaignState.partner
	)
	var maximum_hp: int = maxi(
		RECOVERABLE_PARTNER_MIN_HP,
		int(stats.get("max_hp", 1))
	)
	CampaignState.partner.current_hp = mini(
		RECOVERABLE_PARTNER_MIN_HP,
		maximum_hp
	)
	CampaignState.notify_partner_changed()
	SaveManager.request_checkpoint(
		&"combat.repair_recoverable_partner_hp",
		false
	)
