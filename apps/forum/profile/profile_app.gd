extends PanelContainer
class_name ProfileApp

signal browser_navigation_requested(url: String)

enum ProfileTab {
	ABOUT,
	THREADS,
	FRIENDS
}

@export_category("Profile")
@export var default_user_id: String = ""
@export var profile_url_prefix: String = "null.net/profile/"
@export var max_friends_preview: int = 12

@export_category("Threads")
@export var thread_row_scene: PackedScene
@export var thread_url_prefix: String = "null.net/forums/thread/"

@export_category("Friend Cards")
@export var friend_card_scene: PackedScene
@export var compact_friend_card_size: Vector2 = Vector2(72, 88)
@export var full_friend_card_size: Vector2 = Vector2(104, 128)

var current_user: NetworkUserData
var current_tab: ProfileTab = ProfileTab.ABOUT

@onready var site_header: NullChannelHeader = %SiteHeader

@onready var about_btn: Button = %AboutBtn
@onready var threads_tab_btn: Button = %ThreadsTabBtn
@onready var friends_tab_btn: Button = %FriendsTabBtn

@onready var about_right_page: VBoxContainer = %AboutRightPage
@onready var threads_page: VBoxContainer = %ThreadsPage
@onready var friends_page: VBoxContainer = %FriendsPage

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_label: Label = %NameLabel
@onready var user_id_label: Label = %UserIdLabel
@onready var title_badge: Label = %TitleBadge
@onready var rank_stars_label: Label = %RankStarsLabel
@onready var location_value_label: Label = %LocationValueLabel
@onready var status_value_label: Label = %StatusValueLabel
@onready var joined_value_label: Label = %JoinedValueLabel
@onready var last_seen_value_label: Label = %LastSeenValueLabel
@onready var profile_banner_rect: TextureRect = %ProfileBannerRect
@onready var signature_text: RichTextLabel = %SignatureText

@onready var bio_text: RichTextLabel = %BioText

@onready var rank_value_label: Label = %RankValueLabel
@onready var score_value_label: Label = %ScoreValueLabel
@onready var level_value_label: Label = %LevelValueLabel
@onready var partner_value_label: Label = %PartnerValueLabel
@onready var reputation_value_label: Label = %ReputationValueLabel
@onready var posts_value_label: Label = %PostsValueLabel
@onready var threads_value_label: Label = %ThreadsValueLabel

@onready var friends_preview_title_label: Label = %FriendsPreviewTitleLabel
@onready var friends_preview_grid: GridContainer = %FriendsPreviewGrid

@onready var threads_title_label: Label = %ThreadsTitleLabel
@onready var user_threads_container: VBoxContainer = %UserThreadsContainer

@onready var friends_title_label: Label = %FriendsTitleLabel
@onready var friends_grid: GridContainer = %FriendsGrid


func _ready() -> void:
	_connect_site_header()
	_connect_tab_buttons()

	_load_user(default_user_id)
	_show_about_tab()


func _connect_site_header() -> void:
	site_header.refresh_player()
	site_header.configure_navigation(true, true, true, false)

	if not site_header.navigation_requested.is_connected(_on_site_header_navigation_requested):
		site_header.navigation_requested.connect(_on_site_header_navigation_requested)


func _connect_tab_buttons() -> void:
	if not about_btn.pressed.is_connected(_show_about_tab):
		about_btn.pressed.connect(_show_about_tab)

	if not threads_tab_btn.pressed.is_connected(_show_threads_tab):
		threads_tab_btn.pressed.connect(_show_threads_tab)

	if not friends_tab_btn.pressed.is_connected(_show_friends_tab):
		friends_tab_btn.pressed.connect(_show_friends_tab)


func _on_site_header_navigation_requested(url: String) -> void:
	var clean_url: String = url.strip_edges()

	if not clean_url.is_empty():
		browser_navigation_requested.emit(clean_url)


func set_browser_url(url: String) -> void:
	var user_id: String = _extract_user_id_from_url(url)

	if not user_id.is_empty():
		_load_user(user_id)


