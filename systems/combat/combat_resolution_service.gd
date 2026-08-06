extends RefCounted
class_name CombatResolutionService


static func resolve(
	outcome: CombatResult.Outcome,
	encounter: CombatEncounter,
	player_actor: Dictionary,
	resolved_enemies: Array[Dictionary],
	progress_states: Array[PlayerActionProgressData],
	tendency_log: CombatTendencyLog,
	resolved_allies: Array[Dictionary] = []
) -> Dictionary:
	var errors := PackedStringArray()

	if encounter == null or encounter.resolution == null:
		errors.append("Combat resolution requires a valid encounter profile.")
		return {"errors": errors}

	if player_actor.is_empty():
		errors.append("Combat resolution has no player snapshot.")
		return {"errors": errors}

	var plan: Dictionary = _build_plan(
		outcome,
		encounter,
		resolved_enemies,
		progress_states,
		tendency_log
	)
	errors.append_array(plan.get("errors", PackedStringArray()))

	if not errors.is_empty():
		return {"errors": errors}

	errors.append_array(APKProgressionService.commit_combat_snapshot(player_actor))

	if not errors.is_empty():
		return {"errors": errors}

	var party_commit: Dictionary = _commit_party_partner_snapshots(
		resolved_allies,
		encounter.encounter_id
	)
	var lost_party_member_ids: PackedStringArray = party_commit.get(
		"lost_party_member_ids",
		PackedStringArray()
	)
	var tamed_partner: PartnerStateData = plan.get("tamed_partner") as PartnerStateData

	if tamed_partner != null:
		for module_id: String in CampaignState.known_module_ids:
			var module: ModuleData = ContentRegistry.get_module(module_id)

			if module != null \
				and module.module_kind == ModuleData.ModuleKind.ACTIVE \
				and not tamed_partner.known_active_module_ids.has(module_id):
				tamed_partner.known_active_module_ids.append(module_id)

		if not CampaignState.set_partner_state(tamed_partner):
			errors.append("CampaignState rejected the TAME partner replacement.")
			return {"errors": errors}

	for module_id: String in plan.get("module_ids", PackedStringArray()):
		CampaignState.learn_module(module_id)

	var passive_id: String = str(plan.get("passive_module_id", ""))

	if not passive_id.is_empty():
		CampaignState.learn_module(passive_id, false)
		CampaignState.partner.secondary_passive_module_id = passive_id
		CampaignState.notify_partner_changed()

	for item_reward: Dictionary in plan.get("items", []):
		CampaignState.grant_item(
			str(item_reward.get("item_id", "")),
			int(item_reward.get("amount", 0))
		)

	for entry: Dictionary in plan.get("encyclopedia_entries", []):
		CampaignState.record_encyclopedia_entry(
			str(entry.get("entry_id", "")),
			entry.get("data", {}) as Dictionary
		)

	for gain: Dictionary in plan.get("tendency_gains", []):
		CampaignState.modify_tendency(
			int(gain.get("tendency", TendencyStateData.Tendency.VALOUR)),
			int(gain.get("amount", 0))
		)

	var experience: int = int(plan.get("experience", 0))
	var experience_result: Dictionary = _distribute_experience(
		experience,
		player_actor,
		resolved_allies
	)
	errors.append_array(
		experience_result.get("errors", PackedStringArray())
	)

	var effects: Array[GameEffectData] = _effects_for_outcome(
		encounter.resolution,
		outcome
	)
	var effect_context := GameEffectContext.create(
		"combat.%s" % encounter.encounter_id,
		CampaignState.partner.apk_id,
		CampaignState.current_location_id,
		str(CombatManager.get_session_activity_context().get(
			"activity_transaction_id",
			""
		)),
		"combat_resolution"
	)
	var failed_effects: PackedStringArray = GameEffectData.apply_all(
		effects,
		effect_context
	)

	if not failed_effects.is_empty():
		errors.append(
			"Combat resolution effects failed: %s"
			% ", ".join(failed_effects)
		)

	return {
		"errors": errors,
		"metadata": {
			"experience": experience,
			"experience_assigned": int(
				experience_result.get("assigned", 0)
			),
			"experience_distributed": int(
				experience_result.get("granted", 0)
			),
			"experience_unassigned": int(
				experience_result.get("unassigned", experience)
			),
			"experience_distribution": experience_result.get(
				"entries",
				[]
			),
			"lost_party_member_ids": Array(lost_party_member_ids),
			"module_ids": Array(plan.get(
				"module_ids",
				PackedStringArray()
			)),
			"passive_module_id": passive_id,
			"items": plan.get("items", []),
			"encyclopedia_entries": plan.get("encyclopedia_entries", []),
			"combat_style": plan.get("combat_style", {}),
			"tendency_gains": plan.get("tendency_gains", []),
			"tamed_apk_id": (
				tamed_partner.apk_id
				if tamed_partner != null
				else ""
			)
		}
	}


