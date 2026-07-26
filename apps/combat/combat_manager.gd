extends Node


signal encounter_started(encounter: CombatEncounter)
signal combat_victory
signal combat_defeat
signal cycle_ended_ready_for_next
signal cycle_completed(cycle_index: int)
signal escape_attempted(success: bool)
signal combat_log_added(message: String)
signal floating_text_requested(
	actor: Dictionary,
	text: String,
	color: Color
)
signal timeline_generated(actions: Array)
signal stats_updated
signal action_executed(
	index: int,
	action_data: Dictionary
)


const TEAM_SIZE: int = 4
const MAX_EVENT_DEPTH: int = 16
const UNSTABILITY_STATUS: StatusEffectData = preload(
	"res://data/content/combat/status_effects/unstability.tres"
)


var ally_team: Array = [null, null, null, null]
var enemy_team: Array = [null, null, null, null]
var current_cycle_actions: Array = []
var current_cycle: int = 0


var _current_encounter: CombatEncounter
var _encounter_active: bool = false
var _next_uid: int = 1
var _next_event_id: int = 1


func load_encounter(
	encounter: CombatEncounter
) -> bool:
	reset_encounter()

	if encounter == null:
		push_error(
			"CombatManager: cannot load a null encounter."
		)
		return false

	var validation_errors := encounter.validate_data()

	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error(
				"Combat content validation: %s"
				% error
			)
		return false

	_current_encounter = encounter
	_encounter_active = true

	_load_team_from_slots(
		encounter.ally_slots,
		ally_team,
		true
	)
	_load_team_from_slots(
		encounter.enemy_slots,
		enemy_team,
		false
	)

	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.ENCOUNTER_START
		)
	)
	stats_updated.emit()
	rebuild_timeline()
	encounter_started.emit(encounter)
	return true


func reset_encounter() -> void:
	ally_team = [null, null, null, null]
	enemy_team = [null, null, null, null]
	current_cycle_actions.clear()
	current_cycle = 0
	_current_encounter = null
	_encounter_active = false
	_next_uid = 1
	_next_event_id = 1


func is_encounter_active() -> bool:
	return _encounter_active


func get_current_encounter() -> CombatEncounter:
	return _current_encounter


func get_player_actor() -> Variant:
	return _get_player_actor()


func rebuild_timeline() -> void:
	current_cycle_actions.clear()

	if not _encounter_active:
		timeline_generated.emit(
			current_cycle_actions
		)
		return

	var ally_actors := _get_timeline_actors(
		ally_team
	)
	var enemy_actors := _get_timeline_actors(
		enemy_team
	)

	for action_slot in range(TEAM_SIZE):
		_append_timeline_action(
			ally_actors,
			action_slot
		)
		_append_timeline_action(
			enemy_actors,
			action_slot
		)

	timeline_generated.emit(current_cycle_actions)


func execute_cycle(
	animated: bool = true
) -> void:
	if not _encounter_active:
		return

	if animated:
		_execute_cycle_animated()
	else:
		_execute_cycle_immediate()


func try_escape() -> bool:
	if (
		not _encounter_active
		or _current_encounter == null
	):
		return false

	if not _current_encounter.can_escape:
		combat_log_added.emit(
			"> Escape is blocked in this encounter."
		)
		escape_attempted.emit(false)
		return false

	var player := _get_player_actor()

	if player == null:
		escape_attempted.emit(false)
		return false

	var dodge := get_effective_stat(
		player,
		CombatConstants.Stat.DODGE
	)
	var chance := clampf(
		_current_encounter.base_escape_chance
		+ dodge,
		0.05,
		0.95
	)
	var success := randf() <= chance

	if success:
		_encounter_active = false
		combat_log_added.emit(
			"> Escape successful."
		)
	else:
		combat_log_added.emit(
			"> Escape failed."
		)

	escape_attempted.emit(success)
	return success


func swap_ally_slots(
	source_index: int,
	target_index: int
) -> bool:
	if (
		source_index < 0
		or source_index >= TEAM_SIZE
		or target_index < 0
		or target_index >= TEAM_SIZE
	):
		return false

	var temporary: Variant = ally_team[target_index]
	ally_team[target_index] = ally_team[source_index]
	ally_team[source_index] = temporary
	rebuild_timeline()
	stats_updated.emit()
	return true


func set_player_module(
	slot_index: int,
	module: ModuleData
) -> bool:
	var player := _get_player_actor()

	if (
		player == null
		or slot_index < 0
		or slot_index >= TEAM_SIZE
	):
		return false

	player["modules"][slot_index] = module
	rebuild_timeline()
	return true


func get_effective_stat(
	actor: Dictionary,
	stat: CombatConstants.Stat
) -> float:
	return _get_effective_stat(
		actor,
		stat,
		0
	)


func preview_action(
	action: Dictionary
) -> Dictionary:
	var preview := {
		"entries": [],
		"lines": PackedStringArray()
	}
	var actor: Variant = action.get("actor")
	var module: ModuleData = action.get("module")

	if not (actor is Dictionary) or module == null:
		return preview

	var context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.MODULE_USED
	)

	for effect in module.combat_effects:
		if effect == null:
			continue

		if (
			effect.effect_type
			== CombatEffectData.EffectType.SPAWN_DUMMY
		):
			preview["lines"].append(
				effect.describe()
			)
			continue

		var targets := resolve_targets(
			effect.target_selector,
			actor,
			context,
			actor
		)

		if targets.is_empty():
			preview["lines"].append(
				"%s: no valid target."
				% effect.describe()
			)
			continue

		for target in targets:
			var entry := _preview_effect(
				actor,
				target,
				module,
				effect,
				context
			)

			if not entry.is_empty():
				preview["entries"].append(entry)

	return preview


func get_module_tooltip(
	module: ModuleData,
	action: Dictionary = {}
) -> String:
	if module == null:
		return "EMPTY"

	var lines := PackedStringArray([
		"[%s]" % module.module_name
	])

	if not module.description.strip_edges().is_empty():
		lines.append(module.description)

	lines.append(
		"Cost: %d STB"
		% module.stability_cost
	)
	lines.append_array(module.describe_effects())

	if not action.is_empty():
		var preview := preview_action(action)

		for entry in preview.get("entries", []):
			lines.append(
				str(entry.get("summary", ""))
			)

		for line in preview.get(
			"lines",
			PackedStringArray()
		):
			lines.append(line)

	return "\n".join(lines)


func get_result_metadata() -> Dictionary:
	return {
		"cycles": current_cycle,
		"allies": _team_snapshot(ally_team),
		"enemies": _team_snapshot(enemy_team)
	}


