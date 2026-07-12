extends Resource
class_name NavigatorWorldData

@export_category("Identity")
@export var world_id: String = ""
@export var world_name: String = ""

@export_category("Presentation")
@export var map_texture: Texture2D
@export var map_logical_size: Vector2i = Vector2i.ZERO
@export var initial_pan_normalized: Vector2 = Vector2(0.5, 0.5)

@export_category("Locations")
@export var locations: Array[MapLocation] = []
@export var initial_location_id: String = ""


func get_resolved_map_size() -> Vector2:
	if map_logical_size.x > 0 and map_logical_size.y > 0:
		return Vector2(map_logical_size)

	if map_texture != null:
		return Vector2(map_texture.get_size())

	return Vector2.ZERO
