extends PanelContainer
class_name RankingsApp

signal browser_navigation_requested(url: String)

@export_category("Display")
@export var page_title: String = "GLOBAL PLAYER RANKINGS"
@export_multiline var page_description: String = "Current worldwide standings for active NULL NETWORK players."
@export var top_limit: int = 50

@export_category("Data")
@export var ranking_row_scene: PackedScene

@export_category("Column Layout")
@export var rank_column_width: float = 35.0
@export var score_column_width: float = 50.0
@export var level_column_width: float = 35.0
@export var partner_column_width: float = 75.0
@export var server_column_width: float = 130.0
@export var hide_server_below_width: float = 620.0
@export var hide_partner_below_width: float = 500.0
@export var hide_level_below_width: float = 400.0

@onready var site_header: NullChannelHeader = %SiteHeader
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var ranking_list: VBoxContainer = %RankingList
@onready var player_separator: HSeparator = %PlayerSeparator
@onready var player_rank_title: Label = %PlayerRankTitle
@onready var player_rank_container: VBoxContainer = %PlayerRankContainer
@onready var refresh_btn: Button = %RefreshBtn

@onready var rank_header_label: Label = %RankHeaderLabel
@onready var score_header_label: Label = %ScoreHeaderLabel
@onready var level_header_label: Label = %LevelHeaderLabel
@onready var partner_header_label: Label = %PartnerHeaderLabel
@onready var server_header_label: Label = %ServerHeaderLabel

var _show_level_column: bool = true
var _show_partner_column: bool = true
var _show_server_column: bool = true


func _ready() -> void:
	site_header.configure_navigation(true, true, true, false)

	if not site_header.navigation_requested.is_connected(_on_navigation_requested):
		site_header.navigation_requested.connect(_on_navigation_requested)

	if not refresh_btn.pressed.is_connected(_refresh_page):
		refresh_btn.pressed.connect(_refresh_page)

	if not resized.is_connected(_apply_responsive_layout):
		resized.connect(_apply_responsive_layout)

	_apply_column_widths()
	_refresh_page()
	call_deferred("_apply_responsive_layout")


func _refresh_page() -> void:
	_clear_container(ranking_list)
	_clear_container(player_rank_container)

	title_label.text = page_title
	description_label.text = page_description

	NetworkUserDatabase.reload_users()
	_build_top_ranking()
	_build_player_rank_section()
	_apply_responsive_layout()


func _build_top_ranking() -> void:
	var top_users: Array[NetworkUserData] = NetworkUserDatabase.get_top_ranked_users(top_limit)

	if top_users.is_empty():
		_add_empty_label(ranking_list, "No ranking data available.")
		return

	var player_user: NetworkUserData = NetworkUserDatabase.get_player_user()

	for user in top_users:
		_add_ranking_row(ranking_list, user, user == player_user)


func _build_player_rank_section() -> void:
	var player_user: NetworkUserData = NetworkUserDatabase.get_player_user()

	if player_user == null or NetworkUserDatabase.is_player_in_top(top_limit):
		_hide_player_section()
		return

	player_separator.show()
	player_rank_title.show()
	player_rank_container.show()
	_add_ranking_row(player_rank_container, player_user, true)


func _hide_player_section() -> void:
	player_separator.hide()
	player_rank_title.hide()
	player_rank_container.hide()


func _add_ranking_row(
	parent: VBoxContainer,
	user: NetworkUserData,
	highlight: bool = false
) -> void:
	if ranking_row_scene == null:
		push_error("RankingsApp: ranking_row_scene não configurada.")
		return

	var row: RankingRowUI = ranking_row_scene.instantiate() as RankingRowUI

	if row == null:
		push_error("RankingsApp: ranking_row_scene precisa instanciar RankingRowUI.")
		return

	parent.add_child(row)
	_apply_row_layout(row)
	row.setup(user, highlight)
	row.profile_requested.connect(_on_profile_requested)
	parent.add_child(HSeparator.new())


func _apply_column_widths() -> void:
	_set_header_width(rank_header_label, rank_column_width)
	_set_header_width(score_header_label, score_column_width)
	_set_header_width(level_header_label, level_column_width)
	_set_header_width(partner_header_label, partner_column_width)
	_set_header_width(server_header_label, server_column_width)


func _set_header_width(label: Label, width: float) -> void:
	label.custom_minimum_size.x = max(0.0, width)
	label.clip_text = true


func _apply_responsive_layout() -> void:
	var available_width: float = size.x

	if available_width <= 0.0:
		available_width = get_viewport_rect().size.x

	_show_server_column = available_width >= hide_server_below_width
	_show_partner_column = available_width >= hide_partner_below_width
	_show_level_column = available_width >= hide_level_below_width

	server_header_label.visible = _show_server_column
	partner_header_label.visible = _show_partner_column
	level_header_label.visible = _show_level_column

	_apply_layout_to_container(ranking_list)
	_apply_layout_to_container(player_rank_container)


func _apply_layout_to_container(container: Node) -> void:
	for child in container.get_children():
		if child is RankingRowUI:
			_apply_row_layout(child as RankingRowUI)


func _apply_row_layout(row: RankingRowUI) -> void:
	row.apply_layout_widths(
		rank_column_width,
		score_column_width,
		level_column_width,
		partner_column_width,
		server_column_width
	)
	row.apply_column_visibility(
		_show_level_column,
		_show_partner_column,
		_show_server_column
	)


func _on_navigation_requested(url: String) -> void:
	var clean_url: String = url.strip_edges()

	if not clean_url.is_empty():
		browser_navigation_requested.emit(clean_url)


func _on_profile_requested(url: String) -> void:
	browser_navigation_requested.emit(url)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _add_empty_label(container: Control, message: String) -> void:
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
