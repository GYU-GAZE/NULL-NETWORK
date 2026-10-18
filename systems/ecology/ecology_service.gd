extends Node

## Campaign-wide ecological authority. Definitions come from ContentRegistry;
## all mutable state and the exactly-once ledger live in WorldStateData.
signal zone_changed(zone_id: String, species_ids: PackedStringArray, reason: String)
signal zone_collapsed(zone_id: String)
signal feedback_requested(zone_id: String, text: String)
signal predator_changed
var _busy: bool = false
var _event_action_index: int = -1
var _resuming: bool = false
var _condition_bindings: Dictionary = {}
var _pressure_signatures: Dictionary = {}

func _ready() -> void:
	GlobalSignals.time_advanced.connect(_on_time)
	CampaignState.campaign_created.connect(func(_id: String) -> void: _resume.call_deferred())
	SaveManager.campaign_loaded.connect(func(_id: String, _backup: bool) -> void: _resume())
	ContentRegistry.registry_rebuilt.connect(func() -> void: _resume.call_deferred())
	SaveManager.register_save_section(self)
	CampaignState.campaign_changed.connect(_on_world_section)
	GameState.number_changed.connect(_on_danger)

func get_save_section_id() -> String:
	return "ecology_lifecycle"
func export_save_data() -> Dictionary:
	return {"version": 1} # Mutable data belongs exclusively to CampaignState.world_state.
func import_save_data(_data: Dictionary) -> void:
	pass # SaveManager.campaign_loaded resumes only after every provider is restored.
func reset_save_data() -> void:
	_busy = false
func can_save_now() -> bool:
	return not _busy

func definitions() -> Array[EcologyZoneData]:
	var result: Array[EcologyZoneData] = []
	var ids := {}
	for resource: Resource in ContentRegistry.get_all(ContentRegistry.CATEGORY_ECOLOGY_ZONES):
		var zone := resource as EcologyZoneData
		if zone != null:
			result.append(zone)
			ids[zone.ecology_zone_id] = true
	for resource: Resource in ContentRegistry.get_all(ContentRegistry.CATEGORY_LOCATIONS):
		var location := resource as MapLocation
		if location != null and location.ecology_zone != null and not ids.has(location.ecology_zone.ecology_zone_id):
			result.append(location.ecology_zone)
			ids[location.ecology_zone.ecology_zone_id] = true
	result.sort_custom(func(a: EcologyZoneData, b: EcologyZoneData) -> bool: return a.ecology_zone_id < b.ecology_zone_id)
	return result

func definition(id: String) -> EcologyZoneData:
	for zone: EcologyZoneData in definitions():
		if zone.ecology_zone_id == id: return zone
	return null

func zone_for_location(location_id: String) -> EcologyZoneData:
	var location := ContentRegistry.get_location(location_id)
	if location != null and location.ecology_zone != null: return location.ecology_zone
	for zone: EcologyZoneData in definitions():
		if location_id in zone.location_ids: return zone
	return null

func context(zone: EcologyZoneData) -> Dictionary:
	var location_id := zone.location_ids[0] if not zone.location_ids.is_empty() else ""
	var result := {"ecology_zone_id": zone.ecology_zone_id, "location_id": location_id, "days_passed": TimeManager.days_passed, "current_period": int(TimeManager.current_period), "current_action_block": TimeManager.current_action_block, "infestation": CampaignState.world_state.get_infestation(location_id)}
	if _event_action_index >= 0:
		result["days_passed"] = int(_event_action_index / 24) + 1
		result["current_period"] = int((_event_action_index % 24) / 12)
		result["current_action_block"] = _event_action_index % 12
	if not zone.danger_number_key.is_empty(): result["danger"] = GameState.get_number(zone.danger_number_key)
	return result

