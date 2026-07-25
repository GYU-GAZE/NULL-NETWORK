extends Resource
class_name NavigatorMarkerBadge


@export_category("Identity")
@export var badge_id: String = ""


@export_category("Presentation")
@export var text: String = ""
@export var tint: Color = Color.WHITE
@export_multiline var tooltip_text: String = ""


func is_empty() -> bool:
	return text.strip_edges().is_empty()
