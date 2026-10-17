extends PanelContainer
class_name CalendarEventCard


@onready var header_label: Label = %HeaderLabel
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var location_label: Label = %LocationLabel


func setup(event: Dictionary, resolved_location_name: String = "") -> void:
	header_label.text = "%s // %s" % [
		str(event.get("time_label", "")),
		str(event.get("kind_label", "EVENT"))
	]
	title_label.text = str(event.get("title", "UNKNOWN EVENT"))
	description_label.text = str(event.get("description", ""))

	var location_name := resolved_location_name.strip_edges()
	location_label.visible = not location_name.is_empty()
	location_label.text = (
		"LOCATION // %s" % location_name
		if location_label.visible
		else ""
	)
