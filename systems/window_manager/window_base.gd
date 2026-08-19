extends Control
class_name WindowBase

signal window_opened
signal window_closed
signal window_focused
signal window_moved
signal window_resized

enum ResizeMode {
	NONE,
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

@export_category("Window Animation")
@export var motion_profile: UiMotionProfileData = preload(
	"res://data/content/ui/motion/kubuos_default_motion.tres"
)
@export var opening_scale: Vector2 = Vector2(0.95, 0.95)
@export var closing_scale: Vector2 = Vector2(0.96, 0.96)
@export var opening_offset: Vector2 = Vector2(0, 4)
@export var closing_offset: Vector2 = Vector2(0, 3)

@export_category("Resize")
@export var border_size: float = 8.0

@export_category("Window Buttons")
@export var maximize_button_text: String = "□"
@export var restore_button_text: String = "❐"
@export var maximize_button_icon: Texture2D
@export var restore_button_icon: Texture2D

var app_id: String = ""

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var can_resize: bool = false
var min_window_size: Vector2 = Vector2(400, 300)

var is_resizing: bool = false
var resize_mode: ResizeMode = ResizeMode.NONE
var resize_start_mouse: Vector2 = Vector2.ZERO
var resize_start_size: Vector2 = Vector2.ZERO
var resize_start_position: Vector2 = Vector2.ZERO

var is_maximized: bool = false
var restore_position: Vector2 = Vector2.ZERO
var restore_size: Vector2 = Vector2.ZERO

var _motion_player: UiMotionPlayer
var _is_opening: bool = false
var _open_animation_pending: bool = true
var _has_completed_open_animation: bool = false
var _is_closing: bool = false
var _is_geometry_transitioning: bool = false

@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var maximize_button: Button = %MaximizeButton
@onready var content_container: MarginContainer = %ContentContainer
@onready var top_bar: Control = %TopBar
@onready var resize_border: ResizeBorder = %ResizeBorder
@onready var background: PanelContainer = %Background


func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_LEFT
	_motion_player = UiMotionPlayer.new()
	_motion_player.name = "WindowMotionPlayer"
	_motion_player.profile = motion_profile
	add_child(_motion_player)

	close_button.pressed.connect(close)
	maximize_button.pressed.connect(toggle_maximized)
	top_bar.gui_input.connect(_on_top_bar_gui_input)
	resize_border.gui_input.connect(_on_resize_border_gui_input)

	if not resized.is_connected(_refresh_pivot_offset):
		resized.connect(_refresh_pivot_offset)

	_refresh_maximize_button()
	_open_animation_pending = true
	call_deferred("play_open_animation")


func setup(
	id: String,
	window_name: String,
	window_size: Vector2,
	minimum_size: Vector2,
	resize_enabled: bool
) -> void:
	app_id = id
	title_label.text = window_name

	min_window_size = KubuOSMetrics.snap_vector(minimum_size)
	can_resize = resize_enabled

	custom_minimum_size = Vector2.ZERO
	anchors_preset = Control.PRESET_TOP_LEFT

	size = KubuOSMetrics.snap_vector(Vector2(
		max(window_size.x, min_window_size.x),
		max(window_size.y, min_window_size.y)
	))

	resize_border.visible = can_resize
	resize_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resize_border.border_size = border_size

	_refresh_pivot_offset()
	_refresh_maximize_button()


func wait_until_opened() -> void:
	if _has_completed_open_animation:
		return
	await window_opened


func play_open_animation() -> void:
	if _is_closing:
		_open_animation_pending = false
		return

	_cancel_active_motion()
	_refresh_pivot_offset()
	_is_opening = true
	await _motion_player.enter_scaled_control(
		self,
		opening_scale,
		opening_offset,
		motion_profile.window_enter_duration
	)
	_finish_open_animation()


func _finish_open_animation() -> void:
	_is_opening = false
	_open_animation_pending = false
	position = KubuOSMetrics.snap_vector(position)
	scale = Vector2.ONE
	modulate = Color.WHITE
	if not _has_completed_open_animation:
		_has_completed_open_animation = true
		window_opened.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		window_focused.emit()


func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			toggle_maximized()
			accept_event()
			return

		if event.pressed:
			if is_maximized:
				return

			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			window_focused.emit()
			accept_event()
		else:
			is_dragging = false
			global_position = KubuOSMetrics.snap_vector(global_position)
			window_moved.emit()
			accept_event()

	elif event is InputEventMouseMotion and is_dragging:
		global_position = KubuOSMetrics.snap_vector(
			get_global_mouse_position() - drag_offset
		)
		window_moved.emit()
		accept_event()


func toggle_maximized() -> void:
	if is_maximized:
		restore_from_maximized()
	else:
		maximize()


func maximize(animated: bool = true) -> void:
	if is_maximized or _is_geometry_transitioning:
		return

