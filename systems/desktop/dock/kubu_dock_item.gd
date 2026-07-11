extends Control
class_name KubuDockItem

signal activated(app: AppResource)

@export_category("Hover Animation")
@export var hover_scale: Vector2 = Vector2(1.14, 1.14)
@export var hover_offset_y: float = -7.0
@export var hover_duration: float = 0.14

@export_category("State Visuals")
@export var idle_modulate: Color = Color.WHITE
@export var running_modulate: Color = Color(1.05, 1.05, 1.12, 1.0)
@export var focused_modulate: Color = Color(1.18, 1.08, 1.18, 1.0)
@export var running_indicator_color: Color = Color(0.48, 0.75, 1.0, 1.0)
@export var focused_indicator_color: Color = Color(1.0, 0.12, 0.65, 1.0)

@onready var visual_root: Control = %VisualRoot
@onready var icon_button: Button = %IconButton
@onready var app_name_label: Label = %AppNameLabel
@onready var state_indicator: ColorRect = %StateIndicator
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var badge_label: Label = %BadgeLabel
@onready var locked_overlay: ColorRect = %LockedOverlay

var app_data: AppResource

var _is_running: bool = false
var _is_focused: bool = false
var _is_locked: bool = false
var _hover_tween: Tween


func _ready() -> void:
	icon_button.pressed.connect(_on_icon_button_pressed)
	icon_button.mouse_entered.connect(_on_mouse_entered)
	icon_button.mouse_exited.connect(_on_mouse_exited)

	badge_panel.visible = false
	state_indicator.visible = false
	locked_overlay.visible = false

	call_deferred("_refresh_pivot")


func setup(app: AppResource) -> void:
	app_data = app

	if app_data == null:
		icon_button.disabled = true
		app_name_label.text = "INVALID"
		return

	icon_button.icon = app_data.app_icon
	icon_button.tooltip_text = app_data.app_name
	app_name_label.text = app_data.app_name.to_upper()

	_refresh_visual_state()


func set_running(running: bool) -> void:
	_is_running = running
	_refresh_visual_state()


func set_focused(focused: bool) -> void:
	_is_focused = focused
	_refresh_visual_state()


func set_locked(locked: bool) -> void:
	_is_locked = locked

	var app_can_ignore_lock: bool = (
		app_data != null
		and app_data.available_while_locked
	)

	var effectively_locked: bool = (
		_is_locked
		and not app_can_ignore_lock
	)

	icon_button.disabled = effectively_locked
	locked_overlay.visible = effectively_locked

	if effectively_locked:
		_reset_hover_immediately()

	_refresh_visual_state()


func set_badge_count(count: int) -> void:
	var sanitized_count: int = maxi(0, count)

	badge_panel.visible = sanitized_count > 0

	if sanitized_count > 99:
		badge_label.text = "99+"
	else:
		badge_label.text = str(sanitized_count)


func _refresh_visual_state() -> void:
	if not is_instance_valid(visual_root):
		return

	if _is_focused:
		visual_root.modulate = focused_modulate
		state_indicator.color = focused_indicator_color
		state_indicator.custom_minimum_size = Vector2(18.0, 3.0)
		state_indicator.visible = true
		return

	if _is_running:
		visual_root.modulate = running_modulate
		state_indicator.color = running_indicator_color
		state_indicator.custom_minimum_size = Vector2(6.0, 3.0)
		state_indicator.visible = true
		return

	visual_root.modulate = idle_modulate
	state_indicator.visible = false


func _on_icon_button_pressed() -> void:
	if app_data == null:
		return

	activated.emit(app_data)


func _on_mouse_entered() -> void:
	if icon_button.disabled:
		return

	_kill_hover_tween()

	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_BACK)
	_hover_tween.set_ease(Tween.EASE_OUT)

	_hover_tween.tween_property(
		visual_root,
		"scale",
		hover_scale,
		hover_duration
	)

	_hover_tween.tween_property(
		visual_root,
		"position:y",
		hover_offset_y,
		hover_duration
	)


func _on_mouse_exited() -> void:
	_kill_hover_tween()

	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)

	_hover_tween.tween_property(
		visual_root,
		"scale",
		Vector2.ONE,
		hover_duration
	)

	_hover_tween.tween_property(
		visual_root,
		"position:y",
		0.0,
		hover_duration
	)


func _reset_hover_immediately() -> void:
	_kill_hover_tween()

	visual_root.scale = Vector2.ONE
	visual_root.position.y = 0.0


func _kill_hover_tween() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()

	_hover_tween = null


func _refresh_pivot() -> void:
	if not is_instance_valid(visual_root):
		return

	visual_root.pivot_offset = visual_root.size / 2.0
