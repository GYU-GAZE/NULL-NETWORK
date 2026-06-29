extends Control
class_name ProfileApp

signal browser_navigation_requested(url: String)

enum ProfileTab {
	BIO,
	STATS,
	FRIENDS
}

@export var default_user_id: String = ""
@export var profile_url_prefix: String = "null.net/profile/"

var current_user: NetworkUserData
var current_tab: ProfileTab = ProfileTab.BIO

@onready var banner_rect: TextureRect = %BannerRect
@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_label: Label = %NameLabel
@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var meta_label: Label = %MetaLabel

@onready var bio_btn: Button = %BioBtn
@onready var stats_btn: Button = %StatsBtn
@onready var friends_btn: Button = %FriendsBtn

@onready var bio_page: VBoxContainer = %BioPage
@onready var stats_page: VBoxContainer = %StatsPage
@onready var friends_page: VBoxContainer = %FriendsPage

@onready var bio_text: RichTextLabel = %BioText
@onready var signature_text: RichTextLabel = %SignatureText

@onready var rank_value_label: Label = %RankValueLabel
@onready var score_value_label: Label = %ScoreValueLabel
@onready var level_value_label: Label = %LevelValueLabel
@onready var partner_value_label: Label = %PartnerValueLabel
@onready var server_value_label: Label = %ServerValueLabel
@onready var reputation_value_label: Label = %ReputationValueLabel
@onready var posts_value_label: Label = %PostsValueLabel
@onready var threads_value_label: Label = %ThreadsValueLabel
@onready var tags_value_label: Label = %TagsValueLabel

@onready var friends_container: GridContainer = %FriendsContainer


func _ready() -> void:
	bio_btn.pressed.connect(_show_bio_tab)
	stats_btn.pressed.connect(_show_stats_tab)
	friends_btn.pressed.connect(_show_friends_tab)

	_load_user(default_user_id)
	_show_bio_tab()


func set_browser_url(url: String) -> void:
	var user_id: String = _extract_user_id_from_url(url)

	if user_id.is_empty():
		return

	_load_user(user_id)


func _extract_user_id_from_url(url: String) -> String:
	var clean_url: String = url.strip_edges()

	if clean_url.begins_with(profile_url_prefix):
		return clean_url.trim_prefix(profile_url_prefix)

	return clean_url


func _load_user(user_id: String) -> void:
	var target_id: String = user_id.strip_edges()

	if target_id.is_empty():
		target_id = default_user_id

	if target_id.is_empty():
		_render_missing_user("unknown")
		return

	current_user = NetworkUserDatabase.get_user_by_id(target_id)

	if current_user == null:
		_render_missing_user(target_id)
		return

	_render_user()


func _render_missing_user(user_id: String) -> void:
	current_user = null

	banner_rect.texture = null
	avatar_rect.texture = null
	name_label.text = "User not found"
	title_label.text = "Unknown profile"
	status_label.text = "No data."
	meta_label.text = "Could not find user: %s" % user_id

	bio_text.text = "[center][b]404 PROFILE NOT FOUND[/b][/center]"
	signature_text.text = ""

	_clear_container(friends_container)
	_set_stat_labels_empty()


func _render_user() -> void:
	banner_rect.texture = current_user.profile_banner
	avatar_rect.texture = current_user.avatar

	name_label.text = current_user.display_name
	title_label.text = current_user.get_display_title()
	status_label.text = current_user.get_status_label()
	meta_label.text = "Joined: %s  •  Last seen: %s  •  Location: %s" % [
		current_user.joined_label,
		current_user.last_seen_label,
		current_user.location
	]

	bio_text.bbcode_enabled = true
	bio_text.text = current_user.get_bio_bbcode()

	signature_text.bbcode_enabled = true
	signature_text.text = current_user.get_signature_bbcode()

	rank_value_label.text = current_user.get_global_rank_label()
	score_value_label.text = str(current_user.score)
	level_value_label.text = str(current_user.level)
	partner_value_label.text = current_user.get_partner_apk_label()
	server_value_label.text = current_user.get_server_label()
	reputation_value_label.text = str(current_user.reputation)
	posts_value_label.text = str(current_user.total_posts)
	threads_value_label.text = str(current_user.total_threads)
	tags_value_label.text = ", ".join(current_user.profile_tags)

	_rebuild_friends()


func _set_stat_labels_empty() -> void:
	rank_value_label.text = "-"
	score_value_label.text = "-"
	level_value_label.text = "-"
	partner_value_label.text = "-"
	server_value_label.text = "-"
	reputation_value_label.text = "-"
	posts_value_label.text = "-"
	threads_value_label.text = "-"
	tags_value_label.text = "-"


func _show_bio_tab() -> void:
	current_tab = ProfileTab.BIO
	_apply_tab_visibility()


func _show_stats_tab() -> void:
	current_tab = ProfileTab.STATS
	_apply_tab_visibility()


func _show_friends_tab() -> void:
	current_tab = ProfileTab.FRIENDS
	_apply_tab_visibility()


func _apply_tab_visibility() -> void:
	bio_page.visible = current_tab == ProfileTab.BIO
	stats_page.visible = current_tab == ProfileTab.STATS
	friends_page.visible = current_tab == ProfileTab.FRIENDS

	bio_btn.disabled = current_tab == ProfileTab.BIO
	stats_btn.disabled = current_tab == ProfileTab.STATS
	friends_btn.disabled = current_tab == ProfileTab.FRIENDS


func _rebuild_friends() -> void:
	_clear_container(friends_container)

	if current_user == null:
		return

	if current_user.friend_users.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No friends listed."
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		friends_container.add_child(empty_label)
		return

	for friend in current_user.friend_users:
		if friend == null:
			continue

		var card: Button = _create_friend_card(friend)
		friends_container.add_child(card)


func _on_friend_pressed(user: NetworkUserData) -> void:
	if user == null:
		return

	var url: String = user.get_profile_url()

	if url.is_empty():
		return

	browser_navigation_requested.emit(url)

func _create_friend_card(friend: NetworkUserData) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(120, 150)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.text = "%s\n%s" % [
		friend.display_name,
		friend.get_global_rank_label()
	]
	button.icon = friend.avatar
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.pressed.connect(_on_friend_pressed.bind(friend))
	return button

func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()
