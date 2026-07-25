extends Node2D
class_name NavigatorLocalAreaScene


var area_data: LocalAreaData
var active_entry_id: String = ""


func setup_local_area(
	data: LocalAreaData,
	entry_id: String = ""
) -> void:
	area_data = data

	var resolved_entry_id: String = entry_id.strip_edges()

	if (
		resolved_entry_id.is_empty()
		and area_data != null
	):
		resolved_entry_id = (
			area_data.default_entry_id.strip_edges()
		)

	active_entry_id = resolved_entry_id