func resolve_targets(
	selector: CombatTargetSelector,
	caster: Dictionary,
	context: CombatEventContext = null,
	holder: Dictionary = {}
) -> Array:
	if selector == null:
		return []

	var allies := (
		ally_team
		if bool(caster.get("is_ally", false))
		else enemy_team
	)
	var enemies := (
		enemy_team
		if bool(caster.get("is_ally", false))
		else ally_team
	)
	var caster_index := allies.find(caster)
	var result: Array = []

	match selector.target_kind:
		CombatTargetSelector.TargetKind.USER:
			result = [caster]

		CombatTargetSelector.TargetKind.DIRECT_ENEMY:
			var direct_target := (
				_get_direct_enemy_target(
					caster_index,
					enemies
				)
			)
			if direct_target != null:
				result = [direct_target]

		CombatTargetSelector.TargetKind.ALL_ENEMIES:
			result = _get_valid_targets(
				enemies,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.ENEMY_SLOT:
			result = _target_from_slot(
				enemies,
				selector.slot_index,
				selector
			)

		CombatTargetSelector.TargetKind.ADJACENT_ALLY:
			var adjacent := _get_adjacent_ally(
				caster_index,
				allies
			)
			if adjacent != null:
				result = [adjacent]

		CombatTargetSelector.TargetKind.ALL_ALLIES:
			result = _get_valid_targets(
				allies,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.ALLY_SLOT:
			result = _target_from_slot(
				allies,
				selector.slot_index,
				selector
			)

		CombatTargetSelector.TargetKind.EVENT_SOURCE:
			result = _variant_as_target_array(
				context.source if context != null else null,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.EVENT_TARGET:
			result = _variant_as_target_array(
				context.target if context != null else null,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.STATUS_HOLDER:
			result = _variant_as_target_array(
				holder,
				selector.include_defeated
			)

		CombatTargetSelector.TargetKind.DUMMY_CREATOR:
			var creator_uid := int(
				holder.get(
					"creator_uid",
					caster.get("creator_uid", -1)
				)
			)
			var creator := _find_combatant_by_uid(
				creator_uid
			)
			result = _variant_as_target_array(
				creator,
				selector.include_defeated
			)

	return result


func _load_team_from_slots(
	slot_data_list: Array[CombatSlotData],
	target_team: Array,
	is_ally: bool
) -> void:
	for slot_data in slot_data_list:
		if (
			slot_data == null
			or not slot_data.is_available()
		):
			continue

		var index := clampi(
			slot_data.slot_index,
			0,
			TEAM_SIZE - 1
		)
		target_team[index] = _create_combatant(
			slot_data.character,
			is_ally,
			is_ally and index == 0
		)


func _create_combatant(
	data: CharacterLoadout,
	is_ally: bool,
	is_player: bool = false
) -> Dictionary:
	var modules: Array = data.equipped_modules.duplicate()
	modules.resize(TEAM_SIZE)
	var actor := {
		"uid": _consume_uid(),
		"character_id": data.character_id,
		"name": data.char_name,
		"icon": data.combat_icon,
		"level": data.level,
		"type": data.apk_type,
		"hp": float(data.max_hp),
		"max_hp": float(data.max_hp),
		"stability": float(data.max_stability),
		"max_stability": float(data.max_stability),
		"stability_recovery": float(
			data.stability_recovery
		),
		"atk": float(data.base_atk),
		"def": float(data.base_def),
		"matk": float(data.base_matk),
		"mdef": float(data.base_mdef),
		"dodge": data.dodge_chance,
		"crit": data.crit_chance,
		"modules": modules,
		"is_ally": is_ally,
		"is_player": is_player,
		"is_dummy": false,
		"dummy_data": null,
		"creator_uid": -1,
		"remaining_cycles": -1,
		"spawned_cycle": -1,
		"active_statuses": [],
		"runtime_effects": []
	}
	return actor


func _create_dummy(
	data: DummyData,
	creator: Dictionary
) -> Dictionary:
	var actor := {
		"uid": _consume_uid(),
		"character_id": data.dummy_id,
		"name": data.display_name,
		"icon": data.combat_icon,
		"level": creator.get("level", 1),
		"type": data.apk_type,
		"hp": 1.0,
		"max_hp": 1.0,
		"stability": 0.0,
		"max_stability": 0.0,
		"stability_recovery": 0.0,
		"atk": 0.0,
		"def": 0.0,
		"matk": 0.0,
		"mdef": 0.0,
		"dodge": 0.0,
		"crit": 0.0,
		"modules": [null, null, null, null],
		"is_ally": creator.get("is_ally", false),
		"is_player": false,
		"is_dummy": true,
		"dummy_data": data,
		"creator_uid": creator.get("uid", -1),
		"remaining_cycles": data.duration_cycles,
		"spawned_cycle": current_cycle,
		"active_statuses": [],
		"runtime_effects": []
	}
	var context := _make_context(
		CombatConstants.TriggerTiming.DUMMY_CREATED,
		creator,
		actor
	)

	for stat_formula in data.stat_formulas:
		if (
			stat_formula == null
			or stat_formula.formula == null
		):
			continue

		var value := _evaluate_formula(
			stat_formula.formula,
			creator,
			actor,
			actor,
			null,
			context
		)
		var key := CombatConstants.stat_key(
			stat_formula.stat
		)

		if not key.is_empty():
			actor[key] = value

	actor["max_hp"] = maxf(
		1.0,
		float(actor.get("max_hp", 1.0))
	)
	actor["hp"] = actor["max_hp"]
	actor["max_stability"] = maxf(
		0.0,
		float(actor.get("max_stability", 0.0))
	)
	actor["stability"] = actor["max_stability"]

	for status in data.initial_statuses:
		if status != null:
			_apply_status(
				creator,
				actor,
				status,
				status.default_stacks,
				context
			)

	return actor


func _append_timeline_action(
	actors: Array,
	action_slot: int
) -> void:
	if action_slot >= actors.size():
		return

	var actor: Variant = actors[action_slot]

	if not (actor is Dictionary):
		return

	var modules: Array = actor.get("modules", [])

	if action_slot >= modules.size():
		return

	var module: ModuleData = modules[action_slot]

	if module == null:
		return

	var action := {
		"actor": actor,
		"module": module,
		"action_slot": action_slot,
		"target": null
	}
	action["target"] = _get_action_primary_target(
		action
	)
	current_cycle_actions.append(action)


func _get_action_primary_target(
	action: Dictionary
) -> Variant:
	var actor: Dictionary = action.get("actor", {})
	var module: ModuleData = action.get("module")

	if actor.is_empty() or module == null:
		return null

	var context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.MODULE_USED
	)

	for effect in module.combat_effects:
		if (
			effect == null
			or effect.target_selector == null
		):
			continue

		var targets := resolve_targets(
			effect.target_selector,
			actor,
			context,
			actor
		)

		if targets.size() == 1:
			return targets[0]

		if targets.size() > 1:
			return targets

	return null


func _execute_cycle_immediate() -> void:
	_begin_cycle()

	for index in range(
		current_cycle_actions.size()
	):
		_execute_action(
			index,
			current_cycle_actions[index]
		)

		if _has_terminal_state():
			_finish_terminal_cycle()
			return

	_finish_non_terminal_cycle()


func _execute_cycle_animated() -> void:
	_begin_cycle()
	var wait_time: float = 1.0

	for index in range(
		current_cycle_actions.size()
	):
		_execute_action(
			index,
			current_cycle_actions[index]
		)

		if _has_terminal_state():
			_finish_terminal_cycle()
			return

		await get_tree().create_timer(
			wait_time
		).timeout
		wait_time = maxf(
			0.15,
			wait_time * 0.70
		)

	_finish_non_terminal_cycle()


func _begin_cycle() -> void:
	current_cycle += 1
	combat_log_added.emit(
		"\n[color=yellow]--- CYCLE %d ---[/color]"
		% current_cycle
	)
	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.CYCLE_START
		)
	)


func _execute_action(
	timeline_index: int,
	action: Dictionary
) -> void:
	var actor: Variant = action.get("actor")
	var module: ModuleData = action.get("module")

	if (
		not (actor is Dictionary)
		or module == null
		or float(actor.get("hp", 0.0)) <= 0.0
	):
		return

	var before_context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.BEFORE_ACTION,
		timeline_index
	)
	_dispatch_event(before_context)

	if float(actor.get("hp", 0.0)) <= 0.0:
		return

	var stability := float(
		actor.get("stability", 0.0)
	)

	if stability < module.stability_cost:
		combat_log_added.emit(
			"> %s lacks Stability for %s."
			% [
				actor.get("name", "Entity"),
				module.module_name
			]
		)
		floating_text_requested.emit(
			actor,
			"NO STB!",
			Color.GRAY
		)
	else:
		actor["stability"] = maxf(
			0.0,
			stability - module.stability_cost
		)

		if (
			module.stability_cost > 0
			and is_zero_approx(
				float(actor["stability"])
			)
		):
			_apply_status(
				actor,
				actor,
				UNSTABILITY_STATUS,
				1,
				before_context
			)

		combat_log_added.emit(
			"[color=cyan]%s[/color] activated [b]%s[/b]."
			% [
				actor.get("name", "Entity"),
				module.module_name
			]
		)

		var module_context := _context_from_action(
			action,
			CombatConstants.TriggerTiming.MODULE_USED,
			timeline_index
		)
		_dispatch_event(module_context)
		_execute_effects(
			actor,
			module.combat_effects,
			module,
			module_context,
			actor
		)

	action_executed.emit(
		timeline_index,
		action
	)
	stats_updated.emit()

	var after_context := _context_from_action(
		action,
		CombatConstants.TriggerTiming.AFTER_ACTION,
		timeline_index
	)
	_dispatch_event(after_context)


