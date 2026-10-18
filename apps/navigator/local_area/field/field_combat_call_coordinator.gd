extends Node2D
class_name FieldCombatCallCoordinator

signal call_presented(formation: Dictionary)
## Compatibility intent signal; durable receipts are consumed by EcologyService.
## Field projection counts are NOT ecological Population Units.
signal ecology_effects_requested(receipt_id: String, location_id: String, effects: Array[Dictionary])
var area: NavigatorLocalAreaScene
var busy: bool = false
var presenting: bool = false
var main: LocalAreaExeActor
var formation: Dictionary = {}
var decisions: Array[Dictionary] = []
var _clock: float = 0.0

func _ready() -> void:
	set_process(false)

func begin(actor: LocalAreaExeActor, involuntary: bool = false) -> bool:
	if busy or actor == null or actor.encounter_profile == null or not actor.can_interact() or not area.is_field_active():
		return false
	if actor.global_position.distance_to(area.player.global_position) > 56 or not area.field_navigation.ready:
		return false
	if not area.field_navigation.line_clear(area.to_local(actor.global_position), area.to_local(area.player.global_position)):
		return false
	if involuntary and (actor.motor.grace_seconds > 0 or actor.motor.needs_separation):
		return false
	if actor.persistent_ecology_actor_id.is_empty() and area.map_location.ecology_zone != null and EcologyService.population(area.map_location.ecology_zone.ecology_zone_id, actor.environmental_apk.species_line_id) <= 0:
		return false
	busy = true
	main = actor
	formation.clear()
	decisions.clear()
	main.set_call_locked(true, "CALL!")
	return true

func build_encounter() -> CombatEncounter:
	if not busy or not is_instance_valid(main) or not main.available:
		cancel(true)
		return null
	var profile := main.encounter_profile
	var call_id := area.population_controller.reserve_field_call_id()
	var candidates: Array[LocalAreaExeActor] = area.get_field_exes()
	candidates.sort_custom(func(a: LocalAreaExeActor, b: LocalAreaExeActor) -> bool:
		var da := a.global_position.distance_squared_to(main.global_position)
		var db := b.global_position.distance_squared_to(main.global_position)
		return a.field_unit_id < b.field_unit_id if is_equal_approx(da, db) else da < db)
	var responders: Array[Dictionary] = []
	var delay := profile.signal_seconds
	for candidate: LocalAreaExeActor in candidates:
		if candidate == main or not main.persistent_ecology_actor_id.is_empty() or not candidate.persistent_ecology_actor_id.is_empty() or candidate.call_locked or candidate.encounter_profile == null or candidate.behavior_profile == null:
			continue
		var distance := candidate.global_position.distance_to(main.global_position)
		if distance > profile.call_radius or not area.field_navigation.line_clear(area.to_local(candidate.global_position), area.to_local(main.global_position)):
			continue
		candidate.refresh_field_context()
		var context := candidate.field_context.duplicate()
		context.merge({"distance": distance, "same_species": candidate.environmental_apk.species_line_id == main.environmental_apk.species_line_id, "caller_protected": main.environmental_apk.form_type == APKData.FormType.INIT or main.hp_fraction <= candidate.behavior_profile.protection_hp_threshold, "caller_in_territory": area.to_local(main.global_position).distance_to(candidate.motor.home) <= candidate.behavior_profile.territory_radius, "caller_variant_node_id": main.spawn_entry.variant_node_id}, true)
		var response := FieldResponseEvaluator.evaluate(candidate.behavior_profile, candidate.effective_behavior if candidate.behavior_enabled else FieldBehaviorProfileData.Behavior.DORMANT, context, hash(call_id + candidate.field_unit_id))
		response["unit_id"] = candidate.field_unit_id
		decisions.append(response.duplicate(true))
		delay = maxf(delay, float(response.delay))
		candidate.presentation.signal_text = FieldCallResponseRule.Response.keys()[int(response.response)]
		if bool(response.join):
			responders.append({"actor": candidate, "response": response})
		elif int(response.response) == FieldCallResponseRule.Response.FLEE:
			candidate.motor.disengage()
			candidate.motor.begin_call_motion(area.to_local(candidate.global_position) + main.global_position.direction_to(candidate.global_position) * candidate.behavior_profile.roaming_radius, delay)
		elif int(response.response) == FieldCallResponseRule.Response.HESITATE:
			candidate.motor.begin_call_motion(area.to_local(candidate.global_position.lerp(main.global_position, 0.25)), maxf(0.2, float(response.delay)))
	responders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.response.response == FieldCallResponseRule.Response.INTERCEPT) > int(b.response.response == FieldCallResponseRule.Response.INTERCEPT))
	var members: Array[Dictionary] = [_member(main)]
	var ecological_counts := {main.environmental_apk.species_line_id: 1}
	for value: Dictionary in responders:
		if members.size() >= 4:
			break
		var actor := value.actor as LocalAreaExeActor
		var zone := area.map_location.ecology_zone
		var species_id := actor.environmental_apk.species_line_id
		if zone != null and int(ecological_counts.get(species_id, 0)) >= EcologyService.population(zone.ecology_zone_id, species_id): continue
		ecological_counts[species_id] = int(ecological_counts.get(species_id, 0)) + 1
		actor.set_call_locked(true, FieldCallResponseRule.Response.keys()[int(value.response.response)])
		var target := area.player.global_position if int(value.response.response) == FieldCallResponseRule.Response.INTERCEPT else main.global_position
		target += target.direction_to(actor.global_position) * 30.0
		actor.motor.begin_call_motion(area.to_local(target), delay)
		delay = maxf(delay, float(value.response.delay))
		members.append(_member(actor))
	formation = {"version": 1, "call_id": call_id, "location_id": area.map_location.get_display_id(), "ecology_zone_id": area.map_location.ecology_zone.ecology_zone_id if area.map_location.ecology_zone != null and main.persistent_ecology_actor_id.is_empty() else "", "predator_id": main.persistent_ecology_actor_id, "profile_path": profile.resource_path, "members": members, "decisions": decisions.duplicate(true)}
	presenting = true
	set_process(true)
	call_presented.emit(formation.duplicate(true))
	await get_tree().create_timer(delay).timeout
	for candidate: LocalAreaExeActor in candidates:
		if is_instance_valid(candidate):
			candidate.motor.end_call_motion()
	presenting = false
	set_process(false)
	queue_redraw()
	if not busy: return null
	var counts := {}
	for member: Dictionary in formation.get("members", []):
		var actor := area.find_interactable_by_id(str(member.unit_id)) as LocalAreaExeActor
		if actor == null or not actor.available:
			cancel(true)
			return null
		var species := actor.environmental_apk.species_line_id
		counts[species] = int(counts.get(species, 0)) + 1
		if main.persistent_ecology_actor_id.is_empty() and area.map_location.ecology_zone != null and int(counts[species]) > EcologyService.population(area.map_location.ecology_zone.ecology_zone_id, species):
			cancel(true)
			return null
	return FieldCombatEncounterFactory.create(formation)

