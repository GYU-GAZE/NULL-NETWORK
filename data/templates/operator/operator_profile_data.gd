extends Resource
class_name OperatorProfileData

const WRITING_STYLE_IDS := [
	"normal", "cute", "lazy", "formal"
]
const KAOMOJI_PREFERENCE_IDS := [
	"frequent", "occasional", "never"
]

@export_category("Personal Identity")
@export var first_name: String = ""
@export var last_name: String = ""
@export var nickname: String = ""

@export_category("NULL NETWORK Account")
@export var username: String = ""
@export var server_id: String = "tokyo_japan"
@export var occupation_id: String = ""
@export var avatar_id: String = ""
@export var writing_style_id: String = "normal"
@export var kaomoji_preference_id: String = "never"

@export_category("Identity and Address")
@export var gender: String = ""
# Pronouns are persisted for compatibility with existing dialogue/address systems,
# but registration no longer exposes them as an independent player choice.
@export var pronoun_set_id: String = ""

func get_display_name() -> String:
	var clean_nickname: String = nickname.strip_edges()
	if not clean_nickname.is_empty():
		return clean_nickname
	return "%s %s" % [first_name.strip_edges(), last_name.strip_edges()]

func get_operator_id() -> String:
	return SaveConstants.sanitize_identifier(username)

func resolve_pronoun_set_from_gender() -> void:
	match gender.strip_edges().to_lower():
		"male":
			pronoun_set_id = "he_him"
		"female":
			pronoun_set_id = "she_her"
		"other":
			pronoun_set_id = "they_them"
		_:
			pronoun_set_id = ""

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
	if not WRITING_STYLE_IDS.has(writing_style_id.strip_edges().to_lower()):
		errors.append("Writing style is invalid.")
	if not KAOMOJI_PREFERENCE_IDS.has(kaomoji_preference_id.strip_edges().to_lower()):
		errors.append("Kaomoji preference is invalid.")
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
		"avatar_id": avatar_id.strip_edges(),
		"writing_style_id": writing_style_id.strip_edges().to_lower(),
		"kaomoji_preference_id": kaomoji_preference_id.strip_edges().to_lower()
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
	writing_style_id = str(data.get("writing_style_id", "normal")).strip_edges().to_lower()
	kaomoji_preference_id = str(data.get("kaomoji_preference_id", "never")).strip_edges().to_lower()
	# Older saves may predate the explicit pronoun persistence. The current rule is
	# deterministic from gender, so reconstructing it is safe and backward-compatible.
	if pronoun_set_id.is_empty() and not gender.is_empty():
		resolve_pronoun_set_from_gender()

func duplicate_state() -> OperatorProfileData:
	var result := OperatorProfileData.new()
	result.load_save_data(to_save_data())
	return result
