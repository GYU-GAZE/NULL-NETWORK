extends Node


var _failures := PackedStringArray()
var _combat_manager: Node


func _ready() -> void:
	seed(1337)
	_combat_manager = get_node_or_null(
		"/root/CombatManager"
	)

	if _combat_manager == null:
		_failures.append(
			"CombatManager autoload is unavailable."
		)
		call_deferred("_finish")
		return

	call_deferred("_run")


func _run() -> void:
	var encounter := load(
		"res://data/content/combat/1v1.tres"
	) as CombatEncounter
	_check(
		encounter != null,
		"1v1.tres did not load."
	)

	if encounter == null:
		_finish()
		return

	_validate_content(encounter)
	_test_timeline_and_preview(encounter)
	_test_runtime_slots(encounter)
	_test_status_and_cycle_trigger(encounter)
	_test_combat_resolution(encounter)
	_finish()


func _validate_content(
	encounter: CombatEncounter
) -> void:
	var errors := encounter.validate_data()
	_check(
		errors.is_empty(),
		"Combat content validation failed: %s"
		% "; ".join(errors)
	)

	var turret := load(
		"res://data/content/combat/dummies/turret.tres"
	) as DummyData
	_check(
		turret != null,
		"Turret DummyData did not load."
	)

	if turret != null:
		var turret_errors := turret.validate_data()
		_check(
			turret_errors.is_empty(),
			"Turret validation failed: %s"
			% "; ".join(turret_errors)
		)

	var barrier := load(
		"res://data/content/combat/status_effects/defense_up.tres"
	) as StatusEffectData
	var defense_module := load(
		"res://data/content/combat/modules/basic_defense.tres"
	) as ModuleData
	_check(
		barrier != null
		and barrier.icon != null
		and barrier.classification == &"barrier"
		and barrier.damage_rule
		== StatusEffectData.DamageRule.BARRIER
		and barrier.duration_cycles < 0,
		"BARRIER metadata is incomplete."
	)
	_check(
		defense_module != null
		and defense_module.module_icon != null
		and defense_module.classification == &"defense",
		"Defense Module icon/classification metadata is incomplete."
	)


func _test_timeline_and_preview(
	encounter: CombatEncounter
) -> void:
	_check(
		_combat_manager.load_encounter(encounter),
		"CombatManager rejected the 1v1 encounter."
	)
	_check(
		_combat_manager.current_cycle_actions.size() == 8,
		"1v1 timeline must contain eight interleaved actions."
	)
	_check(
		not StringName(
			_combat_manager.current_cycle_actions[0].get(
				"action_slot_id",
				&""
			)
		).is_empty(),
		"Timeline action has no stable action slot ID."
	)

	if _combat_manager.current_cycle_actions.is_empty():
		return

	var preview: Dictionary = _combat_manager.preview_action(
		_combat_manager.current_cycle_actions[0]
	)
	_check(
		not preview.get("entries", []).is_empty(),
		"First timeline action produced no preview."
	)

	if not preview.get("entries", []).is_empty():
		var first_entry: Dictionary = (
			preview.get("entries", [])[0]
		)
		_check(
			int(first_entry.get("hp_delta", 0)) < 0,
			"Attack preview did not predict HP damage."
		)


func _test_runtime_slots(
	encounter: CombatEncounter
) -> void:
	_check(
		_combat_manager.load_encounter(encounter),
		"Could not reset encounter for runtime slot test."
	)
	_check(
		_combat_manager.ally_position_slots.size() == 4
		and _combat_manager.enemy_position_slots.size() == 4
		and _combat_manager.action_slots.size() == 8,
		"Combat did not create all runtime slots."
	)

	var enemy_action_id: StringName = (
		_combat_manager.action_slots[1].slot_id
	)
	_check(
		_combat_manager.set_runtime_slot_enabled(
			enemy_action_id,
			false
		),
		"Enemy action slot could not be disabled."
	)
	_check(
		_combat_manager.current_cycle_actions.size() == 7,
		"Disabled action slot still generated an action."
	)
	_combat_manager.set_runtime_slot_enabled(
		enemy_action_id,
		true
	)

	var extra_action_id: StringName = (
		_combat_manager.add_action_slot(true, 0, 1)
	)
	_check(
		not extra_action_id.is_empty()
		and _combat_manager.current_cycle_actions.size() == 9,
		"Added ally action slot did not enter the timeline."
	)
	_check(
		_combat_manager.move_action_slot(
			extra_action_id,
			0
		)
		and _combat_manager.action_slots[0].slot_id
		== extra_action_id,
		"Action slot could not move to a new order."
	)

	var locked_position: CombatRuntimeSlot = (
		_combat_manager.ally_position_slots[3]
	)
	_combat_manager.set_runtime_slot_enabled(
		locked_position.slot_id,
		false
	)
	_check(
		not _combat_manager.swap_ally_slots(0, 3),
		"Actor moved into a disabled position slot."
	)

	_check(
		_combat_manager.load_encounter(encounter),
		"Could not reset encounter for slot effect test."
	)
	var rest_module := load(
		"res://data/content/combat/modules/idle.tres"
	) as ModuleData
	var slot_module := _make_disable_action_slot_module(
		&"enemy.action.0"
	)
	var enemy := _first_living(
		_combat_manager.enemy_team
	)

	if (
		rest_module == null
		or slot_module == null
		or enemy == null
	):
		_failures.append(
			"Slot effect fixtures did not initialize."
		)
		return

	_check(
		slot_module.validate_data().is_empty(),
		"Data-driven slot Module failed validation."
	)

	_combat_manager.set_player_module(0, slot_module)
	_combat_manager.set_player_module(1, rest_module)
	_combat_manager.set_player_module(2, rest_module)
	_combat_manager.set_player_module(3, rest_module)
	enemy["modules"] = [
		rest_module,
		rest_module,
		rest_module,
		rest_module
	]
	_combat_manager.rebuild_timeline()
	_combat_manager.execute_cycle(false)
	_check(
		not _combat_manager.get_runtime_slot(
			&"enemy.action.0"
		).enabled
		and _combat_manager.current_cycle_actions.size() == 7,
		"SET_SLOT_ENABLED effect did not remove the enemy action."
	)


