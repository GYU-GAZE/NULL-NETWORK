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
@export var hover_scale: Vector2 = Vector2.ONE
@export var hover_duration: float = 0.10
@export var callout_line_width: float = 12.0
@export var callout_line_duration: float = 0.11
@export var callout_label_gap: float = 3.0
@export var callout_label_duration: float = 0.14

@export_category("Open State")
@export var running_background_color: Color = Color(0.08, 0.20, 0.31, 0.88)
@export var focused_background_color: Color = Color(0.11, 0.27, 0.40, 0.96)
@export var active_reveal_duration: float = 0.15
@export var active_hidden_scale: Vector2 = Vector2(0.12, 0.12)

@export_category("Badge Animation")
@export var badge_pulse_scale: Vector2 = Vector2(1.18, 1.18)
@export var badge_pulse_duration: float = 0.12

@onready var visual_root: Control = %VisualRoot
@onready var active_backdrop: ColorRect = %ActiveBackdrop
@onready var icon_button: Button = %IconButton
@onready var hover_callout: Control = %HoverCallout
@onready var hover_label_clip: Control = %HoverLabelClip
@onready var hover_label_panel: PanelContainer = %HoverLabelPanel
@onready var app_name_label: Label = %AppNameLabel
@onready var hover_line: ColorRect = %HoverLine
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
var _icon_hover_tween: Tween
var _badge_tween: Tween
var _state_tween: Tween
var _active_backdrop_is_visible: bool = false
var _line_reveal_progress: float = 0.0
var _label_reveal_progress: float = 0.0
var _callout_icon_left_x: float = 0.0
var _callout_center_y: float = 0.0
var _callout_label_right_x: float = 0.0
var _callout_label_full_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	icon_button.gui_input.connect(_on_icon_button_pressed)
	icon_button.mouse_entered.connect(_on_mouse_entered)
	icon_button.mouse_exited.connect(_on_mouse_exited)

	hover_callout.visible = false
	hover_label_clip.visible = false
	badge_panel.visible = false
	badge_dot.visible = false
	badge_icon.visible = false
	locked_overlay.visible = false

	active_backdrop.visible = false
	active_backdrop.modulate.a = 0.0
	active_backdrop.scale = active_hidden_scale

	call_deferred("_refresh_pivots")


func setup(app: AppResource) -> void:
	app_data = app

	if app_data == null:
		icon_button.disabled = true
		app_name_label.text = "INVALID"
		return

	icon_button.icon = app_data.app_icon
	icon_button.tooltip_text = ""
	app_name_label.text = app_data.app_name.to_upper()
	_refresh_visual_state()
	call_deferred("_refresh_callout_geometry")


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
	if not is_instance_valid(active_backdrop):
		return

	var is_active: bool = _is_running or _is_focused
	var target_color: Color = (
		focused_background_color
		if _is_focused
		else running_background_color
	)

	if is_active:
		_show_active_backdrop(target_color)
	else:
		_hide_active_backdrop()


func _show_active_backdrop(target_color: Color) -> void:
	_kill_state_tween()
	active_backdrop.color = target_color

	if _active_backdrop_is_visible:
		active_backdrop.visible = true
		active_backdrop.scale = Vector2.ONE
		active_backdrop.modulate.a = 1.0
		return

	_active_backdrop_is_visible = true
	active_backdrop.visible = true
	_refresh_active_backdrop_pivot()
	active_backdrop.scale = active_hidden_scale
	active_backdrop.modulate.a = 0.0

	_state_tween = create_tween().set_parallel(true)
	_state_tween.set_trans(Tween.TRANS_CUBIC)
	_state_tween.set_ease(Tween.EASE_OUT)
	_state_tween.tween_property(
		active_backdrop,
		"scale",
		Vector2.ONE,
		active_reveal_duration
	)
	_state_tween.tween_property(
		active_backdrop,
		"modulate:a",
		1.0,
		active_reveal_duration * 0.72
	)


func _hide_active_backdrop() -> void:
	if not _active_backdrop_is_visible:
		active_backdrop.visible = false
		return

	_kill_state_tween()
	_active_backdrop_is_visible = false
	_refresh_active_backdrop_pivot()

	_state_tween = create_tween().set_parallel(true)
	_state_tween.set_trans(Tween.TRANS_CUBIC)
	_state_tween.set_ease(Tween.EASE_IN)
	_state_tween.tween_property(
		active_backdrop,
		"scale",
		active_hidden_scale,
		active_reveal_duration * 0.78
	)
	_state_tween.tween_property(
		active_backdrop,
		"modulate:a",
		0.0,
		active_reveal_duration * 0.62
	)
	_state_tween.finished.connect(_on_active_backdrop_hidden, CONNECT_ONE_SHOT)


