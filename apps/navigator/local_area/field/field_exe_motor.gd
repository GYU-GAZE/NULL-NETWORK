extends CharacterBody2D
class_name FieldEXEMotor

enum State { IDLE, ROAMING, PATROL, INVESTIGATING, FOLLOWING, CHASING, FLEEING, RETURNING, COMBAT_CALL, DISABLED }
var actor: LocalAreaExeActor
var area: NavigatorLocalAreaScene
var home: Vector2
var state: State = State.IDLE
var destination: Vector2
var grace_seconds: float = 0.0
var needs_separation: bool = false
var _rng := RandomNumberGenerator.new()
var _perception_left: float = 0.0
var _pause_left: float = 0.0
var _path_left: float = 0.0
var _path := PackedVector2Array()
var _path_index: int = 0
var _patrol_index: int = 0
var _returning: bool = false
var _last_seen: Vector2
var _call_time: float = 0.0
var placement_initialized: bool = false
var restored_position: bool = false

func _ready() -> void:
	top_level = true
	actor = get_parent() as LocalAreaExeActor
	set_physics_process(false)

func bind(owner_area: NavigatorLocalAreaScene, seed_value: int) -> void:
	area = owner_area
	global_position = actor.global_position
	home = area.to_local(global_position)
	destination = home
	_rng.seed = seed_value
	_pause_left = _rng.randf_range(actor.behavior_profile.minimum_pause, actor.behavior_profile.maximum_pause)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if area == null or actor.behavior_profile == null:
		return
	if _call_time > 0 and area.field_calls.presenting and area.field_navigation.ready:
		_call_time = maxf(0, _call_time - delta)
		_move_physics(delta, true)
		return
	var running := area.is_field_active() and actor.can_move_in_field() and area.field_navigation.ready
	if not running:
		velocity = Vector2.ZERO
		actor.presentation.advance(0.0, velocity, false)
		return
	grace_seconds = maxf(0, grace_seconds - delta)
	_pause_left -= delta
	_path_left -= delta
	_perception_left -= delta
	if _perception_left <= 0:
		_perception_left = actor.behavior_profile.perception_interval
		_decide()
	_move_physics(delta)
	var local := area.to_local(global_position)
	if state == State.CHASING and grace_seconds <= 0 and not needs_separation:
		for index: int in range(get_slide_collision_count()):
			if get_slide_collision(index).get_collider() == area.player:
				actor.request_field_contact()
				break
		if actor.contact_sensor.overlaps_body(area.player) and global_position.distance_to(area.player.global_position) <= 22 and area.field_navigation.line_clear(local, area.to_local(area.player.global_position)):
			actor.request_field_contact()

func begin_call_motion(target: Vector2, seconds: float) -> void:
	destination = _bounded(target)
	_call_time = seconds
	_path_left = 0
	state = State.COMBAT_CALL

func end_call_motion() -> void:
	_call_time = 0
	velocity = Vector2.ZERO

func _move_physics(delta: float, during_call: bool = false) -> void:
	var direction := Vector2.ZERO
	if during_call or state not in [State.IDLE, State.COMBAT_CALL, State.DISABLED]:
		if _path_left <= 0:
			_path_left = 0.35
			_path = area.field_navigation.path(area.to_local(global_position), destination)
			# Do not backtrack to the nearest grid center on every replan. Include
			# it only when recovering from a displaced/blocked starting cell.
			_path_index = 1 if _path.size() > 1 and area.to_local(global_position).distance_to(_path[0]) <= FieldNavigationGrid.CELL * 0.8 else 0
		if _path_index < _path.size():
			var target := area.to_global(_path[_path_index])
			if global_position.distance_to(target) <= 5.0:
				_path_index += 1
			else:
				direction = global_position.direction_to(target)
	var profile := actor.behavior_profile
	velocity = velocity.move_toward(direction * (profile.call_speed if during_call else profile.speed * actor.speed_multiplier), profile.acceleration * delta)
	move_and_slide()
	var local := area.to_local(global_position)
	local = local.clamp(area.area_bounds.position + Vector2.ONE * 12, area.area_bounds.end - Vector2.ONE * 12)
	global_position = area.to_global(local)
	actor.global_position = global_position
	actor.presentation.advance(delta, velocity, true)

