extends RefCounted
class_name FieldContextBuilder

static func build(location: MapLocation) -> Dictionary:
	var context := {"location_id": location.get_display_id(), "current_period": int(TimeManager.current_period), "current_action_block": TimeManager.current_action_block, "days_passed": TimeManager.days_passed}
	context["infestation"] = CampaignState.world_state.get_infestation(location.get_display_id())
	if location.spawn_table != null and location.spawn_table.field_population != null:
		var key := location.spawn_table.field_population.danger_number_key
		if not key.is_empty():
			context["danger"] = GameState.get_number(key)
	return context