func _on_active_backdrop_hidden() -> void:
	if not _active_backdrop_is_visible:
		active_backdrop.visible = false


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
	_kill_hover_tweens()
	_prepare_callout_for_entry()

	_icon_hover_tween = create_tween()
	_icon_hover_tween.set_trans(Tween.TRANS_CUBIC)
	_icon_hover_tween.set_ease(Tween.EASE_OUT)
	_icon_hover_tween.tween_property(
		visual_root,
		"scale",
		hover_scale,
		hover_duration
	)

	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_CUBIC)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_method(
		_set_line_reveal_progress,
		0.0,
		1.0,
		callout_line_duration
	)
	_hover_tween.tween_method(
		_set_label_reveal_progress,
		0.0,
		1.0,
		callout_label_duration
	)


func _on_mouse_exited() -> void:
	_is_hovered = false
	_kill_hover_tweens()

	_icon_hover_tween = create_tween()
	_icon_hover_tween.set_trans(Tween.TRANS_CUBIC)
	_icon_hover_tween.set_ease(Tween.EASE_OUT)
	_icon_hover_tween.tween_property(
		visual_root,
		"scale",
		Vector2.ONE,
		hover_duration
	)

	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_CUBIC)
	_hover_tween.set_ease(Tween.EASE_IN)
	_hover_tween.tween_method(
		_set_label_reveal_progress,
		_label_reveal_progress,
		0.0,
		callout_label_duration * 0.72
	)
	_hover_tween.tween_method(
		_set_line_reveal_progress,
		_line_reveal_progress,
		0.0,
		callout_line_duration * 0.72
	)
	_hover_tween.finished.connect(_on_hover_exit_finished, CONNECT_ONE_SHOT)


func _prepare_callout_for_entry() -> void:
	hover_callout.visible = true
	_refresh_callout_geometry()
	_set_line_reveal_progress(0.0)
	_set_label_reveal_progress(0.0)


func _refresh_callout_geometry() -> void:
	if not is_instance_valid(icon_button):
		return

	var item_rect: Rect2 = get_global_rect()
	var icon_rect: Rect2 = icon_button.get_global_rect()

	_callout_icon_left_x = round(icon_rect.position.x - item_rect.position.x)
	_callout_center_y = round(icon_rect.get_center().y - item_rect.position.y)

	_callout_label_full_size = hover_label_panel.get_combined_minimum_size()

	if _callout_label_full_size.x <= 0.0:
		_callout_label_full_size.x = 48.0
	if _callout_label_full_size.y <= 0.0:
		_callout_label_full_size.y = 14.0

	_callout_label_full_size = Vector2(
		round(_callout_label_full_size.x),
		round(_callout_label_full_size.y)
	)
	_callout_label_right_x = round(
		_callout_icon_left_x
		- callout_line_width
		- callout_label_gap
	)

	hover_label_panel.size = _callout_label_full_size
	hover_label_clip.position.y = round(
		_callout_center_y - _callout_label_full_size.y * 0.5
	)
	hover_label_clip.size.y = _callout_label_full_size.y
	hover_line.position.y = floor(_callout_center_y)


func _set_line_reveal_progress(value: float) -> void:
	_line_reveal_progress = clampf(value, 0.0, 1.0)

	var revealed_width: float = round(
		callout_line_width * _line_reveal_progress
	)

	hover_line.position.x = _callout_icon_left_x - revealed_width
	hover_line.size = Vector2(revealed_width, 1.0)
	hover_line.visible = revealed_width > 0.0


func _set_label_reveal_progress(value: float) -> void:
	_label_reveal_progress = clampf(value, 0.0, 1.0)

	var full_width: float = _callout_label_full_size.x
	var revealed_width: float = round(full_width * _label_reveal_progress)

	hover_label_clip.visible = revealed_width > 0.0
	hover_label_clip.position.x = _callout_label_right_x - revealed_width
	hover_label_clip.size.x = revealed_width

	# Keep the panel's right edge pinned to the clip's right edge. As the clip
	# grows to the left, progressively more of the label is exposed from the
	# connector-line side instead of the whole label simply fading in.
	hover_label_panel.position = Vector2(
		revealed_width - full_width,
		0.0
	)


func _on_hover_exit_finished() -> void:
	if not _is_hovered:
		hover_callout.visible = false


func _reset_hover_immediately() -> void:
	_is_hovered = false
	_kill_hover_tweens()
	visual_root.scale = Vector2.ONE
	_set_label_reveal_progress(0.0)
	_set_line_reveal_progress(0.0)
	hover_callout.visible = false


func _kill_hover_tweens() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null

	if _icon_hover_tween != null and _icon_hover_tween.is_valid():
		_icon_hover_tween.kill()
	_icon_hover_tween = null


func _kill_state_tween() -> void:
	if _state_tween != null and _state_tween.is_valid():
		_state_tween.kill()
	_state_tween = null


func _refresh_pivots() -> void:
	if is_instance_valid(visual_root):
		visual_root.pivot_offset = visual_root.size / 2.0

	_refresh_active_backdrop_pivot()
	_refresh_callout_geometry()


func _refresh_active_backdrop_pivot() -> void:
	if not is_instance_valid(active_backdrop):
		return

	var backdrop_size: Vector2 = active_backdrop.size

	if backdrop_size.x <= 0.0 or backdrop_size.y <= 0.0:
		backdrop_size = active_backdrop.custom_minimum_size

	active_backdrop.pivot_offset = backdrop_size / 2.0
