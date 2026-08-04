extends Marker2D
class_name LocalAreaSpawnPoint


enum SpawnKind {
	COMMON_ENCOUNTER,
	INCIDENT,
	NPC,
	DATA_CENTER
}

@export var spawn_point_id: String = ""
@export var spawn_kind: SpawnKind = SpawnKind.COMMON_ENCOUNTER
@export var enabled: bool = true


func get_display_id() -> String:
	return spawn_point_id.strip_edges()


func can_host(kind: int) -> bool:
	return enabled and spawn_kind == kind and not get_display_id().is_empty()