func _test_status_and_cycle_trigger(
	encounter: CombatEncounter
) -> void:
	_check(
		_combat_manager.load_encounter(encounter),
		"Could not reset encounter for trigger test."
	)

	var player: Variant = _combat_manager.get_player_actor()
	var enemy: Variant = _first_living(
		_combat_manager.enemy_team
	)
	var rest_module := load(
		"res://data/content/combat/modules/idle.tres"
	) as ModuleData
	var barrier_module := _make_barrier_module(4)
	var repeated_attack := _make_repeated_attack(3)

	_check(
		player != null
		and enemy != null
		and rest_module != null
		and barrier_module != null
		and repeated_attack != null,
		"Barrier test fixtures did not initialize."
	)

	if (
		player == null
		or enemy == null
		or rest_module == null
		or barrier_module == null
		or repeated_attack == null
	):
		return

	player["dodge"] = 0.0
	enemy["crit"] = 0.0
	_combat_manager.set_player_module(0, barrier_module)
	_combat_manager.set_player_module(1, rest_module)
	_combat_manager.set_player_module(2, rest_module)
	_combat_manager.set_player_module(3, rest_module)
	enemy["modules"] = [
		repeated_attack,
		rest_module,
		rest_module,
		rest_module
	]
	_combat_manager.rebuild_timeline()

	var player_hp_before := float(
		player.get("hp", 0.0)
	)
	_combat_manager.execute_cycle(false)
	_check(
		is_equal_approx(
			float(player.get("hp", 0.0)),
			player_hp_before
		),
		"Three-hit Module damaged HP through four BARRIER stacks."
	)
	_check(
		_combat_manager.get_barrier_stacks(player) == 1,
		"Three hits did not consume exactly three BARRIER stacks."
	)
	_check(
		_combat_manager.was_targeted_by_classification(
			player,
			&"physical_attack",
			0
		),
		"Module classification targeting history was not recorded."
	)

	var trigger := CombatTriggerData.new()
	trigger.timing = (
		CombatConstants.TriggerTiming.MODULE_USED
	)
	trigger.actor_relation = (
		CombatConstants.TriggerActor.ANY
	)
	trigger.required_module_classification = (
		&"physical_attack"
	)
	var context := CombatEventContext.create(
		CombatConstants.TriggerTiming.MODULE_USED,
		_combat_manager.current_cycle,
		enemy,
		player,
		repeated_attack
	)
	_check(
		trigger.matches(context, player),
		"Trigger did not filter by Module classification."
	)

	var barrier := load(
		"res://data/content/combat/status_effects/defense_up.tres"
	) as StatusEffectData
	trigger.required_module_classification = &""
	trigger.required_status_classification = &"barrier"
	context.status = barrier
	_check(
		trigger.matches(context, player),
		"Trigger did not filter by Status classification."
	)

	_check(
		_combat_manager.load_encounter(encounter),
		"Could not reset encounter for dummy trigger test."
	)

	var turret_module := load(
		"res://data/content/combat/modules/dummy_turret.tres"
	) as ModuleData
	rest_module = load(
		"res://data/content/combat/modules/idle.tres"
	) as ModuleData
	_check(
		turret_module != null and rest_module != null,
		"Trigger test modules did not load."
	)

	if turret_module == null or rest_module == null:
		return

	_combat_manager.set_player_module(0, turret_module)
	_combat_manager.set_player_module(1, rest_module)
	_combat_manager.set_player_module(2, rest_module)
	_combat_manager.set_player_module(3, rest_module)

	var enemy_before: Variant = _first_living(
		_combat_manager.enemy_team
	)
	var enemy_hp_before := float(
		enemy_before.get("hp", 0.0)
	)
	_combat_manager.execute_cycle(false)

	var dummy_found: bool = false

	for actor in _combat_manager.ally_team:
		if (
			actor != null
			and bool(actor.get("is_dummy", false))
		):
			dummy_found = true
			break

	_check(
		dummy_found,
		"Dummy module did not create a runtime dummy."
	)

	var enemy_after: Variant = _first_living(
		_combat_manager.enemy_team
	)
	_check(
		enemy_after != null
		and float(enemy_after.get("hp", 0.0))
		< enemy_hp_before,
		"Turret CYCLE_END trigger caused no damage."
	)


