extends Control
class_name AlertLayer

@export var alert_box_scene: PackedScene
@export var default_animation: UniversalAlerts.AlertAnimation = UniversalAlerts.AlertAnimation.POP
@export var motion_profile: UiMotionProfileData = preload(
	"res://data/content/ui/motion/kubuos_default_motion.tres"
)

@onready var blocker: ColorRect = %Blocker
@onready var center_container: CenterContainer = %CenterContainer
@onready var motion_host: Control = %AlertMotionHost

var current_box: AlertBox
var is_open: bool = false
var _motion_player: UiMotionPlayer


func _ready() -> void:
	_motion_player = UiMotionPlayer.new()
	_motion_player.name = "AlertMotionPlayer"
	_motion_player.profile = motion_profile
	add_child(_motion_player)
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
	if motion_host == null:
		push_error("AlertLayer: AlertMotionHost não configurado.")
		return

	_clear_current_box()

	show()
	blocker.show()
	blocker.modulate.a = 0.0
	is_open = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	current_box = alert_box_scene.instantiate() as AlertBox

	if current_box == null:
		push_error("AlertLayer: alert_box_scene precisa ter root AlertBox.")
		return

	# CenterContainer owns the host geometry. Alert motion owns only the box
	# inside that host, so presentation can never overwrite the centering layout.
	motion_host.add_child(current_box)
	current_box.setup(title, message)

	if not current_box.close_requested.is_connected(close_alert):
		current_box.close_requested.connect(close_alert)

	await _settle_alert_layout()
	if current_box == null or not is_instance_valid(current_box):
		return

	_motion_player.enter_control(
		blocker,
		Vector2.ZERO,
		motion_profile.fade_enter_duration
	)
	await _play_open_animation(animation_mode)


func close_alert() -> void:
	if not is_open:
		return

	is_open = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if current_box == null or not is_instance_valid(current_box):
		_reset_motion_host()
		hide()
		return

	var box: AlertBox = current_box
	current_box = null

	_motion_player.exit_scaled_control(
		box,
		Vector2(0.96, 0.96),
		Vector2.ZERO,
		motion_profile.alert_exit_duration
	)
	_motion_player.exit_control(
		blocker,
		Vector2.ZERO,
		motion_profile.fade_exit_duration
	)
	await get_tree().create_timer(
		maxf(
			motion_profile.alert_exit_duration,
			motion_profile.fade_exit_duration
		)
	).timeout

	if is_instance_valid(box):
		box.queue_free()

	_reset_motion_host()
	hide()


func _clear_current_box() -> void:
	if current_box != null and is_instance_valid(current_box):
		_motion_player.cancel_control(current_box)
	if is_instance_valid(blocker):
		_motion_player.cancel_control(blocker)
	if is_instance_valid(motion_host):
		for child: Node in motion_host.get_children():
			child.queue_free()

	current_box = null
	_reset_motion_host()


func _settle_alert_layout() -> void:
	if current_box == null or not is_instance_valid(current_box):
		return

	# AlertBox text can change its minimum size through fit_content. Give that
	# measurement one layout pass, then make the centered host authoritative.
	await get_tree().process_frame
	if current_box == null or not is_instance_valid(current_box):
		return

	var box_size := current_box.get_combined_minimum_size()
	box_size.x = maxf(box_size.x, current_box.size.x)
	box_size.y = maxf(box_size.y, current_box.size.y)
	box_size = KubuOSMetrics.snap_vector(box_size)
	motion_host.custom_minimum_size = box_size
	current_box.position = Vector2.ZERO
	current_box.size = box_size
	center_container.queue_sort()

	await get_tree().process_frame
	if current_box == null or not is_instance_valid(current_box):
		return

	current_box.position = Vector2.ZERO
	current_box.size = box_size
	current_box.pivot_offset = box_size * 0.5


func _reset_motion_host() -> void:
	if not is_instance_valid(motion_host):
		return
	motion_host.custom_minimum_size = Vector2.ZERO
	center_container.queue_sort()


func _play_open_animation(animation_mode: UniversalAlerts.AlertAnimation) -> void:
	if current_box == null:
		return

	current_box.pivot_offset = current_box.size * 0.5
	current_box.modulate.a = 0.0
	current_box.scale = Vector2.ONE
	current_box.position = Vector2.ZERO

	match animation_mode:
		UniversalAlerts.AlertAnimation.NONE:
			current_box.modulate.a = 1.0
			return

		UniversalAlerts.AlertAnimation.POP:
			await _play_pop_animation()

		UniversalAlerts.AlertAnimation.SHAKE:
			await _play_shake_animation()

		UniversalAlerts.AlertAnimation.FADE:
			await _play_fade_animation()

		UniversalAlerts.AlertAnimation.SLIDE_DOWN:
			await _play_slide_down_animation()


func _play_pop_animation() -> void:
	await _motion_player.enter_scaled_control(
		current_box,
		Vector2(0.94, 0.94),
		Vector2.ZERO,
		motion_profile.alert_enter_duration
	)


func _play_fade_animation() -> void:
	await _motion_player.enter_control(
		current_box,
		Vector2.ZERO,
		motion_profile.fade_enter_duration
	)


func _play_slide_down_animation() -> void:
	await _motion_player.enter_control(
		current_box,
		Vector2(0, -8),
		motion_profile.alert_enter_duration
	)


func _play_shake_animation() -> void:
	await _play_pop_animation()

	if current_box == null or not is_instance_valid(current_box):
		return

	await _motion_player.reject_control(current_box)


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
