extends Control
class_name KubuDockItem

signal activated(app: AppResource)

enum BadgeMode {
	NONE,
	COUNT,
	DOT,
	ICON
}

@export_category("Hover Animation")
@export var hover_scale: Vector2 = Vector2(1.06, 1.06)
@export var hover_offset_x: float = -1.0
@export var hover_duration: float = 0.12
@export var callout_duration: float = 0.16
@export_range(0.5, 1.0, 0.01) var callout_label_start_scale_x: float = 0.92

@export_category("State Visuals")
@export var idle_modulate: Color = Color.WHITE
@export var running_modulate: Color = Color(1.05, 1.05, 1.12, 1.0)
@export var focused_modulate: Color = Color(1.18, 1.08, 1.18, 1.0)
@export var running_indicator_color: Color = Color(0.48, 0.75, 1.0, 1.0)
@export var focused_indicator_color: Color = Color(1.0, 0.12, 0.65, 1.0)
@export var badge_pulse_scale: Vector2 = Vector2(1.18, 1.18)
@export var badge_pulse_duration: float = 0.12

@onready var visual_root: Control = %VisualRoot
@onready var icon_button: Button = %IconButton
@onready var hover_callout: Control = %HoverCallout
@onready var hover_label_panel: PanelContainer = %HoverLabelPanel
@onready var app_name_label: Label = %AppNameLabel
@onready var hover_line: ColorRect = %HoverLine
@onready var state_indicator: ColorRect = %StateIndicator
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var badge_label: Label = %BadgeLabel
@onready var badge_icon: TextureRect = %BadgeIcon
@onready var badge_dot: PanelContainer = %BadgeDot
@onready var locked_overlay: ColorRect = %LockedOverlay

var app_data: AppResource
var _is_running: bool = false
var _is_focused: bool = false
var _is_locked: bool = false
var _is_hovered: bool = false
var _badge_mode: int = BadgeMode.NONE
var _hover_tween: Tween
var _badge_tween: Tween


func _ready() -> void:
	icon_button.gui_input.connect(_on_icon_button_pressed)
	icon_button.mouse_entered.connect(_on_mouse_entered)
	icon_button.mouse_exited.connect(_on_mouse_exited)
	hover_callout.visible = false
	app_name_label.visible = true
	badge_panel.visible = false
	badge_dot.visible = false
	badge_icon.visible = false
	state_indicator.visible = false
	locked_overlay.visible = false
	call_deferred("_refresh_pivots")


func setup(app: AppResource) -> void:
	app_data = app
	if app_data == null:
		icon_button.disabled = true
		app_name_label.text = "INVALID"
		return
	icon_button.icon = app_data.app_icon
	# The custom callout is the app-name affordance; suppress the generic tooltip
	# so both systems never compete on hover.
	icon_button.tooltip_text = ""
	app_name_label.text = app_data.app_name.to_upper()
	_refresh_visual_state()
	call_deferred("_refresh_pivots")


func set_running(running: bool) -> void:
	_is_running = running
	_refresh_visual_state()


func set_focused(focused: bool) -> void:
	_is_focused = focused
	_refresh_visual_state()


func set_locked(locked: bool) -> void:
	_is_locked = locked
	var app_can_ignore_lock: bool = (
		app_data != null and app_data.available_while_locked
	)
	var effectively_locked: bool = _is_locked and not app_can_ignore_lock
	icon_button.disabled = effectively_locked
	locked_overlay.visible = effectively_locked
	if effectively_locked:
		_reset_hover_immediately()
	_refresh_visual_state()


func set_badge_count(count: int) -> void:
	var sanitized_count: int = maxi(0, count)
	if sanitized_count <= 0:
		clear_badge()
		return
	_badge_mode = BadgeMode.COUNT
	badge_label.text = "99+" if sanitized_count > 99 else str(sanitized_count)
	_refresh_badge_state(true)


func set_badge_dot() -> void:
	_badge_mode = BadgeMode.DOT
	_refresh_badge_state(true)


func set_badge_icon(icon: Texture2D) -> void:
	if icon == null:
		clear_badge()
		return
	_badge_mode = BadgeMode.ICON
	badge_icon.texture = icon
	_refresh_badge_state(true)


func clear_badge() -> void:
	_badge_mode = BadgeMode.NONE
	badge_label.text = ""
	badge_icon.texture = null
	_refresh_badge_state(false)


func _refresh_badge_state(animate: bool) -> void:
	badge_panel.visible = _badge_mode in [BadgeMode.COUNT, BadgeMode.ICON]
	badge_dot.visible = _badge_mode == BadgeMode.DOT
	badge_label.visible = _badge_mode == BadgeMode.COUNT
	badge_icon.visible = _badge_mode == BadgeMode.ICON
	if not animate:
		return
	if badge_dot.visible:
		_pulse_badge(badge_dot)
	elif badge_panel.visible:
		_pulse_badge(badge_panel)


