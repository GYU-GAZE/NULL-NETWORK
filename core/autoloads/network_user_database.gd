extends Node

const USERS_FOLDER: String = "res://data/content/users"

var users: Array[NetworkUserData] = []
var users_by_id: Dictionary = {}


func _ready() -> void:
	reload_users()


func reload_users() -> void:
	users.clear()
	users_by_id.clear()

	_load_users_from_folder(USERS_FOLDER)
	_sort_users()


func _load_users_from_folder(folder_path: String) -> void:
	var dir: DirAccess = DirAccess.open(folder_path)

	if dir == null:
		push_warning("NetworkUserDatabase: pasta não encontrada: %s" % folder_path)
		return

	dir.list_dir_begin()

	while true:
		var file_name: String = dir.get_next()

		if file_name.is_empty():
			break

		if file_name.begins_with("."):
			continue

		var full_path: String = "%s/%s" % [folder_path, file_name]

		if dir.current_is_dir():
			_load_users_from_folder(full_path)
			continue

		if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
			continue

		_try_load_user(full_path)

	dir.list_dir_end()


func _try_load_user(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)

	if resource == null:
		return

	if not resource is NetworkUserData:
		return

	var user: NetworkUserData = resource as NetworkUserData

	if user.user_id.is_empty():
		push_warning("NetworkUserDatabase: usuário sem user_id em %s" % path)
	else:
		if users_by_id.has(user.user_id):
			push_warning("NetworkUserDatabase: user_id duplicado: %s" % user.user_id)

		users_by_id[user.user_id] = user

	users.append(user)


func _sort_users() -> void:
	users.sort_custom(_sort_by_global_rank)


func _sort_by_global_rank(a: NetworkUserData, b: NetworkUserData) -> bool:
	if a == null:
		return false

	if b == null:
		return true

	return a.global_rank < b.global_rank


func get_all_users() -> Array[NetworkUserData]:
	return users.duplicate()


func get_user_by_id(user_id: String) -> NetworkUserData:
	if user_id.is_empty():
		return null

	return users_by_id.get(user_id, null)


func get_ranked_users() -> Array[NetworkUserData]:
	var result: Array[NetworkUserData] = []

	for user in users:
		if user == null:
			continue

		if user.global_rank <= 0:
			continue

		result.append(user)

	result.sort_custom(_sort_by_global_rank)
	return result


func get_top_ranked_users(limit: int = 50) -> Array[NetworkUserData]:
	var ranked_users: Array[NetworkUserData] = get_ranked_users()
	var result: Array[NetworkUserData] = []

	for i in range(min(limit, ranked_users.size())):
		result.append(ranked_users[i])

	return result


func get_player_user() -> NetworkUserData:
	for user in users:
		if user != null and user.is_player:
			return user

	return null


func is_player_in_top(limit: int = 50) -> bool:
	var player_user: NetworkUserData = get_player_user()

	if player_user == null:
		return false

	return player_user.global_rank > 0 and player_user.global_rank <= limit
