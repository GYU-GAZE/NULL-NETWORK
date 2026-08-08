extends VBoxContainer
class_name StartupUserEntry


signal selected(entry_id: String)
signal activated(entry_id: String)


@export var normal_style: StyleBox
@export var hover_style: StyleBox
@export var selected_style: StyleBox

@onready var selection_panel: PanelContainer = %SelectionPanel
@onready var avatar_texture: TextureRect = %AvatarTexture
@onready var avatar_fallback: Label = %AvatarFallback
@onready var username_label: Label = %UsernameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var click_target: Button = %ClickTarget
@onready var separator: HSeparator = %Separator

var campaign_id: String = ""
var avatar_id: String = ""
var _selected: bool = false
var _hovered: bool = false
var _interaction_enabled: bool = true


func _ready() -> void:
	click_target.pressed.connect(_on_click_target_pressed)
	click_target.mouse_entered.connect(_on_mouse_entered)
	click_target.mouse_exited.connect(_on_mouse_exited)
	_apply_selection_style()


func configure(profile: Dictionary, avatar: Texture2D = null) -> void:
	campaign_id = str(profile.get("campaign_id", "")).strip_edges()
	avatar_id = str(profile.get("avatar_id", "")).strip_edges()

	var username: String = str(profile.get("username", "")).strip_edges()
	var display_name: String = str(profile.get("display_name", "New User")).strip_edges()

	if username.is_empty():
		username = display_name

	if username.is_empty():
		username = "New User"

	var description: String = str(profile.get("description", "")).strip_edges()

	if description.is_empty():
		var mode: String = (
			"COMMIT"
			if int(profile.get("save_mode", CampaignState.SaveMode.SAFE))
			== CampaignState.SaveMode.COMMIT
			else "SAFE"
		)
		var day: int = maxi(1, int(profile.get("days_passed", 1)))
		description = "%s MODE · Day %d" % [mode, day]

	var fallback: String = str(profile.get("avatar_fallback", "")).strip_edges()

	if fallback.is_empty():
		fallback = username.left(1).to_upper()

	username_label.text = username
	description_label.text = description
	avatar_texture.texture = avatar
	avatar_texture.visible = avatar != null
	avatar_fallback.visible = avatar == null
	avatar_fallback.text = fallback
	avatar_fallback.tooltip_text = avatar_id


func set_selected(value: bool) -> void:
	if _selected == value:
		return

	_selected = value
	_apply_selection_style()


func is_selected() -> bool:
	return _selected


func set_interaction_enabled(value: bool) -> void:
	_interaction_enabled = value
	click_target.disabled = not value


func set_separator_visible(value: bool) -> void:
	separator.visible = value


func _on_click_target_pressed() -> void:
	if not _interaction_enabled or campaign_id.is_empty():
		return

	# Account selection deliberately follows the Windows XP-style two-step flow:
	# first press highlights the row; any later single press while highlighted
	# confirms that same account. This is not OS double-click detection.
	if _selected:
		activated.emit(campaign_id)
		return

	selected.emit(campaign_id)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_selection_style()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_selection_style()


func _apply_selection_style() -> void:
	if selection_panel == null:
		return

	var style: StyleBox = normal_style

	if _selected:
		style = selected_style
	elif _hovered:
		style = hover_style

	if style != null:
		selection_panel.add_theme_stylebox_override("panel", style)
