extends Node

signal alert_requested(title: String, message: String, animation_mode: AlertAnimation)

enum AlertAnimation {
	NONE,
	POP,
	SHAKE,
	FADE,
	SLIDE_DOWN
}

var active_layer: AlertLayer


func set_active_layer(layer: AlertLayer) -> void:
	active_layer = layer


func clear_active_layer(layer: AlertLayer) -> void:
	if active_layer == layer:
		active_layer = null


func show_alert(
	title: String,
	message: String,
	animation_mode: AlertAnimation = AlertAnimation.POP
) -> void:
	var clean_title: String = title.strip_edges()
	var clean_message: String = message.strip_edges()

	if clean_title.is_empty() and clean_message.is_empty():
		return

	if active_layer != null and is_instance_valid(active_layer):
		active_layer.show_alert(clean_title, clean_message, animation_mode)
		return

	alert_requested.emit(clean_title, clean_message, animation_mode)


func get_animation_from_text(animation_text: String) -> AlertAnimation:
	var clean_text: String = animation_text.strip_edges().to_lower()

	match clean_text:
		"none":
			return AlertAnimation.NONE
		"pop":
			return AlertAnimation.POP
		"shake":
			return AlertAnimation.SHAKE
		"fade":
			return AlertAnimation.FADE
		"slide", "slide_down", "slidedown":
			return AlertAnimation.SLIDE_DOWN

	return AlertAnimation.POP
