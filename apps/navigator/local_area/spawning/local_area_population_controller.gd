extends Node
class_name LocalAreaPopulationController


const POPULATION_VERSION: int = 1
const COMMON_ACTOR_SCENE: PackedScene = preload(
	"res://apps/navigator/local_area/actors/local_area_exe_actor.tscn"
)
const INCIDENT_ACTOR_SCENE: PackedScene = preload(
	"res://apps/navigator/local_area/actors/local_area_incident_actor.tscn"
)

@export var spawn_points_path: NodePath
@export var population_actors_path: NodePath

var _location: MapLocation
var _spawn_points_root: Node
var _population_actors_root: Node2D
var _population_state: Dictionary = {}


func _ready() -> void:
	if not LeadIncidentManager.incident_completed.is_connected(
		_on_incident_completed
	):
		LeadIncidentManager.incident_completed.connect(
			_on_incident_completed
		)

	if not LeadIncidentManager.lead_state_changed.is_connected(
		_on_lead_state_changed
	):
		LeadIncidentManager.lead_state_changed.connect(
			_on_lead_state_changed
		)


func populate(location: MapLocation) -> bool:
	if location == null:
		return false

	_spawn_points_root = get_node_or_null(spawn_points_path)
	_population_actors_root = get_node_or_null(
		population_actors_path
	) as Node2D

	if _spawn_points_root == null or _population_actors_root == null:
		push_error(
			"LocalAreaPopulationController requires spawn points "
			+ "and population actor roots."
		)
		return false

	_location = location
	_clear_runtime_actors()
	_population_state = CampaignState.get_location_population_state(
		_location.get_display_id()
	)

	var generation_key: String = _get_generation_key()

	if int(_population_state.get("version", -1)) != POPULATION_VERSION \
		or str(_population_state.get("generation_key", "")) != generation_key:
		_population_state = _create_population_state(generation_key)
	else:
		_ensure_available_incidents()

	_save_population_state()
	_instantiate_population()
	return true


func get_population_state() -> Dictionary:
	return _population_state.duplicate(true)


func get_population_actor(actor_id: String) -> LocalAreaInteractable:
	var clean_id: String = actor_id.strip_edges()

	if _population_actors_root == null:
		return null

	for child: Node in _population_actors_root.get_children():
		var actor := child as LocalAreaInteractable

		if actor != null and actor.get_interaction_id() == clean_id:
			return actor

	return null


func sync_population_state() -> void:
	if _population_actors_root == null:
		return

	for child: Node in _population_actors_root.get_children():
		var actor := child as LocalAreaInteractable

		if actor == null:
			continue

		_update_actor_descriptor(
			actor.get_interaction_id(),
			actor.get_persistent_state()
		)

	_save_population_state()


func _create_population_state(generation_key: String) -> Dictionary:
	var seed_value: int = hash(
		"%s|%s|%s" % [
			CampaignState.campaign_id,
			_location.get_display_id(),
			generation_key
		]
	)
	var actors: Array[Dictionary] = []

	if _location.spawn_table != null:
		var context := {
			"location_id": _location.get_display_id(),
			"days_passed": TimeManager.days_passed,
			"current_period": int(TimeManager.current_period),
			"current_action_block": TimeManager.current_action_block
		}
		var rolled_entries: Array[SpawnEntry] = (
			_location.spawn_table.roll_entries(seed_value, context)
		)

		for index: int in range(rolled_entries.size()):
			var entry: SpawnEntry = rolled_entries[index]
			actors.append({
				"actor_id": _build_actor_id("common", entry.get_display_id(), index),
				"kind": int(LocalAreaSpawnPoint.SpawnKind.COMMON_ENCOUNTER),
				"content_id": entry.get_display_id(),
				"spawn_point_id": "",
				"resolved": false
			})

	var state := {
		"version": POPULATION_VERSION,
		"generation_key": generation_key,
		"seed": seed_value,
		"actors": actors
	}
	_population_state = state
	_ensure_available_incidents()
	return _population_state


func _ensure_available_incidents() -> void:
	var actors: Array = _population_state.get("actors", [])
	var known_incidents: Dictionary = {}

	for actor_value: Variant in actors:
		if actor_value is Dictionary \
			and int(actor_value.get("kind", -1)) == int(
				LocalAreaSpawnPoint.SpawnKind.INCIDENT
			):
			known_incidents[str(actor_value.get("content_id", ""))] = true

	var incidents: Array[IncidentData] = (
		LeadIncidentManager.get_available_incidents_for_location(
			_location.get_display_id()
		)
	)

	for incident: IncidentData in incidents:
		var incident_id: String = incident.get_display_id()

		if known_incidents.has(incident_id):
			continue

		actors.append({
			"actor_id": _build_actor_id("incident", incident_id, 0),
			"kind": int(LocalAreaSpawnPoint.SpawnKind.INCIDENT),
			"content_id": incident_id,
			"spawn_point_id": "",
			"resolved": false
		})

	_population_state["actors"] = actors


func _instantiate_population() -> void:
	var points: Array[LocalAreaSpawnPoint] = _get_spawn_points()
	var occupied_points: Dictionary = {}
	var actors: Array = _population_state.get("actors", [])

	for actor_index: int in range(actors.size()):
		var raw_descriptor: Variant = actors[actor_index]

		if not raw_descriptor is Dictionary:
			continue

		var descriptor: Dictionary = raw_descriptor

		if bool(descriptor.get("resolved", false)):
			continue

		var kind: int = int(descriptor.get("kind", -1))
		var point: LocalAreaSpawnPoint = _resolve_spawn_point(
			points,
			kind,
			str(descriptor.get("spawn_point_id", "")),
			occupied_points
		)

		if point == null:
			continue

		descriptor["spawn_point_id"] = point.get_display_id()
		actors[actor_index] = descriptor
		occupied_points[point.get_display_id()] = true
		_instantiate_actor(descriptor, point)

	_population_state["actors"] = actors
	_save_population_state()


