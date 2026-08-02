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


@export_category("Marker State")
## Faz o marcador aparecer mesmo antes do desbloqueio.
@export var show_when_locked: bool = false

## Revela nome e subtítulo mesmo enquanto a localização está bloqueada.
@export var reveal_identity_when_locked: bool = false

## Badge narrativo: MAIN, SIDE, RUMOR etc.
@export var activity_badge: NavigatorMarkerBadge

## Badge de risco conhecido da área.
@export var danger_badge: NavigatorMarkerBadge


@export_category("Availability")
## Quando true, a localização não precisa de flags para ser desbloqueada.
@export var unlocked_by_default: bool = true

## Valores esperados: "DAY" e/ou "NIGHT".
## Array vazio significa disponível nos dois períodos.
@export var required_time_periods: Array[String] = []

## Quando unlocked_by_default é false, todas estas flags precisam estar ativas.
@export var required_flags: Array[String] = []

@export_category("Local Area")
@export var local_area: LocalAreaData

## Atividade executada ao viajar de outra região para esta.
@export var travel_activity: ActivityDefinitionData

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
