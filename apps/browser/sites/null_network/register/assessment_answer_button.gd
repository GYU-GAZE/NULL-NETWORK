extends Button
class_name AssessmentAnswerButton

@onready var answer_frame: NullNetworkFrame = %AnswerFrame
@onready var number_badge: NullNetworkFrame = %NumberBadge
@onready var number_label: Label = %NumberLabel
@onready var answer_label: Label = %AnswerLabel
@onready var arrow_label: Label = %ArrowLabel


func _ready() -> void:
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)
	_on_toggled(button_pressed)

func configure(answer_number: int, answer_text: String, accent: Color) -> void:
	number_label.text = "%02d" % answer_number
	answer_label.text = answer_text
	number_label.add_theme_color_override("font_color", accent)
	arrow_label.add_theme_color_override("font_color", accent)
	answer_frame.accent_override = accent
	number_badge.accent_override = accent

func set_selected(selected: bool) -> void:
	button_pressed = selected
	_on_toggled(selected)


func _on_toggled(selected: bool) -> void:
	answer_frame.tone = (
		NullNetworkFrame.FrameTone.SELECTED
		if selected
		else NullNetworkFrame.FrameTone.QUIET
	)
