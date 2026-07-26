extends Area2D
class_name LocalAreaInteractionSensor


signal target_changed(target: LocalAreaInteractable)
signal interaction_requested(target: LocalAreaInteractable)


@export_range(0.0, 96.0, 1.0)
var facing_distance: float = 22.0


var _current_target: LocalAreaInteractable
var _sensor_enabled: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	set_sensor_enabled(false)


func _physics_process(_delta: float) -> void:
	refresh_target()


func set_sensor_enabled(enabled: bool) -> void:
	_sensor_enabled = enabled
	monitoring = enabled
	set_physics_process(enabled)

	if not enabled:
		_set_current_target(null)
		return

	call_deferred("refresh_target")


func update_facing(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return

	position = direction.normalized() * facing_distance

	if _sensor_enabled:
		call_deferred("refresh_target")


func refresh_target() -> void:
	if not _sensor_enabled:
		_set_current_target(null)
		return

	var candidates: Array[LocalAreaInteractable] = []

	for overlapping_area in get_overlapping_areas():
		var interactable := (
			overlapping_area as LocalAreaInteractable
		)

		if interactable == null:
			continue

		if not interactable.can_interact():
			continue

		candidates.append(interactable)

	if candidates.is_empty():
		_set_current_target(null)
		return

	candidates.sort_custom(_is_candidate_before)
	_set_current_target(candidates[0])


func try_interact() -> bool:
	refresh_target()

	if not is_instance_valid(_current_target):
		return false

	if not _current_target.request_interaction():
		refresh_target()
		return false

	interaction_requested.emit(_current_target)
	return true


func get_current_target() -> LocalAreaInteractable:
	return _current_target


func _is_candidate_before(
	left: LocalAreaInteractable,
	right: LocalAreaInteractable
) -> bool:
	if (
		left.get_interaction_priority()
		!= right.get_interaction_priority()
	):
		return (
			left.get_interaction_priority()
			> right.get_interaction_priority()
		)

	var left_distance: float = (
		global_position.distance_squared_to(
			left.global_position
		)
	)
	var right_distance: float = (
		global_position.distance_squared_to(
			right.global_position
		)
	)

	if not is_equal_approx(left_distance, right_distance):
		return left_distance < right_distance

	return (
		left.get_interaction_id()
		< right.get_interaction_id()
	)


func _set_current_target(
	target: LocalAreaInteractable
) -> void:
	if _current_target == target:
		return

	_current_target = target
	target_changed.emit(_current_target)
