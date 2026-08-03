extends Resource
class_name PlayerActionProgressData


var action_id: String = ""
var target_uid: int = -1
var progress: int = 0
var completed: bool = false
var reward_claimed: bool = false
var selected_reward_id: String = ""


static func create(action: PlayerActionData, target: Dictionary) -> PlayerActionProgressData:
	var state := PlayerActionProgressData.new()
	state.action_id = action.action_id if action != null else ""
	state.target_uid = int(target.get("uid", -1))
	return state


func to_save_data() -> Dictionary:
	return {
		"action_id": action_id,
		"target_uid": target_uid,
		"progress": progress,
		"completed": completed,
		"reward_claimed": reward_claimed,
		"selected_reward_id": selected_reward_id
	}


func load_save_data(data: Dictionary) -> void:
	action_id = str(data.get("action_id", "")).strip_edges()
	target_uid = int(data.get("target_uid", -1))
	progress = clampi(int(data.get("progress", 0)), 0, 100)
	completed = bool(data.get("completed", false))
	reward_claimed = bool(data.get("reward_claimed", false))
	selected_reward_id = str(data.get("selected_reward_id", "")).strip_edges()