static func _build_plan(
	outcome: CombatResult.Outcome,
	encounter: CombatEncounter,
	resolved_enemies: Array[Dictionary],
	progress_states: Array[PlayerActionProgressData],
	log: CombatTendencyLog
) -> Dictionary:
	var errors := PackedStringArray()
	var experience: int = 0
	var module_ids := PackedStringArray()
	var passive_module_id: String = ""
	var items: Array[Dictionary] = []
	var entries: Array[Dictionary] = []
	var tendency_gains: Array[Dictionary] = []
	var tamed_partner: PartnerStateData = null

	for enemy: Dictionary in resolved_enemies:
		var reward: CombatRewardData = enemy.get(
			"reward_profile"
		) as CombatRewardData

		if reward == null:
			continue

		if bool(enemy.get("defeated", false)):
			var enemy_exp: int = reward.base_experience

			if bool(enemy.get("purged", false)):
				enemy_exp = roundi(
					enemy_exp * reward.purge_experience_multiplier
				)
				var purge_module: String = _deterministic_module(
					reward.active_module_ids,
					encounter.encounter_id,
					int(enemy.get("uid", -1))
				)

				if not purge_module.is_empty():
					if CampaignState.known_module_ids.has(purge_module):
						enemy_exp += reward.duplicate_module_experience
					else:
						_add_unique(module_ids, purge_module)

			experience += enemy_exp

			for index: int in range(reward.common_item_ids.size()):
				items.append({
					"item_id": reward.common_item_ids[index],
					"amount": reward.common_item_amounts[index]
				})

		if not reward.encyclopedia_entry_id.strip_edges().is_empty():
			entries.append({
				"entry_id": reward.encyclopedia_entry_id,
				"data": {
					"encountered": true,
					"defeated": bool(enemy.get("defeated", false)),
					"scanned": _is_completed(
						progress_states,
						"scan",
						int(enemy.get("uid", -1))
					)
				}
			})

	for state: PlayerActionProgressData in progress_states:
		if state == null or not state.completed:
			continue

		var action: PlayerActionData = encounter.resolution.get_player_action(
			state.action_id
		)
		var enemy: Dictionary = _find_enemy(
			resolved_enemies,
			state.target_uid
		)
		var reward: CombatRewardData = enemy.get(
			"reward_profile"
		) as CombatRewardData

		if action == null or reward == null:
			errors.append(
				"Completed Player Action '%s' lost its target reward data."
				% state.action_id
			)
			continue

		for gain: CombatTendencyGainData in action.permanent_tendency_gains:
			if gain != null and gain.is_available():
				tendency_gains.append({
					"tendency": int(gain.tendency),
					"amount": gain.amount
				})

		match action.action_kind:
			PlayerActionData.ActionKind.SCAN:
				if state.selected_reward_id.is_empty():
					errors.append(
						"Completed SCAN requires a selected Module reward."
					)
				elif not reward.active_module_ids.has(
					state.selected_reward_id
				):
					errors.append(
						"SCAN selected a Module outside the target reward pool."
					)
				elif CampaignState.known_module_ids.has(
					state.selected_reward_id
				):
					experience += reward.duplicate_module_experience
				else:
					_add_unique(module_ids, state.selected_reward_id)
			PlayerActionData.ActionKind.PURIFY:
				for candidate_id: String in (
					reward.purification_passive_module_ids
				):
					if not CampaignState.known_module_ids.has(candidate_id):
						passive_module_id = candidate_id
						break

				if passive_module_id.is_empty():
					experience += reward.duplicate_module_experience
			PlayerActionData.ActionKind.TAME:
				var integrity := (
					PartnerStateData.IntegrityState.PURIFIED
					if bool(enemy.get("purified", false))
					else PartnerStateData.IntegrityState.EXE
				)
				tamed_partner = APKProgressionService.create_tamed_partner_state(
					reward.tame_apk_id,
					int(enemy.get("level", 1)),
					integrity,
					state.target_uid
				)

				if tamed_partner == null:
					errors.append(
						"TAME could not materialize the target PartnerState."
					)

	var style: Dictionary = encounter.resolution.combat_style_rule.resolve(log)
	tendency_gains.append_array(style.get("tendency_gains", []))

	return {
		"errors": errors,
		"experience": experience,
		"module_ids": module_ids,
		"passive_module_id": passive_module_id,
		"items": items,
		"encyclopedia_entries": entries,
		"tendency_gains": tendency_gains,
		"combat_style": style,
		"tamed_partner": tamed_partner,
		"outcome": int(outcome)
	}


