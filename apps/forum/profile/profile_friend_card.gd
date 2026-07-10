extends Button
class_name ProfileFriendCard

signal friend_selected(user: NetworkUserData)

@export_category("Text")
@export var tooltip_template: String = "Open {user}'s profile"

@export_category("Layout")
@export var compact_card_size: Vector2 = Vector2(72, 88)
@export var full_card_size: Vector2 = Vector2(104, 128)
@export var compact_avatar_size: Vector2 = Vector2(40, 40)
@export var full_avatar_size: Vector2 = Vector2(56, 56)

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_label: Label = %NameLabel
@onready var rank_label: Label = %RankLabel

var user_data: NetworkUserData
var pending_compact: bool = false
var has_pending_setup: bool = false


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	if has_pending_setup:
		_apply_setup()


func setup(user: NetworkUserData, compact: bool = false) -> void:
	user_data = user
	pending_compact = compact
	has_pending_setup = true

	if is_node_ready():
		_apply_setup()


func _apply_setup() -> void:
	has_pending_setup = false
	_apply_layout(pending_compact)

	if user_data == null:
		disabled = true
		name_label.text = "Unknown"
		rank_label.text = ""
		avatar_rect.texture = null
		return

	disabled = false
	name_label.text = user_data.display_name
	rank_label.text = user_data.get_global_rank_label()
	avatar_rect.texture = user_data.avatar
	tooltip_text = tooltip_template.replace("{user}", user_data.display_name)


func _apply_layout(compact: bool) -> void:
	custom_minimum_size = compact_card_size if compact else full_card_size
	avatar_rect.custom_minimum_size = compact_avatar_size if compact else full_avatar_size

	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	name_label.clip_text = true
	rank_label.clip_text = true
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _on_pressed() -> void:
	if user_data != null:
		friend_selected.emit(user_data)
