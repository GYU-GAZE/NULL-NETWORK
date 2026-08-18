extends PanelContainer
class_name NotificationToast

signal finished(toast: NotificationToast)

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel

@export var visible_duration: float = 3.5
@export var motion_profile: UiMotionProfileData = preload(
	"res://data/content/ui/motion/kubuos_default_motion.tres"
)

var final_position: Vector2 = Vector2.ZERO
var _motion_player: UiMotionPlayer


func _ready() -> void:
	_motion_player = UiMotionPlayer.new()
	_motion_player.name = "ToastMotionPlayer"
	_motion_player.profile = motion_profile
	add_child(_motion_player)


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


func play(final_pos: Vector2) -> void:
	final_position = final_pos

	position = KubuOSMetrics.snap_vector(final_position)
	modulate.a = 0.0
	show()
	await _motion_player.enter_control(self, Vector2(0, -6), motion_profile.panel_enter_duration)
	await get_tree().create_timer(visible_duration).timeout

	await dismiss()


func dismiss() -> void:
	await _motion_player.exit_control(self, Vector2(0, -4), motion_profile.panel_exit_duration)

	finished.emit(self)
	queue_free()
