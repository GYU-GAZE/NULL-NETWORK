extends Node


signal partner_selected(apk_id: String)
signal partner_state_changed(apk_id: String)
signal partner_leveled_up(apk_id: String, old_level: int, new_level: int)


const MIN_LEVEL: int = 1
const PRACTICAL_LEVEL_CAP: int = 80
const MAX_LEVEL: int = 100
const ACTIVE_SLOT_COUNT: int = 4


func create_partner_state(
	apk_id: String,
	nickname: String = "",
	personality_roll: int = -1,
	address_term_roll: int = -1
) -> PartnerStateData:
	var apk: APKData = ContentRegistry.get_apk(apk_id)

	if apk == null or not apk.validate_data().is_empty():
		return null

	var partner := PartnerStateData.new()
	partner.apk_id = apk.apk_id
	partner.nickname = (
		nickname.strip_edges()
		if not nickname.strip_edges().is_empty()
		else apk.display_name
	)
	partner.personality_id = _select_personality_id(apk, personality_roll)
	partner.address_term_id = _select_address_term_id(apk, address_term_roll)
	partner.active_module_ids = _module_ids(apk.default_active_modules, false)
	partner.known_active_module_ids = _module_ids(apk.default_active_modules, true)
	partner.level = MIN_LEVEL
	partner.current_exp = 0
	partner.current_stability = PartnerStateData.MAX_STABILITY
	partner.allocation_points = 0
	partner.allocated_stats = {}
	partner.integrity_state = PartnerStateData.IntegrityState.REGISTERED
	var stats: Dictionary = APKStatCalculator.calculate_stats(apk, partner)
	partner.current_hp = int(stats.get("max_hp", 1))
	return partner


func select_starter(
	apk_id: String,
	nickname: String = "",
	personality_roll: int = -1,
	address_term_roll: int = -1
) -> PackedStringArray:
	var errors := PackedStringArray()

	if not CampaignState.has_campaign():
		errors.append("A campaign must exist before choosing a starter.")

	if CampaignState.operator.is_empty():
		errors.append("An Operator must be registered before choosing a starter.")

	if not CampaignState.partner.is_empty():
		errors.append("The current Operator already has a partner.")

	if not errors.is_empty():
		return errors

	var partner: PartnerStateData = create_partner_state(
		apk_id,
		nickname,
		personality_roll,
		address_term_roll
	)

	if partner == null:
		errors.append("Starter APK '%s' is invalid or not registered." % apk_id)
		return errors

	if not CampaignState.set_partner_state(partner):
		errors.append("CampaignState rejected the generated starter partner.")
		return errors

	for module_id: String in partner.known_active_module_ids:
		CampaignState.learn_module(module_id, false)

	partner_selected.emit(partner.apk_id)
	return errors


func get_current_apk() -> APKData:
	return ContentRegistry.get_apk(CampaignState.partner.apk_id)


func validate_partner_state(partner: PartnerStateData) -> PackedStringArray:
	var errors := PackedStringArray()

	if partner == null:
		errors.append("PartnerStateData cannot be null.")
		return errors

	errors.append_array(partner.validate_state())

	if partner.is_empty():
		return errors

	var apk: APKData = ContentRegistry.get_apk(partner.apk_id)

	if apk == null:
		errors.append("Partner references unknown APK '%s'." % partner.apk_id)
		return errors

	if apk.get_personality(partner.personality_id) == null:
		errors.append("Partner personality is not available to APK '%s'." % partner.apk_id)

	if apk.get_address_term(partner.address_term_id) == null:
		errors.append("Partner address term is not available to APK '%s'." % partner.apk_id)

	for module_id: String in partner.known_active_module_ids:
		if ContentRegistry.get_module(module_id) == null:
			errors.append("Partner references unknown Module '%s'." % module_id)

	if not partner.secondary_passive_module_id.is_empty() \
		and ContentRegistry.get_module(partner.secondary_passive_module_id) == null:
		errors.append("Partner references an unknown secondary passive Module.")

	if not partner.growth_lineage.is_empty() \
		and ContentRegistry.get_apk(partner.growth_lineage) == null:
		errors.append("Partner growth_lineage references an unknown APK.")

	var minimum_exp: int = get_total_exp_for_level(partner.level)
	var next_exp: int = get_total_exp_for_level(mini(MAX_LEVEL, partner.level + 1))

	if partner.current_exp < minimum_exp \
		or (partner.level < MAX_LEVEL and partner.current_exp >= next_exp):
		errors.append("Partner EXP is inconsistent with its persisted level.")

	var stats: Dictionary = calculate_partner_stats(partner)

	if partner.current_hp > int(stats.get("max_hp", 1)):
		errors.append("Partner current HP exceeds its calculated maximum.")

	return errors


func get_current_stats() -> Dictionary:
	return calculate_partner_stats(CampaignState.partner)


