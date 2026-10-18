extends NavigatorTestHarness
class_name FieldIntegrationHarness

var desktop: Control
var navigator: NavigatorApp
var area: NavigatorLocalAreaScene
var windows: WindowManager
var confirmation: ActivityConfirmationDialog

func boot(id: String) -> void:
	SaveManager.configure_storage_root("user://field_acceptance")
	check(SaveManager.create_campaign(id, CampaignState.SaveMode.SAFE).is_empty(), "Could not create on-disk field campaign")
	prepare_campaign(id, 90)
	desktop = Control.new()
	desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop)
	navigator = (load("res://apps/navigator/app_navigator.tscn") as PackedScene).instantiate() as NavigatorApp
	desktop.add_child(navigator)
	windows = (load("res://systems/window_manager/window_manager.tscn") as PackedScene).instantiate() as WindowManager
	desktop.add_child(windows)
	confirmation = (load("res://systems/ui/activity_confirmation_dialog.tscn") as PackedScene).instantiate() as ActivityConfirmationDialog
	add_child(confirmation)
	GlobalSignals.workspace_activated.emit("navigator")
	await settle(0.05)
	navigator.world_map_view.select_location_by_id("akihabara")
	navigator.world_map_view.enter_area_button.pressed.emit()
	check(await until(func() -> bool: return confirmation.visible), "Travel confirmation did not appear")
	confirmation.confirm_button.pressed.emit()
	check(await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and not navigator._travel_pending), "Travel did not reach production Akiba")
	area = navigator.local_area_view.get_current_area_instance()
	check(await until(func() -> bool: return area.field_navigation.ready), "Production field geometry was not prepared")

func dispose() -> void:
	desktop.queue_free()
	confirmation.queue_free()
	await get_tree().process_frame

func position_actor(actor: LocalAreaExeActor, point: Vector2) -> void:
	actor.global_position = area.to_global(point)
	actor.motor.global_position = actor.global_position
	actor.motor.home = point
	actor.motor.destination = point
	actor.motor._path_left = 0
	actor.motor._perception_left = 0
	actor.motor._returning = false
	actor.motor.velocity = Vector2.ZERO
	actor.motor.state = FieldEXEMotor.State.IDLE

func configure_call_actors(join: bool) -> Array[LocalAreaExeActor]:
	var actors := area.get_field_exes()
	for index: int in range(actors.size()):
		var actor := actors[index]
		actor.behavior_profile = actor.behavior_profile.duplicate() as FieldBehaviorProfileData
		actor.behavior_profile.speed = 0
		actor.behavior_profile.modifiers = []
		actor.behavior_profile.behavior = FieldBehaviorProfileData.Behavior.AGGRESSIVE if join else FieldBehaviorProfileData.Behavior.SOLITARY
		actor.refresh_field_context()
		position_actor(actor, Vector2(500 + index * 44, 700))
	return actors

func request_fight(actor: LocalAreaExeActor) -> void:
	GlobalSignals.workspace_activated.emit("navigator")
	check(await interact(area, actor), "Player sensor did not request field combat")
	check(await until(func() -> bool: return confirmation.visible), "Field activity did not request its real confirmation")
	confirmation.confirm_button.pressed.emit()
	check(await until(func() -> bool: return navigator.combat_app.is_encounter_active() and navigator.can_save_now()), "Dynamic field combat did not reach stable presentation")

func win_current_fight() -> void:
	var attack := ContentRegistry.get_module("basic_attack")
	# A valid known-module loadout through the existing service; terminal combat
	# outcomes still come from actual timeline execution and UI controls.
	for index: int in range(4):
		CombatManager.set_player_module(index, attack)
	for cycle: int in range(5):
		if navigator.combat_app.resolution_panel.visible:
			break
		navigator.combat_app.execute_btn.pressed.emit()
		check(await until(func() -> bool: return not navigator.combat_app.execute_btn.disabled or navigator.combat_app.resolution_panel.visible, 15), "Field timeline cycle did not settle")
	check(CombatManager.is_resolution_applied() and CombatManager.get_pending_outcome() == CombatResult.Outcome.VICTORY, "Real field combat did not reach victory")

func return_from_fight() -> void:
	navigator.combat_app.resolution_panel.continue_button.pressed.emit()
	check(await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and navigator.can_save_now()), "Field resolution did not return to Overworld")
	area = navigator.local_area_view.get_current_area_instance()
