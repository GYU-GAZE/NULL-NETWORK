extends Resource
class_name APKGrowthProfileData


@export_range(1, 100000, 1) var hp: int = 100
@export_range(5, 10000, 1) var atk: int = 10
@export_range(5, 10000, 1) var def: int = 10
@export_range(5, 10000, 1) var matk: int = 10
@export_range(5, 10000, 1) var mdef: int = 10


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if hp < 1:
		errors.append("A growth profile requires HP greater than zero.")

	for entry: Dictionary in _non_hp_entries():
		if int(entry["value"]) < 5:
			errors.append(
				"Growth stat '%s' cannot be lower than the natural floor of 5."
				% entry["id"]
			)

	return errors


func get_weighted_budget() -> float:
	return (float(hp) / 2.0) + atk + def + matk + mdef


func get_weighted_values() -> Dictionary:
	return {
		"hp": float(hp) / 2.0,
		"atk": float(atk),
		"def": float(def),
		"matk": float(matk),
		"mdef": float(mdef)
	}


func _non_hp_entries() -> Array[Dictionary]:
	return [
		{"id": "atk", "value": atk},
		{"id": "def", "value": def},
		{"id": "matk", "value": matk},
		{"id": "mdef", "value": mdef}
	]
