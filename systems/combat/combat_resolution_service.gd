extends RefCounted
class_name CombatResolutionService


static func resolve(
	outcome: CombatResult.Outcome,
	encounter: CombatEncounter,
	player_actor: Dictionary,
	resolved_enemies: Array[Dictionary],
	progress_states: Array[PlayerActionProgressData],
	tendency_log: CombatTendencyLog
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

	if experience > 0:
		errors.append_array(APKProgressionService.grant_experience(experience))

	var effects: Array[GameEffectData] = _effects_for_outcome(encounter.resolution, outcome)
	var effect_context := GameEffectContext.create(
		"combat.%s" % encounter.encounter_id,
		CampaignState.partner.apk_id,
		CampaignState.current_location_id,
		str(CombatManager.get_session_activity_context().get("activity_transaction_id", "")),
		"combat_resolution"
	)
	var failed_effects: PackedStringArray = GameEffectData.apply_all(effects, effect_context)

	if not failed_effects.is_empty():
		errors.append("Combat resolution effects failed: %s" % ", ".join(failed_effects))

	return {
		"errors": errors,
		"metadata": {
			"experience": experience,
			"module_ids": Array(plan.get("module_ids", PackedStringArray())),
			"passive_module_id": passive_id,
			"items": plan.get("items", []),
			"encyclopedia_entries": plan.get("encyclopedia_entries", []),
			"combat_style": plan.get("combat_style", {}),
			"tendency_gains": plan.get("tendency_gains", []),
			"tamed_apk_id": tamed_partner.apk_id if tamed_partner != null else ""
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
		var reward: CombatRewardData = enemy.get("reward_profile") as CombatRewardData

		if reward == null:
			continue

		if bool(enemy.get("defeated", false)):
			var enemy_exp: int = reward.base_experience

			if bool(enemy.get("purged", false)):
				enemy_exp = roundi(enemy_exp * reward.purge_experience_multiplier)
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
					"scanned": _is_completed(progress_states, "scan", int(enemy.get("uid", -1)))
				}
			})

	for state: PlayerActionProgressData in progress_states:
		if state == null or not state.completed:
			continue

		var action: PlayerActionData = encounter.resolution.get_player_action(state.action_id)
		var enemy: Dictionary = _find_enemy(resolved_enemies, state.target_uid)
		var reward: CombatRewardData = enemy.get("reward_profile") as CombatRewardData

		if action == null or reward == null:
			errors.append("Completed Player Action '%s' lost its target reward data." % state.action_id)
			continue

		for gain: CombatTendencyGainData in action.permanent_tendency_gains:
			if gain != null and gain.is_available():
				tendency_gains.append({"tendency": int(gain.tendency), "amount": gain.amount})

		match action.action_kind:
			PlayerActionData.ActionKind.SCAN:
				if state.selected_reward_id.is_empty():
					errors.append("Completed SCAN requires a selected Module reward.")
				elif not reward.active_module_ids.has(state.selected_reward_id):
					errors.append("SCAN selected a Module outside the target reward pool.")
				elif CampaignState.known_module_ids.has(state.selected_reward_id):
					experience += reward.duplicate_module_experience
				else:
					_add_unique(module_ids, state.selected_reward_id)
			PlayerActionData.ActionKind.PURIFY:
				for candidate_id: String in reward.purification_passive_module_ids:
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
					errors.append("TAME could not materialize the target PartnerState.")

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


static func _find_enemy(enemies: Array[Dictionary], uid: int) -> Dictionary:
	for enemy: Dictionary in enemies:
		if int(enemy.get("uid", -1)) == uid:
			return enemy

	return {}


static func _is_completed(
	states: Array[PlayerActionProgressData],
	action_id: String,
	target_uid: int
) -> bool:
	var state: PlayerActionProgressData = PlayerActionService.get_progress(states, action_id, target_uid)
	return state != null and state.completed


static func _deterministic_module(
	module_ids: PackedStringArray,
	salt: String,
	target_uid: int
) -> String:
	if module_ids.is_empty():
		return ""

	var index: int = posmod((CampaignState.campaign_id + salt + str(target_uid)).hash(), module_ids.size())
	return module_ids[index]


static func _add_unique(target: PackedStringArray, value: String) -> void:
	var clean_value: String = value.strip_edges()

	if not clean_value.is_empty() and not target.has(clean_value):
		target.append(clean_value)
