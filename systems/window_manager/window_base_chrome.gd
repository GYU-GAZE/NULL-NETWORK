extends "res://systems/window_manager/window_base.gd"
class_name WindowBaseChrome

@export_category("Pixel Focus Feedback")
@export var focus_flash_modulate: Color = Color(1.15, 1.08, 1.25, 1.0)


func pulse() -> void:
	if _is_closing:
		return

	_kill_animation_tween()
	top_bar.self_modulate = focus_flash_modulate

	_animation_tween = create_tween()
	_animation_tween.tween_property(
		top_bar,
		"self_modulate",
		Color.WHITE,
		focus_pulse_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