	window_focused.emit()

	restore_position = KubuOSMetrics.snap_vector(position)
	restore_size = KubuOSMetrics.snap_vector(size)

	is_dragging = false
	is_resizing = false
	resize_mode = ResizeMode.NONE
	resize_border.force_capture = false

	is_maximized = true
	_refresh_maximize_button()
	await _apply_window_geometry(
		Rect2(_get_maximized_position(), _get_maximized_size()),
		animated
	)
	window_moved.emit()
	window_resized.emit()


func restore_from_maximized(animated: bool = true) -> void:
	if not is_maximized or _is_geometry_transitioning:
		return

	window_focused.emit()
	is_maximized = false

	var target_size := KubuOSMetrics.snap_vector(Vector2(
		max(restore_size.x, min_window_size.x),
		max(restore_size.y, min_window_size.y)
	))
	_refresh_maximize_button()
	await _apply_window_geometry(
		Rect2(KubuOSMetrics.snap_vector(restore_position), target_size),
		animated
	)
	window_moved.emit()
	window_resized.emit()


func _apply_window_geometry(target_rect: Rect2, animated: bool) -> void:
	_is_geometry_transitioning = true
	is_dragging = false
	is_resizing = false
	resize_mode = ResizeMode.NONE
	resize_border.force_capture = false
	resize_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	maximize_button.disabled = true
	if animated and is_inside_tree():
		await _motion_player.transition_rect(self, target_rect)
	else:
		position = KubuOSMetrics.snap_vector(target_rect.position)
		size = KubuOSMetrics.snap_vector(target_rect.size)
	_is_geometry_transitioning = false
	_refresh_maximize_button()


func apply_maximized_geometry() -> void:
	if not is_maximized:
		return

	position = KubuOSMetrics.snap_vector(_get_maximized_position())
	size = KubuOSMetrics.snap_vector(_get_maximized_size())
	_refresh_pivot_offset()


func _get_maximized_position() -> Vector2:
	var parent_node: Node = get_parent()

	if parent_node != null and parent_node.has_method("get_work_area_position"):
		return parent_node.get_work_area_position()

	return Vector2.ZERO


func _get_maximized_size() -> Vector2:
	var parent_node: Node = get_parent()

	if parent_node != null and parent_node.has_method("get_work_area_size"):
		return parent_node.get_work_area_size()

	var parent_control: Control = get_parent() as Control

	if parent_control != null and parent_control.size.x > 0.0 and parent_control.size.y > 0.0:
		return parent_control.size

	return get_viewport_rect().size


func _refresh_maximize_button() -> void:
	if not is_instance_valid(maximize_button):
		return

	maximize_button.visible = can_resize
	maximize_button.disabled = not can_resize

	if is_maximized:
		maximize_button.text = restore_button_text
		maximize_button.icon = restore_button_icon
		maximize_button.tooltip_text = "Restore"
	else:
		maximize_button.text = maximize_button_text
		maximize_button.icon = maximize_button_icon
		maximize_button.tooltip_text = "Maximize"

	resize_border.visible = can_resize and not is_maximized
	resize_border.mouse_filter = (
		Control.MOUSE_FILTER_STOP
		if can_resize and not is_maximized and not _is_geometry_transitioning
		else Control.MOUSE_FILTER_IGNORE
	)


func _get_resize_mode(border_mouse_pos: Vector2) -> ResizeMode:
	var total_size: Vector2 = resize_border.size

	var left: bool = border_mouse_pos.x <= border_size
	var right: bool = border_mouse_pos.x >= total_size.x - border_size
	var top: bool = border_mouse_pos.y <= border_size
	var bottom: bool = border_mouse_pos.y >= total_size.y - border_size

	if left and top:
		return ResizeMode.TOP_LEFT
	if right and top:
		return ResizeMode.TOP_RIGHT
	if left and bottom:
		return ResizeMode.BOTTOM_LEFT
	if right and bottom:
		return ResizeMode.BOTTOM_RIGHT
	if left:
		return ResizeMode.LEFT
	if right:
		return ResizeMode.RIGHT
	if top:
		return ResizeMode.TOP
	if bottom:
		return ResizeMode.BOTTOM

	return ResizeMode.NONE


func _on_resize_border_gui_input(event: InputEvent) -> void:
	if not can_resize or is_maximized or _is_geometry_transitioning:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			resize_mode = _get_resize_mode(resize_border.get_local_mouse_position())

			if resize_mode == ResizeMode.NONE:
				return

			is_resizing = true
			resize_border.force_capture = true

			resize_start_mouse = KubuOSMetrics.snap_vector(get_global_mouse_position())
			resize_start_size = KubuOSMetrics.snap_vector(size)
			resize_start_position = KubuOSMetrics.snap_vector(position)

