extends Resource
class_name OperatorStateData


var operator_id: String = ""
var profile: OperatorProfileData = OperatorProfileData.new()
var appearance: AppearanceData = AppearanceData.new()
var level: int = 1
var experience: int = 0
var registration_day: int = 1
var last_income_day: int = 1
var archived: bool = false

var display_name: String:
	get:
		return profile.get_display_name()
	set(value):
		profile.nickname = value.strip_edges()

var occupation_id: String:
	get:
		return profile.occupation_id
	set(value):
		profile.occupation_id = value.strip_edges()

var appearance_part_ids: PackedStringArray:
	get:
		return appearance.get_appearance_part_ids()


func reset() -> void:
	operator_id = ""
	profile = OperatorProfileData.new()
	appearance = AppearanceData.new()
	level = 1
	experience = 0
	registration_day = 1
	last_income_day = 1
	archived = false


func is_empty() -> bool:
	return operator_id.strip_edges().is_empty()


func to_save_data() -> Dictionary:
	return {
		"operator_id": operator_id,
		"display_name": display_name,
		"occupation_id": occupation_id,
		"profile": profile.to_save_data(),
		"appearance": appearance.to_save_data(),
		"appearance_part_ids": Array(appearance_part_ids),
		"level": level,
		"experience": experience,
		"registration_day": registration_day,
		"last_income_day": last_income_day,
		"archived": archived
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	operator_id = str(data.get("operator_id", "")).strip_edges()

	var profile_value: Variant = data.get("profile", {})

	if profile_value is Dictionary and not (profile_value as Dictionary).is_empty():
		profile.load_save_data(profile_value as Dictionary)
	else:
		profile.nickname = str(data.get("display_name", "")).strip_edges()
		profile.username = operator_id
		profile.occupation_id = str(
			data.get("occupation_id", "")
		).strip_edges()

	var appearance_value: Variant = data.get("appearance", {})

	if appearance_value is Dictionary \
		and not (appearance_value as Dictionary).is_empty():
		appearance.load_save_data(appearance_value as Dictionary)
	else:
		appearance.load_save_data({
			"appearance_part_ids": data.get("appearance_part_ids", [])
		})

	level = maxi(1, int(data.get("level", 1)))
	experience = maxi(0, int(data.get("experience", 0)))
	registration_day = maxi(1, int(data.get("registration_day", 1)))
	last_income_day = maxi(
		registration_day,
		int(data.get("last_income_day", registration_day))
	)
	archived = bool(data.get("archived", false))


func set_registration_data(
	new_profile: OperatorProfileData,
	new_appearance: AppearanceData
) -> bool:
	if new_profile == null or new_appearance == null:
		return false

	profile = new_profile.duplicate_state()
	appearance = new_appearance.duplicate_state()
	operator_id = profile.get_operator_id()
	return not operator_id.is_empty()
