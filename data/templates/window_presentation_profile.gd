extends Resource
class_name WindowPresentationProfile

## Descreve os tamanhos lógicos e os modos de apresentação de uma janela.
## Os valores são medidos no workspace lógico do KubuOS, antes da escala 1x/2x.

enum InitialPresentation {
	COMPACT,
	PREFERRED,
	MAXIMIZED
}

@export_category("Logical Window Sizes")
@export var compact_size: Vector2 = Vector2(360, 240)
@export var preferred_size: Vector2 = Vector2(720, 360)
@export var minimum_custom_size: Vector2 = Vector2(320, 220)

@export_category("Available Presentations")
@export var allow_compact: bool = true
@export var allow_preferred: bool = true
@export var allow_maximized: bool = true
@export var allow_manual_resize: bool = true
@export var initial_presentation: InitialPresentation = InitialPresentation.PREFERRED


func get_minimum_size() -> Vector2:
	return _sanitize_size(minimum_custom_size)


func get_compact_size() -> Vector2:
	var minimum: Vector2 = get_minimum_size()
	var sanitized: Vector2 = _sanitize_size(compact_size)

	return Vector2(
		max(minimum.x, sanitized.x),
		max(minimum.y, sanitized.y)
	)


func get_preferred_size() -> Vector2:
	var compact: Vector2 = get_compact_size()
	var sanitized: Vector2 = _sanitize_size(preferred_size)

	return Vector2(
		max(compact.x, sanitized.x),
		max(compact.y, sanitized.y)
	)


func get_initial_size() -> Vector2:
	match initial_presentation:
		InitialPresentation.COMPACT:
			return get_compact_size()
		InitialPresentation.PREFERRED:
			return get_preferred_size()
		InitialPresentation.MAXIMIZED:
			return get_preferred_size()

	return get_preferred_size()


func _sanitize_size(value: Vector2) -> Vector2:
	return Vector2(
		max(1.0, round(value.x)),
		max(1.0, round(value.y))
	)
