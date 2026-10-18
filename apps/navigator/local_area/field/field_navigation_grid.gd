extends RefCounted
class_name FieldNavigationGrid

## One shared sampled map per local area. Sampling happens on geometry changes,
## never per actor/frame. CharacterBody2D remains the final collision authority.
const CELL: float = 24.0
const RADIUS: float = 12.0
var grid := AStarGrid2D.new()
var area: NavigatorLocalAreaScene
var ready: bool = false
var excluded: Array[RID] = []

func rebuild(owner_area: NavigatorLocalAreaScene) -> void:
	area = owner_area
	excluded.clear()
	for node: Node in area.find_children("*", "CharacterBody2D", true, false):
		excluded.append((node as CharacterBody2D).get_rid())
	grid.region = Rect2i(Vector2i.ZERO, Vector2i((area.area_bounds.size / CELL).ceil()))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = area.area_bounds.position + Vector2.ONE * (CELL / 2.0)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y: int in range(grid.region.size.y):
		for x: int in range(grid.region.size.x):
			var id := Vector2i(x, y)
			grid.set_point_solid(id, not is_position_valid(grid.get_point_position(id)))
	ready = true

func is_position_valid(local_position: Vector2, exclude: Array[RID] = []) -> bool:
	if area == null or not area.area_bounds.grow(-RADIUS).has_point(local_position):
		return false
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, area.to_global(local_position))
	query.collision_mask = 1
	query.exclude = excluded + exclude
	return area.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func path(from: Vector2, target: Vector2) -> PackedVector2Array:
	if not ready:
		return PackedVector2Array()
	var start := nearest_open(from)
	var end := nearest_open(target)
	if start == Vector2i(-1, -1) or end == Vector2i(-1, -1):
		return PackedVector2Array()
	return grid.get_point_path(start, end, true)

func nearest_open(point: Vector2) -> Vector2i:
	var requested := Vector2i(((point - grid.offset) / CELL).round())
	requested = requested.clamp(grid.region.position, grid.region.end - Vector2i.ONE)
	for radius: int in range(0, 8):
		for y: int in range(-radius, radius + 1):
			for x: int in range(-radius, radius + 1):
				var id := requested + Vector2i(x, y)
				if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
					return id
	return Vector2i(-1, -1)

func line_clear(from: Vector2, target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(area.to_global(from), area.to_global(target), 1, excluded)
	return area.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