func _pulse_badge(target: Control) -> void:
	if target == null:
		return
	if _badge_tween != null and _badge_tween.is_valid():
		_badge_tween.kill()
	target.pivot_offset = target.size / 2.0
	target.scale = badge_pulse_scale
	_badge_tween = create_tween()
	_badge_tween.tween_property(
		target,
		"scale",
		Vector2.ONE,
		badge_pulse_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh_visual_state() -> void:
	if not is_instance_valid(visual_root):
		return
	if _is_focused:
		visual_root.modulate = focused_modulate
		state_indicator.color = focused_indicator_color
		state_indicator.custom_minimum_size = Vector2(2.0, 18.0)
		state_indicator.visible = true
		return
	if _is_running:
		visual_root.modulate = running_modulate
		state_indicator.color = running_indicator_color
		state_indicator.custom_minimum_size = Vector2(2.0, 7.0)
		state_indicator.visible = true
		return
	visual_root.modulate = idle_modulate
	state_indicator.visible = false


func _on_icon_button_pressed(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if app_data == null:
		return
	if mouse_event.double_click and _is_running:
		GlobalSignals.request_close_app.emit(app_data.app_id)
		return
	activated.emit(app_data)


func _on_mouse_entered() -> void:
	if icon_button.disabled:
		return
	_is_hovered = true
	_kill_hover_tween()
	_prepare_callout_for_entry()

	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_BACK)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(visual_root, "scale", hover_scale, hover_duration)
	_hover_tween.tween_property(
		visual_root,
		"position:x",
		hover_offset_x,
		hover_duration
	)
	_hover_tween.tween_property(
		hover_label_panel,
		"modulate:a",
		1.0,
		callout_duration * 0.78
	).set_trans(Tween.TRANS_CUBIC)
	_hover_tween.tween_property(
		hover_label_panel,
		"scale:x",
		1.0,
		callout_duration
	)
	_hover_tween.tween_property(
		hover_line,
		"modulate:a",
		1.0,
		callout_duration * 0.55
	).set_trans(Tween.TRANS_CUBIC)
	_hover_tween.tween_property(
		hover_line,
		"scale:x",
		1.0,
		callout_duration * 0.9
	).set_trans(Tween.TRANS_CUBIC)


func _on_mouse_exited() -> void:
	_is_hovered = false
	_kill_hover_tween()
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(visual_root, "scale", Vector2.ONE, hover_duration)
	_hover_tween.tween_property(visual_root, "position:x", 0.0, hover_duration)
	_hover_tween.tween_property(
		hover_label_panel,
		"modulate:a",
		0.0,
		callout_duration * 0.72
	)
	_hover_tween.tween_property(
		hover_label_panel,
		"scale:x",
		callout_label_start_scale_x,
		callout_duration
	)
	_hover_tween.tween_property(
		hover_line,
		"modulate:a",
		0.0,
		callout_duration * 0.5
	)
	_hover_tween.tween_property(
		hover_line,
		"scale:x",
		0.01,
		callout_duration * 0.8
	)
	_hover_tween.finished.connect(_on_hover_exit_finished, CONNECT_ONE_SHOT)


func _prepare_callout_for_entry() -> void:
	hover_callout.visible = true
	_refresh_pivots()
	hover_label_panel.modulate.a = 0.0
	hover_label_panel.scale = Vector2(callout_label_start_scale_x, 1.0)
	hover_line.modulate.a = 0.0
	hover_line.scale = Vector2(0.01, 1.0)


func _on_hover_exit_finished() -> void:
	if not _is_hovered:
		hover_callout.visible = false


func _reset_hover_immediately() -> void:
	_is_hovered = false
	_kill_hover_tween()
	visual_root.scale = Vector2.ONE
	visual_root.position.x = 0.0
	hover_label_panel.modulate.a = 0.0
	hover_label_panel.scale = Vector2(callout_label_start_scale_x, 1.0)
	hover_line.modulate.a = 0.0
	hover_line.scale = Vector2(0.01, 1.0)
	hover_callout.visible = false


func _kill_hover_tween() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null


func _refresh_pivots() -> void:
	if is_instance_valid(visual_root):
		visual_root.pivot_offset = visual_root.size / 2.0
	if is_instance_valid(hover_label_panel):
		hover_label_panel.pivot_offset = Vector2(
			hover_label_panel.size.x,
			hover_label_panel.size.y * 0.5
		)
	if is_instance_valid(hover_line):
		hover_line.pivot_offset = Vector2(
			hover_line.size.x,
			hover_line.size.y * 0.5
		)
