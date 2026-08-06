extends RefCounted
class_name ProfileProjectionService


## Read-only projection for the KubuOS Profile app.
##
## The service never owns campaign state. It resolves mutable IDs from
## CampaignState against immutable catalog Resources and returns one runtime
## snapshot that presentation code may render without duplicating rules.

static func build_snapshot() -> Dictionary:
	if not CampaignState.has_campaign():
		return {
			"has_campaign": false,
			"operator": {},
			"tendencies": [],
			"partner": {},
			"equipped_modules": [],
			"known_modules": [],
			"inventory": [],
			"money": 0
		}

	return {
		"has_campaign": true,
		"operator": _build_operator_snapshot(),
		"tendencies": _build_tendency_snapshot(),
		"partner": _build_partner_snapshot(),
		"equipped_modules": _build_equipped_modules(),
		"known_modules": _build_known_modules(),
		"inventory": _build_inventory_snapshot(),
		"money": CampaignState.money
	}


static func _build_operator_snapshot() -> Dictionary:
	var state: OperatorStateData = CampaignState.operator

	if state == null or state.is_empty():
		return {}

	var profile: OperatorProfileData = state.profile
	var occupation: OccupationData = ContentRegistry.get_occupation(
		profile.occupation_id
	)
	var network_user: NetworkUserData = NetworkUserDatabase.get_user_by_id(
		profile.username
	)
	var full_name: String = "%s %s" % [
		profile.first_name.strip_edges(),
		profile.last_name.strip_edges()
	]
	var rank_text: String = "UNRANKED"
	var avatar: Texture2D = null

	if network_user != null:
		avatar = network_user.avatar
		var network_rank: String = network_user.rank_label.strip_edges()

		if not network_rank.is_empty():
			rank_text = network_rank.to_upper()

	return {
		"operator_id": state.operator_id,
		"display_name": state.display_name,
		"full_name": full_name.strip_edges(),
		"username": profile.username.strip_edges(),
		"occupation_id": profile.occupation_id.strip_edges(),
		"occupation_name": (
			occupation.get_display_name()
			if occupation != null
			else profile.occupation_id.strip_edges()
		),
		"server_id": profile.server_id.strip_edges(),
		"server_name": profile.server_id.replace("_", ", ").to_upper(),
		"rank_text": rank_text,
		"gender": profile.gender.strip_edges(),
		"pronoun_set_id": profile.pronoun_set_id.strip_edges(),
		"level": state.level,
		"experience": state.experience,
		"avatar": avatar
	}


static func _build_tendency_snapshot() -> Array[Dictionary]:
	var values: Array[Dictionary] = [
		{
			"id": "valour",
			"display_name": "VALOUR",
			"value": CampaignState.tendencies.valour
		},
		{
			"id": "logic",
			"display_name": "LOGIC",
			"value": CampaignState.tendencies.logic
		},
		{
			"id": "sync",
			"display_name": "SYNC",
			"value": CampaignState.tendencies.sync
		},
		{
			"id": "self",
			"display_name": "SELF",
			"value": CampaignState.tendencies.self_value
		}
	]
	var total: int = maxi(1, CampaignState.tendencies.get_total())

	for entry: Dictionary in values:
		entry["share"] = float(int(entry["value"])) / float(total)

	return values