static func _commit_party_partner_snapshots(
	resolved_allies: Array[Dictionary],
	encounter_id: String
) -> Dictionary:
	var lost_party_member_ids := PackedStringArray()
	var committed_npc_ids: Dictionary = {}

	for actor: Dictionary in resolved_allies:
		if bool(actor.get("is_dummy", false)) \
			or int(actor.get("source_kind", -1)) \
			!= CombatSlotData.ParticipantSource.PARTY_MEMBER:
			continue

		var npc_id: String = _resolve_party_npc_id(actor)

		if npc_id.is_empty() or committed_npc_ids.has(npc_id):
			continue

		committed_npc_ids[npc_id] = true
		var commit_result: Dictionary = (
			SocialService.commit_party_partner_combat_actor(
				npc_id,
				actor,
				encounter_id
			)
		)

		if bool(commit_result.get("lost", false)):
			lost_party_member_ids.append(npc_id)

	return {
		"lost_party_member_ids": lost_party_member_ids
	}


static func _distribute_experience(
	total_experience: int,
	player_actor: Dictionary,
	resolved_allies: Array[Dictionary]
) -> Dictionary:
	var errors := PackedStringArray()
	var entries: Array[Dictionary] = []
	var recipients: Array[Dictionary] = _get_experience_recipients(
		player_actor,
		resolved_allies
	)

	if total_experience <= 0:
		return {
			"errors": errors,
			"entries": entries,
			"assigned": 0,
			"granted": 0,
			"unassigned": 0
		}

	if recipients.is_empty():
		return {
			"errors": errors,
			"entries": entries,
			"assigned": 0,
			"granted": 0,
			"unassigned": total_experience
		}

	var base_share: int = floori(
		float(total_experience) / float(recipients.size())
	)
	var remainder: int = total_experience - base_share * recipients.size()
	var assigned_total: int = 0
	var granted_total: int = 0

	for index: int in range(recipients.size()):
		var recipient: Dictionary = recipients[index]
		var assigned: int = base_share + (1 if index < remainder else 0)
		var source_kind: int = int(recipient.get("source_kind", -1))
		var actor: Dictionary = recipient.get("actor", {}) as Dictionary
		var entry := {
			"recipient_kind": "",
			"recipient_id": "",
			"character_id": str(actor.get("character_id", "")),
			"slot_index": int(actor.get("encounter_slot_index", -1)),
			"assigned": assigned,
			"granted": 0,
			"old_level": 0,
			"new_level": 0
		}

		assigned_total += assigned

		match source_kind:
			CombatSlotData.ParticipantSource.PLAYER_PARTNER:
				entry["recipient_kind"] = "player_partner"
				entry["recipient_id"] = CampaignState.partner.apk_id
				entry["old_level"] = CampaignState.partner.level
				var previous_exp: int = CampaignState.partner.current_exp

				if assigned > 0:
					errors.append_array(
						APKProgressionService.grant_experience(assigned)
					)

				entry["granted"] = maxi(
					0,
					CampaignState.partner.current_exp - previous_exp
				)
				entry["new_level"] = CampaignState.partner.level

			CombatSlotData.ParticipantSource.PARTY_MEMBER:
				var npc_id: String = str(
					recipient.get("npc_id", "")
				).strip_edges()
				entry["recipient_kind"] = "party_partner"
				entry["recipient_id"] = npc_id
				var progression: Dictionary = (
					SocialService.grant_party_partner_experience(
						npc_id,
						assigned
					)
					if assigned > 0
					else {}
				)
				entry["granted"] = int(progression.get("granted", 0))
				entry["old_level"] = int(
					progression.get("old_level", 0)
				)
				entry["new_level"] = int(
					progression.get("new_level", 0)
				)

		granted_total += int(entry.get("granted", 0))
		entries.append(entry)

	return {
		"errors": errors,
		"entries": entries,
		"assigned": assigned_total,
		"granted": granted_total,
		"unassigned": maxi(0, total_experience - assigned_total)
	}


