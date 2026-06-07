extends Resource
class_name ThreadButtonData

enum ThreadPeriod {
	DAY,
	NIGHT
}

@export_category("Thread")
@export var thread_ref: ForumThread
@export var conditions: Array[ConditionData] = []

@export_category("Thread Lifecycle")
@export var release_day: int = 1
@export var release_period: ThreadPeriod = ThreadPeriod.DAY
@export_range(0, 5) var release_action_block: int = 0
@export var archive_after_actions: int = -1

@export_category("Visibility Overrides")
@export var force_hidden: bool = false
@export var force_pinned: bool = false
@export var force_archived: bool = false


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


func is_archived() -> bool:
	if force_archived:
		return true

	if thread_ref != null and thread_ref.is_archived:
		return true

	if archive_after_actions < 0:
		return false

	return TimeManager.get_total_action_index() >= get_release_action_index() + archive_after_actions


func is_pinned() -> bool:
	if force_pinned:
		return true

	if thread_ref == null:
		return false

	return thread_ref.is_pinned


func is_locked() -> bool:
	if thread_ref == null:
		return false

	return thread_ref.is_locked


func is_active() -> bool:
	return is_visible() and not is_archived()


func matches_search(query: String) -> bool:
	if thread_ref == null:
		return false

	return thread_ref.matches_search(query)


func get_release_action_index() -> int:
	var period_offset := 0

	if release_period == ThreadPeriod.NIGHT:
		period_offset = TimeManager.ACTION_BLOCKS_PER_PERIOD

	return ((release_day - 1) * TimeManager.ACTION_BLOCKS_PER_PERIOD * 2) + period_offset + release_action_block
