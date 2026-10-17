extends RefCounted
class_name WindowGeometry

## All rectangles use integer logical desktop coordinates (one unit = 2 physical
## pixels). The work area is supplied by the manager; this class has no OS state.
static func resolve(requested: Rect2, minimum: Vector2, work: Rect2) -> Rect2:
	var bounds := Rect2(work.position.round(), work.size.round().max(Vector2.ONE))
	var effective_min := minimum.ceil().max(Vector2.ONE).min(bounds.size)
	if not requested.position.is_finite():
		requested.position = bounds.position
	if not requested.size.is_finite():
		requested.size = effective_min
	var extent := requested.size.round().clamp(effective_min, bounds.size)
	var origin := requested.position.round().clamp(bounds.position, bounds.end - extent)
	return Rect2(origin, extent)


## ResizeMode's numeric values are the public WindowBase edge contract. Only
## moving edges are constrained here, so hitting a minimum never moves an anchor.
static func resize(start: Rect2, delta: Vector2, mode: int, minimum: Vector2, work: Rect2) -> Rect2:
	var bounds := Rect2(work.position.round(), work.size.round().max(Vector2.ONE))
	var effective_min := minimum.ceil().max(Vector2.ONE).min(bounds.size)
	var first := start.position
	var last := start.end
	var movement := delta.round()
	if mode in [1, 5, 7]:
		first.x = clampf(start.position.x + movement.x, bounds.position.x, last.x - effective_min.x)
	if mode in [2, 6, 8]:
		last.x = clampf(start.end.x + movement.x, first.x + effective_min.x, bounds.end.x)
	if mode in [3, 5, 6]:
		first.y = clampf(start.position.y + movement.y, bounds.position.y, last.y - effective_min.y)
	if mode in [4, 7, 8]:
		last.y = clampf(start.end.y + movement.y, first.y + effective_min.y, bounds.end.y)
	return Rect2(first.round(), (last - first).round())
