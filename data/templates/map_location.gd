extends Resource
class_name MapLocation

enum LocationCategory {
	STORY,
	SHOP,
	HANGOUT,
	DATA,
	SERVICE,
	TRANSIT,
	BOSS,
	OTHER
}

@export_category("Identity")
@export var location_id: String = ""
@export var location_name: String = ""
@export var location_subtitle: String = ""
@export_multiline var location_description: String = ""

@export_category("World Map")
@export var show_on_world_map: bool = true
@export var world_map_position: Vector2 = Vector2(0.5, 0.5)
@export var marker_icon: Texture2D
@export var marker_tint: Color = Color(0.30, 0.85, 1.0, 1.0)
@export var category: LocationCategory = LocationCategory.OTHER

@export_category("Availability")
@export var unlocked_by_default: bool = true
@export var required_time_periods: Array[String] = []
@export var required_flags: Array[String] = []

@export_category("Encounters")
@export var spawn_table: SpawnTable


func get_display_id() -> String:
	if not location_id.strip_edges().is_empty():
		return location_id.strip_edges()

	return location_name.to_lower().replace(" ", "_")


func get_marker_title() -> String:
	return location_name


func get_marker_subtitle() -> String:
	return location_subtitle
