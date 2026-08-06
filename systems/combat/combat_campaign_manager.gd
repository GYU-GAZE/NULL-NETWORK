extends "res://apps/combat/combat_manager.gd"


## System-level policy boundary for combat outcomes that affect the campaign.
##
## The inherited combat runtime owns turn execution and the tactical grid.
## This layer owns campaign-facing combat policies and resolves reusable
## catalog APK and Social party participants.

const RECOVERABLE_TURD_MIN_HP: int = 1


func _ready() -> void:
	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_state_changed
	):
		CampaignState.campaign_changed.connect(
			_on_campaign_state_changed
		)

	call_deferred("_repair_loaded_recoverable_turd")


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
	_prepare_recoverable_turd_snapshot(outcome)
	var active_turd_snapshot: PartnerStateData = _capture_active_turd_snapshot()
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
				_current_encounter.encounter_id
			)
		)
		errors.append_array(
			loss_result.get("errors", PackedStringArray())
		)
		var loss_metadata: Dictionary = loss_result.get(
			"metadata",
			{}
		) as Dictionary

		for raw_key: Variant in loss_metadata:
			_resolution_metadata[str(raw_key)] = loss_metadata[raw_key]

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


func _capture_defeated_primary_snapshot(
	outcome: CombatResult.Outcome
) -> PartnerStateData:
	if PartnerContinuityService.is_turd_active() \
		or CampaignState.partner == null \
		or CampaignState.partner.is_empty() \
		or _current_encounter == null \
		or _current_encounter.resolution == null:
		return null

	var player_actor: Variant = _get_player_resolution_actor()

	if player_actor is not Dictionary:
		return null

	var actor: Dictionary = player_actor as Dictionary
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


func _capture_active_turd_snapshot() -> PartnerStateData:
	if not PartnerContinuityService.is_turd_active():
		return null

	var snapshot: PartnerStateData = CampaignState.partner.duplicate_state()
	var player_actor: Variant = _get_player_resolution_actor()

	if player_actor is Dictionary:
		_apply_actor_runtime_to_snapshot(
			snapshot,
			player_actor as Dictionary
		)

	return snapshot


func _apply_actor_runtime_to_snapshot(
	snapshot: PartnerStateData,
	actor: Dictionary
) -> void:
	if snapshot == null:
		return

	var stats: Dictionary = APKProgressionService.calculate_partner_stats(
		snapshot
	)
	snapshot.current_hp = clampi(
		roundi(float(actor.get("hp", snapshot.current_hp))),
		0,
		int(stats.get("max_hp", 1))
	)
	snapshot.current_stability = clampi(
		roundi(float(actor.get(
			"stability",
			snapshot.current_stability
	))),
		0,
		PartnerStateData.MAX_STABILITY
	)
	var module_ids := PackedStringArray()

	for raw_module: Variant in actor.get("modules", []):
		var module := raw_module as ModuleData
		module_ids.append(str(module.module_id) if module != null else "")

	if module_ids.size() != PartnerStateData.ACTIVE_SLOT_COUNT \
		or module_ids.has(""):
		return

	for module_id: String in module_ids:
		if not snapshot.known_active_module_ids.has(module_id):
			return

	snapshot.active_module_ids = module_ids


func _prepare_recoverable_turd_snapshot(
	outcome: CombatResult.Outcome
) -> void:
	if not _uses_recoverable_turd_policy(outcome):
		return

	var player_actor: Variant = _get_player_resolution_actor()

	if player_actor is not Dictionary:
		return

	var actor: Dictionary = player_actor as Dictionary

	if int(actor.get("source_kind", -1)) \
		!= CombatSlotData.ParticipantSource.PLAYER_PARTNER \
		or float(actor.get("hp", 0.0)) > 0.0:
		return

	# Operator Loss is implemented in the next Phase 14 subphase. Until then,
	# only TURD retains the old one-HP compatibility policy. Primary partners
	# now resolve permanent Partner Loss normally.
	actor["defeated_in_combat"] = true
	var maximum_hp: int = maxi(
		RECOVERABLE_TURD_MIN_HP,
		roundi(float(actor.get("max_hp", 1.0)))
	)
	actor["hp"] = float(mini(
		RECOVERABLE_TURD_MIN_HP,
		maximum_hp
	))


func _uses_recoverable_turd_policy(
	outcome: CombatResult.Outcome
) -> bool:
	if outcome not in [
		CombatResult.Outcome.VICTORY,
		CombatResult.Outcome.DEFEAT,
		CombatResult.Outcome.ESCAPED
	]:
		return false

	return (
		PartnerContinuityService.is_turd_active()
		and CampaignState.campaign_phase not in [
			CampaignState.CampaignPhase.NO_CAMPAIGN,
			CampaignState.CampaignPhase.OPERATOR_LOSS
		]
	)


func _on_campaign_state_changed(section: StringName) -> void:
	if section != &"campaign":
		return

	call_deferred("_repair_loaded_recoverable_turd")


func _repair_loaded_recoverable_turd() -> void:
	if not CampaignState.has_campaign() \
		or not PartnerContinuityService.is_turd_active() \
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
		RECOVERABLE_TURD_MIN_HP,
		int(stats.get("max_hp", 1))
	)
	CampaignState.partner.current_hp = mini(
		RECOVERABLE_TURD_MIN_HP,
		maximum_hp
	)
	CampaignState.notify_partner_changed()
	SaveManager.request_checkpoint(
		&"combat.repair_recoverable_turd_hp",
		false
	)
