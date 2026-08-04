extends Node


signal player_user_changed(player_user: NetworkUserData)


const USERS_FOLDER: String = "res://data/content/users"
const PLAYER_PLACEHOLDER_AVATAR: Texture2D = preload("res://icon.svg")

var users: Array[NetworkUserData] = []
var users_by_id: Dictionary = {}
var users_by_lower_id: Dictionary = {}
var resolved_friends_by_id: Dictionary = {}
var _runtime_player_user: NetworkUserData


func _ready() -> void:
	if not CampaignState.campaign_changed.is_connected(_on_campaign_changed):
		CampaignState.campaign_changed.connect(_on_campaign_changed)

	if not CampaignState.campaign_reset.is_connected(_on_campaign_reset):
		CampaignState.campaign_reset.connect(_on_campaign_reset)

	reload_users()


func reload_users() -> void:
	users.clear()
	users_by_id.clear()
	users_by_lower_id.clear()
	resolved_friends_by_id.clear()
	_runtime_player_user = null

	_load_users_from_folder(USERS_FOLDER)
	_sync_runtime_player_user(false)
	_sort_users()
	_rebuild_resolved_friend_links()


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

	if resource == null or not resource is NetworkUserData:
		return

	var user: NetworkUserData = resource as NetworkUserData

	if user.user_id.is_empty():
		push_warning("NetworkUserDatabase: usuário sem user_id em %s" % path)
	else:
		if users_by_id.has(user.user_id):
			push_warning("NetworkUserDatabase: user_id duplicado: %s" % user.user_id)

		users_by_id[user.user_id] = user
		users_by_lower_id[user.user_id.to_lower()] = user

	users.append(user)


func _sync_runtime_player_user(emit_change: bool = true) -> void:
	_remove_runtime_player_user()

	if not CampaignState.has_campaign() or CampaignState.operator.is_empty():
		if emit_change:
			player_user_changed.emit(null)
		return

	var profile: OperatorProfileData = CampaignState.operator.profile
	var clean_user_id: String = profile.username.strip_edges()

	if clean_user_id.is_empty():
		if emit_change:
			player_user_changed.emit(null)
		return

	var player_user := NetworkUserData.new()
	player_user.user_id = clean_user_id
	player_user.display_name = clean_user_id
	player_user.avatar = PLAYER_PLACEHOLDER_AVATAR
	player_user.title = "New Operator"
	player_user.rank_label = "Unranked"
	player_user.location = _get_player_location_label()
	player_user.role = NetworkUserData.UserRole.USER
	player_user.joined_label = "Campaign day %d" % TimeManager.days_passed
	player_user.last_seen_label = "Online"
	player_user.status_message = (
		"Registered as %s" % profile.nickname.strip_edges()
		if not profile.nickname.strip_edges().is_empty()
		else "Newly registered Operator"
	)
	player_user.global_rank = 999
	player_user.level = 1
	player_user.partner_apk_name = "???"
	player_user.server_name = "TOKYO, JAPAN"
	player_user.is_player = true
	player_user.is_known_to_player = true
	player_user.bio_bbcode = (
		"[b]Campaign Operator[/b]\n"
		+ "Occupation: %s\n"
		+ "Physical server: TOKYO, JAPAN"
	) % _get_player_occupation_label()
	player_user.signature_bbcode = (
		"Temporary runtime profile synchronized from CampaignState."
	)

	if not CampaignState.partner.is_empty():
		player_user.level = CampaignState.partner.level
		var apk: APKData = ContentRegistry.get_apk(CampaignState.partner.apk_id)
		player_user.partner_apk_name = (
			apk.display_name
			if apk != null
			else CampaignState.partner.apk_id
		)

	_runtime_player_user = player_user
	users.append(player_user)
	users_by_id[player_user.user_id] = player_user
	users_by_lower_id[player_user.user_id.to_lower()] = player_user
	_sort_users()
	_rebuild_resolved_friend_links()

	if emit_change:
		player_user_changed.emit(player_user)


