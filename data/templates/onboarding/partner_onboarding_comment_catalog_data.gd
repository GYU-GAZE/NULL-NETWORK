@tool
extends Resource
class_name PartnerOnboardingCommentCatalogData


@export var comments: Array[PartnerOnboardingCommentData] = []


func get_comment(apk_id: String) -> PartnerOnboardingCommentData:
	var clean_id := apk_id.strip_edges()
	for comment: PartnerOnboardingCommentData in comments:
		if comment != null and comment.apk_id == clean_id:
			return comment
	return null


func get_line(apk_id: String, dominant_tendency: String) -> String:
	var comment := get_comment(apk_id)
	if comment == null:
		return "Looks like {TENDENCY} led the way. Let's see what you do with it.".replace(
			"{TENDENCY}", dominant_tendency.strip_edges().to_upper()
		)
	return comment.get_line(dominant_tendency)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := PackedStringArray()
	for comment: PartnerOnboardingCommentData in comments:
		if comment == null:
			errors.append("Partner onboarding comment catalog contains a null entry.")
			continue
		errors.append_array(comment.validate_data())
		if ids.has(comment.apk_id):
			errors.append("Partner onboarding comment catalog repeats '%s'." % comment.apk_id)
		else:
			ids.append(comment.apk_id)
	return errors
