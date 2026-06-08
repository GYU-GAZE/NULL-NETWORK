extends Resource
class_name RankingBoardData

@export_category("Board")
@export var board_id: String = "global"
@export var board_title: String = "GLOBAL PLAYER RANKINGS"
@export_multiline var board_description: String = "Current worldwide standings for active NULL NETWORK players."

@export_category("Entries")
@export var users: Array[NetworkUserData] = []

@export_category("Player")
@export var player_user: NetworkUserData


func get_sorted_users() -> Array[NetworkUserData]:
	var result: Array[NetworkUserData] = []

	for user in users:
		if user == null:
			continue

		result.append(user)

	result.sort_custom(_sort_users)
	return result


func get_top_users(limit: int = 50) -> Array[NetworkUserData]:
	var sorted_users: Array[NetworkUserData] = get_sorted_users()
	var result: Array[NetworkUserData] = []

	for i in range(min(limit, sorted_users.size())):
		result.append(sorted_users[i])

	return result


func is_player_in_top(limit: int = 50) -> bool:
	if player_user == null:
		return false

	return player_user.global_rank <= limit


func _sort_users(a: NetworkUserData, b: NetworkUserData) -> bool:
	if a == null:
		return false

	if b == null:
		return true

	return a.global_rank < b.global_rank