func _decide() -> void:
	var profile := actor.behavior_profile
	var local := area.to_local(global_position)
	var player_position := area.to_local(area.player.global_position)
	var distance := local.distance_to(player_position)
	if needs_separation and distance > profile.reengage_distance:
		needs_separation = false
	if not actor.behavior_enabled or actor.effective_behavior == FieldBehaviorProfileData.Behavior.DORMANT:
		state = State.IDLE
		return
	if local.distance_to(home) > profile.maximum_pursuit:
		_returning = true
	if _returning:
		state = State.RETURNING
		destination = home
		if local.distance_to(home) < 18:
			_returning = false
		return
	var seen := distance <= profile.perception_radius and area.field_navigation.line_clear(local, player_position)
	var behavior := actor.effective_behavior
	var can_aggro := grace_seconds <= 0 and not needs_separation and actor.aggro_enabled
	if behavior == FieldBehaviorProfileData.Behavior.TERRITORIAL and player_position.distance_to(home) > profile.territory_radius:
		if state == State.CHASING:
			_returning = true
			state = State.RETURNING
			destination = home
			return
		seen = false
	if seen:
		_last_seen = player_position
		if behavior in [FieldBehaviorProfileData.Behavior.CAUTIOUS, FieldBehaviorProfileData.Behavior.COWARDLY] or grace_seconds > 0:
			state = State.FLEEING
			destination = _bounded(local + player_position.direction_to(local) * profile.roaming_radius)
			return
		if behavior == FieldBehaviorProfileData.Behavior.CURIOUS:
			state = State.INVESTIGATING if distance > profile.following_distance * 2 else State.FOLLOWING
			destination = local if distance < profile.following_distance else player_position
			return
		var attacks := behavior in [FieldBehaviorProfileData.Behavior.AGGRESSIVE, FieldBehaviorProfileData.Behavior.TERRITORIAL, FieldBehaviorProfileData.Behavior.SWARM]
		if behavior in [FieldBehaviorProfileData.Behavior.PACK, FieldBehaviorProfileData.Behavior.PROTECTIVE]:
			for friend: LocalAreaExeActor in area.get_field_exes():
				if friend != actor and friend.global_position.distance_to(global_position) < profile.perception_radius:
					var protected := friend.environmental_apk.species_line_id == actor.environmental_apk.species_line_id or friend.environmental_apk.form_type == APKData.FormType.INIT or friend.hp_fraction <= profile.protection_hp_threshold
					if not protected:
						continue
					attacks = behavior == FieldBehaviorProfileData.Behavior.PACK or friend.global_position.distance_to(area.player.global_position) < profile.following_distance
					if attacks:
						break
		if behavior == FieldBehaviorProfileData.Behavior.OPPORTUNIST:
			attacks = float(actor.field_context.get("player_hp_fraction", 1.0)) <= profile.opportunist_hp_threshold
		if attacks and can_aggro:
			state = State.CHASING
			destination = player_position
			return
	elif state == State.CHASING:
		state = State.INVESTIGATING
		destination = _last_seen
		return
	if behavior == FieldBehaviorProfileData.Behavior.PACK and not seen:
		for friend: LocalAreaExeActor in area.get_field_exes():
			if friend != actor and friend.environmental_apk.species_line_id == actor.environmental_apk.species_line_id:
				if global_position.distance_to(friend.global_position) > profile.following_distance:
					state = State.FOLLOWING
					destination = area.to_local(friend.global_position)
					return
	if behavior == FieldBehaviorProfileData.Behavior.SOLITARY:
		for other: LocalAreaExeActor in area.get_field_exes():
			if other != actor and other.global_position.distance_to(global_position) < profile.following_distance:
				state = State.FLEEING
				destination = _bounded(local + other.global_position.direction_to(global_position) * profile.roaming_radius)
				return
	if state in [State.PATROL, State.ROAMING] and local.distance_to(destination) > 18 and not _path.is_empty():
		return
	if state != State.IDLE:
		state = State.IDLE
		_pause_left = _rng.randf_range(profile.minimum_pause, profile.maximum_pause)
	if _pause_left > 0:
		return
	if not profile.patrol_offsets.is_empty():
		state = State.PATROL
		destination = _bounded(home + profile.patrol_offsets[_patrol_index % profile.patrol_offsets.size()])
		_patrol_index += 1
	else:
		state = State.ROAMING
		destination = _bounded(home + Vector2.from_angle(_rng.randf_range(-PI, PI)) * _rng.randf_range(20, profile.roaming_radius))
	_path_left = 0

func _bounded(point: Vector2) -> Vector2:
	return point.clamp(area.area_bounds.position + Vector2.ONE * 16, area.area_bounds.end - Vector2.ONE * 16)

func disengage() -> void:
	grace_seconds = actor.behavior_profile.escape_grace_seconds
	needs_separation = true
	_perception_left = 0
	_returning = true

func to_data() -> Dictionary:
	var position := area.to_local(global_position) if area != null else global_position
	# JSON numbers cannot preserve every 64-bit RNG state. Persist decimal text.
	return {"position": {"x": position.x, "y": position.y}, "home": {"x": home.x, "y": home.y}, "destination": {"x": destination.x, "y": destination.y}, "state": int(state), "rng": str(_rng.state), "pause": _pause_left, "patrol": _patrol_index, "grace": grace_seconds, "separate": needs_separation, "returning": _returning}

func restore(data: Dictionary) -> void:
	if data.is_empty() or area == null:
		return
	var position: Dictionary = data.get("position", {})
	var saved_home: Dictionary = data.get("home", {})
	var target: Dictionary = data.get("destination", {})
	if not position.is_empty():
		restored_position = true
		global_position = area.to_global(Vector2(float(position.get("x", 0)), float(position.get("y", 0))))
		actor.global_position = global_position
	if not saved_home.is_empty():
		home = Vector2(float(saved_home.get("x", 0)), float(saved_home.get("y", 0)))
	destination = Vector2(float(target.get("x", home.x)), float(target.get("y", home.y)))
	state = clampi(int(data.get("state", State.IDLE)), State.IDLE, State.DISABLED) as State
	_rng.state = int(data.get("rng", _rng.state))
	_pause_left = float(data.get("pause", 0))
	_patrol_index = int(data.get("patrol", 0))
	grace_seconds = maxf(0, float(data.get("grace", 0)))
	needs_separation = bool(data.get("separate", false))
	_returning = bool(data.get("returning", false))
	_path_left = 0