static func _get_experience_recipients(
	player_actor: Dictionary,
	resolved_allies: Array[Dictionary]
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_uids: Dictionary = {}
	var allies: Array[Dictionary] = resolved_allies.duplicate()

	if allies.is_empty():
		allies.append(player_actor)
	else:
		var player_uid: int = int(player_actor.get("uid", -1))
		var player_found: bool = false

		for ally: Dictionary in allies:
			if int(ally.get("uid", -2)) == player_uid:
				player_found = true
				break

		if not player_found:
			allies.append(player_actor)

	for actor: Dictionary in allies:
		var uid: int = int(actor.get("uid", -1))

		if uid >= 0 and seen_uids.has(uid):
			continue

		if not _is_experience_eligible(actor):
			continue

		if uid >= 0:
			seen_uids[uid] = true

		var source_kind: int = int(actor.get("source_kind", -1))
		var npc_id: String = ""

		if source_kind == CombatSlotData.ParticipantSource.PARTY_MEMBER:
			npc_id = _resolve_party_npc_id(actor)

			if npc_id.is_empty() \
				or SocialService.is_party_partner_lost(npc_id):
				continue

		result.append({
			"source_kind": source_kind,
			"npc_id": npc_id,
			"actor": actor
		})

	result.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			var left_actor: Dictionary = left.get("actor", {}) as Dictionary
			var right_actor: Dictionary = right.get("actor", {}) as Dictionary
			var left_slot: int = int(
				left_actor.get("encounter_slot_index", 999)
			)
			var right_slot: int = int(
				right_actor.get("encounter_slot_index", 999)
			)

			if left_slot != right_slot:
				return left_slot < right_slot

			return int(left.get("source_kind", 999)) \
				< int(right.get("source_kind", 999))
	)
	return result


static func _is_experience_eligible(actor: Dictionary) -> bool:
	if actor.is_empty() \
		or bool(actor.get("is_dummy", false)) \
		or float(actor.get("hp", 0.0)) <= 0.0 \
		or bool(actor.get("defeated", false)) \
		or bool(actor.get("defeated_in_combat", false)):
		return false

	return int(actor.get("source_kind", -1)) in [
		CombatSlotData.ParticipantSource.PLAYER_PARTNER,
		CombatSlotData.ParticipantSource.PARTY_MEMBER
	]


static func _resolve_party_npc_id(actor: Dictionary) -> String:
	var explicit_id: String = str(
		actor.get("party_member_id", "")
	).strip_edges()

	if not explicit_id.is_empty():
		return explicit_id

	var character_id: String = str(
		actor.get("character_id", "")
	).strip_edges()

	for npc_id: String in SocialService.get_party_member_ids():
		var npc: NPCData = SocialService.get_npc(npc_id)

		if npc != null \
			and npc.party_loadout != null \
			and str(npc.party_loadout.character_id).strip_edges() \
			== character_id:
			return npc_id

	return ""


static func _effects_for_outcome(
	resolution: CombatResolutionData,
	outcome: CombatResult.Outcome
) -> Array[GameEffectData]:
	match outcome:
		CombatResult.Outcome.VICTORY:
			return resolution.victory_effects
		CombatResult.Outcome.DEFEAT:
			return resolution.defeat_effects
		CombatResult.Outcome.ESCAPED:
			return resolution.escape_effects

	return []


static func _find_enemy(
	enemies: Array[Dictionary],
	uid: int
) -> Dictionary:
	for enemy: Dictionary in enemies:
		if int(enemy.get("uid", -1)) == uid:
			return enemy

	return {}


static func _is_completed(
	states: Array[PlayerActionProgressData],
	action_id: String,
	target_uid: int
) -> bool:
	var state: PlayerActionProgressData = PlayerActionService.get_progress(
		states,
		action_id,
		target_uid
	)
	return state != null and state.completed


static func _deterministic_module(
	module_ids: PackedStringArray,
	salt: String,
	target_uid: int
) -> String:
	if module_ids.is_empty():
		return ""

	var index: int = posmod(
		(CampaignState.campaign_id + salt + str(target_uid)).hash(),
		module_ids.size()
	)
	return module_ids[index]


static func _add_unique(
	target: PackedStringArray,
	value: String
) -> void:
	var clean_value: String = value.strip_edges()

	if not clean_value.is_empty() and not target.has(clean_value):
		target.append(clean_value)