func _execute_effects(
	caster: Dictionary,
	effects: Array[CombatEffectData],
	module: ModuleData,
	context: CombatEventContext,
	holder: Dictionary,
	status_instance: CombatStatusInstance = null
) -> void:
	for effect in effects:
		if effect == null:
			continue

		if (
			effect.effect_type
			== CombatEffectData.EffectType.SPAWN_DUMMY
		):
			_spawn_dummy(caster, effect, context)
			continue

		if effect.effect_type in [
			CombatEffectData.EffectType.MODIFY_DAMAGE_TAKEN,
			CombatEffectData.EffectType.MODIFY_DAMAGE_DEALT
		]:
			continue

		var targets := resolve_targets(
			effect.target_selector,
			caster,
			context,
			holder
		)

		if targets.is_empty():
			_fail_effect(
				caster,
				"No valid target for %s."
				% effect.describe()
			)
			continue

		for target in targets:
			_execute_effect_on_target(
				caster,
				target,
				module,
				effect,
				context,
				holder,
				status_instance
			)


func _execute_effect_on_target(
	caster: Dictionary,
	target: Dictionary,
	module: ModuleData,
	effect: CombatEffectData,
	context: CombatEventContext,
	holder: Dictionary,
	status_instance: CombatStatusInstance
) -> void:
	var amount := _evaluate_formula(
		effect.value_formula,
		caster,
		target,
		holder,
		status_instance,
		context
	)

	match effect.effect_type:
		CombatEffectData.EffectType.DAMAGE:
			_apply_damage(
				caster,
				target,
				module,
				effect,
				amount,
				context
			)

		CombatEffectData.EffectType.HEAL:
			_apply_heal(
				caster,
				target,
				amount
			)

		CombatEffectData.EffectType.MODIFY_STABILITY:
			_modify_stability(
				target,
				amount
			)

		CombatEffectData.EffectType.APPLY_STATUS:
			var stacks := maxi(
				1,
				int(amount)
			)
			var status_critical := (
				effect.can_crit
				and _roll_crit(caster)
			)

			if status_critical:
				stacks = maxi(
					1,
					int(roundf(
						stacks
						* effect.crit_multiplier
					))
				)

				if (
					effect.applies_unstability_on_crit
				):
					_apply_status(
						caster,
						target,
						UNSTABILITY_STATUS,
						1,
						context
					)

			_apply_status(
				caster,
				target,
				effect.status_effect,
				stacks,
				context
			)

		CombatEffectData.EffectType.REMOVE_STATUS:
			_remove_status(
				target,
				effect.status_id_to_remove,
				effect.remove_all_stacks,
				maxi(1, absi(int(amount))),
				context
			)

		CombatEffectData.EffectType.MODIFY_STAT:
			_modify_actor_stat(
				target,
				effect.target_stat,
				amount
			)

		CombatEffectData.EffectType.REDIRECT_NEXT_DAMAGE:
			_apply_redirect(
				caster,
				target,
				effect.redirect_duration_actions
			)


