extends HBoxContainer
class_name ProfileValueRow


@onready var left_label: Label = %LeftLabel
@onready var right_label: Label = %RightLabel


func setup(left_text: String, right_text: String) -> void:
	left_label.text = left_text
	right_label.text = right_text
