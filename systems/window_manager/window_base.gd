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

@export_category("Resize")
@export var border_size: float = 8.0

@export_category("Window Buttons")
@export var maximize_button_text: String = "□"
@export var restore_button_text: String = "❐"
@export var maximize_button_icon: Texture2D = preload("res://data/assets/ui/window_maximize.svg")
@export var restore_button_icon: Texture2D = preload("res://data/assets/ui/window_restore.svg")

var app_id: String = ""
var has_window_focus: bool = false

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

## Supplied by WindowManager. Standalone window fixtures use their host bounds.
var geometry_resolver: Callable
var _configured: bool = false

var _motion_player: UiMotionPlayer
var _is_opening: bool = false
var _open_animation_pending: bool = true
var _has_completed_open_animation: bool = false
var _is_closing: bool = false
var _is_geometry_transitioning: bool = false
var _geometry_revision: int = 0

@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var maximize_button: Button = %MaximizeButton
@onready var visual_root: Control = %VisualRoot
@onready var content_container: ScrollContainer = %ContentContainer
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
	resize_border.excluded_controls.assign([close_button, maximize_button])

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

	min_window_size = minimum_size.ceil().max(Vector2.ONE)
	can_resize = resize_enabled

	_configured = true
	custom_minimum_size = Vector2.ZERO
	anchors_preset = Control.PRESET_TOP_LEFT

	size = KubuOSMetrics.snap_vector(Vector2(
		max(window_size.x, min_window_size.x),
		max(window_size.y, min_window_size.y)
	))

	resize_border.visible = can_resize
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
	if _has_completed_open_animation:
		return

	_cancel_active_motion()
	_refresh_pivot_offset()
	_is_opening = true
	await _motion_player.enter_control(
		self,
		Vector2.ZERO,
		motion_profile.window_enter_duration
	)
	_finish_open_animation()


func _finish_open_animation() -> void:
	if _is_closing:
		return
	_is_opening = false
	_open_animation_pending = false
	position = KubuOSMetrics.snap_vector(position)
	scale = Vector2.ONE
	modulate = Color.WHITE
	if not _has_completed_open_animation:
		_has_completed_open_animation = true
		window_opened.emit()


func _is_activation_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE] and not _is_closing


func _request_window_focus() -> void:
	if not has_window_focus and not _is_closing:
		window_focused.emit()


func _gui_input(event: InputEvent) -> void:
	if _is_activation_click(event):
		_request_window_focus()


func _on_top_bar_gui_input(event: InputEvent) -> void:
	if _is_closing or _is_geometry_transitioning:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			if can_resize:
				toggle_maximized()
			accept_event()
			return
		if is_maximized:
			return
		_settle_opening_motion()
		is_dragging = true
		drag_offset = _control_point_in_parent(top_bar, event.position) - position
		_request_window_focus()
		accept_event()


func toggle_maximized() -> void:
	if is_maximized:
		restore_from_maximized()
	else:
		maximize()


func maximize(animated: bool = true) -> void:
	if is_maximized or _is_closing:
		return

	_settle_opening_motion()
	_request_window_focus()

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
	if not is_maximized or _is_closing:
		return

	_cancel_geometry_motion()
	_request_window_focus()
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
	_cancel_geometry_motion()
	var revision := _geometry_revision
	target_rect = resolve_geometry(target_rect)
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
		apply_resolved_geometry(target_rect)
	if revision != _geometry_revision or _is_closing:
		return
	_is_geometry_transitioning = false
	_sync_surfaces()
	_refresh_maximize_button()


func apply_maximized_geometry() -> void:
	if not is_maximized:
		return
	_cancel_geometry_motion()
	apply_resolved_geometry(resolve_geometry(Rect2(_get_maximized_position(), _get_maximized_size())))


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
		maximize_button.text = restore_button_text if restore_button_icon == null else ""
		maximize_button.icon = restore_button_icon
		maximize_button.tooltip_text = "Restore"
	else:
		maximize_button.text = maximize_button_text if maximize_button_icon == null else ""
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
	if not can_resize or is_maximized or _is_geometry_transitioning or _is_closing:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			resize_mode = _get_resize_mode(event.position)

			if resize_mode == ResizeMode.NONE:
				return

			_settle_opening_motion()
			is_dragging = false
			is_resizing = true
			resize_border.force_capture = true

			resize_start_mouse = _control_point_in_parent(resize_border, event.position)
			resize_start_size = KubuOSMetrics.snap_vector(size)
			resize_start_position = KubuOSMetrics.snap_vector(position)

			_request_window_focus()
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

	cancel_interaction()
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
	await _motion_player.exit_control(
		self,
		Vector2.ZERO,
		motion_profile.window_exit_duration
	)
	window_closed.emit()


