extends RefCounted
class_name OperatorLossService


const DEFAULT_INFESTATION_INCREASE: int = 3


static func resolve_after_combat(
	destroyed_turd: PartnerStateData,
	encounter_id: String,
	infestation_increase: int = DEFAULT_INFESTATION_INCREASE
) -> Dictionary:
	var errors := PackedStringArray()
	var metadata: Dictionary = {
		"operator_loss_required": false,
		"operator_lost": false,
		"archived_operator_id": "",
		"legacy_site_id": "",
		"infestation_increase": 0,
		"irreversible": false
	}

	if not CampaignState.has_campaign():
		errors.append("Operator Loss requires an active campaign.")
		return {"errors": errors, "metadata": metadata}

	if CampaignState.operator == null or CampaignState.operator.is_empty():
		errors.append("Operator Loss requires an active Operator.")
		return {"errors": errors, "metadata": metadata}

	if destroyed_turd == null \
		or destroyed_turd.is_empty() \
		or destroyed_turd.integrity_state != PartnerStateData.IntegrityState.TURD \
		or destroyed_turd.current_hp > 0:
		errors.append("Operator Loss requires a destroyed TURD snapshot.")
		return {"errors": errors, "metadata": metadata}

	var location_id: String = CampaignState.current_location_id.strip_edges()

	if location_id.is_empty():
		errors.append("Operator Loss requires a current location for its Legacy Site.")
		return {"errors": errors, "metadata": metadata}

	var archived_operator: Dictionary = CampaignState.operator.to_save_data()
	archived_operator["archived"] = true
	var archived_operator_id: String = str(
		archived_operator.get("operator_id", "")
	).strip_edges()
	var destroyed_turd_data: Dictionary = destroyed_turd.to_save_data()
	destroyed_turd_data["current_hp"] = 0
	var legacy_site := LegacySiteStateData.new()
	legacy_site.legacy_site_id = _build_legacy_site_id(
		archived_operator_id,
		TimeManager.get_total_action_index(),
		CampaignState.operator_history.size()
	)
	legacy_site.operator_id = archived_operator_id
	legacy_site.operator_display_name = CampaignState.operator.display_name
	legacy_site.location_id = location_id
	legacy_site.game_day = TimeManager.days_passed
	legacy_site.action_index = TimeManager.get_total_action_index()
	legacy_site.encounter_id = encounter_id
	legacy_site.recoverable_data = {
		"money": CampaignState.money,
		"inventory": CampaignState.inventory.to_save_data(),
		"known_module_ids": Array(CampaignState.known_module_ids),
		"encyclopedia_state": CampaignState.encyclopedia_state.duplicate(true),
		"game_state": GameState.export_save_data(),
		"app_sessions": AppSessionStore.export_save_data()
	}
	legacy_site.metadata = {
		"save_mode": int(CampaignState.save_mode),
		"destroyed_turd_apk_id": destroyed_turd.apk_id
	}
	errors.append_array(legacy_site.validate_state())

	if not errors.is_empty():
		return {"errors": errors, "metadata": metadata}

	var legacy_data: Dictionary = legacy_site.to_save_data()
	CampaignState.world_state.persistent_objects[
		legacy_site.get_display_id()
	] = legacy_data.duplicate(true)

	var applied_infestation: int = maxi(0, infestation_increase)

	if applied_infestation > 0:
		CampaignState.world_state.set_infestation(
			location_id,
			CampaignState.world_state.get_infestation(location_id)
			+ applied_infestation
		)

	CampaignState.operator_history.append({
		"operator": archived_operator.duplicate(true),
		"destroyed_turd": destroyed_turd_data.duplicate(true),
		"legacy_site_id": legacy_site.get_display_id(),
		"loss": {
			"reason": "turd_hp_zero",
			"location_id": location_id,
			"game_day": TimeManager.days_passed,
			"action_index": TimeManager.get_total_action_index(),
			"encounter_id": encounter_id.strip_edges()
		}
	})

	_clear_operator_scoped_state()
	CampaignState.campaign_phase = CampaignState.CampaignPhase.OPERATOR_LOSS
	GameState.set_flag("operator.registered", false)
	CampaignState.campaign_changed.emit(&"operator_loss")
	CampaignState.campaign_changed.emit(&"campaign")
	CampaignState.partner_changed.emit("")

	metadata["operator_loss_required"] = true
	metadata["operator_lost"] = true
	metadata["archived_operator_id"] = archived_operator_id
	metadata["legacy_site_id"] = legacy_site.get_display_id()
	metadata["infestation_increase"] = applied_infestation
	metadata["irreversible"] = true
	return {"errors": errors, "metadata": metadata}


static func get_legacy_site(site_id: String) -> LegacySiteStateData:
	var clean_id: String = site_id.strip_edges()
	var raw_value: Variant = CampaignState.world_state.persistent_objects.get(
		clean_id,
		{}
	)

	if raw_value is not Dictionary:
		return null

	var data := raw_value as Dictionary

	if str(data.get("object_kind", "")) != LegacySiteStateData.OBJECT_KIND:
		return null

	var site := LegacySiteStateData.from_save_data(data)
	return site if site.validate_state().is_empty() else null


static func get_legacy_sites_for_location(
	location_id: String,
	include_recovered: bool = false
) -> Array[LegacySiteStateData]:
	var result: Array[LegacySiteStateData] = []
	var clean_location: String = location_id.strip_edges()

	for raw_key: Variant in CampaignState.world_state.persistent_objects.keys():
		var site: LegacySiteStateData = get_legacy_site(str(raw_key))

		if site == null \
			or site.location_id != clean_location \
			or (site.recovered and not include_recovered):
			continue

		result.append(site)

	result.sort_custom(
		func(left: LegacySiteStateData, right: LegacySiteStateData) -> bool:
			if left.action_index != right.action_index:
				return left.action_index < right.action_index

			return left.get_display_id() < right.get_display_id()
	)
	return result


static func _clear_operator_scoped_state() -> void:
	CampaignState.operator = OperatorStateData.new()
	CampaignState.partner = PartnerStateData.new()
	CampaignState.tendencies = TendencyStateData.new()
	CampaignState.money = 0
	CampaignState.inventory = InventoryStateData.new()
	CampaignState.known_module_ids.clear()
	CampaignState.installed_app_ids.clear()
	CampaignState.active_lead_ids.clear()
	CampaignState.lead_progress.clear()
	CampaignState.incident_progress.clear()
	CampaignState.queued_story_event_ids.clear()
	CampaignState.active_story_event_id = ""
	CampaignState.active_story_event_step_index = 0
	CampaignState.active_story_event_step_id = ""
	CampaignState.active_story_event_waiting = false
	CampaignState.social_state.clear()
	CampaignState.encyclopedia_state.clear()
	GameState.reset_save_data()
	AppSessionStore.reset_save_data()


static func _build_legacy_site_id(
	operator_id: String,
	action_index: int,
	history_index: int
) -> String:
	var clean_operator: String = operator_id.strip_edges().to_lower()

	for separator: String in [" ", "@", ".", "/", "\\", ":"]:
		clean_operator = clean_operator.replace(separator, "_")

	if clean_operator.is_empty():
		clean_operator = "unknown_operator"

	return "legacy.%s.%d.%d" % [
		clean_operator,
		maxi(0, action_index),
		maxi(0, history_index)
	]
