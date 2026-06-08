extends PanelContainer
class_name RankingRowUI

signal profile_requested(url: String)

@onready var rank_label: Label = %RankLabel
@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_button: Button = %NameButton
@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var level_label: Label = %LevelLabel

@onready var partner_apk_label: Label = %PartnerAPKLabel

@onready var server_flag_rect: TextureRect = %ServerFlagRect
@onready var server_label: Label = %ServerLabel

var user_data: NetworkUserData


func _ready() -> void:
	if not name_button.pressed.is_connected(_on_name_pressed):
		name_button.pressed.connect(_on_name_pressed)


func setup(user: NetworkUserData, highlight: bool = false) -> void:
	user_data = user

	if user_data == null:
		hide()
		return

	show()

	rank_label.text = user_data.get_global_rank_label()
	name_button.text = user_data.display_name
	title_label.text = user_data.get_display_title()
	score_label.text = str(user_data.score)
	level_label.text = "Lv. %d" % user_data.level
	partner_apk_label.text = user_data.get_partner_apk_label()
	server_label.text = user_data.get_server_label()

	_setup_avatar()
	_setup_server_flag()
	_apply_visual_state(highlight)


func _setup_avatar() -> void:
	if user_data.avatar != null:
		avatar_rect.texture = user_data.avatar
		avatar_rect.show()
	else:
		avatar_rect.hide()


func _setup_server_flag() -> void:
	if user_data.server_flag_icon != null:
		server_flag_rect.texture = user_data.server_flag_icon
		server_flag_rect.show()
	else:
		server_flag_rect.hide()


func _apply_visual_state(highlight: bool) -> void:
	if highlight:
		modulate = Color(1.0, 0.95, 0.75, 1.0)
		return

	if user_data.is_banned():
		modulate = Color(1.0, 0.65, 0.65, 1.0)
		return

	modulate = Color.WHITE


func _on_name_pressed() -> void:
	if user_data == null:
		return

	var url: String = user_data.get_profile_url()

	if url.is_empty():
		return

	profile_requested.emit(url)