func ensure_zone(zone: EcologyZoneData) -> Dictionary:
	if zone == null or not CampaignState.has_campaign(): return {}
	var zones := CampaignState.world_state.ecology_zones
	if not zones.has(zone.ecology_zone_id):
		var species := {}
		var remaining := zone.population_capacity
		for entry: EcologySpeciesData in zone.species:
			var base := mini(remaining, _base(entry, context(zone)))
			species[entry.species_line_id] = {"species_line_id": entry.species_line_id, "population_base": base, "population_capacity": entry.population_capacity, "population_current": base, "purify_resonance": 0, "ecology_status": "STABLE" if base > 0 else "LOCALLY ABSENT", "last_update": TimeManager.get_total_action_index()}
			remaining -= base
		zones[zone.ecology_zone_id] = {"version": 1, "ecology_zone_id": zone.ecology_zone_id, "population_capacity": zone.population_capacity, "species": species, "collapsed": false, "ecology_status": "HEALTHY", "last_update": TimeManager.get_total_action_index(), "last_micro_update_day": TimeManager.days_passed, "revision": 0, "projection_epoch": 0, "applied_effect_receipts": {}, "history": []}
		zones[zone.ecology_zone_id]["ecology_status"] = status(zone, zones[zone.ecology_zone_id])
		for entry: Dictionary in zones[zone.ecology_zone_id].species.values():
			entry["ecology_status"] = zones[zone.ecology_zone_id].ecology_status if int(entry.population_current) > 0 else "LOCALLY ABSENT"
	return zones[zone.ecology_zone_id]

func snapshot(id: String) -> Dictionary:
	return ensure_zone(definition(id)).duplicate(true)

func _base(species: EcologySpeciesData, rules_context: Dictionary) -> int:
	var value := species.population_base
	for rule: EcologyPressureRuleData in species.pressure_rules:
		if rule.matches(rules_context): value += rule.population_base_bonus
	return clampi(value, 0, species.population_capacity)

func total(state: Dictionary) -> int:
	var value := 0
	for species: Dictionary in state.get("species", {}).values(): value += int(species.get("population_current", 0))
	return value

func status(zone: EcologyZoneData, state: Dictionary) -> String:
	if bool(state.get("collapsed", false)): return "COLLAPSED"
	var count := total(state)
	if count == 1: return "LAST SIGNATURE"
	var base := 0
	for entry: Dictionary in state.get("species", {}).values(): base += int(entry.get("population_base", 0))
	var ratio := float(count) / maxf(1, base)
	if ratio >= zone.presentation.healthy_ratio: return "HEALTHY"
	if ratio >= zone.presentation.stable_ratio: return "STABLE"
	if ratio >= zone.presentation.declining_ratio: return "DECLINING"
	return "CRITICAL"

func status_text(zone: EcologyZoneData) -> String:
	if zone == null: return ""
	var state := ensure_zone(zone)
	match status(zone, state):
		"COLLAPSED": return zone.presentation.collapsed_text
		"LAST SIGNATURE": return zone.presentation.last_signature_text
		"HEALTHY": return zone.presentation.healthy_text
		"STABLE": return zone.presentation.stable_text
		"DECLINING": return zone.presentation.declining_text
	return zone.presentation.critical_text

func population(zone_id: String, species_id: String) -> int:
	return int(ensure_zone(definition(zone_id)).get("species", {}).get(species_id, {}).get("population_current", 0))

func resonance(zone_id: String, species_id: String) -> int:
	return int(ensure_zone(definition(zone_id)).get("species", {}).get(species_id, {}).get("purify_resonance", 0))

func projection_context(zone: EcologyZoneData, desired: int) -> Dictionary:
	if zone == null: return {}
	var state := ensure_zone(zone)
	var limits := {}
	var weights := {}
	var rules_context := context(zone)
	var enabled := not bool(state.get("collapsed", false)) and (zone.conditions == null or zone.conditions.is_met(rules_context))
	for species: EcologySpeciesData in zone.species:
		var current := population(zone.ecology_zone_id, species.species_line_id)
		var base := maxi(1, int(state.get("species", {}).get(species.species_line_id, {}).get("population_base", species.population_base)))
		var frequency := species.frequency * float(current) / base * (1.0 + resonance(zone.ecology_zone_id, species.species_line_id) * zone.resonance_presence_bonus)
		for rule: EcologyPressureRuleData in species.pressure_rules:
			if rule.matches(rules_context): frequency *= rule.frequency_multiplier
		if not enabled or (species.conditions != null and not species.conditions.is_met(rules_context)): frequency = 0
		limits[species.species_line_id] = mini(current, mini(desired, ceili(desired * frequency))) if frequency > 0 else 0
		weights[species.species_line_id] = frequency
	return {"ecology_zone_id": zone.ecology_zone_id, "ecology_limits": limits, "ecology_weights": weights}

