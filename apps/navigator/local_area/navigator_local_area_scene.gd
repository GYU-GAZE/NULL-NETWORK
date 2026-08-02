extends Node2D
class_name NavigatorLocalAreaScene


signal interaction_target_changed(
	target: LocalAreaInteractable
)
signal interaction_requested(
	target: LocalAreaInteractable
)


@export_category("Area Geometry")
@export var area_bounds: Rect2 = Rect2(
	Vector2.ZERO,
	Vector2(640, 360)
)

@onready var entry_points_root: Node = %EntryPoints
@onready var player: LocalAreaPlayerController = %Player


var area_data: LocalAreaData
var active_entry_id: String = ""


func _ready() -> void:
	if (
		is_instance_valid(player)
		and not player.interaction_target_changed.is_connected(
			_on_player_interaction_target_changed
		)
	):
		player.interaction_target_changed.connect(
			_on_player_interaction_target_changed
		)

	if (
		is_instance_valid(player)
		and not player.interaction_requested.is_connected(
			_on_player_interaction_requested
		)
	):
		player.interaction_requested.connect(
			_on_player_interaction_requested
		)


func setup_local_area(
	data: LocalAreaData,
	entry_id: String = "",
	restored_player_position: Vector2 = Vector2.ZERO,
	has_restored_player_position: bool = false,
	restored_runtime_state: Dictionary = {}
) -> bool:
	if data == null:
		push_error(
			"NavigatorLocalAreaScene: LocalAreaData is null."
		)
		return false

	if not is_instance_valid(player):
		push_error(
			"NavigatorLocalAreaScene: a unique Player node "
			+ "inheriting LocalAreaPlayerController is required."
		)
		return false

	if not is_instance_valid(entry_points_root):
		push_error(
			"NavigatorLocalAreaScene: a unique EntryPoints node "
			+ "is required."
		)
		return false

	area_data = data

	var resolved_entry_id: String = entry_id.strip_edges()

	if resolved_entry_id.is_empty():
		resolved_entry_id = (
			area_data.default_entry_id.strip_edges()
		)

	var entry_point := _find_entry_point(
		resolved_entry_id
	)

	if entry_point == null:
		push_error(
			"NavigatorLocalAreaScene: entry point '%s' "
			% resolved_entry_id
			+ "was not found in area '%s'."
			% area_data.get_display_id()
		)
		return false

	active_entry_id = resolved_entry_id

	if has_restored_player_position:
		player.global_position = (
			restored_player_position.round()
		)
	else:
		player.global_position = (
			entry_point.global_position.round()
		)

	player.configure_camera_bounds(area_bounds)
	apply_runtime_state(restored_runtime_state)
	player.set_input_enabled(false)

	return true


func set_area_active(active: bool) -> void:
	if not is_instance_valid(player):
		return

	player.set_input_enabled(active)


func get_player_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO

	return player.global_position.round()


func get_interact_action() -> StringName:
	if not is_instance_valid(player):
		return &"local_area_interact"

	return player.get_interact_action()


func get_runtime_state() -> Dictionary:
	var interactable_states: Dictionary = {}

	for interactable in _get_interactables():
		var interaction_id: String = (
			interactable.get_interaction_id()
		)

		if interaction_id.is_empty():
			continue

		if interactable_states.has(interaction_id):
			push_warning(
				"NavigatorLocalAreaScene: duplicate "
				+ "interaction id '%s' while saving state."
				% interaction_id
			)
			continue

		interactable_states[interaction_id] = (
			interactable.get_persistent_state()
		)

	return {
		"interactables": interactable_states
	}


func find_interactable_by_id(
	interaction_id: String
) -> LocalAreaInteractable:
	var clean_id: String = interaction_id.strip_edges()

	if clean_id.is_empty():
		return null

	for interactable: LocalAreaInteractable in _get_interactables():
		if interactable.get_interaction_id() == clean_id:
			return interactable

	return null


func apply_runtime_state(state: Dictionary) -> void:
	var raw_interactable_states: Variant = state.get(
		"interactables",
		{}
	)

	if not raw_interactable_states is Dictionary:
		return

	var interactable_states := (
		raw_interactable_states as Dictionary
	)

	for interactable in _get_interactables():
		var interaction_id: String = (
			interactable.get_interaction_id()
		)

		if not interactable_states.has(interaction_id):
			continue

		var raw_state: Variant = (
			interactable_states[interaction_id]
		)

		if not raw_state is Dictionary:
			continue

		interactable.apply_persistent_state(
			raw_state as Dictionary
		)


func _get_interactables() -> Array[LocalAreaInteractable]:
	var interactables: Array[LocalAreaInteractable] = []
	var pending_nodes: Array[Node] = [self]

	while not pending_nodes.is_empty():
		var current: Node = pending_nodes.pop_back()

		for child in current.get_children():
			pending_nodes.append(child)

			var interactable := (
				child as LocalAreaInteractable
			)

			if interactable != null:
				interactables.append(interactable)

	return interactables


func _find_entry_point(
	requested_entry_id: String
) -> LocalAreaEntryPoint:
	var clean_id: String = requested_entry_id.strip_edges()

	if clean_id.is_empty():
		return null

	var matching_entry: LocalAreaEntryPoint
	var pending_nodes: Array[Node] = [
		entry_points_root
	]

	while not pending_nodes.is_empty():
		var current: Node = pending_nodes.pop_back()

		for child in current.get_children():
			pending_nodes.append(child)

			var entry := child as LocalAreaEntryPoint

			if entry == null:
				continue

			if entry.get_entry_id() != clean_id:
				continue

			if matching_entry != null:
				push_error(
					"NavigatorLocalAreaScene: duplicate entry "
					+ "point id '%s'." % clean_id
				)
				return null

			matching_entry = entry

	return matching_entry


func _on_player_interaction_target_changed(
	target: LocalAreaInteractable
) -> void:
	interaction_target_changed.emit(target)


func _on_player_interaction_requested(
	target: LocalAreaInteractable
) -> void:
	interaction_requested.emit(target)
