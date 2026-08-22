extends Control

@export var author_user: NetworkUserData

@onready var introduction_button: Button = %IntroductionBtn
@onready var get_started_button: Button = %GetStartedBtn
@onready var introduction_label: SiteRichTextLabel = %IntroductionLabel
@onready var get_started_label: SiteRichTextLabel = %GetStartedLabel
@onready var article_title: Label = %ArticleTitle
@onready var author_profile: VBoxContainer = %AuthorProfile
@onready var author_avatar: TextureRect = %AuthorAvatar
@onready var author_username: Label = %AuthorUsername
@onready var author_title: Label = %AuthorTitle
@onready var author_location: Label = %AuthorLocation
@onready var section_frames: Array[NullNetworkFrame] = [
	%IntroductionFrame,
	%GetStartedFrame,
]


func _ready() -> void:
	introduction_button.pressed.connect(_show_section.bind(0))
	get_started_button.pressed.connect(_show_section.bind(1))
	_setup_author_profile()
	_show_section(0)


func _show_section(section_index: int) -> void:
	var buttons: Array[Button] = [introduction_button, get_started_button]
	var labels: Array[SiteRichTextLabel] = [introduction_label, get_started_label]
	var titles := PackedStringArray(["01  INTRODUCTION", "02  GET STARTED!"])

	if section_index < 0 or section_index >= buttons.size():
		return

	for index: int in range(buttons.size()):
		buttons[index].button_pressed = index == section_index
		labels[index].visible = index == section_index
		section_frames[index].tone = (
			NullNetworkFrame.FrameTone.SELECTED
			if index == section_index
			else NullNetworkFrame.FrameTone.QUIET
		)

	article_title.text = titles[section_index]


func _setup_author_profile() -> void:
	if author_user == null:
		author_profile.hide()
		return

	author_profile.show()
	author_avatar.texture = author_user.avatar
	author_avatar.visible = author_user.avatar != null
	author_username.text = _build_author_username()
	author_title.text = author_user.get_display_title()
	author_location.text = author_user.location


func _build_author_username() -> String:
	if author_user == null:
		return "Unknown User"

	var badges: Array[String] = []

	if author_user.is_moderator():
		badges.append("MOD")

	if author_user.is_system():
		badges.append("SYSTEM")

	if badges.is_empty():
		return author_user.display_name

	return "%s [%s]" % [
		author_user.display_name,
		" / ".join(badges)
	]