static func _build_partner_snapshot() -> Dictionary:
	var state: PartnerStateData = CampaignState.partner

	if state == null or state.is_empty():
		return {}

	var apk: APKData = ContentRegistry.get_apk(state.apk_id)
	var stats: Dictionary = APKProgressionService.calculate_partner_stats(state)
	var personality: APKPersonalityData = (
		apk.get_personality(state.personality_id)
		if apk != null
		else null
	)
	var address_term: AddressTermData = (
		apk.get_address_term(state.address_term_id)
		if apk != null
		else null
	)
	var level_floor: int = APKProgressionService.get_total_exp_for_level(
		state.level
	)
	var next_level_total: int = (
		APKProgressionService.get_total_exp_for_level(state.level + 1)
		if state.level < APKProgressionService.MAX_LEVEL
		else level_floor
	)
	var exp_into_level: int = maxi(0, state.current_exp - level_floor)
	var exp_required: int = maxi(0, next_level_total - level_floor)
	var portrait: Texture2D = null

	if apk != null:
		if not apk.portraits.is_empty():
			portrait = apk.portraits[0]
		elif apk.combat_icon != null:
			portrait = apk.combat_icon

	return {
		"apk_id": state.apk_id,
		"nickname": state.nickname,
		"species_name": apk.display_name if apk != null else state.apk_id,
		"species_line_id": apk.species_line_id if apk != null else "",
		"form_name": (
			APKData.FormType.keys()[apk.form_type]
			if apk != null
			else "UNKNOWN"
		),
		"integrity_name": PartnerStateData.IntegrityState.keys()[
			state.integrity_state
		],
		"level": state.level,
		"current_exp": state.current_exp,
		"exp_into_level": exp_into_level,
		"exp_required": exp_required,
		"exp_ratio": (
			1.0
			if state.level >= APKProgressionService.MAX_LEVEL
			else float(exp_into_level) / float(maxi(1, exp_required))
		),
		"current_hp": state.current_hp,
		"max_hp": int(stats.get("max_hp", 1)),
		"current_stability": state.current_stability,
		"max_stability": PartnerStateData.MAX_STABILITY,
		"affinity": state.affinity,
		"personality_name": (
			personality.display_name
			if personality != null
			else state.personality_id
		),
		"address_term": (
			address_term.resolve_text(CampaignState.operator.profile)
			if address_term != null
			else state.address_term_id
		),
		"allocation_points": state.allocation_points,
		"stats": [
			{"id": "atk", "display_name": "ATK", "value": int(stats.get("atk", 0))},
			{"id": "def", "display_name": "DEF", "value": int(stats.get("def", 0))},
			{"id": "matk", "display_name": "MATK", "value": int(stats.get("matk", 0))},
			{"id": "mdef", "display_name": "MDEF", "value": int(stats.get("mdef", 0))},
			{"id": "dodge", "display_name": "DODGE", "value": float(stats.get("dodge", 0.0))},
			{"id": "crit", "display_name": "CRIT", "value": float(stats.get("crit", 0.0))},
			{
				"id": "stability_recovery",
				"display_name": "STB REC",
				"value": int(stats.get("stability_recovery", 0))
			}
		],
		"portrait": portrait
	}


static func _build_equipped_modules() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for slot_index: int in range(CampaignState.partner.active_module_ids.size()):
		var module_id: String = CampaignState.partner.active_module_ids[slot_index]
		var entry: Dictionary = _module_entry(module_id)
		entry["slot_index"] = slot_index
		result.append(entry)

	return result


static func _build_known_modules() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for module_id: String in CampaignState.partner.known_active_module_ids:
		result.append(_module_entry(module_id))

	var passive_id: String = CampaignState.partner.secondary_passive_module_id

	if not passive_id.is_empty():
		var passive_entry: Dictionary = _module_entry(passive_id)
		passive_entry["secondary_passive"] = true
		result.append(passive_entry)

	result.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return str(left.get("display_name", "")).naturalnocasecmp_to(
				str(right.get("display_name", ""))
			) < 0
	)
	return result


static func _module_entry(module_id: String) -> Dictionary:
	var module: ModuleData = ContentRegistry.get_module(module_id)

	return {
		"module_id": module_id.strip_edges(),
		"display_name": (
			module.module_name
			if module != null
			else module_id.strip_edges()
		),
		"classification": (
			str(module.classification)
			if module != null
			else ""
		),
		"module_kind": (
			int(module.module_kind)
			if module != null
			else ModuleData.ModuleKind.ACTIVE
		),
		"icon": module.module_icon if module != null else null,
		"secondary_passive": false
	}


static func _build_inventory_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for inventory_entry: InventoryEntryData in CampaignState.inventory.entries:
		if inventory_entry == null or inventory_entry.amount <= 0:
			continue

		var item: ItemData = ContentRegistry.get_item(inventory_entry.item_id)
		result.append({
			"item_id": inventory_entry.item_id,
			"display_name": (
				item.display_name
				if item != null
				else inventory_entry.item_id
			),
			"amount": inventory_entry.amount,
			"item_type": (
				int(item.item_type)
				if item != null
				else ItemData.ItemType.MATERIAL
			),
			"icon": item.icon if item != null else null
		})

	result.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return str(left.get("display_name", "")).naturalnocasecmp_to(
				str(right.get("display_name", ""))
			) < 0
	)
	return result
