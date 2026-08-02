extends Resource
class_name OperatorStateData


var operator_id: String = ""
var display_name: String = ""
var occupation_id: String = ""
var level: int = 1
var experience: int = 0
var archived: bool = false


func reset() -> void:
	operator_id = ""
	display_name = ""
	occupation_id = ""
	level = 1
	experience = 0
	archived = false


func is_empty() -> bool:
	return operator_id.strip_edges().is_empty()


func to_save_data() -> Dictionary:
	return {
		"operator_id": operator_id,
		"display_name": display_name,
		"occupation_id": occupation_id,
		"level": level,
		"experience": experience,
		"archived": archived
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	operator_id = str(data.get("operator_id", "")).strip_edges()
	display_name = str(data.get("display_name", ""))
	occupation_id = str(data.get("occupation_id", "")).strip_edges()
	level = maxi(1, int(data.get("level", 1)))
	experience = maxi(0, int(data.get("experience", 0)))
	archived = bool(data.get("archived", false))