func calculate_partner_stats(partner: PartnerStateData) -> Dictionary:
	if partner == null or partner.is_empty():
		return {}

	var apk: APKData = ContentRegistry.get_apk(partner.apk_id)
	var lineage: APKData = null

	if not partner.growth_lineage.strip_edges().is_empty():
		lineage = ContentRegistry.get_apk(partner.growth_lineage)

	return APKStatCalculator.calculate_stats(apk, partner, lineage)


func create_combat_snapshot(partner: PartnerStateData = null) -> CharacterLoadout:
	var source: PartnerStateData = partner if partner != null else CampaignState.partner

	if source == null or source.is_empty():
		return null

	var apk: APKData = ContentRegistry.get_apk(source.apk_id)
	var stats: Dictionary = calculate_partner_stats(source)

	if apk == null or stats.is_empty():
		return null

	var loadout := CharacterLoadout.new()
	loadout.character_id = StringName(source.apk_id)
	loadout.char_name = source.nickname if not source.nickname.is_empty() else apk.display_name
	loadout.combat_icon = apk.combat_icon
	loadout.level = source.level
	loadout.apk_type = APKData.FormType.keys()[apk.form_type]
	loadout.max_hp = int(stats["max_hp"])
	loadout.starting_hp = clampi(source.current_hp, 0, loadout.max_hp)
	loadout.max_stability = PartnerStateData.MAX_STABILITY
	loadout.starting_stability = clampi(source.current_stability, 0, 100)
	loadout.stability_recovery = int(stats["stability_recovery"])
	loadout.base_atk = int(stats["atk"])
	loadout.base_def = int(stats["def"])
	loadout.base_matk = int(stats["matk"])
	loadout.base_mdef = int(stats["mdef"])
	loadout.dodge_chance = float(stats["dodge"])
	loadout.crit_chance = float(stats["crit"])
	loadout.equipped_modules = _resolve_modules(source.active_module_ids, false)
	loadout.module_pool = _resolve_modules(source.known_active_module_ids, true)
	return loadout


func commit_combat_snapshot(actor: Dictionary, experience_gain: int = 0) -> PackedStringArray:
	var errors := PackedStringArray()

	if CampaignState.partner.is_empty():
		errors.append("No persistent partner exists for combat write-back.")
		return errors

	if str(actor.get("character_id", "")) != CampaignState.partner.apk_id:
		errors.append("Combat actor does not match the persistent partner APK.")
		return errors

	var stats_before: Dictionary = get_current_stats()
	CampaignState.partner.current_hp = clampi(
		roundi(float(actor.get("hp", 0.0))),
		0,
		int(stats_before.get("max_hp", 1))
	)
	CampaignState.partner.current_stability = clampi(
		roundi(float(actor.get("stability", 0.0))),
		0,
		PartnerStateData.MAX_STABILITY
	)
	var module_ids := PackedStringArray()

	for raw_module: Variant in actor.get("modules", []):
		var module := raw_module as ModuleData
		module_ids.append(str(module.module_id) if module != null else "")

	var modules_known: bool = true

	for module_id: String in module_ids:
		if not CampaignState.partner.known_active_module_ids.has(module_id):
			modules_known = false
			break

	if module_ids.size() == ACTIVE_SLOT_COUNT \
		and not module_ids.has("") \
		and modules_known:
		CampaignState.partner.active_module_ids = module_ids
	else:
		errors.append("Combat snapshot does not contain four valid known active Modules.")

	if errors.is_empty() and experience_gain > 0:
		errors.append_array(grant_experience(experience_gain))

	if errors.is_empty():
		CampaignState.notify_partner_changed()
		partner_state_changed.emit(CampaignState.partner.apk_id)

	return errors


func grant_experience(amount: int) -> PackedStringArray:
	var errors := PackedStringArray()

	if CampaignState.partner.is_empty():
		errors.append("Cannot grant EXP without a persistent partner.")
		return errors

	if amount <= 0 or CampaignState.partner.level >= MAX_LEVEL:
		return errors

	var old_level: int = CampaignState.partner.level
	var old_stats: Dictionary = get_current_stats()
	CampaignState.partner.current_exp += amount

	while CampaignState.partner.level < MAX_LEVEL:
		var next_level: int = CampaignState.partner.level + 1

		if CampaignState.partner.current_exp < get_total_exp_for_level(next_level):
			break

		CampaignState.partner.level = next_level
		CampaignState.partner.allocation_points += 1
		_apply_level_rewards(next_level)

	if CampaignState.partner.level >= MAX_LEVEL:
		CampaignState.partner.current_exp = get_total_exp_for_level(MAX_LEVEL)

	if CampaignState.partner.level != old_level:
		var new_stats: Dictionary = get_current_stats()
		var hp_difference: int = int(new_stats.get("max_hp", 1)) - int(old_stats.get("max_hp", 1))
		CampaignState.partner.current_hp = clampi(
			CampaignState.partner.current_hp + hp_difference,
			1 if CampaignState.partner.current_hp > 0 else 0,
			int(new_stats.get("max_hp", 1))
		)
		partner_leveled_up.emit(CampaignState.partner.apk_id, old_level, CampaignState.partner.level)

	CampaignState.notify_partner_changed()
	partner_state_changed.emit(CampaignState.partner.apk_id)
	return errors


