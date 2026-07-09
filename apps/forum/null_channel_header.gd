extends PanelContainer
class_name NullChannelHeader

@export var fallback_username: String = "null.guy"
@export var fallback_rank_label: String = "#999 Worldwide"
@export var banner_texture: Texture2D

@onready var banner_rect: TextureRect = %BannerRect
@onready var username_label: Label = %UsernameLabel
@onready var user_rank_label: Label = %UserRankLabel
@onready var user_avatar_rect: TextureRect = %UserAvatarRect


func _ready() -> void:
	_apply_banner()
	refresh_player()


func refresh_player() -> void:
	var player_user: NetworkUserData = NetworkUserDatabase.get_player_user()

	if player_user == null:
		username_label.text = fallback_username
		user_rank_label.text = fallback_rank_label
		user_avatar_rect.texture = null
		return

	username_label.text = player_user.display_name
	user_rank_label.text = "%s Worldwide" % player_user.get_global_rank_label()
	user_avatar_rect.texture = player_user.avatar


func _apply_banner() -> void:
	if banner_texture != null:
		banner_rect.texture = banner_texture

	banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
