extends Resource
class_name NetworkUserData

enum UserRole {
	USER,
	MODERATOR,
	SYSTEM,
	VIP,
	BANNED
}

@export_category("Identity")
@export var user_id: String = ""
@export var display_name: String = "Anonymous"
@export var avatar: Texture2D

@export_category("Profile")
@export var title: String = "Newbie"
@export var rank_label: String = ""
@export var location: String = "Unknown"
@export var role: UserRole = UserRole.USER

@export_category("NULL NETWORK Stats")
@export var global_rank: int = 999
@export var score: int = 0
@export var level: int = 1
@export var partner_apk_name: String = "???"

@export_category("Server")
@export var server_name: String = "Unknown"
@export var server_flag_icon: Texture2D

@export_category("Player State")
@export var is_player: bool = false
@export var is_known_to_player: bool = true

@export_category("Flavor")
@export_multiline var bio: String = ""


func get_display_title() -> String:
	var lines: Array[String] = []

	if not title.is_empty():
		lines.append(title)

	if not rank_label.is_empty() and rank_label != title:
		lines.append(rank_label)

	if lines.is_empty():
		return "Newbie"

	return "\n".join(lines)


func get_global_rank_label() -> String:
	return "#%d" % global_rank


func get_partner_apk_label() -> String:
	if partner_apk_name.is_empty():
		return "???"

	return partner_apk_name


func get_server_label() -> String:
	if server_name.is_empty():
		return "Unknown"

	return server_name


func get_profile_url() -> String:
	if user_id.is_empty():
		return ""

	return "null.net/profile/%s" % user_id


func is_moderator() -> bool:
	return role == UserRole.MODERATOR


func is_system() -> bool:
	return role == UserRole.SYSTEM


func is_banned() -> bool:
	return role == UserRole.BANNED