func eligible_variants(zone: EcologyZoneData, species_id: String) -> Array[EcologyVariantData]:
	var result: Array[EcologyVariantData] = []
	var species := zone.get_species(species_id)
	if species == null or population(zone.ecology_zone_id, species_id) == 0: return result
	var candidates: Array[EcologyVariantData] = species.variants.duplicate()
	var rules_context := context(zone)
	for rule: EcologyPressureRuleData in species.pressure_rules:
		if rule.matches(rules_context): candidates.append_array(rule.variant_additions)
	for variant: EcologyVariantData in candidates:
		if species_id in variant.species_line_ids and (variant.zone_ids.is_empty() or zone.ecology_zone_id in variant.zone_ids) and resonance(zone.ecology_zone_id, species_id) >= variant.minimum_resonance and (variant.conditions == null or variant.conditions.is_met(rules_context)):
			result.append(variant)
	return result

func select_variant(zone: EcologyZoneData, species_id: String, seed_value: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var choices := eligible_variants(zone, species_id)
	var weight := 1.0 # Standard/no Node remains a compatible authored baseline.
	for variant: EcologyVariantData in choices: weight += variant.weight + variant.resonance_weight_bonus * resonance(zone.ecology_zone_id, species_id)
	var roll := rng.randf() * weight - 1.0
	if roll < 0: return ""
	for variant: EcologyVariantData in choices:
		roll -= variant.weight + variant.resonance_weight_bonus * resonance(zone.ecology_zone_id, species_id)
		if roll < 0: return variant.node_id
	return ""

func _resume() -> void:
	if _resuming or not CampaignState.has_campaign() or SaveManager.is_runtime_busy(): return
	_resuming = true
	for zone: EcologyZoneData in definitions(): ensure_zone(zone)
	_bind_conditions()
	_update_route_completeness()
	consume_pending_receipts()
	_process_time()
	_resuming = false

func _on_time(_period: int, _days: int, _day: int, _month: String) -> void:
	if CampaignState.has_campaign() and not SaveManager.is_runtime_busy(): _process_time()

func _process_time() -> void:
	if _busy: return
	_busy = true
	var through := TimeManager.get_total_action_index()
	var events: Array[Dictionary] = []
	for zone: EcologyZoneData in definitions():
		var state := ensure_zone(zone)
		var previous := int(state.get("last_update", through))
		var previous_day := int(state.get("last_micro_update_day", TimeManager.days_passed))
		for day: int in range(previous_day + 1, TimeManager.days_passed + 1):
			if int(TimeManager.get_date_for_game_day(day).weekday) == zone.micro_update_weekday:
				events.append({"at": (day - 1) * 24, "priority": 0, "zone": zone, "day": day, "id": zone.ecology_zone_id})
		for activity: EcologyNPCActivityData in zone.npc_activities:
			var first := int(previous / activity.interval_blocks) + 1
			var last := int(through / activity.interval_blocks)
			for cycle: int in range(first, last + 1):
				events.append({"at": cycle * activity.interval_blocks, "priority": 1, "zone": zone, "activity": activity, "cycle": cycle, "id": zone.ecology_zone_id + "." + activity.activity_id})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.at != b.at: return int(a.at) < int(b.at)
		if a.priority != b.priority: return int(a.priority) < int(b.priority)
		return str(a.id) < str(b.id))
	for event: Dictionary in events:
		_event_action_index = int(event.at)
		if int(event.priority) == 0: _micro_update(event.zone, int(event.day))
		else: _npc_activity(event.zone, event.activity, int(event.cycle))
	_event_action_index = -1
	for zone: EcologyZoneData in definitions():
		var state := ensure_zone(zone)
		state["last_update"] = through
		state["last_micro_update_day"] = TimeManager.days_passed
	_busy = false