func _apply_damage(
	caster: Dictionary,
	original_target: Dictionary,
	module: ModuleData,
	effect: CombatEffectData,
	raw_amount: float,
	parent_context: CombatEventContext
) -> void:
	var target := _resolve_redirect_target(
		original_target
	)

	if target == null:
		return

	var accuracy := (
		effect.accuracy_override
		if effect.accuracy_override >= 0.0
		else (
			module.accuracy
			if module != null
			else 1.0
		)
	)

	if not _roll_accuracy(target, accuracy):
		combat_log_added.emit(
			"> %s missed %s."
			% [
				caster.get("name", "Entity"),
				target.get("name", "Entity")
			]
		)
		floating_text_requested.emit(
			target,
			"MISS!",
			Color.GRAY
		)
		return

	var damage := _calculate_damage(
		caster,
		target,
		effect,
		raw_amount
	)
	var did_crit := (
		effect.can_crit
		and _roll_crit(caster)
	)

	if did_crit:
		damage = maxi(
			1,
			int(roundf(
				damage * effect.crit_multiplier
			))
		)

		if effect.applies_unstability_on_crit:
			_apply_status(
				caster,
				target,
				UNSTABILITY_STATUS,
				1,
				parent_context
			)

	target["hp"] = maxf(
		0.0,
		float(target.get("hp", 0.0))
		- damage
	)

	var floating_text := "-%d" % damage
	var floating_color := Color.CRIMSON

	if did_crit:
		floating_text = "CRIT! -%d" % damage
		floating_color = Color.ORANGE_RED

	floating_text_requested.emit(
		target,
		floating_text,
		floating_color
	)
	combat_log_added.emit(
		"> %s took %d damage."
		% [
			target.get("name", "Entity"),
			damage
		]
	)

	var dealt_context := _make_context(
		CombatConstants.TriggerTiming.DAMAGE_DEALT,
		caster,
		target,
		module,
		parent_context.action_slot,
		parent_context.timeline_index,
		damage,
		parent_context.event_depth + 1
	)
	_dispatch_event(dealt_context)

	var received_context := _make_context(
		CombatConstants.TriggerTiming.DAMAGE_RECEIVED,
		caster,
		target,
		module,
		parent_context.action_slot,
		parent_context.timeline_index,
		damage,
		parent_context.event_depth + 1
	)
	_dispatch_event(received_context)

	if float(target.get("hp", 0.0)) <= 0.0:
		_defeat_actor(target, received_context)


func _apply_heal(
	_caster: Dictionary,
	target: Dictionary,
	raw_amount: float
) -> void:
	var maximum := get_effective_stat(
		target,
		CombatConstants.Stat.MAX_HP
	)
	var previous := float(
		target.get("hp", 0.0)
	)
	target["hp"] = clampf(
		previous + maxf(0.0, raw_amount),
		0.0,
		maximum
	)
	var healed := int(roundf(
		float(target["hp"]) - previous
	))

	floating_text_requested.emit(
		target,
		"+%d" % healed,
		Color.LIME_GREEN
	)
	combat_log_added.emit(
		"> %s recovered %d HP."
		% [
			target.get("name", "Entity"),
			healed
		]
	)


func _modify_stability(
	target: Dictionary,
	amount: float
) -> void:
	var maximum := get_effective_stat(
		target,
		CombatConstants.Stat.MAX_STABILITY
	)
	target["stability"] = clampf(
		float(target.get("stability", 0.0))
		+ amount,
		0.0,
		maximum
	)
	var sign_text := "+" if amount >= 0.0 else ""
	floating_text_requested.emit(
		target,
		"%s%d STB"
		% [sign_text, int(roundf(amount))],
		Color.DODGER_BLUE
	)


func _modify_actor_stat(
	target: Dictionary,
	stat: CombatConstants.Stat,
	amount: float
) -> void:
	var key := CombatConstants.stat_key(stat)

	if key.is_empty() or stat in [
		CombatConstants.Stat.HP,
		CombatConstants.Stat.STABILITY
	]:
		return

	target[key] = float(
		target.get(key, 0.0)
	) + amount


func _apply_status(
	caster: Dictionary,
	target: Dictionary,
	status: StatusEffectData,
	stacks: int,
	parent_context: CombatEventContext
) -> void:
	if status == null:
		return

	var existing := _find_status_instance(
		target,
		status.status_id
	)

	if existing == null:
		existing = CombatStatusInstance.create(
			status,
			stacks,
			int(caster.get("uid", -1)),
			current_cycle
		)
		target["active_statuses"].append(
			existing
		)
	else:
		_stack_status(
			existing,
			status,
			stacks
		)

	combat_log_added.emit(
		"> %s gained %s (%d)."
		% [
			target.get("name", "Entity"),
			status.display_name,
			existing.stacks
		]
	)

	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.STATUS_APPLIED,
			caster,
			target,
			parent_context.module,
			parent_context.action_slot,
			parent_context.timeline_index,
			stacks,
			parent_context.event_depth + 1
		)
	)


func _stack_status(
	instance: CombatStatusInstance,
	status: StatusEffectData,
	added_stacks: int
) -> void:
	match status.stack_mode:
		StatusEffectData.StackMode.ADD:
			instance.stacks = clampi(
				instance.stacks + added_stacks,
				1,
				status.max_stacks
			)
		StatusEffectData.StackMode.REFRESH:
			pass
		StatusEffectData.StackMode.REPLACE:
			instance.stacks = clampi(
				added_stacks,
				1,
				status.max_stacks
			)
		StatusEffectData.StackMode.KEEP_HIGHEST:
			instance.stacks = clampi(
				maxi(
					instance.stacks,
					added_stacks
				),
				1,
				status.max_stacks
			)

	if status.refresh_duration_when_stacked:
		instance.remaining_cycles = (
			status.duration_cycles
		)
		instance.applied_cycle = current_cycle


func _remove_status(
	target: Dictionary,
	status_id: StringName,
	remove_all: bool,
	stack_amount: int,
	context: CombatEventContext
) -> void:
	var instance := _find_status_instance(
		target,
		status_id
	)

	if instance == null:
		return

	if remove_all:
		_expire_status(
			target,
			instance,
			context
		)
		return

	var remaining_stacks := (
		instance.stacks - stack_amount
	)

	if remaining_stacks <= 0:
		_expire_status(
			target,
			instance,
			context
		)
	else:
		instance.stacks = remaining_stacks


func _spawn_dummy(
	caster: Dictionary,
	effect: CombatEffectData,
	context: CombatEventContext
) -> void:
	if effect.dummy_data == null:
		_fail_effect(
			caster,
			"SPAWN_DUMMY has no DummyData."
		)
		return

	var team := (
		ally_team
		if bool(caster.get("is_ally", false))
		else enemy_team
	)
	var spawn_index := _find_dummy_spawn_slot(
		caster,
		team,
		effect
	)

	if spawn_index < 0:
		_fail_effect(
			caster,
			"No free slot for %s."
			% effect.dummy_data.display_name
		)
		return

	var dummy := _create_dummy(
		effect.dummy_data,
		caster
	)
	team[spawn_index] = dummy
	combat_log_added.emit(
		"> %s created %s in slot %d."
		% [
			caster.get("name", "Entity"),
			dummy.get("name", "Dummy"),
			spawn_index + 1
		]
	)
	stats_updated.emit()
	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.DUMMY_CREATED,
			caster,
			dummy,
			context.module,
			context.action_slot,
			context.timeline_index,
			0.0,
			context.event_depth + 1
		)
	)


