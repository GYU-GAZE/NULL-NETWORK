extends Control

@onready var introduction_button: Button = %IntroductionBtn
@onready var get_started_button: Button = %GetStartedBtn
@onready var glossary_button: Button = %GlossaryBtn
@onready var introduction_label: Label = %IntroductionLabel
@onready var get_started_label: Label = %GetStartedLabel
@onready var glossary_label: Label = %GlossaryLabel
@onready var article_title: Label = %ArticleTitle
@onready var section_frames: Array[NullNetworkFrame] = [
	%IntroductionFrame,
	%GetStartedFrame,
	%GlossaryFrame,
]

func _ready() -> void:
	introduction_button.pressed.connect(_show_section.bind(0))
	get_started_button.pressed.connect(_show_section.bind(1))
	glossary_button.pressed.connect(_show_section.bind(2))
	_show_section(0)

func _show_section(section_index: int) -> void:
	var buttons: Array[Button] = [introduction_button, get_started_button, glossary_button]
	var labels: Array[Label] = [introduction_label, get_started_label, glossary_label]
	var titles := PackedStringArray(["01  INTRODUCTION", "02  GET STARTED!", "03  GLOSSARY"])
	for index: int in range(buttons.size()):
		buttons[index].button_pressed = index == section_index
		labels[index].visible = index == section_index
		section_frames[index].tone = (
			NullNetworkFrame.FrameTone.SELECTED
			if index == section_index
			else NullNetworkFrame.FrameTone.QUIET
		)
	article_title.text = titles[section_index]