func _micro_update(zone: EcologyZoneData, day: int) -> void:
	var state := ensure_zone(zone)
	var receipt := "micro_update.%s.%d" % [zone.ecology_zone_id, day]
	if bool(state.collapsed) or state.applied_effect_receipts.has(receipt): return
	if zone.conditions != null and not zone.conditions.is_met(context(zone)): return
	var rules_context := context(zone)
	for species: EcologySpeciesData in zone.species:
		if species.conditions != null and not species.conditions.is_met(rules_context): continue
		var entry: Dictionary = state.species[species.species_line_id]
		var recovery := species.weekly_recovery
		for rule: EcologyPressureRuleData in species.pressure_rules:
			if rule.matches(rules_context): recovery += rule.weekly_recovery_bonus
		entry.population_base = _base(species, rules_context)
		var room := maxi(0, zone.population_capacity - total(state))
		entry.population_current = mini(species.population_capacity, int(entry.population_current) + mini(room, maxi(0, recovery)))
		entry.purify_resonance = maxi(0, int(entry.purify_resonance) - species.weekly_resonance_decay)
	for migration: EcologyMigrationData in zone.migrations:
		if migration.conditions != null and not migration.conditions.is_met(rules_context): continue
		var source := definition(migration.source_zone_id)
		if source == null or source == zone or zone.get_species(migration.species_line_id) == null: continue
		var source_state := ensure_zone(source)
		if bool(source_state.collapsed): continue
		var source_entry: Dictionary = source_state.species.get(migration.species_line_id, {})
		if source_entry.is_empty(): continue
		var target_entry: Dictionary = state.species[migration.species_line_id]
		var count := mini(migration.maximum_units, maxi(0, int(source_entry.population_current) - migration.leave_in_source))
		count = mini(count, maxi(0, total(source_state) - 1))
		count = mini(count, mini(zone.get_species(migration.species_line_id).population_capacity - int(target_entry.population_current), zone.population_capacity - total(state)))
		if count > 0:
			source_entry.population_current -= count
			target_entry.population_current += count
			_changed(source, PackedStringArray([migration.species_line_id]), "migration")
	state.applied_effect_receipts[receipt] = {"source": "micro_update", "day": day}
	if zone.recompile_on_micro_update: state.projection_epoch = int(state.projection_epoch) + 1
	_changed(zone, PackedStringArray(state.species.keys()), "micro_update")
	feedback_requested.emit(zone.ecology_zone_id, zone.presentation.weekly_feedback)

func _npc_activity(zone: EcologyZoneData, activity: EcologyNPCActivityData, cycle: int) -> void:
	if zone.conditions != null and not zone.conditions.is_met(context(zone)): return
	if activity.conditions != null and not activity.conditions.is_met(context(zone)): return
	if ContentRegistry.get_npc(activity.npc_id) == null: return
	var operation: String = EcologyNPCActivityData.Operation.keys()[activity.operation]
	var receipt := {"operation_id": "npc.%s.%s.%d" % [zone.ecology_zone_id, activity.activity_id, cycle], "zone_id": zone.ecology_zone_id, "species_line_id": activity.species_line_id, "operation": operation, "source": "npc", "target_id": activity.npc_id, "formal_result": true, "provenance": activity.resource_path}
	receipt["infestation_delta"] = activity.infestation_delta
	receipt["danger_delta"] = activity.danger_delta
	apply_operation(receipt)

