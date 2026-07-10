extends PanelContainer
class_name RankingRowUI

signal profile_requested(url: String)

@export_category("Column Layout")
@export var rank_column_width: float = 35.0
@export var score_column_width: float = 50.0
@export var level_column_width: float = 35.0
@export var partner_column_width: float = 75.0
@export var server_column_width: float = 130.0

@onready var rank_label: Label = %RankLabel
@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_button: Button = %NameButton
@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var level_label: Label = %LevelLabel
@onready var partner_apk_label: Label = %PartnerAPKLabel
@onready var server_hbox: HBoxContainer = %ServerHBox
@onready var server_flag_rect: TextureRect = %ServerFlagRect
@onready var server_label: Label = %ServerLabel

var user_data: NetworkUserData

var _show_level_column: bool = true
var _show_partner_column: bool = true
var _show_server_column: bool = true


func _ready() -> void:
	if not name_button.pressed.is_connected(_on_name_pressed):
		name_button.pressed.connect(_on_name_pressed)

	_apply_column_widths()
	_apply_column_visibility()


func apply_layout_widths(
	rank_width: float,
	score_width: float,
	level_width: float,
	partner_width: float,
	server_width: float
) -> void:
	rank_column_width = max(0.0, rank_width)
	score_column_width = max(0.0, score_width)
	level_column_width = max(0.0, level_width)
	partner_column_width = max(0.0, partner_width)
	server_column_width = max(0.0, server_width)

	if is_inside_tree():
		_apply_column_widths()


func apply_column_visibility(
	show_level: bool,
	show_partner: bool,
	show_server: bool
) -> void:
	_show_level_column = show_level
	_show_partner_column = show_partner
	_show_server_column = show_server

	if is_inside_tree():
		_apply_column_visibility()


func setup(user: NetworkUserData, highlight: bool = false) -> void:
	user_data = user

	if user_data == null:
		hide()
		return

	show()
	rank_label.text = user_data.get_global_rank_label()
	name_button.text = user_data.display_name
	name_button.clip_text = true
	name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Ranking intentionally displays the username without profile title metadata.
	title_label.text = ""
	title_label.hide()

	score_label.text = str(user_data.score)
	level_label.text = "Lv. %d" % user_data.level
	partner_apk_label.text = user_data.get_partner_apk_label()
	server_label.text = user_data.get_server_label()

	_setup_avatar()
	_setup_server_flag()
	_apply_visual_state(highlight)
	_apply_column_visibility()


func _apply_column_widths() -> void:
	rank_label.custom_minimum_size.x = rank_column_width
	score_label.custom_minimum_size.x = score_column_width
	level_label.custom_minimum_size.x = level_column_width
	partner_apk_label.custom_minimum_size.x = partner_column_width
	server_hbox.custom_minimum_size.x = server_column_width


func _apply_column_visibility() -> void:
	level_label.visible = _show_level_column
	partner_apk_label.visible = _show_partner_column
	server_hbox.visible = _show_server_column


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

	if not url.is_empty():
		profile_requested.emit(url)
