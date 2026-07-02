extends Button
class_name ProfileFriendCard

signal friend_selected(user: NetworkUserData)

@export var tooltip_template: String = "Open {user}'s profile"
@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_label: Label = %NameLabel
@onready var rank_label: Label = %RankLabel

var user_data: NetworkUserData


func setup(user: NetworkUserData, compact: bool = false) -> void:
	user_data = user

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

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if user_data == null:
		return

	friend_selected.emit(user_data)