func _test_combat_resolution(
	encounter: CombatEncounter
) -> void:
	_check(
		_combat_manager.load_encounter(encounter),
		"Could not reset encounter for resolution test."
	)

	var player: Variant = _combat_manager.get_player_actor()
	var enemy: Variant = _first_living(
		_combat_manager.enemy_team
	)

	if player != null:
		player["crit"] = 0.0
		player["dodge"] = 0.0

	if enemy != null:
		enemy["crit"] = 0.0
		enemy["dodge"] = 0.0

	var cycle_guard: int = 0

	while (
		_combat_manager.is_encounter_active()
		and cycle_guard < 20
	):
		_combat_manager.execute_cycle(false)
		cycle_guard += 1

	_check(
		not _combat_manager.is_encounter_active(),
		"1v1 did not resolve within 20 cycles."
	)
	_check(
		_all_non_dummy_defeated(
			_combat_manager.enemy_team
		),
		"1v1 did not end in the expected victory."
	)

	var metadata: Dictionary = (
		_combat_manager.get_result_metadata()
	)
	_check(
		int(metadata.get("cycles", 0)) > 0,
		"Combat result metadata contains no cycle count."
	)
	_check(
		not metadata.get("runtime_slots", []).is_empty(),
		"Combat result metadata contains no runtime slot snapshot."
	)

func _make_barrier_module(
	stack_count: int
) -> ModuleData:
	var barrier := load(
		"res://data/content/combat/status_effects/defense_up.tres"
	) as StatusEffectData

	if barrier == null:
		return null

	var selector := CombatTargetSelector.new()
	selector.target_kind = (
		CombatTargetSelector.TargetKind.USER
	)
	var formula := CombatValueFormula.new()
	formula.base_value = stack_count
	var effect := CombatEffectData.new()
	effect.effect_type = (
		CombatEffectData.EffectType.APPLY_STATUS
	)
	effect.target_selector = selector
	effect.value_formula = formula
	effect.status_effect = barrier
	effect.can_crit = false

	var module := ModuleData.new()
	module.module_id = &"test_barrier"
	module.module_name = "Test Barrier"
	module.classification = &"defense"
	module.stability_cost = 0
	var effects: Array[CombatEffectData] = [effect]
	module.combat_effects = effects
	return module


func _make_repeated_attack(
	executions: int
) -> ModuleData:
	var source := load(
		"res://data/content/combat/modules/basic_attack.tres"
	) as ModuleData

	if source == null:
		return null

	var module := source.duplicate(true) as ModuleData
	module.execution_count = executions
	module.accuracy = 1.0
	module.classification = &"physical_attack"

	for effect in module.combat_effects:
		if effect != null:
			effect.accuracy_override = 1.0
			effect.can_crit = false

	return module


func _make_disable_action_slot_module(
	slot_id: StringName
) -> ModuleData:
	var selector := CombatSlotSelector.new()
	selector.slot_kind = (
		CombatSlotSelector.SlotKind.ACTION
	)
	selector.team_relation = (
		CombatSlotSelector.TeamRelation.ENEMY_TEAM
	)
	selector.slot_id = slot_id

	var effect := CombatEffectData.new()
	effect.effect_type = (
		CombatEffectData.EffectType.SET_SLOT_ENABLED
	)
	effect.slot_selector = selector
	effect.slot_enabled = false

	var module := ModuleData.new()
	module.module_id = &"test_disable_action"
	module.module_name = "Test Disable Action"
	module.classification = &"control"
	module.stability_cost = 0
	var effects: Array[CombatEffectData] = [effect]
	module.combat_effects = effects
	return module


func _first_living(
	team: Array
) -> Variant:
	for actor in team:
		if (
			actor != null
			and float(actor.get("hp", 0.0)) > 0.0
		):
			return actor

	return null


func _all_non_dummy_defeated(
	team: Array
) -> bool:
	for actor in team:
		if (
			actor != null
			and not bool(actor.get("is_dummy", false))
			and float(actor.get("hp", 0.0)) > 0.0
		):
			return false

	return true


func _check(
	condition: bool,
	message: String
) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("COMBAT_RUNTIME_TEST: PASS")
		get_tree().quit(0)
		return

	for failure in _failures:
		push_error(
			"COMBAT_RUNTIME_TEST: %s"
			% failure
		)

	get_tree().quit(1)
