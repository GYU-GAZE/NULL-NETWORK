extends PanelContainer
class_name NullNetworkPortalHeader

@export var title_text: String = "NULL NETWORK"
@export var subtitle_text: String = ""
@export var sign_up_target: String = "null.net/register"
@export var show_assessment_progress: bool = false

@onready var title_label: Label = %PortalTitle
@onready var subtitle_label: Label = %PortalSubtitle
@onready var assessment_progress: HBoxContainer = %AssessmentProgress
@onready var everyday_label: Label = %EverydayStage
@onready var critical_label: Label = %CriticalStage
@onready var dilemma_label: Label = %DilemmaStage
@onready var sign_up_button: SiteActionButton = %SignUpButton

func _ready() -> void:
	title_label.text = title_text
	subtitle_label.text = subtitle_text
	subtitle_label.visible = not subtitle_text.is_empty()
	assessment_progress.visible = show_assessment_progress
	sign_up_button.target_url = sign_up_target
	set_assessment_category(0)

func set_assessment_mode(enabled: bool) -> void:
	assessment_progress.visible = enabled
	title_label.add_theme_font_size_override("font_size", 16 if enabled else 22)
	subtitle_label.add_theme_font_size_override("font_size", 9 if enabled else 12)
	for stage_label: Label in [everyday_label, critical_label, dilemma_label]:
		stage_label.add_theme_font_size_override("font_size", 9 if enabled else 11)
	if enabled:
		title_label.text = "NULL NETWORK"
		subtitle_label.text = "COMPATIBILITY ASSESSMENT"
		subtitle_label.show()
	else:
		title_label.text = title_text
		subtitle_label.text = subtitle_text
		subtitle_label.visible = not subtitle_text.is_empty()

func set_assessment_category(category_index: int) -> void:
	var labels: Array[Label] = [everyday_label, critical_label, dilemma_label]
	for index: int in range(labels.size()):
		var label: Label = labels[index]
		if label == null:
			continue
		label.modulate = Color(0.94, 0.98, 1.0, 1.0) if index == category_index else Color(0.37, 0.52, 0.68, 0.72)
