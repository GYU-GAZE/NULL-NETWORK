extends Resource
class_name ForumPost

enum ThreadPeriod {
	DAY,
	NIGHT
}

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

@export_category("Post Lifecycle")
@export var release_day: int = 1
@export var release_period: ThreadPeriod = ThreadPeriod.DAY
@export_range(0, 5) var release_action_block: int = 0
@export var conditions: Array[ConditionData] = []
@export var force_hidden: bool = false

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
	return time_label


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
	var period_offset: int = 0

	if release_period == ThreadPeriod.NIGHT:
		period_offset = TimeManager.ACTION_BLOCKS_PER_PERIOD

	return ((release_day - 1) * TimeManager.ACTION_BLOCKS_PER_PERIOD * 2) + period_offset + release_action_block


func matches_search(query: String) -> bool:
	var normalized_query: String = query.strip_edges().to_lower()

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
