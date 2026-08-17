extends Button
class_name AssessmentAnswerButton

@onready var number_badge: PanelContainer = %NumberBadge
@onready var number_label: Label = %NumberLabel
@onready var answer_label: Label = %AnswerLabel
@onready var arrow_label: Label = %ArrowLabel

func configure(answer_number: int, answer_text: String, accent: Color) -> void:
	number_label.text = "%02d" % answer_number
	answer_label.text = answer_text
	number_label.add_theme_color_override("font_color", accent)
	arrow_label.add_theme_color_override("font_color", accent)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.08, 0.96)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.border_color = accent
	badge_style.corner_radius_top_left = 2
	badge_style.corner_radius_top_right = 2
	badge_style.corner_radius_bottom_right = 2
	badge_style.corner_radius_bottom_left = 2
	number_badge.add_theme_stylebox_override("panel", badge_style)

func set_selected(selected: bool) -> void:
	button_pressed = selected