func apply_operation(operation: Dictionary) -> bool:
	var zone := definition(str(operation.get("zone_id", "")))
	if zone == null or not bool(operation.get("formal_result", false)): return false
	var state := ensure_zone(zone)
	var id := str(operation.get("operation_id", ""))
	if id.is_empty() or state.applied_effect_receipts.has(id): return false
	var species_id := str(operation.get("species_line_id", ""))
	var kind := str(operation.get("operation", ""))
	var entry: Dictionary = state.species.get(species_id, {})
	if entry.is_empty() and kind in ["PURGE", "PURIFY"]: return false
	if bool(state.collapsed) and kind in ["PURGE", "PURIFY"]: return false
	var previous_busy := _busy
	var delta := 0
	if kind == "PURGE":
		if int(entry.population_current) <= 0: return false
		if total(state) <= 1:
			if str(operation.get("source", "")) != "protagonist" or not bool(operation.get("collapse_authorized", false)): return false
		entry.population_current = int(entry.population_current) - 1
		delta = -1
	elif kind == "PURIFY": entry.purify_resonance = mini(3, int(entry.purify_resonance) + 1)
	elif kind not in ["CONTAIN_SWARM", "WORLD_PRESSURE"]: return false
	_busy = true
	state.applied_effect_receipts[id] = operation.merged({"applied": true, "applied_population_delta": delta}, true)
	var location_id := zone.location_ids[0]
	var infestation_delta := int(operation.get("infestation_delta", 0))
	if infestation_delta != 0:
		CampaignState.world_state.set_infestation(location_id, maxi(0, CampaignState.world_state.get_infestation(location_id) + infestation_delta))
		CampaignState.campaign_changed.emit(&"world_infestation")
	var danger_delta := int(operation.get("danger_delta", 0))
	if danger_delta != 0 and not zone.danger_number_key.is_empty(): GameState.set_number(zone.danger_number_key, GameState.get_number(zone.danger_number_key) + danger_delta)
	if total(state) == 0 and kind == "PURGE":
		state.collapsed = true
		for value: Dictionary in state.species.values(): value.purify_resonance = 0
		_register_collapse(zone)
	_changed(zone, PackedStringArray([species_id]), kind)
	if kind in ["PURGE", "PURIFY"]: feedback_requested.emit(zone.ecology_zone_id, zone.presentation.purge_feedback if kind == "PURGE" else zone.presentation.purify_feedback)
	_busy = previous_busy
	return true

func _changed(zone: EcologyZoneData, species_ids: PackedStringArray, reason: String) -> void:
	var state := ensure_zone(zone)
	state.revision = int(state.revision) + 1
	state.ecology_status = status(zone, state)
	state.last_update = _event_action_index if _event_action_index >= 0 else TimeManager.get_total_action_index()
	for id: String in state.species:
		var species_state: Dictionary = state.species[id]
		species_state["ecology_status"] = "COLLAPSED" if bool(state.collapsed) else ("LOCALLY ABSENT" if int(species_state.population_current) == 0 else str(state.ecology_status))
		if id in species_ids: species_state["last_update"] = state.last_update
	state.history.append({"at": state.last_update, "reason": reason, "status": state.ecology_status})
	if state.history.size() > 24: state.history.pop_front()
	GameState.set_flag("ecology.%s.collapsed" % zone.ecology_zone_id, bool(state.collapsed))
	GameState.set_flag("ecology.%s.last_signature" % zone.ecology_zone_id, total(state) == 1 and not bool(state.collapsed))
	for species_id: String in species_ids:
		GameState.set_flag("ecology.%s.%s.absent" % [zone.ecology_zone_id, species_id], population(zone.ecology_zone_id, species_id) == 0)
		GameState.set_number("ecology.%s.%s.resonance" % [zone.ecology_zone_id, species_id], resonance(zone.ecology_zone_id, species_id))
	CampaignState.campaign_changed.emit(&"ecology")
	SaveManager.request_checkpoint(&"ecology.settled")
	zone_changed.emit(zone.ecology_zone_id, species_ids, reason)

