extends RefCounted
class_name NavigatorAreaHistory

## Presentation/session state of visited areas. World population and location
## identity stay in CampaignState/ContentRegistry, never copied into this cache.
var _areas: Dictionary = {}


func remember(location_id: String, view: NavigatorLocalAreaView) -> void:
	if location_id.is_empty() or view.get_current_area_instance() == null:
		return
	var position := view.get_current_player_position()
	_areas[location_id] = {"entry_id": view.get_current_entry_id(), "position": {"x": position.x, "y": position.y}, "runtime": view.get_current_runtime_state()}


func get_area(location_id: String) -> Dictionary:
	return _areas.get(location_id, {}).duplicate(true)


func to_data() -> Dictionary:
	return _areas.duplicate(true)


func restore(data: Dictionary) -> void:
	_areas.clear()
	for id: Variant in data:
		if id is String and data[id] is Dictionary:
			_areas[id] = data[id].duplicate(true)
