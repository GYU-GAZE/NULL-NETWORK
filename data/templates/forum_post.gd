extends Resource
class_name ForumPost

enum ThreadPeriod {
	DAY,
	NIGHT
}

@export_category("Author")
@export var author: NetworkUserData

@export_category("Post Metadata")
@export var post_id: String = ""
@export var time_label_override: String = ""
@export var edited_label: String = ""
@export var is_op: bool = false
@export var is_moderator_override: bool = false
@export var is_system_post_override: bool = false

@export_category("Post Lifecycle / Timestamp")
@export var release_day: int = 1
@export var release_period: ThreadPeriod = ThreadPeriod.DAY
@export_range(0, 5) var release_action_block: int = 0
@export var conditions: Array[ConditionData] = []
@export var force_hidden: bool = false

@export_category("Content")
@export_multiline var text_content: String = ""


func get_avatar() -> Texture2D:
	if author == null:
		return null

	return author.avatar


func get_username() -> String:
	if author == null:
		return "Unknown User"

	return author.display_name


func get_user_location() -> String:
	if author == null:
		return "Unknown"

	return author.location


func get_display_title() -> String:
	if author == null:
		return "Unknown"

	return author.get_display_title()


func is_author_moderator() -> bool:
	if is_moderator_override:
		return true

	if author == null:
		return false

	return author.is_moderator()


func is_author_system() -> bool:
	if is_system_post_override:
		return true

	if author == null:
		return false

	return author.is_system()


func get_time_label() -> String:
	if not time_label_override.is_empty():
		return time_label_override

	return TimeManager.format_forum_timestamp(
		release_day,
		release_period,
		release_action_block
	)


func are_conditions_met() -> bool:
	for condition in conditions:
		if condition == null:
			continue

		if not condition.is_met():
			return false

	return true


func is_released() -> bool:
	return TimeManager.get_total_action_index() >= get_release_action_index()


func is_visible() -> bool:
	if force_hidden:
		return false

	return is_released() and are_conditions_met()


func get_release_action_index() -> int:
	return TimeManager.get_action_index_for_game_time(
		release_day,
		release_period,
		release_action_block
	)


func matches_search(query: String) -> bool:
	var normalized_query: String = query.strip_edges().to_lower()

	if normalized_query.is_empty():
		return true

	if get_username().to_lower().contains(normalized_query):
		return true

	if get_display_title().to_lower().contains(normalized_query):
		return true

	if get_user_location().to_lower().contains(normalized_query):
		return true

	if text_content.to_lower().contains(normalized_query):
		return true

	return false
