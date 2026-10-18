extends Node
class_name NavigatorTestHarness

var failures := PackedStringArray()
var capture_directory: String = ""


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="):
			capture_directory = argument.trim_prefix("--capture-directory=")
			DirAccess.make_dir_recursive_absolute(capture_directory)
			KubuDisplaySetting.set_windowed_size(Vector2i(1800, 1100))
	call_deferred("run")


func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func settle(seconds: float = 0.4) -> void:
	await get_tree().create_timer(seconds).timeout


func prepare_campaign(id: String, level: int = 60) -> void:
	ActivityManager.reset_runtime_state()
	CombatManager.reset_encounter()
	CampaignState.reset_campaign(false)
	TimeManager.reset_save_data()
	CampaignState.create_campaign(id, CampaignState.SaveMode.SAFE, CampaignState.CampaignPhase.MAIN_CAMPAIGN)
	var partner := APKProgressionService.create_partner_state("novire_init", "Navigator acceptance", 1, 2)
	partner.level = level
	partner.current_exp = APKProgressionService.get_total_exp_for_level(level)
	partner.allocation_points = maxi(0, level - 1)
	partner.current_hp = int(APKProgressionService.calculate_partner_stats(partner).get("max_hp", 1))
	CampaignState.set_partner_state(partner)
	var presentation := load("res://data/content/onboarding/default_prologue_onboarding_presentation.tres") as PrologueOnboardingPresentationData
	GameState.set_flag(presentation.world_revealed_flag, true)


func interact(area: NavigatorLocalAreaScene, target: LocalAreaInteractable) -> bool:
	area.player.global_position = target.global_position - Vector2(0, 22)
	area.player.interaction_sensor.update_facing(Vector2.DOWN)
	area.set_area_active(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	return area.player.interaction_sensor.try_interact()


func until(predicate: Callable, seconds: float = 8.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return predicate.call()


func capture(name: String) -> void:
	if capture_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_directory.path_join(name + ".png"))


func finish(marker: String) -> void:
	for failure: String in failures:
		push_error(failure)
	print(marker + (": PASS" if failures.is_empty() else ": FAIL (%d)" % failures.size()))
	get_tree().quit(0 if failures.is_empty() else 1)
