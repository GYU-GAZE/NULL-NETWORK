extends Node2D
class_name NavigatorLocalAreaScene


@export_category("Area Geometry")
@export var area_bounds: Rect2 = Rect2(
	Vector2.ZERO,
	Vector2(640, 360)
)

@onready var entry_points_root: Node = %EntryPoints
@onready var player: LocalAreaPlayerController = %Player


var area_data: LocalAreaData
var active_entry_id: String = ""


func setup_local_area(
	data: LocalAreaData,
	entry_id: String = "",
	restored_player_position: Vector2 = Vector2.ZERO,
	has_restored_player_position: bool = false
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
