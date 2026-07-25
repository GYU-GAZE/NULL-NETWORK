extends Resource
class_name LocalAreaData


@export_category("Identity")
@export var area_id: String = ""
@export var area_name: String = ""
@export var area_subtitle: String = ""
@export_multiline var area_description: String = ""


@export_category("Scene")
@export var area_scene: PackedScene
@export var default_entry_id: String = "default"


@export_category("Presentation")
@export var enter_button_text: String = "ENTER"
@export var background_color: Color = Color(
	0.035,
	0.055,
	0.08,
	1.0
)


func get_display_id() -> String:
	if not area_id.strip_edges().is_empty():
		return area_id.strip_edges()

	return area_name.to_lower().replace(" ", "_")


func is_valid() -> bool:
	return area_scene != null