func _extract_user_id_from_url(url: String) -> String:
	var clean_url: String = SimulatedDNS.normalize_url(url)
	var clean_prefix: String = SimulatedDNS.normalize_url(profile_url_prefix)

	if clean_url.begins_with(clean_prefix):
		return clean_url.trim_prefix(clean_prefix).strip_edges()

	return clean_url


func _load_user(user_id: String) -> void:
	var target_id: String = user_id.strip_edges()

	if target_id.is_empty():
		target_id = default_user_id.strip_edges()

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

	avatar_rect.texture = null
	profile_banner_rect.texture = null
	name_label.text = "USER NOT FOUND"
	user_id_label.text = "#404"
	title_badge.text = "MISSING"
	rank_stars_label.text = ""
	location_value_label.text = "-"
	status_value_label.text = "-"
	joined_value_label.text = "-"
	last_seen_value_label.text = "-"

	bio_text.bbcode_enabled = true
	bio_text.text = "[center][b]404 PROFILE NOT FOUND[/b][/center]\n\nCould not find user: %s" % user_id

	signature_text.bbcode_enabled = true
	signature_text.text = ""

	_set_stat_labels_empty()
	_clear_container(friends_preview_grid)
	_clear_container(friends_grid)
	_clear_container(user_threads_container)

	friends_preview_title_label.text = "FRIENDS (0)"
	friends_title_label.text = "FRIENDS (0)"
	threads_title_label.text = "THREADS (0)"


func _render_user() -> void:
	_render_left_profile_card()
	_render_bio()
	_render_stats()
	_rebuild_friends_preview()
	_rebuild_full_friends()
	_rebuild_user_threads()


func _render_left_profile_card() -> void:
	avatar_rect.texture = current_user.avatar
	profile_banner_rect.texture = current_user.profile_banner

	name_label.text = current_user.display_name
	user_id_label.text = "#%s" % current_user.user_id
	title_badge.text = current_user.title.to_upper()
	rank_stars_label.text = _get_rank_stars_text(current_user)

	location_value_label.text = current_user.location
	status_value_label.text = current_user.get_status_label()
	joined_value_label.text = current_user.joined_label
	last_seen_value_label.text = current_user.last_seen_label

	signature_text.bbcode_enabled = true
	signature_text.text = current_user.get_signature_bbcode()


func _render_bio() -> void:
	bio_text.bbcode_enabled = true
	bio_text.text = current_user.get_bio_bbcode()


func _render_stats() -> void:
	rank_value_label.text = current_user.get_global_rank_label()
	score_value_label.text = _format_number(current_user.score)
	level_value_label.text = "Lv. %d" % current_user.level
	partner_value_label.text = current_user.get_partner_apk_label()
	reputation_value_label.text = _format_number(current_user.reputation)
	posts_value_label.text = _format_number(current_user.total_posts)
	threads_value_label.text = _format_number(current_user.total_threads)


func _set_stat_labels_empty() -> void:
	for label in [
		rank_value_label,
		score_value_label,
		level_value_label,
		partner_value_label,
		reputation_value_label,
		posts_value_label,
		threads_value_label
	]:
		label.text = "-"


func _show_about_tab() -> void:
	current_tab = ProfileTab.ABOUT
	_apply_tab_visibility()


func _show_threads_tab() -> void:
	current_tab = ProfileTab.THREADS
	_apply_tab_visibility()


func _show_friends_tab() -> void:
	current_tab = ProfileTab.FRIENDS
	_apply_tab_visibility()


func _apply_tab_visibility() -> void:
	about_right_page.visible = current_tab == ProfileTab.ABOUT
	threads_page.visible = current_tab == ProfileTab.THREADS
	friends_page.visible = current_tab == ProfileTab.FRIENDS

	about_btn.button_pressed = current_tab == ProfileTab.ABOUT
	threads_tab_btn.button_pressed = current_tab == ProfileTab.THREADS
	friends_tab_btn.button_pressed = current_tab == ProfileTab.FRIENDS


func _get_current_user_friends() -> Array[NetworkUserData]:
	if current_user == null:
		return []

	return NetworkUserDatabase.get_resolved_friends_for_user(current_user)


