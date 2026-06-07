extends Resource
class_name ForumPost

@export_category("User Profile")
@export var avatar: Texture2D
@export var username: String = "Anonymous"
@export var user_rank: String = "Newbie"
@export var user_title: String = "Newbie"
@export var location: String = "Unknown"

@export_category("Post Metadata")
@export var post_id: String = ""
@export var time_label: String = ""
@export var edited_label: String = ""
@export var is_op: bool = false
@export var is_moderator: bool = false
@export var is_system_post: bool = false

@export_category("Content")
@export_multiline var text_content: String = ""
@export var image_content: Texture2D


func get_display_title() -> String:
	if user_rank.is_empty():
		return user_title

	if user_title.is_empty() or user_title == user_rank:
		return user_rank

	return "%s | %s" % [user_rank, user_title]


func get_time_label() -> String:
	if time_label.is_empty():
		return "agora"

	return time_label


func matches_search(query: String) -> bool:
	var normalized_query := query.strip_edges().to_lower()

	if normalized_query.is_empty():
		return true

	if username.to_lower().contains(normalized_query):
		return true

	if user_rank.to_lower().contains(normalized_query):
		return true

	if user_title.to_lower().contains(normalized_query):
		return true

	if location.to_lower().contains(normalized_query):
		return true

	if text_content.to_lower().contains(normalized_query):
		return true

	return false