func allocate_stat(stat_id: String, amount: int = 1) -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_stat: String = stat_id.strip_edges().to_lower()

	if CampaignState.partner.is_empty():
		errors.append("Cannot allocate stats without a persistent partner.")
	elif not PartnerStateData.ALLOCATABLE_STATS.has(clean_stat):
		errors.append("Unknown allocatable stat '%s'." % clean_stat)
	elif amount <= 0:
		errors.append("Allocation amount must be positive.")
	elif amount > CampaignState.partner.allocation_points:
		errors.append("Not enough Allocation Points.")
	elif CampaignState.partner.get_allocated_stat(clean_stat) + amount > CampaignState.partner.get_maximum_allocation_per_stat():
		errors.append("Allocation exceeds the per-stat concentration limit.")

	if not errors.is_empty():
		return errors

	var old_stats: Dictionary = get_current_stats()
	CampaignState.partner.allocated_stats[clean_stat] = (
		CampaignState.partner.get_allocated_stat(clean_stat) + amount
	)
	CampaignState.partner.allocation_points -= amount
	var new_stats: Dictionary = get_current_stats()
	var hp_difference: int = int(new_stats.get("max_hp", 1)) - int(old_stats.get("max_hp", 1))
	CampaignState.partner.current_hp = clampi(
		CampaignState.partner.current_hp + hp_difference,
		1 if CampaignState.partner.current_hp > 0 else 0,
		int(new_stats.get("max_hp", 1))
	)
	CampaignState.notify_partner_changed()
	partner_state_changed.emit(CampaignState.partner.apk_id)
	return errors


func get_exp_for_next_level(level: int) -> int:
	var clean_level: int = clampi(level, MIN_LEVEL, MAX_LEVEL)

	if clean_level >= MAX_LEVEL:
		return 0

	var base: int = 3 * clean_level * clean_level + 3 * clean_level + 1

	if clean_level < PRACTICAL_LEVEL_CAP:
		return base

	return base * 100 * int(pow(2.0, clean_level - PRACTICAL_LEVEL_CAP))


func get_total_exp_for_level(level: int) -> int:
	var target: int = clampi(level, MIN_LEVEL, MAX_LEVEL)

	if target <= PRACTICAL_LEVEL_CAP:
		return target * target * target - 1

	var total: int = PRACTICAL_LEVEL_CAP * PRACTICAL_LEVEL_CAP * PRACTICAL_LEVEL_CAP - 1

	for current_level: int in range(PRACTICAL_LEVEL_CAP, target):
		total += get_exp_for_next_level(current_level)

	return total


func _apply_level_rewards(level: int) -> void:
	var apk: APKData = get_current_apk()

	if apk == null:
		return

	for reward: APKLevelRewardData in apk.learnable_modules:
		if reward == null or reward.required_level != level:
			continue

		for module_id: String in reward.active_module_ids:
			if not CampaignState.partner.known_active_module_ids.has(module_id):
				CampaignState.partner.known_active_module_ids.append(module_id)
			CampaignState.learn_module(module_id, false)


func _select_personality_id(apk: APKData, roll: int) -> String:
	var index: int = _controlled_index(apk.apk_id + "|personality", roll, apk.available_personalities.size())
	return apk.available_personalities[index].personality_id


func _select_address_term_id(apk: APKData, roll: int) -> String:
	var index: int = _controlled_index(apk.apk_id + "|address", roll, apk.available_address_terms.size())
	return apk.available_address_terms[index].address_term_id


func _controlled_index(salt: String, roll: int, size: int) -> int:
	if size <= 0:
		return 0

	if roll >= 0:
		return posmod(roll, size)

	var identity: String = "%s|%s|%s" % [CampaignState.campaign_id, CampaignState.operator.operator_id, salt]
	return posmod(identity.hash(), size)


func _module_ids(modules: Array[ModuleData], unique_only: bool) -> PackedStringArray:
	var ids := PackedStringArray()

	for module: ModuleData in modules:
		if module == null:
			continue

		var module_id: String = str(module.module_id)

		if not unique_only or not ids.has(module_id):
			ids.append(module_id)

	return ids


func _resolve_modules(ids: PackedStringArray, unique_only: bool) -> Array[ModuleData]:
	var modules: Array[ModuleData] = []
	var seen := PackedStringArray()

	for module_id: String in ids:
		var module: ModuleData = ContentRegistry.get_module(module_id)

		if module == null or (unique_only and seen.has(module_id)):
			continue

		modules.append(module)
		seen.append(module_id)

	return modules