func _instantiate_actor(
	descriptor: Dictionary,
	point: LocalAreaSpawnPoint
) -> void:
	var kind: int = int(descriptor.get("kind", -1))
	var actor_id: String = str(descriptor.get("actor_id", ""))
	var content_id: String = str(descriptor.get("content_id", ""))
	var actor: LocalAreaInteractable

	match kind:
		LocalAreaSpawnPoint.SpawnKind.COMMON_ENCOUNTER:
			if _location.spawn_table == null:
				return

			var entry: SpawnEntry = _location.spawn_table.get_entry(content_id)
			var exe_actor := COMMON_ACTOR_SCENE.instantiate() as LocalAreaExeActor

			if exe_actor == null \
				or not exe_actor.configure_population_actor(actor_id, entry):
				if exe_actor != null:
					exe_actor.free()
				return

			actor = exe_actor

		LocalAreaSpawnPoint.SpawnKind.INCIDENT:
			var incident: IncidentData = ContentRegistry.get_incident(content_id)
			var incident_actor := (
				INCIDENT_ACTOR_SCENE.instantiate() as LocalAreaIncidentActor
			)

			if incident_actor == null \
				or not incident_actor.configure_population_actor(actor_id, incident):
				if incident_actor != null:
					incident_actor.free()
				return

			actor = incident_actor

	if actor == null:
		return

	_population_actors_root.add_child(actor)
	actor.global_position = point.global_position.round()
	actor.apply_persistent_state(descriptor)
	actor.persistent_state_changed.connect(_on_actor_state_changed)


func _resolve_spawn_point(
	points: Array[LocalAreaSpawnPoint],
	kind: int,
	preferred_point_id: String,
	occupied_points: Dictionary
) -> LocalAreaSpawnPoint:
	var clean_preferred_id: String = preferred_point_id.strip_edges()

	for point: LocalAreaSpawnPoint in points:
		if point.get_display_id() == clean_preferred_id \
			and point.can_host(kind) \
			and not occupied_points.has(clean_preferred_id):
			return point

	for point: LocalAreaSpawnPoint in points:
		if point.can_host(kind) \
			and not occupied_points.has(point.get_display_id()):
			return point

	return null


func _get_spawn_points() -> Array[LocalAreaSpawnPoint]:
	var result: Array[LocalAreaSpawnPoint] = []
	var pending: Array[Node] = [_spawn_points_root]

	while not pending.is_empty():
		var current: Node = pending.pop_back()

		for child: Node in current.get_children():
			pending.append(child)
			var point := child as LocalAreaSpawnPoint

			if point != null:
				result.append(point)

	result.sort_custom(
		func(a: LocalAreaSpawnPoint, b: LocalAreaSpawnPoint) -> bool:
			return a.get_display_id() < b.get_display_id()
	)
	return result


func _update_actor_descriptor(actor_id: String, state: Dictionary) -> void:
	var actors: Array = _population_state.get("actors", [])

	for index: int in range(actors.size()):
		var raw_descriptor: Variant = actors[index]

		if not raw_descriptor is Dictionary:
			continue

		var descriptor: Dictionary = raw_descriptor

		if str(descriptor.get("actor_id", "")) != actor_id:
			continue

		for key: Variant in state.keys():
			descriptor[str(key)] = state[key]

		actors[index] = descriptor
		_population_state["actors"] = actors
		return


func _mark_incident_resolved(incident_id: String) -> void:
	var actors: Array = _population_state.get("actors", [])

	for index: int in range(actors.size()):
		var raw_descriptor: Variant = actors[index]

		if not raw_descriptor is Dictionary:
			continue

		var descriptor: Dictionary = raw_descriptor

		if int(descriptor.get("kind", -1)) == int(
			LocalAreaSpawnPoint.SpawnKind.INCIDENT
		) and str(descriptor.get("content_id", "")) == incident_id:
			descriptor["resolved"] = true
			actors[index] = descriptor
			var actor := get_population_actor(
				str(descriptor.get("actor_id", ""))
			)

			if is_instance_valid(actor):
				actor.queue_free()

	_population_state["actors"] = actors
	_save_population_state()


func _on_actor_state_changed(
	actor: LocalAreaInteractable,
	state: Dictionary
) -> void:
	if actor == null:
		return

	_update_actor_descriptor(actor.get_interaction_id(), state)
	_save_population_state()


func _on_incident_completed(incident_id: String, _lead_id: String) -> void:
	if _location != null:
		_mark_incident_resolved(incident_id)


func _on_lead_state_changed(_lead_id: String) -> void:
	if _location == null:
		return

	_ensure_available_incidents()
	_save_population_state()
	_clear_runtime_actors()
	_instantiate_population()


func _save_population_state() -> void:
	if _location == null:
		return

	CampaignState.set_location_population_state(
		_location.get_display_id(),
		_population_state
	)


func _clear_runtime_actors() -> void:
	if _population_actors_root == null:
		return

	for child: Node in _population_actors_root.get_children():
		_population_actors_root.remove_child(child)
		child.queue_free()


func _build_actor_id(kind: String, content_id: String, index: int) -> String:
	return "%s.%s.%s.%d" % [
		_location.get_display_id(),
		kind,
		content_id.strip_edges(),
		index
	]


func _get_generation_key() -> String:
	return "%d:%d" % [
		TimeManager.days_passed,
		int(TimeManager.current_period)
	]
