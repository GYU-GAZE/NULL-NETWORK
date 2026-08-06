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
	_prepare_recoverable_partner_snapshot(outcome)
	return super.resolve_encounter(outcome)


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
			var npc: NPCData = SocialService.get_npc(
				slot_data.party_member_id
			)

			if npc == null \
				or not SocialService.is_party_member(npc.get_display_id()) \
				or npc.party_loadout == null:
				return null

			return npc.party_loadout.duplicate(true) as CharacterLoadout

	return super._resolve_slot_loadout(slot_data)


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
