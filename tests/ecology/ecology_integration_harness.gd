extends FieldIntegrationHarness
class_name EcologyIntegrationHarness

func complete_action(kind: String, target: Dictionary) -> void:
	for index: int in range(4):
		check(CombatManager.set_player_action(index, kind, int(target.uid)).is_empty(), "Actual timeline rejected " + kind)
	CombatManager.execute_cycle(false)
	await get_tree().process_frame
	var progress := PlayerActionService.get_progress(CombatManager.player_action_progress, kind, int(target.uid))
	check(progress != null and progress.completed, "Actual timeline did not complete " + kind)
	if kind == "scan":
		navigator.combat_app.resolution_panel.module_choice_requested.emit("heavy_attack")
		await get_tree().process_frame

func ordinary_exes() -> Array[LocalAreaExeActor]:
	var result: Array[LocalAreaExeActor] = []
	for actor: LocalAreaExeActor in area.get_field_exes():
		if actor.persistent_ecology_actor_id.is_empty(): result.append(actor)
	return result

func next_day() -> void:
	check(await until(func() -> bool: return CampaignState.active_story_event_id.is_empty() and CampaignState.queued_story_event_ids.is_empty()), "Narrative ecology reaction did not settle")
	var result := await TimeManager.advance_development_hours(24)
	check(bool(result.ok), "Could not process the next day through TimeManager: " + str(result.reason))
	await settle(0.1)
	area = navigator.local_area_view.get_current_area_instance()
