extends Marker2D
class_name LocalAreaEntryPoint


@export var entry_id: String = "default"


func get_entry_id() -> String:
	return entry_id.strip_edges()
