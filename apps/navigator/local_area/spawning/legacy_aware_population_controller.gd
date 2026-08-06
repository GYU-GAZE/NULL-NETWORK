extends "res://apps/navigator/local_area/spawning/local_area_population_controller.gd"


const LEGACY_SITE_SCENE: PackedScene = preload(
	"res://apps/navigator/local_area/actors/local_area_legacy_site_actor.tscn"
)


func _ensure_available_incidents() -> void:
	super._ensure_available_incidents()
	_ensure_legacy_sites()


func _ensure_legacy_sites() -> void:
	if _location == null:
		return

	var actors: Array = _population_state.get("actors", [])
	var known_sites: Dictionary = {}

	for actor_value: Variant in actors:
		if actor_value is not Dictionary:
			continue

		var descriptor := actor_value as Dictionary

		if int(descriptor.get("kind", -1)) \
			== int(LocalAreaSpawnPoint.SpawnKind.LEGACY_SITE):
			known_sites[str(descriptor.get("content_id", ""))] = true

	for site: LegacySiteStateData in OperatorLossService.get_legacy_sites_for_location(
		_location.get_display_id()
	):
		var site_id: String = site.get_display_id()

		if known_sites.has(site_id):
			continue

		actors.append({
			"actor_id": site_id,
			"kind": int(LocalAreaSpawnPoint.SpawnKind.LEGACY_SITE),
			"content_id": site_id,
			"spawn_point_id": "",
			"resolved": site.recovered
		})

	_population_state["actors"] = actors


func _instantiate_actor(
	descriptor: Dictionary,
	point: LocalAreaSpawnPoint
) -> void:
	if int(descriptor.get("kind", -1)) \
		!= int(LocalAreaSpawnPoint.SpawnKind.LEGACY_SITE):
		super._instantiate_actor(descriptor, point)
		return

	var site_id: String = str(
		descriptor.get("content_id", "")
	).strip_edges()
	var site: LegacySiteStateData = OperatorLossService.get_legacy_site(site_id)
	var legacy_actor := (
		LEGACY_SITE_SCENE.instantiate() as LocalAreaLegacySiteActor
	)

	if site == null \
		or legacy_actor == null \
		or not legacy_actor.configure_population_actor(
			str(descriptor.get("actor_id", site_id)),
			site.to_save_data()
		):
		if legacy_actor != null:
			legacy_actor.free()
		return

	_population_actors_root.add_child(legacy_actor)
	legacy_actor.global_position = point.global_position.round()
	legacy_actor.apply_persistent_state(descriptor)
	legacy_actor.persistent_state_changed.connect(_on_actor_state_changed)
