extends PanelContainer
class_name RankingsApp

signal browser_navigation_requested(url: String)

@export_category("Data")
@export var ranking_board: RankingBoardData
@export var ranking_row_scene: PackedScene

@export_category("Navigation")
@export var home_url: String = "null.net"
@export var forums_url: String = "null.net/forums"
@export var updates_url: String = "null.net/updates"

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var ranking_list: VBoxContainer = %RankingList
@onready var player_separator: HSeparator = %PlayerSeparator
@onready var player_rank_title: Label = %PlayerRankTitle
@onready var player_rank_container: VBoxContainer = %PlayerRankContainer

@onready var home_btn: Button = %HomeBtn
@onready var forums_btn: Button = %ForumsBtn
@onready var updates_btn: Button = %UpdatesBtn
@onready var refresh_btn: Button = %RefreshBtn


func _ready() -> void:
	_connect_buttons()
	_refresh_page()


func _connect_buttons() -> void:
	if not home_btn.pressed.is_connected(_on_home_pressed):
		home_btn.pressed.connect(_on_home_pressed)

	if not forums_btn.pressed.is_connected(_on_forums_pressed):
		forums_btn.pressed.connect(_on_forums_pressed)

	if not updates_btn.pressed.is_connected(_on_updates_pressed):
		updates_btn.pressed.connect(_on_updates_pressed)

	if not refresh_btn.pressed.is_connected(_refresh_page):
		refresh_btn.pressed.connect(_refresh_page)


func _refresh_page() -> void:
	_clear_container(ranking_list)
	_clear_container(player_rank_container)

	if ranking_board == null:
		title_label.text = "GLOBAL PLAYER RANKINGS"
		description_label.text = "Ranking data unavailable."
		_hide_player_section()
		return

	title_label.text = ranking_board.board_title
	description_label.text = ranking_board.board_description

	_build_top_ranking()
	_build_player_rank_section()


func _build_top_ranking() -> void:
	var top_users: Array[NetworkUserData] = ranking_board.get_top_users(50)

	if top_users.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No ranking data available."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ranking_list.add_child(empty_label)
		return

	for user in top_users:
		_add_ranking_row(ranking_list, user, _is_player_user(user))


func _build_player_rank_section() -> void:
	if ranking_board.player_user == null:
		_hide_player_section()
		return

	if ranking_board.is_player_in_top(50):
		_hide_player_section()
		return

	player_separator.show()
	player_rank_title.show()
	player_rank_container.show()

	_add_ranking_row(player_rank_container, ranking_board.player_user, true)


func _hide_player_section() -> void:
	player_separator.hide()
	player_rank_title.hide()
	player_rank_container.hide()


func _add_ranking_row(parent: VBoxContainer, user: NetworkUserData, highlight: bool = false) -> void:
	if ranking_row_scene == null:
		push_error("RankingsApp: ranking_row_scene não configurada.")
		return

	var instance: Node = ranking_row_scene.instantiate()

	if not instance is RankingRowUI:
		push_error("RankingsApp: ranking_row_scene precisa ter root RankingRowUI.")
		instance.queue_free()
		return

	var row: RankingRowUI = instance as RankingRowUI
	parent.add_child(row)

	row.setup(user, highlight)

	if not row.profile_requested.is_connected(_on_profile_requested):
		row.profile_requested.connect(_on_profile_requested)

	parent.add_child(HSeparator.new())


func _is_player_user(user: NetworkUserData) -> bool:
	if user == null:
		return false

	if ranking_board == null or ranking_board.player_user == null:
		return false

	return user == ranking_board.player_user


func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_home_pressed() -> void:
	browser_navigation_requested.emit(home_url)


func _on_forums_pressed() -> void:
	browser_navigation_requested.emit(forums_url)


func _on_updates_pressed() -> void:
	browser_navigation_requested.emit(updates_url)


func _on_profile_requested(url: String) -> void:
	browser_navigation_requested.emit(url)
