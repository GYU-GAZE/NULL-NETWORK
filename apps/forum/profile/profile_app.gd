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
@export var thread_data_folders: Array[String] = [
	"res://data/content/forum/threads",
	"res://data/content/updates/threads"
]
@export var thread_row_scene: PackedScene

var current_user: NetworkUserData
var current_tab: ProfileTab = ProfileTab.ABOUT
var loaded_thread_buttons: Array[ThreadButtonData] = []

@onready var username_label: Label = %UsernameLabel
@onready var user_rank_label: Label = %UserRankLabel
@onready var user_avatar_rect: TextureRect = %UserAvatarRect

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
	about_btn.pressed.connect(_show_about_tab)
	threads_tab_btn.pressed.connect(_show_threads_tab)
	friends_tab_btn.pressed.connect(_show_friends_tab)

	_load_thread_database()
	_load_user(default_user_id)
	_show_about_tab()


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

	username_label.text = "unknown"
	user_rank_label.text = "#??? Worldwide"
	user_avatar_rect.texture = null

	avatar_rect.texture = null
	name_label.text = "USER NOT FOUND"
	user_id_label.text = "#404"
	title_badge.text = "MISSING"
	rank_stars_label.text = ""
	location_value_label.text = "-"
	status_value_label.text = "-"
	joined_value_label.text = "-"
	last_seen_value_label.text = "-"
	profile_banner_rect.texture = null

	bio_text.bbcode_enabled = true
	bio_text.text = "[center][b]404 PROFILE NOT FOUND[/b][/center]\n\nCould not find user: %s" % user_id

	signature_text.bbcode_enabled = true
	signature_text.text = ""

	_set_stat_labels_empty()
	_clear_container(friends_preview_grid)
	_clear_container(friends_grid)
	_clear_container(user_threads_container)


func _render_user() -> void:
	_render_header_user()
	_render_left_profile_card()
	_render_bio()
	_render_stats()
	_rebuild_friends_preview()
	_rebuild_full_friends()
	_rebuild_user_threads()


func _render_header_user() -> void:
	var player_user: NetworkUserData = NetworkUserDatabase.get_player_user()

	if player_user == null:
		username_label.text = "null.guy"
		user_rank_label.text = "#999 Worldwide"
		user_avatar_rect.texture = null
		return

	username_label.text = player_user.display_name
	user_rank_label.text = "%s Worldwide" % player_user.get_global_rank_label()
	user_avatar_rect.texture = player_user.avatar


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
	rank_value_label.text = "-"
	score_value_label.text = "-"
	level_value_label.text = "-"
	partner_value_label.text = "-"
	reputation_value_label.text = "-"
	posts_value_label.text = "-"
	threads_value_label.text = "-"


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

		if friend == null:
			continue

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
		if friend == null:
			continue

		friends_grid.add_child(_create_friend_card(friend, false))


func _create_friend_card(friend: NetworkUserData, compact: bool = false) -> Button:
	var button: Button = Button.new()

	if compact:
		button.custom_minimum_size = Vector2(80, 96)
	else:
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


func _on_friend_pressed(user: NetworkUserData) -> void:
	if user == null:
		return

	var url: String = user.get_profile_url()

	if url.is_empty():
		return

	browser_navigation_requested.emit(url)


func _load_thread_database() -> void:
	loaded_thread_buttons.clear()

	for folder_path in thread_data_folders:
		_load_threads_from_folder(folder_path)


func _load_threads_from_folder(folder_path: String) -> void:
	var dir: DirAccess = DirAccess.open(folder_path)

	if dir == null:
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
			_load_threads_from_folder(full_path)
			continue

		if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
			continue

		_try_load_thread(full_path)

	dir.list_dir_end()


func _try_load_thread(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)

	if resource == null:
		return

	if resource is ThreadButtonData:
		loaded_thread_buttons.append(resource as ThreadButtonData)
		return

	if resource is ForumThread:
		var data := ThreadButtonData.new()
		data.thread_ref = resource as ForumThread
		loaded_thread_buttons.append(data)


func _rebuild_user_threads() -> void:
	_clear_container(user_threads_container)

	if current_user == null:
		return

	var user_threads: Array[ThreadButtonData] = _get_threads_started_by_user(current_user)

	threads_title_label.text = "THREADS BY %s (%d)" % [
		current_user.display_name,
		user_threads.size()
	]

	if user_threads.is_empty():
		_add_empty_label(user_threads_container, "No threads started by this user.")
		return

	for thread_data in user_threads:
		if thread_row_scene != null:
			var row: ForumThreadRowUI = thread_row_scene.instantiate() as ForumThreadRowUI
			user_threads_container.add_child(row)
			row.setup(thread_data)
			row.thread_selected.connect(_on_profile_thread_selected)
		else:
			user_threads_container.add_child(_create_thread_fallback_button(thread_data))


func _get_threads_started_by_user(user: NetworkUserData) -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []

	for data in loaded_thread_buttons:
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		var author_post: ForumPost = data.thread_ref.get_author_post()

		if author_post == null:
			continue

		if author_post.author == null:
			continue

		if author_post.author.user_id == user.user_id:
			result.append(data)

	return result


func _create_thread_fallback_button(thread_data: ThreadButtonData) -> Button:
	var button: Button = Button.new()

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

	# Por enquanto, thread permalink ainda não existe.
	# Depois vamos trocar isso por algo tipo:
	# browser_navigation_requested.emit("null.net/forums/thread/%s" % thread.thread_id)
	browser_navigation_requested.emit("null.net/forums")


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
	var label: Label = Label.new()
	label.text = message
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)


func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()

func _get_current_user_friends() -> Array[NetworkUserData]:
	if current_user == null:
		return []

	return NetworkUserDatabase.get_resolved_friends_for_user(current_user)
	