func _member(actor: LocalAreaExeActor) -> Dictionary:
	var reward := actor.encounter_profile.reward_profile
	return {"unit_id": actor.field_unit_id, "apk_id": actor.environmental_apk.apk_id, "variant_node_id": actor.spawn_entry.variant_node_id, "level": actor.spawn_entry.field_level, "hp_fraction": actor.hp_fraction, "stability_fraction": actor.stability_fraction, "reward_path": reward.resource_path if reward != null else "", "module_ids": CampaignState.world_state.ecology_route.get("predator", {}).get("assimilated_module_ids", []) if not actor.persistent_ecology_actor_id.is_empty() else []}

func restore(data: Dictionary) -> void:
	formation = data.duplicate(true)
	busy = not formation.is_empty()
	for value: Dictionary in formation.get("members", []):
		var actor := area.find_interactable_by_id(str(value.get("unit_id", ""))) as LocalAreaExeActor
		if actor != null:
			actor.set_call_locked(true)

func apply_result(result: CombatResult) -> void:
	if result == null:
		cancel(true)
		return
	var records := {}
	for record: Dictionary in result.metadata.get("field_units", []):
		records[str(record.get("unit_id", ""))] = record
	for member: Dictionary in formation.get("members", []):
		var id := str(member.get("unit_id", ""))
		var actor := area.find_interactable_by_id(id) as LocalAreaExeActor
		if actor != null:
			actor.apply_unit_result(records.get(id, {}), result.outcome)
	if result.outcome not in [CombatResult.Outcome.ESCAPED, CombatResult.Outcome.CANCELLED]:
		var receipt_id := "field_resolution." + result.encounter_id
		if not CampaignState.world_state.persistent_objects.has(receipt_id):
			var effects: Array[Dictionary] = []
			for member: Dictionary in formation.get("members", []):
				var record: Dictionary = records.get(str(member.unit_id), {})
				if bool(record.get("purged", false)) and bool(record.get("defeated", false)):
					var apk := ContentRegistry.get_apk(str(member.apk_id))
					effects.append({"operation": "PURGE", "field_unit_id": str(member.unit_id), "species_line_id": apk.species_line_id if apk != null else "", "population_delta": -1})
			CampaignState.world_state.persistent_objects[receipt_id] = {"call_id": result.encounter_id, "location_id": area.map_location.get_display_id(), "ecology_requests": effects.duplicate(true)}
			CampaignState.campaign_changed.emit(&"field_resolutions")
			if not effects.is_empty():
				ecology_effects_requested.emit(receipt_id, area.map_location.get_display_id(), effects)
	EcologyService.consume_pending_receipts()
	# All nearby survivors get grace; an unselected aggressive neighbor must not
	# immediately reopen combat at the return position after escape.
	cancel(result.outcome in [CombatResult.Outcome.ESCAPED, CombatResult.Outcome.CANCELLED])
	area.population_controller.sync_population_state()

func cancel(grace: bool = false) -> void:
	for actor: LocalAreaExeActor in area.get_field_exes():
		actor.motor.end_call_motion()
		actor.release_call(grace)
	busy = false
	presenting = false
	main = null
	formation.clear()
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()

func _draw() -> void:
	if presenting and is_instance_valid(main):
		var center := to_local(main.global_position)
		var radius := 18.0 + fmod(_clock * 70.0, 45.0)
		draw_arc(center.round(), radius, 0, TAU, 32, Color(1, 0.7, 0.2), 1)
		draw_string(ThemeDB.fallback_font, center.round() + Vector2(-62, -50), "COMBAT CALL // %d HOSTILES" % (formation.get("members", []) as Array).size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.85, 0.25))