func _apply_redirect(
	caster: Dictionary,
	target: Dictionary,
	duration_actions: int
) -> void:
	target["runtime_effects"].append({
		"type": &"redirect_next_damage",
		"redirect_to_uid": caster.get("uid", -1),
		"remaining_actions": maxi(
			1,
			duration_actions
		)
	})


func _dispatch_event(
	context: CombatEventContext
) -> void:
	if (
		context == null
		or context.event_depth > MAX_EVENT_DEPTH
	):
		if (
			context != null
			and context.event_depth > MAX_EVENT_DEPTH
		):
			push_error(
				"CombatManager: maximum event recursion reached."
			)
		return

	var actors := _all_combatants()

	for holder in actors:
		if holder == null:
			continue

		if (
			float(holder.get("hp", 0.0)) <= 0.0
			and context.timing not in [
				CombatConstants.TriggerTiming.DUMMY_DESTROYED,
				CombatConstants.TriggerTiming.DUMMY_EXPIRED,
				CombatConstants.TriggerTiming.STATUS_EXPIRED
			]
		):
			continue

		_process_status_triggers(
			holder,
			context
		)
		_process_dummy_triggers(
			holder,
			context
		)


func _process_status_triggers(
	holder: Dictionary,
	context: CombatEventContext
) -> void:
	var statuses: Array = holder.get(
		"active_statuses",
		[]
	).duplicate()

	for instance in statuses:
		if (
			not (instance is CombatStatusInstance)
			or instance.data == null
			or (
				instance.expiring
				and context.timing
				!= CombatConstants.TriggerTiming.STATUS_EXPIRED
			)
		):
			continue

		for triggered_effect in (
			instance.data.triggered_effects
		):
			if (
				triggered_effect == null
				or triggered_effect.trigger == null
				or triggered_effect.trigger.timing
				== CombatConstants.TriggerTiming.CONTINUOUS
				or not triggered_effect.trigger.matches(
					context,
					holder
				)
			):
				continue

			var trigger_key := triggered_effect.get_instance_id()

			if (
				triggered_effect.trigger_once_per_cycle
				and int(instance.last_triggered_cycle.get(
					trigger_key,
					-1
				)) == current_cycle
			):
				continue

			instance.last_triggered_cycle[
				trigger_key
			] = current_cycle
			var source := _find_combatant_by_uid(
				instance.source_uid
			)

			if source == null:
				source = holder

			_execute_effects(
				source,
				triggered_effect.effects,
				context.module,
				context,
				holder,
				instance
			)

			if (
				triggered_effect.stack_delta_after_trigger
				!= 0
			):
				var resulting_stacks := clampi(
					instance.stacks
					+ triggered_effect.stack_delta_after_trigger,
					0,
					instance.data.max_stacks
				)

				if resulting_stacks <= 0:
					_expire_status(
						holder,
						instance,
						context
					)
					break
				else:
					instance.stacks = resulting_stacks


func _process_dummy_triggers(
	holder: Dictionary,
	context: CombatEventContext
) -> void:
	if not bool(holder.get("is_dummy", false)):
		return

	var data: DummyData = holder.get("dummy_data")

	if data == null:
		return

	for triggered_effect in data.triggered_effects:
		if (
			triggered_effect == null
			or triggered_effect.trigger == null
			or triggered_effect.trigger.timing
			== CombatConstants.TriggerTiming.CONTINUOUS
			or not triggered_effect.trigger.matches(
				context,
				holder
			)
		):
			continue

		_execute_effects(
			holder,
			triggered_effect.effects,
			context.module,
			context,
			holder
		)


func _finish_non_terminal_cycle() -> void:
	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.CYCLE_END
		)
	)

	if _has_terminal_state():
		_finish_terminal_cycle()
		return

	_recover_stability()
	_tick_status_durations()
	_tick_dummy_durations()
	_desfragment_enemies()
	stats_updated.emit()

	if _has_terminal_state():
		_finish_terminal_cycle()
		return

	rebuild_timeline()
	cycle_completed.emit(current_cycle)
	cycle_ended_ready_for_next.emit()


func _finish_terminal_cycle() -> void:
	_encounter_active = false
	stats_updated.emit()
	cycle_completed.emit(current_cycle)

	if _all_defeated(enemy_team):
		combat_log_added.emit(
			"\n[color=lime]>>> VICTORY <<<[/color]"
		)
		combat_victory.emit()
	elif _all_defeated(ally_team):
		combat_log_added.emit(
			"\n[color=red]>>> DEFEAT <<<[/color]"
		)
		combat_defeat.emit()


func _recover_stability() -> void:
	for actor in _all_combatants():
		if (
			actor == null
			or float(actor.get("hp", 0.0)) <= 0.0
		):
			continue

		var recovery := get_effective_stat(
			actor,
			CombatConstants.Stat.STABILITY_RECOVERY
		)
		var maximum := get_effective_stat(
			actor,
			CombatConstants.Stat.MAX_STABILITY
		)
		actor["stability"] = clampf(
			float(actor.get("stability", 0.0))
			+ recovery,
			0.0,
			maximum
		)


func _tick_status_durations() -> void:
	for actor in _all_combatants():
		if actor == null:
			continue

		var statuses: Array = actor.get(
			"active_statuses",
			[]
		).duplicate()

		for instance in statuses:
			if (
				not (instance is CombatStatusInstance)
				or instance.data == null
				or instance.remaining_cycles < 0
			):
				continue

			if (
				instance.applied_cycle == current_cycle
				and not instance.data.tick_on_application_cycle
			):
				continue

			instance.remaining_cycles -= 1

			if instance.remaining_cycles <= 0:
				_expire_status(
					actor,
					instance,
					_make_context(
						CombatConstants.TriggerTiming.STATUS_EXPIRED,
						actor,
						actor
					)
				)


func _tick_dummy_durations() -> void:
	var actors := _all_combatants()

	for actor in actors:
		if (
			actor == null
			or not bool(actor.get("is_dummy", false))
			or int(actor.get("remaining_cycles", -1)) < 0
			or int(actor.get("spawned_cycle", -1))
			== current_cycle
		):
			continue

		actor["remaining_cycles"] = int(
			actor["remaining_cycles"]
		) - 1

		if int(actor["remaining_cycles"]) <= 0:
			var context := _make_context(
				CombatConstants.TriggerTiming.DUMMY_EXPIRED,
				actor,
				actor
			)
			_dispatch_event(context)
			_remove_actor_from_grid(actor)