func _rebuild_friends_preview() -> void:
	_clear_container(friends_preview_grid)

	if current_user == null:
		return

	var friends: Array[NetworkUserData] = _get_current_user_friends()
	friends_preview_title_label.text = "FRIENDS (%d)" % friends.size()

	if friends.is_empty():
		_add_empty_label(friends_preview_grid, "No friends listed.")
		return

	var count: int = min(max_friends_preview, friends.size())

	for i in range(count):
		var friend: NetworkUserData = friends[i]

		if friend != null:
			friends_preview_grid.add_child(_create_friend_card(friend, true))


func _rebuild_full_friends() -> void:
	_clear_container(friends_grid)

	if current_user == null:
		return

	var friends: Array[NetworkUserData] = _get_current_user_friends()
	friends_title_label.text = "FRIENDS (%d)" % friends.size()

	if friends.is_empty():
		_add_empty_label(friends_grid, "No friends listed.")
		return

	for friend in friends:
		if friend != null:
			friends_grid.add_child(_create_friend_card(friend, false))


func _create_friend_card(friend: NetworkUserData, compact: bool = false) -> Control:
	if friend_card_scene != null:
		var card: ProfileFriendCard = friend_card_scene.instantiate() as ProfileFriendCard

		if card != null:
			card.setup(friend, compact)
			card.friend_selected.connect(_on_friend_pressed)
			return card

	var button := Button.new()
	button.custom_minimum_size = compact_friend_card_size if compact else full_friend_card_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.text = "%s\n%s" % [friend.display_name, friend.get_global_rank_label()]
	button.icon = friend.avatar
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.pressed.connect(_on_friend_pressed.bind(friend))
	return button


func _on_friend_pressed(user: NetworkUserData) -> void:
	if user == null:
		return

	var url: String = user.get_profile_url()

	if not url.is_empty():
		browser_navigation_requested.emit(url)


func _rebuild_user_threads() -> void:
	_clear_container(user_threads_container)

	if current_user == null:
		return

	var user_threads: Array[ThreadButtonData] = ForumThreadDatabase.get_threads_started_by_user(
		current_user,
		true
	)

	threads_title_label.text = "THREADS BY %s (%d)" % [
		current_user.display_name,
		user_threads.size()
	]

	if user_threads.is_empty():
		_add_empty_label(user_threads_container, "No threads started by this user.")
		return

	for thread_data in user_threads:
		if thread_row_scene == null:
			user_threads_container.add_child(_create_thread_fallback_button(thread_data))
			continue

		var row: ForumThreadRowUI = thread_row_scene.instantiate() as ForumThreadRowUI

		if row == null:
			user_threads_container.add_child(_create_thread_fallback_button(thread_data))
			continue

		user_threads_container.add_child(row)
		row.setup(thread_data)
		row.thread_selected.connect(_on_profile_thread_selected)


func _create_thread_fallback_button(thread_data: ThreadButtonData) -> Button:
	var button := Button.new()

	if thread_data == null or thread_data.thread_ref == null:
		button.text = "Missing thread"
		button.disabled = true
		return button

	button.text = "[%s] %s" % [
		thread_data.thread_ref.get_category_label(),
		thread_data.thread_ref.thread_title
	]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_profile_thread_selected.bind(thread_data.thread_ref))
	return button


func _on_profile_thread_selected(thread: ForumThread) -> void:
	if thread == null:
		return

	var thread_id: String = thread.thread_id.strip_edges()

	if thread_id.is_empty():
		browser_navigation_requested.emit("null.net/forums")
		return

	browser_navigation_requested.emit("%s%s" % [thread_url_prefix, thread_id])


func _get_rank_stars_text(user: NetworkUserData) -> String:
	if user.global_rank <= 3:
		return "★★★★★"
	if user.global_rank <= 10:
		return "★★★★"
	if user.global_rank <= 50:
		return "★★★"
	if user.global_rank <= 100:
		return "★★"

	return "★"


func _format_number(value: int) -> String:
	var text: String = str(value)
	var result: String = ""
	var counter: int = 0

	for i in range(text.length() - 1, -1, -1):
		result = text[i] + result
		counter += 1

		if counter % 3 == 0 and i > 0:
			result = "," + result

	return result


func _add_empty_label(container: Control, message: String) -> void:
	var label := Label.new()
	label.text = message
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