			window_focused.emit()
			accept_event()


func pulse() -> void:
	if _is_closing or _open_animation_pending or _is_opening or _is_geometry_transitioning:
		# A just-created window has a deferred opening presentation. Treat the
		# pending frame as part of opening too, so focus cannot start a competing
		# motion before play_open_animation() marks _is_opening.
		return

	_motion_player.flash_control(background)


func close() -> void:
	if _is_closing:
		return

	_is_closing = true
	_is_opening = false
	_open_animation_pending = false
	close_button.disabled = true
	maximize_button.disabled = true
	is_dragging = false
	is_resizing = false
	resize_border.force_capture = false
	_is_geometry_transitioning = false

	_cancel_active_motion()
	_refresh_pivot_offset()
	await _motion_player.exit_scaled_control(
		self,
		closing_scale,
		closing_offset,
		motion_profile.window_exit_duration
	)
	window_closed.emit()


func _input(event: InputEvent) -> void:
	if not is_resizing:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			is_resizing = false
			resize_mode = ResizeMode.NONE
			resize_border.force_capture = false
			position = KubuOSMetrics.snap_vector(position)
			size = KubuOSMetrics.snap_vector(size)
			window_resized.emit()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		_apply_resize_from_mouse()
		get_viewport().set_input_as_handled()


func _apply_resize_from_mouse() -> void:
	if is_maximized:
		return

	var delta: Vector2 = KubuOSMetrics.snap_vector(
		get_global_mouse_position() - resize_start_mouse
	)
	var work_rect: Rect2 = _get_work_area_rect()

	var work_left: float = work_rect.position.x
	var work_top: float = work_rect.position.y
	var work_right: float = work_rect.position.x + work_rect.size.x
	var work_bottom: float = work_rect.position.y + work_rect.size.y

	var min_width: float = min(min_window_size.x, max(1.0, work_rect.size.x))
	var min_height: float = min(min_window_size.y, max(1.0, work_rect.size.y))

	var start_left: float = resize_start_position.x
	var start_top: float = resize_start_position.y
	var start_right: float = resize_start_position.x + resize_start_size.x
	var start_bottom: float = resize_start_position.y + resize_start_size.y

	var new_left: float = start_left
	var new_top: float = start_top
	var new_right: float = start_right
	var new_bottom: float = start_bottom

	match resize_mode:
		ResizeMode.RIGHT:
			new_right = clamp(start_right + delta.x, start_left + min_width, work_right)

		ResizeMode.BOTTOM:
			new_bottom = clamp(start_bottom + delta.y, start_top + min_height, work_bottom)

		ResizeMode.BOTTOM_RIGHT:
			new_right = clamp(start_right + delta.x, start_left + min_width, work_right)
			new_bottom = clamp(start_bottom + delta.y, start_top + min_height, work_bottom)

		ResizeMode.LEFT:
			new_left = clamp(start_left + delta.x, work_left, start_right - min_width)

		ResizeMode.TOP:
			new_top = clamp(start_top + delta.y, work_top, start_bottom - min_height)

		ResizeMode.TOP_LEFT:
			new_left = clamp(start_left + delta.x, work_left, start_right - min_width)
			new_top = clamp(start_top + delta.y, work_top, start_bottom - min_height)

		ResizeMode.TOP_RIGHT:
			new_right = clamp(start_right + delta.x, start_left + min_width, work_right)
			new_top = clamp(start_top + delta.y, work_top, start_bottom - min_height)

		ResizeMode.BOTTOM_LEFT:
			new_left = clamp(start_left + delta.x, work_left, start_right - min_width)
			new_bottom = clamp(start_bottom + delta.y, start_top + min_height, work_bottom)

	position = KubuOSMetrics.snap_vector(Vector2(new_left, new_top))
	size = KubuOSMetrics.snap_vector(Vector2(
		max(min_width, new_right - new_left),
		max(min_height, new_bottom - new_top)
	))

	window_resized.emit()


func _get_work_area_rect() -> Rect2:
	var parent_node: Node = get_parent()

	if parent_node != null:
		if parent_node.has_method("get_work_area_position") and parent_node.has_method("get_work_area_size"):
			return Rect2(
				parent_node.get_work_area_position(),
				parent_node.get_work_area_size()
			)

	var parent_control: Control = get_parent() as Control

	if parent_control != null and parent_control.size.x > 0.0 and parent_control.size.y > 0.0:
		return Rect2(Vector2.ZERO, parent_control.size)

	return Rect2(Vector2.ZERO, get_viewport_rect().size)


func _refresh_pivot_offset() -> void:
	pivot_offset = size * 0.5


func _cancel_active_motion() -> void:
	if is_instance_valid(_motion_player):
		_motion_player.cancel_all()
