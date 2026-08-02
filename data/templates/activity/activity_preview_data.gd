extends RefCounted
class_name ActivityPreviewData


var request_id: String = ""
var activity_id: String = ""
var display_name: String = ""
var source_id: String = ""
var parent_transaction_id: String = ""

var action_cost: int = 0
var charged_action_cost: int = 0
var available_blocks_in_period: int = 0
var available_blocks_in_day: int = 0

var initial_day: int = 1
var initial_period: int = 0
var initial_action_block: int = 0

var final_day: int = 1
var final_period: int = 0
var final_action_block: int = 0

var crosses_period: bool = false
var crosses_day: bool = false
var is_included_activity: bool = false
var requires_confirmation: bool = false

var can_start: bool = false
var denial_reason: String = ""
var expiration_warnings: PackedStringArray = PackedStringArray()


func is_valid() -> bool:
	return can_start and denial_reason.is_empty()


func get_final_period_name() -> String:
	if final_period == TimeManager.TimePeriod.DAY:
		return "DAY"

	if final_period == TimeManager.TimePeriod.NIGHT:
		return "NIGHT"

	return "UNKNOWN"


func get_final_time_text() -> String:
	return "%s %d/12" % [
		get_final_period_name(),
		final_action_block + 1
	]
