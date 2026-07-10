extends PanelContainer
class_name NullChannelHeader

signal navigation_requested(url: String)
signal alerts_requested

@export_category("Banner")
@export var fallback_username: String = "null.guy"
@export var fallback_rank_label: String = "#999 Worldwide"
@export var banner_texture: Texture2D
@export var banner_logical_size: Vector2 = Vector2(256, 40)
@export var hide_banner_below_width: float = 420.0

@onready var header_hbox: HBoxContainer = %HeaderHBox
@onready var banner_rect: TextureRect = %BannerRect
@onready var user_block: HBoxContainer = %UserBlock
@onready var username_label: Label = %UsernameLabel
@onready var user_rank_label: Label = %UserRankLabel
@onready var user_avatar_rect: TextureRect = %UserAvatarRect

@onready var home_btn: Button = %HomeBtn
@onready var threads_btn: Button = %ThreadsBtn
@onready var updates_btn: Button = %UpdatesBtn
@onready var rankings_btn: Button = %RankingsBtn
@onready var alerts_btn: Button = %AlertsBtn
@onready var alerts_notification_badge: Control = %AlertsNotificationBadge


func _ready() -> void:
	_apply_banner()
	_connect_navigation_buttons()
	_connect_alerts_button()
	refresh_player()
	set_alerts_badge_visible(false)

	if not resized.is_connected(_apply_responsive_layout):
		resized.connect(_apply_responsive_layout)

	call_deferred("_apply_responsive_layout")


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


func configure_navigation(
	show_main_nav: bool,
	show_updates_navigation: bool,
	show_rankings_navigation: bool,
	show_alerts_navigation: bool
) -> void:
	home_btn.visible = show_main_nav
	threads_btn.visible = show_main_nav
	updates_btn.visible = show_main_nav and show_updates_navigation
	rankings_btn.visible = show_main_nav and show_rankings_navigation
	alerts_btn.visible = show_main_nav and show_alerts_navigation


func set_alerts_badge_visible(value: bool) -> void:
	if not is_instance_valid(alerts_notification_badge):
		return

	alerts_notification_badge.visible = value

	if not value:
		return

	alerts_notification_badge.scale = Vector2(0.75, 0.75)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(alerts_notification_badge, "scale", Vector2.ONE, 0.18)


func _apply_banner() -> void:
	if banner_texture != null:
		banner_rect.texture = banner_texture

	banner_rect.custom_minimum_size = banner_logical_size
	banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _apply_responsive_layout() -> void:
	var available_width: float = size.x

	if available_width <= 0.0:
		available_width = get_viewport_rect().size.x

	banner_rect.visible = available_width >= hide_banner_below_width

	if banner_rect.visible:
		banner_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		user_block.size_flags_horizontal = Control.SIZE_SHRINK_END
	else:
		user_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	header_hbox.queue_sort()


func _connect_navigation_buttons() -> void:
	_connect_site_action_button(home_btn)
	_connect_site_action_button(threads_btn)
	_connect_site_action_button(updates_btn)
	_connect_site_action_button(rankings_btn)


func _connect_site_action_button(button: Button) -> void:
	if button == null:
		return

	if not button.has_signal("browser_navigation_requested"):
		push_warning(
			"NullChannelHeader: botão '%s' não possui browser_navigation_requested." % button.name
		)
		return

	var callback := Callable(self, "_on_button_navigation_requested")

	if not button.is_connected("browser_navigation_requested", callback):
		button.connect("browser_navigation_requested", callback)


func _connect_alerts_button() -> void:
	if not alerts_btn.pressed.is_connected(_on_alerts_pressed):
		alerts_btn.pressed.connect(_on_alerts_pressed)

	alerts_notification_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_button_navigation_requested(url: String) -> void:
	var clean_url: String = url.strip_edges()

	if not clean_url.is_empty():
		navigation_requested.emit(clean_url)


func _on_alerts_pressed() -> void:
	alerts_requested.emit()