func _expire_status(
	holder: Dictionary,
	instance: CombatStatusInstance,
	parent_context: CombatEventContext
) -> void:
	var statuses: Array = holder.get(
		"active_statuses",
		[]
	)

	if not statuses.has(instance):
		return

	if instance.expiring:
		return

	instance.expiring = true
	_dispatch_event(
		_make_context(
			CombatConstants.TriggerTiming.STATUS_EXPIRED,
			holder,
			holder,
			parent_context.module,
			parent_context.action_slot,
			parent_context.timeline_index,
			0.0,
			parent_context.event_depth + 1
		)
	)
	statuses.erase(instance)


func _defeat_actor(
	actor: Dictionary,
	parent_context: CombatEventContext
) -> void:
	if bool(actor.get("is_dummy", false)):
		_dispatch_event(
			_make_context(
				CombatConstants.TriggerTiming.DUMMY_DESTROYED,
				parent_context.source,
				actor,
				parent_context.module,
				parent_context.action_slot,
				parent_context.timeline_index,
				0.0,
				parent_context.event_depth + 1
			)
		)

	_remove_actor_from_grid(actor)


func _remove_actor_from_grid(
	actor: Dictionary
) -> void:
	for team in [ally_team, enemy_team]:
		for index in range(team.size()):
			if team[index] == actor:
				team[index] = null
				stats_updated.emit()
				return


func _calculate_damage(
	caster: Dictionary,
	target: Dictionary,
	effect: CombatEffectData,
	raw_amount: float
) -> int:
	var damage := maxf(
		0.0,
		raw_amount
	)

	if not effect.ignore_defense:
		damage -= get_effective_stat(
			target,
			effect.defense_stat
		)

	damage = maxf(1.0, damage)
	damage *= _continuous_multiplier(
		caster,
		CombatEffectData.EffectType.MODIFY_DAMAGE_DEALT
	)
	damage *= _continuous_multiplier(
		target,
		CombatEffectData.EffectType.MODIFY_DAMAGE_TAKEN
	)
	return maxi(
		1,
		int(roundf(damage))
	)


func _continuous_multiplier(
	actor: Dictionary,
	effect_type: CombatEffectData.EffectType
) -> float:
	var multiplier: float = 1.0

	for binding in _continuous_bindings():
		var holder: Dictionary = binding["holder"]
		var source: Dictionary = binding["source"]
		var instance: CombatStatusInstance = (
			binding["status_instance"]
		)
		var triggered_effect: CombatTriggeredEffectData = (
			binding["triggered_effect"]
		)

		for effect in triggered_effect.effects:
			if (
				effect == null
				or effect.effect_type != effect_type
				or not _effect_targets_actor(
					effect,
					holder,
					actor
				)
			):
				continue

			multiplier *= maxf(
				0.0,
				_evaluate_formula(
					effect.value_formula,
					source,
					actor,
					holder,
					instance,
					null
				)
			)

	return multiplier


func _get_effective_stat(
	actor: Dictionary,
	stat: CombatConstants.Stat,
	depth: int
) -> float:
	var key := CombatConstants.stat_key(stat)
	var value := float(actor.get(key, 0.0))

	if depth > 8:
		return value

	for binding in _continuous_bindings():
		var holder: Dictionary = binding["holder"]
		var source: Dictionary = binding["source"]
		var instance: CombatStatusInstance = (
			binding["status_instance"]
		)
		var triggered_effect: CombatTriggeredEffectData = (
			binding["triggered_effect"]
		)

		for effect in triggered_effect.effects:
			if (
				effect == null
				or effect.effect_type
				!= CombatEffectData.EffectType.MODIFY_STAT
				or effect.target_stat != stat
				or not _effect_targets_actor(
					effect,
					holder,
					actor
				)
			):
				continue

			value += _evaluate_formula(
				effect.value_formula,
				source,
				actor,
				holder,
				instance,
				null,
				depth + 1
			)

	return maxf(0.0, value)


func _evaluate_formula(
	formula: CombatValueFormula,
	caster: Dictionary,
	target: Dictionary,
	holder: Dictionary,
	status_instance: CombatStatusInstance,
	context: CombatEventContext,
	stat_depth: int = 0
) -> float:
	if formula == null:
		return 0.0

	var value := formula.base_value
	var reference_actor := _resolve_formula_actor(
		formula.stat_reference,
		caster,
		target,
		holder,
		context
	)

	if (
		reference_actor != null
		and not is_zero_approx(
			formula.stat_multiplier
		)
	):
		var stat_value := _base_stat(
			reference_actor,
			formula.stat
		)

		if formula.use_effective_stat:
			stat_value = _get_effective_stat(
				reference_actor,
				formula.stat,
				stat_depth + 1
			)

		value += (
			stat_value
			* formula.stat_multiplier
		)

	if (
		status_instance != null
		and not is_zero_approx(
			formula.stack_multiplier
		)
	):
		value += (
			status_instance.stacks
			* formula.stack_multiplier
		)

	if formula.use_minimum:
		value = maxf(
			value,
			formula.minimum_value
		)

	if formula.use_maximum:
		value = minf(
			value,
			formula.maximum_value
		)

	match formula.round_mode:
		CombatValueFormula.RoundMode.ROUND:
			return roundf(value)
		CombatValueFormula.RoundMode.FLOOR:
			return floorf(value)
		CombatValueFormula.RoundMode.CEIL:
			return ceilf(value)

	return value


func _resolve_formula_actor(
	reference: CombatValueFormula.ReferenceActor,
	caster: Dictionary,
	target: Dictionary,
	holder: Dictionary,
	context: CombatEventContext
) -> Variant:
	match reference:
		CombatValueFormula.ReferenceActor.CASTER:
			return caster
		CombatValueFormula.ReferenceActor.TARGET:
			return target
		CombatValueFormula.ReferenceActor.STATUS_HOLDER:
			return holder
		CombatValueFormula.ReferenceActor.EVENT_SOURCE:
			return (
				context.source
				if context != null
				else null
			)
		CombatValueFormula.ReferenceActor.EVENT_TARGET:
			return (
				context.target
				if context != null
				else null
			)
		CombatValueFormula.ReferenceActor.DUMMY_CREATOR:
			var creator_uid := int(
				holder.get(
					"creator_uid",
					caster.get("creator_uid", -1)
				)
			)
			return _find_combatant_by_uid(
				creator_uid
			)

	return null


