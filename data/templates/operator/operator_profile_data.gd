extends Resource
class_name OperatorProfileData


@export_category("Personal Identity")
@export var first_name: String = ""
@export var last_name: String = ""
@export var nickname: String = ""

@export_category("NULL NETWORK Account")
@export var username: String = ""
@export var server_id: String = "tokyo_japan"
@export var occupation_id: String = ""
@export var avatar_id: String = ""

@export_category("Identity and Address")
@export var gender: String = ""
@export var pronoun_set_id: String = ""


func get_display_name() -> String:
	var clean_nickname: String = nickname.strip_edges()

	if not clean_nickname.is_empty():
		return clean_nickname

	return "%s %s" % [first_name.strip_edges(), last_name.strip_edges()]


func get_operator_id() -> String:
	return SaveConstants.sanitize_identifier(username)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if first_name.strip_edges().is_empty():
		errors.append("First name is required.")

	if last_name.strip_edges().is_empty():
		errors.append("Last name is required.")

	if nickname.strip_edges().is_empty():
		errors.append("IRL nickname is required.")

	if get_operator_id().is_empty():
		errors.append("NULL NETWORK username is invalid.")

	if server_id.strip_edges().is_empty():
		errors.append("Physical server is required.")

	if occupation_id.strip_edges().is_empty():
		errors.append("Occupation is required.")

	if gender.strip_edges().is_empty():
		errors.append("Gender is required.")

	if pronoun_set_id.strip_edges().is_empty():
		errors.append("Pronoun set is required.")

	if avatar_id.strip_edges().is_empty():
		errors.append("Forum avatar is required.")

	return errors


func to_save_data() -> Dictionary:
	return {
		"first_name": first_name.strip_edges(),
		"last_name": last_name.strip_edges(),
		"nickname": nickname.strip_edges(),
		"username": username.strip_edges(),
		"server_id": server_id.strip_edges(),
		"occupation_id": occupation_id.strip_edges(),
		"gender": gender.strip_edges(),
		"pronoun_set_id": pronoun_set_id.strip_edges(),
		"avatar_id": avatar_id.strip_edges()
	}


func load_save_data(data: Dictionary) -> void:
	first_name = str(data.get("first_name", "")).strip_edges()
	last_name = str(data.get("last_name", "")).strip_edges()
	nickname = str(data.get("nickname", "")).strip_edges()
	username = str(data.get("username", "")).strip_edges()
	server_id = str(data.get("server_id", "tokyo_japan")).strip_edges()
	occupation_id = str(data.get("occupation_id", "")).strip_edges()
	gender = str(data.get("gender", "")).strip_edges()
	pronoun_set_id = str(data.get("pronoun_set_id", "")).strip_edges()
	avatar_id = str(data.get("avatar_id", "")).strip_edges()


func duplicate_state() -> OperatorProfileData:
	var result := OperatorProfileData.new()
	result.load_save_data(to_save_data())
	return result
