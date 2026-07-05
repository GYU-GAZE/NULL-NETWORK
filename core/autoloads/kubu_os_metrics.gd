extends Node

signal metrics_changed

@export_category("Base")
@export var base_resolution: Vector2 = Vector2(960, 540)

@export_category("OS Chrome")
@export var taskbar_height: float = 19.0
@export var dock_height: float = 0.0
@export var reserved_left_width: float = 0.0
@export var reserved_right_width: float = 0.0

@export_category("Notifications")
@export var notification_panel_size: Vector2 = Vector2(360, 300)
@export var notification_right_margin: float = 6.0
@export var notification_top_gap: float = 0.0

@export_category("Toast")
@export var toast_right_margin: float = 6.0
@export var toast_top_gap: float = 4.0
@export var toast_hidden_extra_y: float = 6.0

@export_category("Windows")
@export var default_window_margin: float = 0.0


func get_work_area_position() -> Vector2:
	return Vector2(
		reserved_left_width,
		taskbar_height
	)


func get_work_area_size(parent_size: Vector2) -> Vector2:
	return Vector2(
		max(0.0, parent_size.x - reserved_left_width - reserved_right_width),
		max(0.0, parent_size.y - taskbar_height - dock_height)
	)


func emit_changed() -> void:
	metrics_changed.emit()