func _register_collapse(zone: EcologyZoneData) -> void:
	var route := CampaignState.world_state.ecology_route
	var collapsed: Array = route.get("collapsed_zone_ids", [])
	if zone.ecology_zone_id in collapsed: return
	collapsed.append(zone.ecology_zone_id)
	route["collapsed_zone_ids"] = collapsed
	route["collapse_count"] = collapsed.size()
	var predator_definition := zone.predator
	var existing_path := str(route.get("predator", {}).get("profile_path", ""))
	if existing_path.begins_with("res://") and ResourceLoader.exists(existing_path): predator_definition = load(existing_path) as EcologyPredatorData
	if predator_definition == null:
		for known: EcologyZoneData in definitions():
			if known.predator != null:
				predator_definition = known.predator
				break
	if predator_definition != null:
		var predator: Dictionary = route.get("predator", {})
		if str(predator.get("id", "")).is_empty(): predator["id"] = predator_definition.predator_id + "." + CampaignState.campaign_id
		predator["profile_path"] = predator_definition.resource_path
		if str(predator.get("status", "")) == "RECOMPILING": predator["locations"] = {}
		predator["status"] = "ACTIVE"
		predator["identified_operator_id"] = CampaignState.operator.operator_id
		predator["identified_campaign_id"] = CampaignState.campaign_id
		predator["collapse_count"] = collapsed.size()
		var modules: Array = predator.get("assimilated_module_ids", [])
		for stage: EcologyPredatorStageData in predator_definition.stages:
			if stage.minimum_collapses <= collapsed.size():
				for id: String in stage.active_module_ids:
					if ContentRegistry.get_module(id) != null and id not in modules: modules.append(id)
				if stage.assimilate_destroyed_modules:
					for resource: Resource in ContentRegistry.get_all(ContentRegistry.CATEGORY_APKS):
						var apk := resource as APKData
						if apk != null and zone.get_species(apk.species_line_id) != null:
							for module: ModuleData in apk.default_active_modules:
								if str(module.module_id) not in modules: modules.append(str(module.module_id))
							if apk.field_encounter != null and apk.field_encounter.reward_profile != null:
								for id: String in apk.field_encounter.reward_profile.active_module_ids:
									var module := ContentRegistry.get_module(id)
									if module != null and module.module_kind == ModuleData.ModuleKind.ACTIVE and id not in modules: modules.append(id)
		predator["assimilated_module_ids"] = modules
		route["predator"] = predator
		predator_changed.emit()
		feedback_requested.emit(zone.ecology_zone_id, zone.presentation.predator_feedback)
	GameState.set_flag("ecology.extinction_route", true)
	GameState.set_number("ecology.collapsed_zone_count", collapsed.size())
	_update_route_completeness()
	zone_collapsed.emit(zone.ecology_zone_id)

func consume_pending_receipts() -> void:
	for key: Variant in CampaignState.world_state.persistent_objects.keys():
		if not str(key).begins_with("field_resolution."): continue
		var envelope: Variant = CampaignState.world_state.persistent_objects[key]
		if envelope is not Dictionary or int(envelope.get("outcome", CombatResult.Outcome.VICTORY)) in [CombatResult.Outcome.ESCAPED, CombatResult.Outcome.CANCELLED]: continue
		var zone := definition(str(envelope.get("zone_id", "")))
		if zone == null: zone = zone_for_location(str(envelope.get("location_id", "")))
		if zone == null: continue
		for index: int in range(envelope.get("ecology_requests", []).size()):
			var request: Dictionary = envelope.ecology_requests[index]
			var operation := request.duplicate(true)
			operation["zone_id"] = zone.ecology_zone_id
			operation["operation_id"] = str(request.get("operation_id", "%s.%d.%s" % [key, index, request.get("operation", "")]))
			operation["battle_id"] = str(envelope.get("call_id", str(key).trim_prefix("field_resolution.")))
			operation["target_id"] = str(request.get("target_id", request.get("field_unit_id", "")))
			operation["source"] = "protagonist"
			operation["formal_result"] = true
			operation["provenance"] = "combat_resolution" if int(envelope.get("version", 1)) >= 2 else "phase04_persistent_receipt"
			operation["collapse_authorized"] = bool(envelope.get("collapse_authorized", false))
			var applied := apply_operation(operation)
			if applied or ensure_zone(zone).applied_effect_receipts.has(operation.operation_id): request["application_status"] = "APPLIED"
			else: request["application_status"] = "PENDING_PROTECTED"
func reserve_battle_identity(encounter: CombatEncounter) -> String:
	if not encounter.field_formation.is_empty(): return encounter.encounter_id
	var route := CampaignState.world_state.ecology_route
	var sequence := int(route.get("battle_sequence", 0)) + 1
	route["battle_sequence"] = sequence
	return "ecology.battle.%s.%s.%d" % [CampaignState.campaign_id, encounter.encounter_id, sequence]

