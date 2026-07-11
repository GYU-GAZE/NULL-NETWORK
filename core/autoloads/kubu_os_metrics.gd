extends Node

signal metrics_changed
signal display_state_changed(
	pixel_scale: int,
	physical_size: Vector2i,
	logical_workspace_size: Vector2i
)

@export_category("Reference Workspace")
@export var reference_workspace: Vector2 = Vector2(960, 540)

@export_category("OS Chrome — Logical Units")
@export var taskbar_height: float = 19.0
@export var dock_height: float = 86.0
@export var reserved_left_width: float = 0.0
@export var reserved_right_width: float = 0.0

@export_category("Notifications — Logical Units")
@export var notification_panel_size: Vector2 = Vector2(360, 300)
@export var notification_right_margin: float = 6.0
@export var notification_top_gap: float = 0.0

@export_category("Toast — Logical Units")
@export var toast_right_margin: float = 6.0
@export var toast_top_gap: float = 4.0
@export var toast_hidden_extra_y: float = 6.0

@export_category("Windows — Logical Units")
@export var default_window_margin: float = 0.0

var pixel_scale: int = 1
var physical_size: Vector2i = Vector2i.ZERO
var logical_workspace_size: Vector2i = Vector2i.ZERO


func set_display_state(
	new_pixel_scale: int,
	new_physical_size: Vector2i,
	new_logical_workspace_size: Vector2i
) -> void:
	var sanitized_scale: int = max(1, new_pixel_scale)
	var state_changed: bool = (
		pixel_scale != sanitized_scale
		or physical_size != new_physical_size
		or logical_workspace_size != new_logical_workspace_size
	)

	pixel_scale = sanitized_scale
	physical_size = new_physical_size
	logical_workspace_size = new_logical_workspace_size

	if not state_changed:
		return

	display_state_changed.emit(pixel_scale, physical_size, logical_workspace_size)
	metrics_changed.emit()


func get_pixel_scale() -> int:
	return pixel_scale


func get_physical_size() -> Vector2i:
	return physical_size


func get_logical_workspace_size() -> Vector2i:
	return logical_workspace_size


func get_work_area_position() -> Vector2:
	return snap_vector(Vector2(
		reserved_left_width,
		taskbar_height
	))


func get_work_area_size(parent_size: Vector2) -> Vector2:
	return snap_vector(Vector2(
		max(0.0, parent_size.x - reserved_left_width - reserved_right_width),
		max(0.0, parent_size.y - taskbar_height - dock_height)
	))


func get_work_area_rect(parent_size: Vector2) -> Rect2:
	return Rect2(
		get_work_area_position(),
		get_work_area_size(parent_size)
	)


func snap_value(value: float) -> float:
	return round(value)


func snap_vector(value: Vector2) -> Vector2:
	return Vector2(
		snap_value(value.x),
		snap_value(value.y)
	)


func logical_to_physical(value: Vector2) -> Vector2i:
	return Vector2i(
		int(round(value.x * pixel_scale)),
		int(round(value.y * pixel_scale))
	)


func physical_to_logical(value: Vector2i) -> Vector2:
	var safe_scale: float = float(max(1, pixel_scale))
	return Vector2(
		float(value.x) / safe_scale,
		float(value.y) / safe_scale
	)


func is_compact_workspace() -> bool:
	if logical_workspace_size == Vector2i.ZERO:
		return false

	return logical_workspace_size.x < 640 or logical_workspace_size.y < 360


func emit_changed() -> void:
	metrics_changed.emit()
