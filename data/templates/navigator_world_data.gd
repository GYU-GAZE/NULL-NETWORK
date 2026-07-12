extends Resource
class_name NavigatorWorldData

@export_category("Identity")
@export var world_id: String = ""
@export var world_name: String = ""

@export_category("Presentation")
@export var map_texture: Texture2D
@export var locations: Array[MapLocation] = []
@export var initial_location_id: String = ""