func combat_operations(encounter: CombatEncounter, records: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var zone := definition(encounter.ecology_zone_id)
	if zone == null or not str(encounter.field_formation.get("predator_id", "")).is_empty(): return result
	for record: Dictionary in records:
		var apk_id := ""
		var target_id := str(record.get("field_unit_id", str(record.get("uid", -1))))
		for member: Dictionary in encounter.field_formation.get("members", []):
			if str(member.get("unit_id", "")) == target_id: apk_id = str(member.get("apk_id", ""))
		if apk_id.is_empty():
			var slot_index := int(record.get("encounter_slot_index", -1))
			for slot: CombatSlotData in encounter.enemy_slots:
				if slot.slot_index == slot_index: apk_id = slot.apk_id
		var apk := ContentRegistry.get_apk(apk_id)
		if apk == null or zone.get_species(apk.species_line_id) == null: continue
		var operation := ""
		if bool(record.get("purged", false)) and bool(record.get("defeated", false)): operation = "PURGE"
		elif bool(record.get("purified", false)): operation = "PURIFY"
		if not operation.is_empty(): result.append({"operation": operation, "target_id": target_id, "field_unit_id": target_id, "species_line_id": apk.species_line_id, "population_delta": -1 if operation == "PURGE" else 0, "resonance_delta": 1 if operation == "PURIFY" else 0})
	return result

func collapse_warning(encounter: CombatEncounter, records: Array[Dictionary], outcome: CombatResult.Outcome, authorization: Dictionary = {}) -> String:
	if outcome in [CombatResult.Outcome.ESCAPED, CombatResult.Outcome.CANCELLED]: return ""
	var zone := definition(encounter.ecology_zone_id)
	if zone == null: return ""
	var state := ensure_zone(zone)
	var targets: Array[String] = []
	for operation: Dictionary in combat_operations(encounter, records):
		if operation.operation == "PURGE": targets.append(str(operation.target_id))
	targets.sort()
	if targets.is_empty() or total(state) > targets.size() or bool(state.collapsed): return ""
	if str(authorization.get("zone_id", "")) == zone.ecology_zone_id and int(authorization.get("revision", -1)) == int(state.revision) and authorization.get("target_ids", []) == targets: return ""
	return zone.presentation.collapse_warning

func authorize_collapse(encounter: CombatEncounter, records: Array[Dictionary]) -> Dictionary:
	var state := ensure_zone(definition(encounter.ecology_zone_id))
	var targets: Array[String] = []
	for operation: Dictionary in combat_operations(encounter, records):
		if operation.operation == "PURGE": targets.append(str(operation.target_id))
	targets.sort()
	return {"zone_id": encounter.ecology_zone_id, "revision": int(state.get("revision", -1)), "target_ids": targets, "confirmed_action_index": TimeManager.get_total_action_index()}

func commit_combat(encounter: CombatEncounter, records: Array[Dictionary], outcome: CombatResult.Outcome, battle_id: String, authorization: Dictionary) -> String:
	if outcome in [CombatResult.Outcome.ESCAPED, CombatResult.Outcome.CANCELLED] or encounter.ecology_zone_id.is_empty(): return ""
	if not collapse_warning(encounter, records, outcome, authorization).is_empty(): return ""
	var key := "field_resolution." + battle_id
	if not CampaignState.world_state.persistent_objects.has(key):
		var operations := combat_operations(encounter, records)
		for operation: Dictionary in operations: operation["operation_id"] = "%s.%s.%s" % [battle_id, operation.target_id, operation.operation]
		CampaignState.world_state.persistent_objects[key] = {"version": 2, "call_id": battle_id, "zone_id": encounter.ecology_zone_id, "location_id": str(encounter.field_formation.get("location_id", CampaignState.current_location_id)), "outcome": int(outcome), "ecology_requests": operations, "collapse_authorized": not authorization.is_empty(), "consent_provenance": authorization.duplicate(true), "submitted_at": TimeManager.get_total_action_index()}
	consume_pending_receipts()
	return key


func _bind_conditions() -> void:
	for child: Variant in _condition_bindings.values():
		remove_child(child)
		child.queue_free()
	_condition_bindings.clear()
	for zone: EcologyZoneData in definitions():
		var conditions: Array[ConditionRuleData] = [zone.conditions]
		for species: EcologySpeciesData in zone.species:
			conditions.append(species.conditions)
			for variant: EcologyVariantData in species.variants: conditions.append(variant.conditions)
			for rule: EcologyPressureRuleData in species.pressure_rules: conditions.append(rule.conditions)
		var subscription := ConditionChangeSubscription.new()
		add_child(subscription)
		subscription.configure(conditions)
		subscription.changed.connect(func() -> void:
			if definition(zone.ecology_zone_id) == zone: zone_changed.emit(zone.ecology_zone_id, PackedStringArray(), "conditions"))
		_condition_bindings[zone.ecology_zone_id] = subscription
		_pressure_signatures[zone.ecology_zone_id] = int(context(zone).get("infestation", 0))

func _on_world_section(section: StringName) -> void:
	if section != &"world_infestation": return
	for zone: EcologyZoneData in definitions():
		var pressure := int(context(zone).get("infestation", 0))
		if int(_pressure_signatures.get(zone.ecology_zone_id, -1)) != pressure:
			_pressure_signatures[zone.ecology_zone_id] = pressure
			zone_changed.emit(zone.ecology_zone_id, PackedStringArray(), "infestation")

func _on_danger(key: String, _value: int) -> void:
	for zone: EcologyZoneData in definitions():
		if not zone.danger_number_key.is_empty() and zone.danger_number_key == key:
			zone_changed.emit(zone.ecology_zone_id, PackedStringArray(), "danger")
func predator_state() -> Dictionary:
	return CampaignState.world_state.ecology_route.get("predator", {}).duplicate(true)

func predator_profile() -> EcologyPredatorData:
	var path := str(predator_state().get("profile_path", ""))
	return load(path) as EcologyPredatorData if path.begins_with("res://") and ResourceLoader.exists(path) else null

func predator_spawn_entry() -> SpawnEntry:
	var profile := predator_profile()
	if profile == null or str(predator_state().get("status", "")) != "ACTIVE": return null
	var entry := SpawnEntry.new()
	entry.spawn_id = profile.predator_id
	entry.display_name = profile.display_name
	entry.environmental_apk = ContentRegistry.get_apk(profile.apk_id)
	entry.behavior_override = profile.behavior_profile
	entry.encounter_override = profile.encounter_profile
	entry.field_level = profile.level
	return entry

func commit_predator_result(id: String, outcome: CombatResult.Outcome) -> void:
	var route := CampaignState.world_state.ecology_route
	var state: Dictionary = route.get("predator", {})
	if id.is_empty() or str(state.get("id", "")) != id: return
	state["last_outcome"] = int(outcome)
	if outcome == CombatResult.Outcome.VICTORY:
		state["status"] = "RECOMPILING"
		state["defeated_at"] = TimeManager.get_total_action_index()
		GameState.set_flag("ecology.null_predator_defeated", true)
	elif outcome == CombatResult.Outcome.ESCAPED:
		GameState.set_flag("ecology.null_predator_evaded", true)
	CampaignState.campaign_changed.emit(&"ecology")
	predator_changed.emit()


func presence_summaries(species_id: String, precise: bool = false) -> PackedStringArray:
	var result := PackedStringArray()
	for zone: EcologyZoneData in definitions():
		if zone.get_species(species_id) == null: continue
		var text := zone.display_name + " // "
		text += zone.presentation.absent_text if population(zone.ecology_zone_id, species_id) == 0 else status_text(zone)
		if precise: text += " // %d SIGNATURES // RESONANCE %d" % [population(zone.ecology_zone_id, species_id), resonance(zone.ecology_zone_id, species_id)]
		result.append(text)
	return result


func _update_route_completeness() -> void:
	var relevant := 0
	var collapsed := 0
	for zone: EcologyZoneData in definitions():
		if not zone.counts_towards_extinction_route: continue
		relevant += 1
		if bool(ensure_zone(zone).get("collapsed", false)): collapsed += 1
	var complete := relevant > 0 and collapsed == relevant
	CampaignState.world_state.ecology_route["all_authored_zones_collapsed"] = complete
	GameState.set_flag("ecology.all_zones_collapsed", complete)
