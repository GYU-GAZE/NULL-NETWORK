@tool
extends Resource
class_name UiMotionProfileData


@export_category("Page Motion")
@export_range(0.05, 0.4, 0.005) var page_duration: float = 0.18
@export var page_offset: Vector2 = Vector2(8, 0)

@export_category("Panel Motion")
@export_range(0.05, 0.4, 0.005) var panel_enter_duration: float = 0.18
@export_range(0.05, 0.4, 0.005) var panel_exit_duration: float = 0.12
@export var panel_offset: Vector2 = Vector2(0, 8)

@export_category("Feedback")
@export_range(0.04, 0.25, 0.005) var confirm_duration: float = 0.09
@export_range(0.0, 0.08, 0.005) var stagger_delay: float = 0.045
@export_range(1.0, 4.0, 1.0) var selection_lift_pixels: float = 2.0


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if page_duration <= 0.0:
		errors.append("page_duration must be positive.")
	if panel_enter_duration <= 0.0 or panel_exit_duration <= 0.0:
		errors.append("Panel motion durations must be positive.")
	if confirm_duration <= 0.0:
		errors.append("confirm_duration must be positive.")
	if stagger_delay < 0.0:
		errors.append("stagger_delay cannot be negative.")
	return errors
