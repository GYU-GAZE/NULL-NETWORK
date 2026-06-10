extends PanelContainer
class_name NotificationToast

signal finished(toast: NotificationToast)

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel

@export var visible_duration: float = 3.5
@export var enter_duration: float = 0.25
@export var exit_duration: float = 0.25

var final_position: Vector2 = Vector2.ZERO
var hidden_position: Vector2 = Vector2.ZERO


func setup(title: String, message: String) -> void:
	if is_node_ready():
		_apply_text(title, message)
	else:
		await ready
		_apply_text(title, message)


func _apply_text(title: String, message: String) -> void:
	title_label.text = title
	message_label.text = message

	title_label.visible = not title.strip_edges().is_empty()
	message_label.visible = not message.strip_edges().is_empty()


func play(final_pos: Vector2, hidden_pos: Vector2) -> void:
	final_position = final_pos
	hidden_position = hidden_pos

	position = hidden_position
	modulate.a = 1.0
	show()

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", final_position, enter_duration)

	await tween.finished
	await get_tree().create_timer(visible_duration).timeout

	await dismiss()


func dismiss() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "position", hidden_position, exit_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, exit_duration)

	await tween.finished

	finished.emit(self)
	queue_free()