func _remove_runtime_player_user() -> void:
	if _runtime_player_user == null:
		return

	users.erase(_runtime_player_user)
	users_by_id.erase(_runtime_player_user.user_id)
	users_by_lower_id.erase(_runtime_player_user.user_id.to_lower())
	resolved_friends_by_id.erase(_runtime_player_user.user_id)
	_runtime_player_user = null


func _get_player_location_label() -> String:
	var location: MapLocation = ContentRegistry.get_location(
		CampaignState.current_location_id
	)

	if location != null:
		return location.location_name

	return "TOKYO, JAPAN"


func _get_player_occupation_label() -> String:
	var occupation: OccupationData = ContentRegistry.get_occupation(
		CampaignState.operator.occupation_id
	)

	if occupation != null:
		return occupation.get_display_name()

	return CampaignState.operator.occupation_id


func _sort_users() -> void:
	users.sort_custom(_sort_by_global_rank)


func _sort_by_global_rank(a: NetworkUserData, b: NetworkUserData) -> bool:
	if a == null:
		return false

	if b == null:
		return true

	return a.global_rank < b.global_rank


func _rebuild_resolved_friend_links() -> void:
	resolved_friends_by_id.clear()

	for user in users:
		if user == null or user.user_id.is_empty():
			continue

		resolved_friends_by_id[user.user_id] = []

	for user in users:
		if user == null or user.user_id.is_empty():
			continue

		for friend in user.friend_users:
			if friend == null or friend.user_id.is_empty():
				continue

			_add_resolved_friend(user, friend)
			_add_resolved_friend(friend, user)


func _add_resolved_friend(user: NetworkUserData, friend: NetworkUserData) -> void:
	if user == null or friend == null:
		return

	if user.user_id.is_empty() or friend.user_id.is_empty():
		return

	if user.user_id == friend.user_id:
		return

	if not resolved_friends_by_id.has(user.user_id):
		resolved_friends_by_id[user.user_id] = []

	var friend_list: Array = resolved_friends_by_id[user.user_id]

	for existing_friend in friend_list:
		if existing_friend != null and existing_friend.user_id == friend.user_id:
			return

	friend_list.append(friend)
	friend_list.sort_custom(_sort_by_global_rank)


func get_all_users() -> Array[NetworkUserData]:
	return users.duplicate()


func get_user_by_id(user_id: String) -> NetworkUserData:
	if user_id.is_empty():
		return null

	if users_by_id.has(user_id):
		return users_by_id[user_id]

	return users_by_lower_id.get(user_id.to_lower(), null)


func get_resolved_friends_for_user(user: NetworkUserData) -> Array[NetworkUserData]:
	if user == null:
		return []

	return get_resolved_friends_for_user_id(user.user_id)


func get_resolved_friends_for_user_id(user_id: String) -> Array[NetworkUserData]:
	if user_id.is_empty():
		return []

	var user: NetworkUserData = get_user_by_id(user_id)

	if user == null:
		return []

	var friend_list: Array = resolved_friends_by_id.get(user.user_id, [])
	var result: Array[NetworkUserData] = []

	for friend in friend_list:
		if friend != null:
			result.append(friend)

	return result


func are_users_friends(user_a: NetworkUserData, user_b: NetworkUserData) -> bool:
	if user_a == null or user_b == null:
		return false

	for friend in get_resolved_friends_for_user(user_a):
		if friend != null and friend.user_id == user_b.user_id:
			return true

	return false


func get_ranked_users() -> Array[NetworkUserData]:
	var result: Array[NetworkUserData] = []

	for user in users:
		if user != null and user.global_rank > 0:
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
	if _runtime_player_user != null:
		return _runtime_player_user

	for user in users:
		if user != null and user.is_player:
			return user

	return null


func is_player_in_top(limit: int = 50) -> bool:
	var player_user: NetworkUserData = get_player_user()

	if player_user == null:
		return false

	return player_user.global_rank > 0 and player_user.global_rank <= limit


func _on_campaign_changed(section: StringName) -> void:
	if section in [
		&"operator",
		&"partner",
		&"current_location",
		&"campaign"
	]:
		_sync_runtime_player_user()


func _on_campaign_reset() -> void:
	_sync_runtime_player_user()
