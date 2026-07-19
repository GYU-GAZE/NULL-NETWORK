extends Resource
class_name WindowPresentationProfile

## Configura os tamanhos e a densidade visual de uma janela do KubuOS.
##
## O desktop inteiro é renderizado em 2x. Enquanto a janela estiver acima de
## minimum_custom_size, seu conteúdo acompanha essa densidade. Ao atravessar
## esse limite, somente a janela passa a ser desenhada em 1x, sem alterar a
## escala do restante do jogo.
##
## minimum_outer_size é o único limite rígido de resize. Ele deve permitir que
## o frame e a barra superior continuem acessíveis mesmo quando o conteúdo não
## tiver mais espaço visível.

enum InitialPresentation {
	COMPACT,
	PREFERRED,
	MAXIMIZED
}

@export_category("Logical Window Sizes")
@export var compact_size: Vector2 = Vector2(360, 240)
@export var preferred_size: Vector2 = Vector2(720, 360)

## Mantido com este nome para preservar compatibilidade com Resources atuais.
## Agora representa o limite de transição 2x -> 1x, não o limite rígido.
@export var minimum_custom_size: Vector2 = Vector2(320, 220)

## Menor tamanho externo permitido no workspace 2x. Em densidade 1x, a área
## interna possui o dobro dessas dimensões antes da transformação visual.
@export var minimum_outer_size: Vector2 = Vector2(96, 12)

@export_category("Adaptive Pixel Density")
@export var allow_adaptive_pixel_density: bool = true
@export var density_hysteresis: Vector2 = Vector2(16, 12)

@export_category("Available Presentations")
@export var allow_compact: bool = true
@export var allow_preferred: bool = true
@export var allow_maximized: bool = true
@export var allow_manual_resize: bool = true
@export var initial_presentation: InitialPresentation = InitialPresentation.PREFERRED


func get_minimum_size() -> Vector2:
	return _sanitize_size(minimum_outer_size)


func get_scale_switch_size() -> Vector2:
	var hard_minimum: Vector2 = get_minimum_size()
	var requested: Vector2 = _sanitize_size(minimum_custom_size)

	return Vector2(
		max(hard_minimum.x, requested.x),
		max(hard_minimum.y, requested.y)
	)


func get_density_hysteresis() -> Vector2:
	return Vector2(
		max(0.0, round(density_hysteresis.x)),
		max(0.0, round(density_hysteresis.y))
	)


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