func _preview_effect(
	caster: Dictionary,
	target: Dictionary,
	module: ModuleData,
	effect: CombatEffectData,
	context: CombatEventContext
) -> Dictionary:
	var amount := _evaluate_formula(
		effect.value_formula,
		caster,
		target,
		caster,
		null,
		context
	)
	var entry := {
		"target_uid": target.get("uid", -1),
		"target_name": target.get("name", "Entity"),
		"hp_delta": 0,
		"stability_delta": 0,
		"summary": effect.describe()
	}

	match effect.effect_type:
		CombatEffectData.EffectType.DAMAGE:
			var damage := _calculate_damage(
				caster,
				target,
				effect,
				amount
			)
			entry["hp_delta"] = -damage
			entry["summary"] = "%s: -%d HP" % [
				target.get("name", "Entity"),
				damage
			]

		CombatEffectData.EffectType.HEAL:
			var missing_hp := maxi(
				0,
				int(roundf(
					get_effective_stat(
						target,
						CombatConstants.Stat.MAX_HP
					)
					- float(target.get("hp", 0.0))
				))
			)
			var healing := mini(
				missing_hp,
				maxi(0, int(amount))
			)
			entry["hp_delta"] = healing
			entry["summary"] = "%s: +%d HP" % [
				target.get("name", "Entity"),
				healing
			]

		CombatEffectData.EffectType.MODIFY_STABILITY:
			entry["stability_delta"] = int(amount)
			entry["summary"] = "%s: %+d STB" % [
				target.get("name", "Entity"),
				int(amount)
			]

	return entry


func _base_stat(
	actor: Dictionary,
	stat: CombatConstants.Stat
) -> float:
	return float(
		actor.get(
			CombatConstants.stat_key(stat),
			0.0
		)
	)


func _effect_targets_actor(
	effect: CombatEffectData,
	holder: Dictionary,
	target_actor: Dictionary
) -> bool:
	if effect.target_selector == null:
		return false

	var targets := resolve_targets(
		effect.target_selector,
		holder,
		null,
		holder
	)

	for target in targets:
		if (
			int(target.get("uid", -1))
			== int(target_actor.get("uid", -1))
		):
			return true

	return false


func _continuous_bindings() -> Array[Dictionary]:
	var bindings: Array[Dictionary] = []

	for holder in _all_combatants():
		for instance in holder.get(
			"active_statuses",
			[]
		):
			if (
				not (instance is CombatStatusInstance)
				or instance.data == null
			):
				continue

			var source := _find_combatant_by_uid(
				instance.source_uid
			)

			if source == null:
				source = holder

			for triggered_effect in (
				instance.data.triggered_effects
			):
				if (
					triggered_effect != null
					and triggered_effect.trigger != null
					and triggered_effect.trigger.timing
					== CombatConstants.TriggerTiming.CONTINUOUS
				):
					bindings.append({
						"holder": holder,
						"source": source,
						"status_instance": instance,
						"triggered_effect": triggered_effect
					})

		if bool(holder.get("is_dummy", false)):
			var data: DummyData = holder.get(
				"dummy_data"
			)

			if data == null:
				continue

			for triggered_effect in data.triggered_effects:
				if (
					triggered_effect != null
					and triggered_effect.trigger != null
					and triggered_effect.trigger.timing
					== CombatConstants.TriggerTiming.CONTINUOUS
				):
					bindings.append({
						"holder": holder,
						"source": holder,
						"status_instance": null,
						"triggered_effect": triggered_effect
					})

	return bindings


func _get_direct_enemy_target(
	attacker_index: int,
	opposing_team: Array
) -> Variant:
	var alive_targets := _get_valid_targets(
		opposing_team,
		false
	)

	if alive_targets.is_empty():
		return null

	if alive_targets.size() == 1:
		return alive_targets[0]

	if alive_targets.size() == 2:
		return (
			alive_targets[0]
			if attacker_index <= 1
			else alive_targets[1]
		)

	if alive_targets.size() == 3:
		return _get_closest_target_by_slot(
			attacker_index,
			opposing_team
		)

	if (
		attacker_index >= 0
		and attacker_index < opposing_team.size()
		and _is_valid_target(
			opposing_team[attacker_index],
			false
		)
	):
		return opposing_team[attacker_index]

	return _get_closest_target_by_slot(
		attacker_index,
		opposing_team
	)


func _get_adjacent_ally(
	actor_index: int,
	team: Array
) -> Variant:
	if actor_index < 0:
		return null

	for index in [
		actor_index + 1,
		actor_index - 1
	]:
		if (
			index >= 0
			and index < team.size()
			and _is_valid_target(
				team[index],
				false
			)
		):
			return team[index]

	return _get_closest_target_by_slot(
		actor_index,
		team
	)


func _get_closest_target_by_slot(
	origin_index: int,
	team: Array
) -> Variant:
	var closest: Variant = null
	var closest_distance: int = 999

	for index in range(team.size()):
		if not _is_valid_target(
			team[index],
			false
		):
			continue

		var distance := absi(
			origin_index - index
		)

		if distance < closest_distance:
			closest_distance = distance
			closest = team[index]

	return closest


func _target_from_slot(
	team: Array,
	slot_index: int,
	selector: CombatTargetSelector
) -> Array:
	var target: Variant = team[slot_index]

	if _is_valid_target(
		target,
		selector.include_defeated
	):
		return [target]

	if selector.fallback_to_closest:
		var fallback := _get_closest_target_by_slot(
			slot_index,
			team
		)
		if fallback != null:
			return [fallback]

	return []


func _variant_as_target_array(
	value: Variant,
	include_defeated: bool
) -> Array:
	var result: Array = []

	if value is Array:
		for target in value:
			if _is_valid_target(
				target,
				include_defeated
			):
				result.append(target)
	elif _is_valid_target(value, include_defeated):
		result.append(value)

	return result


func _get_valid_targets(
	team: Array,
	include_defeated: bool
) -> Array:
	var result: Array = []

	for actor in team:
		if _is_valid_target(
			actor,
			include_defeated
		):
			result.append(actor)

	return result


func _is_valid_target(
	actor: Variant,
	include_defeated: bool
) -> bool:
	return (
		actor is Dictionary
		and (
			include_defeated
			or float(actor.get("hp", 0.0)) > 0.0
		)
	)


