extends Control
class_name WindowBase

signal window_closed
signal window_focused
signal window_moved
signal window_resized
signal presentation_changed(state: int, content_size: Vector2)

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

enum PresentationState {
	COMPACT,
	PREFERRED,
	CUSTOM,
	MAXIMIZED
}

@export_category("Window Animation")
@export var tween_duration: float = 0.25
@export var opening_scale: Vector2 = Vector2(0.8, 0.8)
@export var focus_scale: Vector2 = Vector2(1.02, 1.02)
@export var closing_scale: Vector2 = Vector2(0.8, 0.8)
@export var focus_pulse_duration: float = 0.1

@export_category("Resize")
@export var border_size: float = 8.0

@export_category("Window Buttons")
@export var compact_button_text: String = "C"
@export var preferred_button_text: String = "P"
@export var maximize_button_text: String = "M"
@export var restore_button_text: String = "R"
@export var maximize_button_icon: Texture2D
@export var restore_button_icon: Texture2D

var app_id: String = ""
var window_profile: WindowPresentationProfile

var presentation_state: PresentationState = PresentationState.CUSTOM
var restore_presentation_state: PresentationState = PresentationState.PREFERRED

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

var _animation_tween: Tween
var _is_closing: bool = false
var _presentation_emit_queued: bool = false

@onready var title_label: Label = %TitleLabel
@onready var compact_button: Button = %CompactButton
@onready var preferred_button: Button = %PreferredButton
@onready var maximize_button: Button = %MaximizeButton
@onready var close_button: Button = %CloseButton
@onready var content_container: MarginContainer = %ContentContainer
@onready var top_bar: Control = %TopBar
@onready var resize_border: ResizeBorder = %ResizeBorder


func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_LEFT

	compact_button.pressed.connect(apply_compact)
	preferred_button.pressed.connect(apply_preferred)
	maximize_button.pressed.connect(toggle_maximized)
	close_button.pressed.connect(close)
	top_bar.gui_input.connect(_on_top_bar_gui_input)
	resize_border.gui_input.connect(_on_resize_border_gui_input)

	if not resized.is_connected(_on_control_resized):
		resized.connect(_on_control_resized)

	_refresh_presentation_buttons()
	call_deferred("play_open_animation")


func setup(
	id: String,
	window_name: String,
	profile: WindowPresentationProfile
) -> void:
	app_id = id
	title_label.text = window_name

	window_profile = profile
	if window_profile == null:
		window_profile = WindowPresentationProfile.new()

	min_window_size = KubuOSMetrics.snap_vector(window_profile.get_minimum_size())
	can_resize = window_profile.allow_manual_resize

	custom_minimum_size = Vector2.ZERO
	anchors_preset = Control.PRESET_TOP_LEFT

	presentation_state = _get_initial_presentation_state()
	restore_presentation_state = presentation_state
	size = KubuOSMetrics.snap_vector(window_profile.get_initial_size())

	resize_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resize_border.border_size = border_size

	_refresh_pivot_offset()
	_refresh_presentation_buttons()
	_queue_presentation_changed()


func get_initial_presentation_state() -> PresentationState:
	return _get_initial_presentation_state()


func get_compact_size() -> Vector2:
	return KubuOSMetrics.snap_vector(window_profile.get_compact_size())


func get_preferred_size() -> Vector2:
	return KubuOSMetrics.snap_vector(window_profile.get_preferred_size())


func supports_compact() -> bool:
	return window_profile != null and window_profile.allow_compact


func supports_preferred() -> bool:
	return window_profile != null and window_profile.allow_preferred


func supports_maximized() -> bool:
	return window_profile != null and window_profile.allow_maximized


func apply_restored_geometry(
	new_position: Vector2,
	new_size: Vector2,
	new_state: int,
	should_maximize: bool = false,
	saved_restore_state: int = PresentationState.PREFERRED
) -> void:
	is_maximized = false
	position = KubuOSMetrics.snap_vector(new_position)
	size = KubuOSMetrics.snap_vector(Vector2(
		max(min_window_size.x, new_size.x),
		max(min_window_size.y, new_size.y)
	))
	presentation_state = _sanitize_presentation_state(new_state)
	restore_presentation_state = _sanitize_presentation_state(saved_restore_state)

	if should_maximize and supports_maximized():
		restore_position = position
		restore_size = size
		if restore_presentation_state == PresentationState.MAXIMIZED:
			restore_presentation_state = PresentationState.PREFERRED
		is_maximized = true
		presentation_state = PresentationState.MAXIMIZED
		apply_maximized_geometry()

	_refresh_presentation_buttons()
	_queue_presentation_changed()


