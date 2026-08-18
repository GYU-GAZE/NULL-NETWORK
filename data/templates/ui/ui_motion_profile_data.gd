@tool
extends Resource
class_name UiMotionProfileData


@export_category("Page Motion")
@export_range(0.05, 0.4, 0.005) var page_enter_duration: float = 0.18
@export_range(0.05, 0.4, 0.005) var page_exit_duration: float = 0.12
@export var page_offset: Vector2 = Vector2(8, 0)

@export_category("Panel Motion")
@export_range(0.05, 0.4, 0.005) var panel_enter_duration: float = 0.18
@export_range(0.05, 0.4, 0.005) var panel_exit_duration: float = 0.12
@export var panel_offset: Vector2 = Vector2(0, 8)

@export_category("Feedback")
@export_range(0.04, 0.25, 0.005) var button_confirm_duration: float = 0.09
@export_range(0.04, 0.25, 0.005) var reject_duration: float = 0.12
@export_range(0.0, 0.08, 0.005) var stagger_delay: float = 0.045
@export_range(1.0, 4.0, 1.0) var selection_lift_pixels: float = 2.0
@export_range(1.0, 6.0, 1.0) var reject_offset_pixels: float = 3.0

@export_category("Windows and Alerts")
@export_range(0.08, 0.3, 0.005) var window_enter_duration: float = 0.18
@export_range(0.08, 0.3, 0.005) var window_exit_duration: float = 0.14
@export_range(0.06, 0.2, 0.005) var window_focus_duration: float = 0.09
@export_range(0.08, 0.3, 0.005) var window_geometry_duration: float = 0.2
@export_range(0.08, 0.3, 0.005) var alert_enter_duration: float = 0.18
@export_range(0.08, 0.3, 0.005) var alert_exit_duration: float = 0.13

@export_category("Fades")
@export_range(0.04, 0.3, 0.005) var fade_enter_duration: float = 0.12
@export_range(0.04, 0.3, 0.005) var fade_exit_duration: float = 0.1


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if page_enter_duration <= 0.0 or page_exit_duration <= 0.0:
		errors.append("Page motion durations must be positive.")
	if panel_enter_duration <= 0.0 or panel_exit_duration <= 0.0:
		errors.append("Panel motion durations must be positive.")
	if button_confirm_duration <= 0.0 or reject_duration <= 0.0:
		errors.append("Feedback durations must be positive.")
	if window_enter_duration <= 0.0 or window_exit_duration <= 0.0:
		errors.append("Window motion durations must be positive.")
	if alert_enter_duration <= 0.0 or alert_exit_duration <= 0.0:
		errors.append("Alert motion durations must be positive.")
	if stagger_delay < 0.0:
		errors.append("stagger_delay cannot be negative.")
	return errors
