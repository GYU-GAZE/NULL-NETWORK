extends Node


const COMBAT_SCENE: PackedScene = preload(
	"res://apps/combat/app_combat.tscn"
)
const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_check(
		catalog_errors.is_empty(),
		"Default catalog failed: %s" % catalog_errors
	)

	CampaignState.reset_campaign()
	CombatManager.reset_encounter()
	_check(
		CampaignState.create_campaign(
			"combat_action_loadout_stats",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Could not create the combat loadout fixture campaign."
	)

	var partner: PartnerStateData = (
		APKProgressionService.create_partner_state(
			"novire_init",
			"NOVIRE",
			0,
			0
		)
	)
	_check(
		partner != null \
		and CampaignState.set_partner_state(partner),
		"Could not create the NOVIRE fixture partner."
	)

	if partner == null:
		_finish_test()
		return

	var novire_stats: Dictionary = (
		APKProgressionService.calculate_partner_stats(partner)
	)
	_check(
		int(novire_stats.get("max_hp", 0)) == 2,
		"Level-1 NOVIRE no longer follows its canonical HP curve."
	)

	var rattildus_loadout: CharacterLoadout = (
		APKCombatLoadoutFactory.create_loadout(
			"rattildus_init",
			1
		)
	)
	_check(
		rattildus_loadout != null \
		and rattildus_loadout.max_hp == 2 \
		and rattildus_loadout.equipped_modules.size() == 4,
		"Level-1 Rattildus did not use catalog APK progression and Modules."
	)

	var combat_app := COMBAT_SCENE.instantiate() as DragActionCombatApp
	_check(
		combat_app != null,
		"Combat scene did not instantiate DragActionCombatApp."
	)

	if combat_app == null:
		_finish_test()
		return

	add_child(combat_app)
	combat_app.size = Vector2(640, 377)
	await get_tree().process_frame
	_check(
		combat_app.start_encounter(TEST_ENCOUNTER),
		"Combat scene rejected the catalog APK encounter."
	)
	await get_tree().process_frame

	var enemy: Variant = CombatManager.enemy_team[1]
	_check(
		enemy is Dictionary \
		and int(enemy.get("source_kind", -1)) \
		== CombatSlotData.ParticipantSource.CATALOG_APK \
		and str(enemy.get("character_id", "")) \
		== "rattildus_init" \
		and int(enemy.get("max_hp", 0)) == 2,
		"Akihabara Rattildus still uses the legacy 100-HP fixed loadout."
	)

	combat_app._on_player_actions_pressed()
	await get_tree().process_frame
	var effective_slots: VBoxContainer = combat_app.equipped_list
	_check(
		effective_slots.get_child_count() == 4,
		"Action planner did not render four effective APK slots."
	)

	if effective_slots.get_child_count() >= 1:
		var first_slot := (
			effective_slots.get_child(0) as PlayerActionSlotUI
		)
		_check(
			first_slot != null \
			and first_slot.current_action == null \
			and first_slot.current_module != null \
			and str(first_slot.current_module.module_id) \
			== "basic_attack",
			"An unmodified action slot did not display its APK Module."
		)

	var found_player_action: bool = false
	var found_apk_module: bool = false

	for child: Node in combat_app.inventory_list.get_children():
		if child is PlayerActionSlotUI:
			found_player_action = true
		elif child is ModuleSlotUI:
			found_apk_module = true

	_check(
		found_player_action and found_apk_module,
		"Action repertoire did not expose both Operator Actions and APK Modules."
	)

	var actions: Array[PlayerActionData] = (
		CombatManager.get_player_actions()
	)

	if not actions.is_empty() and enemy is Dictionary:
		var action: PlayerActionData = actions[0]
		var assignment_errors: PackedStringArray = (
			CombatManager.set_player_action(
				0,
				action.action_id,
				int(enemy.get("uid", -1))
			)
		)
		_check(
			assignment_errors.is_empty(),
			"Could not assign a Player Action: %s"
			% assignment_errors
		)
		combat_app.refresh_module_ui()
		await get_tree().process_frame
		var overridden_slot := (
			effective_slots.get_child(0) as PlayerActionSlotUI
		)
		_check(
			overridden_slot != null \
			and overridden_slot.current_action == action \
			and overridden_slot.current_module != null,
			"Player Action did not override while retaining its underlying Module."
		)

		CombatManager.clear_player_action(0)
		combat_app.refresh_module_ui()
		await get_tree().process_frame
		var restored_slot := (
			effective_slots.get_child(0) as PlayerActionSlotUI
		)
		_check(
			restored_slot != null \
			and restored_slot.current_action == null \
			and restored_slot.current_module != null \
			and str(restored_slot.current_module.module_id) \
			== "basic_attack",
			"Clearing the Player Action did not restore the APK Module."
		)

	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CombatManager.reset_encounter()
	CampaignState.reset_campaign()

	if _failures.is_empty():
		print("COMBAT_ACTION_LOADOUT_STATS_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"COMBAT_ACTION_LOADOUT_STATS_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)
