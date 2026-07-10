extends PanelContainer
class_name NullChannelHeader

signal navigation_requested(url: String)
signal alerts_requested

@export_category("Banner")
@export var fallback_username: String = "null.guy"
@export var fallback_rank_label: String = "#999 Worldwide"
@export var banner_texture: Texture2D
@export var banner_logical_size: Vector2 = Vector2(256, 40)

@export_category("Responsive Layout")
@export var compact_width: float = 620.0
@export var narrow_width: float = 460.0

@onready var banner_rect: TextureRect = %BannerRect
@onready var username_label: Label = %UsernameLabel
@onready var user_rank_label: Label = %UserRankLabel
@onready var user_avatar_rect: TextureRect = %UserAvatarRect

@onready var home_btn: Button = %HomeBtn
@onready var threads_btn: Button = %ThreadsBtn
@onready var updates_btn: Button = %UpdatesBtn
@onready var rankings_btn: Button = %RankingsBtn
@onready var alerts_btn: Button = %AlertsBtn
@onready var alerts_notification_badge: Control = %AlertsNotificationBadge

@onready var site_descriptor: Label = get_node("HeaderVBox/IdentityPanel/IdentityMargin/IdentityHBox/BannerStack/SiteDescriptor")
@onready var user_card: PanelContainer = get_node("HeaderVBox/IdentityPanel/IdentityMargin/IdentityHBox/UserCard")

var _show_main_nav: bool = true
var _show_updates_navigation: bool = true
var _show_rankings_navigation: bool = true
var _show_alerts_navigation: bool = true


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
	_show_main_nav = show_main_nav
	_show_updates_navigation = show_updates_navigation
	_show_rankings_navigation = show_rankings_navigation
	_show_alerts_navigation = show_alerts_navigation
	_apply_responsive_layout()


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
	if not is_inside_tree():
		return

	var available_width: float = size.x
	var compact: bool = available_width > 0.0 and available_width < compact_width
	var narrow: bool = available_width > 0.0 and available_width < narrow_width

	site_descriptor.visible = not compact
	user_rank_label.visible = not compact
	user_avatar_rect.visible = not narrow
	user_card.visible = not narrow

	home_btn.visible = _show_main_nav and not narrow
	threads_btn.visible = _show_main_nav
	updates_btn.visible = _show_main_nav and _show_updates_navigation
	rankings_btn.visible = _show_main_nav and _show_rankings_navigation and not compact
	alerts_btn.visible = _show_main_nav and _show_alerts_navigation

	threads_btn.text = "BOARD" if compact else "THREADS"
	updates_btn.text = "LOG" if narrow else "UPDATES"
	alerts_btn.text = "!" if narrow else "ALERTS"


func _connect_navigation_buttons() -> void:
	_connect_site_action_button(home_btn)
	_connect_site_action_button(threads_btn)
	_connect_site_action_button(updates_btn)
	_connect_site_action_button(rankings_btn)


func _connect_site_action_button(button: Button) -> void:
	if button == null:
		return

	if not button.has_signal("browser_navigation_requested"):
		push_warning("NullChannelHeader: botão '%s' não possui signal browser_navigation_requested." % button.name)
		return

	if not button.browser_navigation_requested.is_connected(_on_button_navigation_requested):
		button.browser_navigation_requested.connect(_on_button_navigation_requested)


func _connect_alerts_button() -> void:
	if not alerts_btn.pressed.is_connected(_on_alerts_pressed):
		alerts_btn.pressed.connect(_on_alerts_pressed)

	alerts_notification_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_button_navigation_requested(url: String) -> void:
	var clean_url: String = url.strip_edges()

	if clean_url.is_empty():
		return

	navigation_requested.emit(clean_url)


func _on_alerts_pressed() -> void:
	alerts_requested.emit()
