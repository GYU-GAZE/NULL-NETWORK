extends Resource
class_name AddressTermData


enum Source {
	LITERAL,
	FIRST_NAME,
	NICKNAME,
	USERNAME
}

@export var address_term_id: String = ""
@export var source: Source = Source.LITERAL
@export var literal_text: String = "Partner"


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if address_term_id.strip_edges().is_empty():
		errors.append("AddressTermData has an empty address_term_id.")

	if source == Source.LITERAL and literal_text.strip_edges().is_empty():
		errors.append("Literal address term '%s' has no text." % address_term_id)

	return errors


func resolve_text(profile: OperatorProfileData) -> String:
	if profile == null:
		return literal_text.strip_edges()

	match source:
		Source.FIRST_NAME:
			return profile.first_name.strip_edges()
		Source.NICKNAME:
			return profile.nickname.strip_edges()
		Source.USERNAME:
			return profile.username.strip_edges()

	return literal_text.strip_edges()
