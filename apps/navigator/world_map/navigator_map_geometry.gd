extends RefCounted
class_name NavigatorMapGeometry

## Stateless geometry shared by pan, centering, resize and contract tests.

static func clamp_axis(
	current_position: float,
	viewport_length: float,
	content_length: float
) -> float:
	if content_length <= viewport_length:
		return (viewport_length - content_length) * 0.5

	var minimum_position: float = viewport_length - content_length

	return clampf(
		current_position,
		minimum_position,
		0.0
	)


static func pan_to_axis(
	normalized_value: float,
	viewport_length: float,
	content_length: float
) -> float:
	if content_length <= viewport_length:
		return (viewport_length - content_length) * 0.5

	var minimum_position: float = viewport_length - content_length

	return lerpf(
		0.0,
		minimum_position,
		normalized_value
	)


static func axis_to_pan(
	current_position: float,
	viewport_length: float,
	content_length: float
) -> float:
	if content_length <= viewport_length:
		return 0.5

	var minimum_position: float = viewport_length - content_length

	if is_zero_approx(minimum_position):
		return 0.5

	return clampf(
		current_position / minimum_position,
		0.0,
		1.0
	)
