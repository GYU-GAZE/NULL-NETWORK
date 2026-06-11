extends Control
class_name AlertLayer

@export var alert_box_scene: PackedScene
@export var default_animation: UniversalAlerts.AlertAnimation = UniversalAlerts.AlertAnimation.POP

@export_category("Animation")
@export var pop_duration: float = 0.18
@export var fade_duration: float = 0.15
@export var shake_duration: float = 0.28
@export var slide_duration: float = 0.18
@export var close_duration: float = 0.12
@export var shake_strength: float = 10.0

@onready var blocker: ColorRect = %Blocker
@onready var center_container: CenterContainer = %CenterContainer

var current_box: AlertBox
var is_open: bool = false


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if blocker != null:
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		if not blocker.gui_input.is_connected(_on_blocker_gui_input):
			blocker.gui_input.connect(_on_blocker_gui_input)

	UniversalAlerts.set_active_layer(self)

	if not UniversalAlerts.alert_requested.is_connected(_on_global_alert_requested):
		UniversalAlerts.alert_requested.connect(_on_global_alert_requested)


func _exit_tree() -> void:
	UniversalAlerts.clear_active_layer(self)


func show_alert(
	title: String,
	message: String,
	animation_mode: UniversalAlerts.AlertAnimation = UniversalAlerts.AlertAnimation.POP
) -> void:
	if alert_box_scene == null:
		push_error("AlertLayer: alert_box_scene não configurada.")
		return

	_clear_current_box()

	show()
	is_open = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	current_box = alert_box_scene.instantiate() as AlertBox

	if current_box == null:
		push_error("AlertLayer: alert_box_scene precisa ter root AlertBox.")
		return

	center_container.add_child(current_box)
	current_box.setup(title, message)

	if not current_box.close_requested.is_connected(close_alert):
		current_box.close_requested.connect(close_alert)

	await get_tree().process_frame

	_play_open_animation(animation_mode)


func close_alert() -> void:
	if not is_open:
		return

	is_open = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if current_box == null or not is_instance_valid(current_box):
		hide()
		return

	var box: AlertBox = current_box
	current_box = null

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(box, "modulate:a", 0.0, close_duration)
	tween.parallel().tween_property(box, "scale", Vector2(0.96, 0.96), close_duration)

	await tween.finished

	if is_instance_valid(box):
		box.queue_free()

	hide()


func _clear_current_box() -> void:
	for child in center_container.get_children():
		child.queue_free()

	current_box = null


func _play_open_animation(animation_mode: UniversalAlerts.AlertAnimation) -> void:
	if current_box == null:
		return

	current_box.pivot_offset = current_box.size * 0.5
	current_box.modulate.a = 1.0
	current_box.scale = Vector2.ONE
	current_box.position = current_box.position

	match animation_mode:
		UniversalAlerts.AlertAnimation.NONE:
			return

		UniversalAlerts.AlertAnimation.POP:
			_play_pop_animation()

		UniversalAlerts.AlertAnimation.SHAKE:
			_play_shake_animation()

		UniversalAlerts.AlertAnimation.FADE:
			_play_fade_animation()

		UniversalAlerts.AlertAnimation.SLIDE_DOWN:
			_play_slide_down_animation()


func _play_pop_animation() -> void:
	current_box.scale = Vector2(0.82, 0.82)
	current_box.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(current_box, "scale", Vector2.ONE, pop_duration)
	tween.parallel().tween_property(current_box, "modulate:a", 1.0, pop_duration)


func _play_fade_animation() -> void:
	current_box.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(current_box, "modulate:a", 1.0, fade_duration)


func _play_slide_down_animation() -> void:
	var original_position: Vector2 = current_box.position
	current_box.position = original_position + Vector2(0.0, -40.0)
	current_box.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(current_box, "position", original_position, slide_duration)
	tween.parallel().tween_property(current_box, "modulate:a", 1.0, slide_duration)


func _play_shake_animation() -> void:
	_play_pop_animation()

	await get_tree().create_timer(pop_duration).timeout

	if current_box == null or not is_instance_valid(current_box):
		return

	var original_position: Vector2 = current_box.position
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	var step_time: float = shake_duration / 6.0

	tween.tween_property(current_box, "position", original_position + Vector2(shake_strength, 0.0), step_time)
	tween.tween_property(current_box, "position", original_position + Vector2(-shake_strength, 0.0), step_time)
	tween.tween_property(current_box, "position", original_position + Vector2(shake_strength * 0.65, 0.0), step_time)
	tween.tween_property(current_box, "position", original_position + Vector2(-shake_strength * 0.65, 0.0), step_time)
	tween.tween_property(current_box, "position", original_position + Vector2(shake_strength * 0.35, 0.0), step_time)
	tween.tween_property(current_box, "position", original_position, step_time)


func _on_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			close_alert()


func _on_global_alert_requested(
	title: String,
	message: String,
	animation_mode: UniversalAlerts.AlertAnimation
) -> void:
	if UniversalAlerts.active_layer != self:
		return

	show_alert(title, message, animation_mode)
