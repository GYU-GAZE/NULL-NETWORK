extends HBoxContainer
class_name ProfileTendencyRow


@onready var tendency_name: Label = %TendencyName
@onready var tendency_bar: ProgressBar = %TendencyBar
@onready var tendency_value: Label = %TendencyValue


func setup(entry: Dictionary) -> void:
	tendency_name.text = str(entry.get("display_name", "—"))
	tendency_bar.value = clampf(
		float(entry.get("share", 0.0)) * 100.0,
		0.0,
		100.0
	)
	tendency_value.text = str(int(entry.get("value", 0)))