func _get_timeline_actors(
	team: Array
) -> Array:
	var secondary: Array = []
	var main_actor: Variant = null

	if (
		_is_valid_target(team[1], false)
		and not bool(team[1].get("is_dummy", false))
	):
		main_actor = team[1]

	for actor in team:
		if (
			_is_valid_target(actor, false)
			and actor != main_actor
			and not bool(actor.get("is_dummy", false))
		):
			secondary.append(actor)

	if main_actor == null and not secondary.is_empty():
		main_actor = secondary.pop_front()

	var actor_count := secondary.size() + (
		1 if main_actor != null else 0
	)

	match actor_count:
		0:
			return []
		1:
			return [
				main_actor,
				main_actor,
				main_actor,
				main_actor
			]
		2:
			return [
				main_actor,
				main_actor,
				secondary[0],
				secondary[0]
			]
		3:
			return [
				main_actor,
				main_actor,
				secondary[0],
				secondary[1]
			]
		4:
			return [
				main_actor,
				secondary[0],
				secondary[1],
				secondary[2]
			]

	return []


func _find_dummy_spawn_slot(
	caster: Dictionary,
	team: Array,
	effect: CombatEffectData
) -> int:
	var caster_index := team.find(caster)

	match effect.spawn_slot_rule:
		CombatEffectData.SpawnSlotRule.FIRST_EMPTY, CombatEffectData.SpawnSlotRule.LEFTMOST_EMPTY:
			for index in range(team.size()):
				if team[index] == null:
					return index

		CombatEffectData.SpawnSlotRule.RIGHTMOST_EMPTY:
			for index in range(
				team.size() - 1,
				-1,
				-1
			):
				if team[index] == null:
					return index

		CombatEffectData.SpawnSlotRule.ADJACENT_LEFT:
			var left := caster_index - 1
			if left >= 0 and team[left] == null:
				return left

		CombatEffectData.SpawnSlotRule.ADJACENT_RIGHT:
			var right := caster_index + 1
			if (
				right < team.size()
				and team[right] == null
			):
				return right

		CombatEffectData.SpawnSlotRule.SPECIFIC_SLOT:
			if (
				team[effect.specific_spawn_slot]
				== null
			):
				return effect.specific_spawn_slot

	return -1


func _resolve_redirect_target(
	original_target: Dictionary
) -> Variant:
	var effects: Array = original_target.get(
		"runtime_effects",
		[]
	)

	for index in range(
		effects.size() - 1,
		-1,
		-1
	):
		var effect: Dictionary = effects[index]

		if (
			effect.get("type")
			!= &"redirect_next_damage"
		):
			continue

		var redirect_target := _find_combatant_by_uid(
			int(effect.get("redirect_to_uid", -1))
		)
		effect["remaining_actions"] = int(
			effect.get("remaining_actions", 1)
		) - 1

		if int(effect["remaining_actions"]) <= 0:
			effects.remove_at(index)

		if (
			redirect_target != null
			and float(redirect_target.get("hp", 0.0))
			> 0.0
		):
			return redirect_target

	return original_target


func _find_status_instance(
	actor: Dictionary,
	status_id: StringName
) -> CombatStatusInstance:
	for instance in actor.get(
		"active_statuses",
		[]
	):
		if (
			instance is CombatStatusInstance
			and instance.data != null
			and instance.data.status_id == status_id
		):
			return instance

	return null


func _find_combatant_by_uid(
	uid: int
) -> Variant:
	if uid < 0:
		return null

	for actor in _all_combatants():
		if (
			actor != null
			and int(actor.get("uid", -1)) == uid
		):
			return actor

	return null


func _get_player_actor() -> Variant:
	for actor in ally_team:
		if (
			actor != null
			and bool(actor.get("is_player", false))
		):
			return actor

	return null


func _all_combatants() -> Array:
	var actors: Array = []

	for actor in ally_team + enemy_team:
		if actor != null:
			actors.append(actor)

	return actors


func _all_defeated(
	team: Array
) -> bool:
	for actor in team:
		if (
			actor != null
			and float(actor.get("hp", 0.0)) > 0.0
			and not bool(actor.get("is_dummy", false))
		):
			return false

	return true


func _has_terminal_state() -> bool:
	return (
		_all_defeated(enemy_team)
		or _all_defeated(ally_team)
	)


func _desfragment_enemies() -> void:
	var survivors := _get_valid_targets(
		enemy_team,
		false
	)
	var gravity_slots := [1, 0, 2, 3]
	enemy_team = [null, null, null, null]

	for index in range(survivors.size()):
		enemy_team[gravity_slots[index]] = (
			survivors[index]
		)


func _roll_accuracy(
	target: Dictionary,
	accuracy: float
) -> bool:
	var dodge := clampf(
		get_effective_stat(
			target,
			CombatConstants.Stat.DODGE
		),
		0.0,
		1.0
	)
	var chance := clampf(
		accuracy - (dodge * 0.5),
		0.05,
		1.0
	)
	return randf() <= chance


func _roll_crit(
	caster: Dictionary
) -> bool:
	var chance := clampf(
		get_effective_stat(
			caster,
			CombatConstants.Stat.CRIT
		),
		0.0,
		1.0
	)
	return randf() <= chance


func _fail_effect(
	actor: Dictionary,
	message: String
) -> void:
	combat_log_added.emit(
		"> EFFECT FAILED: %s" % message
	)
	floating_text_requested.emit(
		actor,
		"FAIL!",
		Color.GRAY
	)


func _context_from_action(
	action: Dictionary,
	timing: CombatConstants.TriggerTiming,
	timeline_index: int = -1
) -> CombatEventContext:
	return _make_context(
		timing,
		action.get("actor"),
		action.get("target"),
		action.get("module"),
		int(action.get("action_slot", -1)),
		timeline_index
	)


func _make_context(
	timing: CombatConstants.TriggerTiming,
	source: Variant = null,
	target: Variant = null,
	module: ModuleData = null,
	action_slot: int = -1,
	timeline_index: int = -1,
	amount: float = 0.0,
	depth: int = 0
) -> CombatEventContext:
	var context := CombatEventContext.create(
		timing,
		current_cycle,
		source,
		target,
		module,
		action_slot,
		timeline_index,
		amount,
		depth,
		_next_event_id
	)
	_next_event_id += 1
	return context


func _consume_uid() -> int:
	var uid := _next_uid
	_next_uid += 1
	return uid


func _team_snapshot(
	team: Array
) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []

	for actor in team:
		if actor == null:
			continue

		snapshot.append({
			"uid": actor.get("uid", -1),
			"character_id": actor.get(
				"character_id",
				&""
			),
			"hp": actor.get("hp", 0.0),
			"stability": actor.get(
				"stability",
				0.0
			),
			"is_dummy": actor.get(
				"is_dummy",
				false
			)
		})

	return snapshot
