extends SceneTree


const COMBAT_MANAGER_SCRIPT: Script = preload(
	"res://apps/combat/combat_manager.gd"
)


var _failures := PackedStringArray()
var _observed_defense_bonus: bool = false
var _combat_manager: Node


func _initialize() -> void:
	seed(1337)
	_combat_manager = COMBAT_MANAGER_SCRIPT.new() as Node

	if _combat_manager == null:
		_failures.append(
			"Could not instantiate the CombatManager script."
		)
		call_deferred("_finish")
		return

	get_root().add_child(_combat_manager)
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

	if _combat_manager.current_cycle_actions.is_empty():
		return

	var preview := _combat_manager.preview_action(
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


func _test_status_and_cycle_trigger(
	encounter: CombatEncounter
) -> void:
	_check(
		_combat_manager.load_encounter(encounter),
		"Could not reset encounter for trigger test."
	)

	if not _combat_manager.action_executed.is_connected(
		_on_action_executed
	):
		_combat_manager.action_executed.connect(
			_on_action_executed
		)

	_combat_manager.execute_cycle(false)
	_check(
		_observed_defense_bonus,
		"Continuous status modifier was not observed during an action."
	)
	_check(
		_combat_manager.load_encounter(encounter),
		"Could not reset encounter for dummy trigger test."
	)

	var turret_module := load(
		"res://data/content/combat/modules/dummy_turret.tres"
	) as ModuleData
	var rest_module := load(
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

	var metadata := _combat_manager.get_result_metadata()
	_check(
		int(metadata.get("cycles", 0)) > 0,
		"Combat result metadata contains no cycle count."
	)


func _on_action_executed(
	_index: int,
	action: Dictionary
) -> void:
	var module: ModuleData = action.get("module")

	if (
		module == null
		or module.module_id != &"basic_defense"
	):
		return

	var actor: Dictionary = action.get("actor", {})
	var base_def := float(actor.get("def", 0.0))
	var effective_def := _combat_manager.get_effective_stat(
		actor,
		CombatConstants.Stat.DEF
	)
	_observed_defense_bonus = (
		effective_def > base_def
	)


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
		quit(0)
		return

	for failure in _failures:
		push_error(
			"COMBAT_RUNTIME_TEST: %s"
			% failure
		)

	quit(1)