func _input(event: InputEvent) -> void:
	# GUI controls may consume clicks before they bubble to the window root.
	# The actual hovered GUI control also excludes modal chrome and other windows.
	if _is_activation_click(event):
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and is_ancestor_of(hovered):
			_request_window_focus()
	if not is_resizing and not is_dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var was_resizing := is_resizing
		cancel_interaction()
		if was_resizing:
			window_resized.emit()
		else:
			window_moved.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var mouse := _viewport_point_in_parent(event.position)
		if is_resizing:
			_apply_resize_from_mouse(mouse)
		else:
			apply_resolved_geometry(resolve_geometry(Rect2(mouse - drag_offset, size)))
			window_moved.emit()
		get_viewport().set_input_as_handled()


func _apply_resize_from_mouse(mouse: Vector2) -> void:
	if not is_resizing or is_maximized or _is_closing:
		return
	var start := Rect2(resize_start_position, resize_start_size)
	var delta := mouse - resize_start_mouse
	# Mouse input describes an edge operation; the manager resolves its limits.
	apply_resolved_geometry(resolve_geometry(Rect2(start.position + delta, start.size), resize_mode, start))
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
	pivot_offset = (size * 0.5).floor()
	_sync_surfaces()


func _cancel_active_motion() -> void:
	if is_instance_valid(_motion_player):
		_motion_player.cancel_all()


func resolve_geometry(requested: Rect2, mode: ResizeMode = ResizeMode.NONE, start: Rect2 = Rect2()) -> Rect2:
	if geometry_resolver.is_valid():
		return geometry_resolver.call(self, requested, mode, start)
	var work := _get_work_area_rect()
	if mode != ResizeMode.NONE:
		return WindowGeometry.resize(start, requested.position - start.position, mode, min_window_size, work)
	return WindowGeometry.resolve(requested, min_window_size, work)


func apply_resolved_geometry(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	_sync_surfaces()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _configured:
		_sync_surfaces()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		cancel_interaction()


func _sync_surfaces() -> void:
	if not _configured or not is_instance_valid(visual_root):
		return
	visual_root.position = Vector2.ZERO
	visual_root.scale = Vector2.ONE
	visual_root.size = size
	resize_border.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	resize_border.position = Vector2.ZERO
	resize_border.size = size
	resize_border.border_size = border_size
	# Containers normally sort on a deferred layout pass. The app's _ready must
	# see the final viewport in this same frame, including title bar/theme margins.
	background.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var column := background.get_child(0) as Container
	column.notification(Container.NOTIFICATION_SORT_CHILDREN)
	content_container.notification(Container.NOTIFICATION_SORT_CHILDREN)


func mount_app(instance: Node) -> void:
	_sync_surfaces()
	if instance is Control:
		var control := instance as Control
		control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		control.custom_minimum_size = Vector2.ZERO
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Assign before add_child: adding to a live tree immediately runs _ready.
		control.size = content_container.size
	content_container.add_child(instance)
	content_container.notification(Container.NOTIFICATION_SORT_CHILDREN)


func _viewport_point_in_parent(point: Vector2) -> Vector2:
	var host := get_parent() as CanvasItem
	return host.get_global_transform_with_canvas().affine_inverse() * point if host != null else point


func _control_point_in_parent(control: Control, point: Vector2) -> Vector2:
	return _viewport_point_in_parent(control.get_global_transform_with_canvas() * point)


func cancel_interaction() -> void:
	is_dragging = false
	is_resizing = false
	resize_mode = ResizeMode.NONE
	if is_instance_valid(resize_border):
		resize_border.force_capture = false


func _settle_opening_motion() -> void:
	if _is_opening or _open_animation_pending:
		_cancel_active_motion()
		_finish_open_animation()


func _cancel_geometry_motion() -> void:
	_geometry_revision += 1
	cancel_interaction()
	_cancel_active_motion()
	_is_geometry_transitioning = false
	_refresh_maximize_button()


func is_closing() -> bool:
	return _is_closing