func play_open_animation() -> void:
	if _is_closing:
		return

	_kill_animation_tween()
	_refresh_pivot_offset()

	scale = opening_scale
	modulate = Color(1.0, 1.0, 1.0, 0.0)

	_animation_tween = create_tween().set_parallel(true)
	_animation_tween.tween_property(self, "scale", Vector2.ONE, tween_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(self, "modulate:a", 1.0, tween_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		window_focused.emit()


func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and supports_maximized():
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


func apply_compact() -> void:
	if not supports_compact():
		return

	_apply_preset(PresentationState.COMPACT, get_compact_size())


func apply_preferred() -> void:
	if not supports_preferred():
		return

	_apply_preset(PresentationState.PREFERRED, get_preferred_size())


func _apply_preset(state: PresentationState, target_size: Vector2) -> void:
	window_focused.emit()

	var source_rect := Rect2(position, size)
	if is_maximized:
		source_rect = Rect2(restore_position, restore_size)
		is_maximized = false

	var center: Vector2 = source_rect.position + (source_rect.size * 0.5)
	size = KubuOSMetrics.snap_vector(Vector2(
		max(min_window_size.x, target_size.x),
		max(min_window_size.y, target_size.y)
	))
	position = KubuOSMetrics.snap_vector(center - (size * 0.5))
	presentation_state = state
	restore_presentation_state = state

	_refresh_presentation_buttons()
	window_moved.emit()
	window_resized.emit()
	_queue_presentation_changed()


func toggle_maximized() -> void:
	if not supports_maximized():
		return

	if is_maximized:
		restore_from_maximized()
	else:
		maximize()


func maximize() -> void:
	if is_maximized or not supports_maximized():
		return

	window_focused.emit()

	restore_position = KubuOSMetrics.snap_vector(position)
	restore_size = KubuOSMetrics.snap_vector(size)
	restore_presentation_state = presentation_state

	is_dragging = false
	is_resizing = false
	resize_mode = ResizeMode.NONE
	resize_border.force_capture = false

	is_maximized = true
	presentation_state = PresentationState.MAXIMIZED
	apply_maximized_geometry()

	_refresh_presentation_buttons()
	window_moved.emit()
	window_resized.emit()
	_queue_presentation_changed()


func restore_from_maximized() -> void:
	if not is_maximized:
		return

	window_focused.emit()
	is_maximized = false
	presentation_state = restore_presentation_state

	position = KubuOSMetrics.snap_vector(restore_position)
	size = KubuOSMetrics.snap_vector(Vector2(
		max(restore_size.x, min_window_size.x),
		max(restore_size.y, min_window_size.y)
	))

	_refresh_presentation_buttons()
	window_moved.emit()
	window_resized.emit()
	_queue_presentation_changed()


func apply_maximized_geometry() -> void:
	if not is_maximized:
		return

	position = KubuOSMetrics.snap_vector(_get_maximized_position())
	size = KubuOSMetrics.snap_vector(_get_maximized_size())
	_refresh_pivot_offset()
	_queue_presentation_changed()


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


func _refresh_presentation_buttons() -> void:
	if not is_instance_valid(compact_button):
		return

	compact_button.text = compact_button_text
	compact_button.tooltip_text = "Compact"
	compact_button.visible = supports_compact()
	compact_button.disabled = presentation_state == PresentationState.COMPACT

	preferred_button.text = preferred_button_text
	preferred_button.tooltip_text = "Preferred size"
	preferred_button.visible = supports_preferred()
	preferred_button.disabled = presentation_state == PresentationState.PREFERRED

	maximize_button.visible = supports_maximized()
	maximize_button.disabled = not supports_maximized()

	if is_maximized:
		maximize_button.text = restore_button_text
		maximize_button.icon = restore_button_icon
		maximize_button.tooltip_text = "Restore"
	else:
		maximize_button.text = maximize_button_text
		maximize_button.icon = maximize_button_icon
		maximize_button.tooltip_text = "Maximize"

	resize_border.visible = can_resize and not is_maximized


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
	if not can_resize or is_maximized:
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
	if _is_closing:
		return

	_kill_animation_tween()
	_refresh_pivot_offset()

	if not scale.is_equal_approx(Vector2.ONE):
		scale = Vector2.ONE

	_animation_tween = create_tween()
	_animation_tween.tween_property(self, "scale", focus_scale, focus_pulse_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(self, "scale", Vector2.ONE, focus_pulse_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)


func close() -> void:
	if _is_closing:
		return

	_is_closing = true
	compact_button.disabled = true
	preferred_button.disabled = true
	maximize_button.disabled = true
	close_button.disabled = true
	is_dragging = false
	is_resizing = false
	resize_border.force_capture = false

	_kill_animation_tween()
	_refresh_pivot_offset()

	_animation_tween = create_tween().set_parallel(true)
	_animation_tween.tween_property(self, "scale", closing_scale, tween_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	_animation_tween.tween_property(self, "modulate:a", 0.0, tween_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	_animation_tween.chain().tween_callback(window_closed.emit)


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
			presentation_state = PresentationState.CUSTOM
			restore_presentation_state = PresentationState.CUSTOM
			_refresh_presentation_buttons()
			window_resized.emit()
			_queue_presentation_changed()
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
	_queue_presentation_changed()


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


func _get_initial_presentation_state() -> PresentationState:
	if window_profile == null:
		return PresentationState.PREFERRED

	match window_profile.initial_presentation:
		WindowPresentationProfile.InitialPresentation.COMPACT:
			return PresentationState.COMPACT
		WindowPresentationProfile.InitialPresentation.PREFERRED:
			return PresentationState.PREFERRED
		WindowPresentationProfile.InitialPresentation.MAXIMIZED:
			return PresentationState.MAXIMIZED

	return PresentationState.PREFERRED


func _sanitize_presentation_state(value: int) -> PresentationState:
	if value < 0 or value >= PresentationState.size():
		return PresentationState.CUSTOM

	return value as PresentationState


func _on_control_resized() -> void:
	_refresh_pivot_offset()
	_queue_presentation_changed()


func _queue_presentation_changed() -> void:
	if _presentation_emit_queued:
		return

	_presentation_emit_queued = true
	call_deferred("_emit_presentation_changed")


func _emit_presentation_changed() -> void:
	_presentation_emit_queued = false

	if not is_inside_tree():
		return

	var content_size: Vector2 = size
	if is_instance_valid(content_container):
		content_size = content_container.size

	presentation_changed.emit(int(presentation_state), KubuOSMetrics.snap_vector(content_size))


func _refresh_pivot_offset() -> void:
	pivot_offset = size * 0.5


func _kill_animation_tween() -> void:
	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()

	_animation_tween = null
