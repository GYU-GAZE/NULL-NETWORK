@tool
extends Resource
class_name KubuShellPresentationData


@export_category("First Run Reveal")
@export_range(0.05, 2.0, 0.01) var first_run_top_seconds: float = 0.48
@export_range(0.05, 2.0, 0.01) var first_run_bottom_seconds: float = 0.44
@export_range(0.0, 1.0, 0.01) var first_run_gap_seconds: float = 0.10
@export_range(0.0, 1.0, 0.01) var first_run_settle_seconds: float = 0.14
@export_range(0.01, 1.0, 0.01) var first_run_top_hidden_scale_y: float = 0.08
@export var first_run_bottom_hidden_scale: Vector2 = Vector2(0.76, 0.76)

@export_category("Day Start Reveal")
@export_range(0.05, 1.0, 0.01) var day_start_seconds: float = 0.26
@export_range(0.01, 1.0, 0.01) var day_start_top_hidden_scale_y: float = 0.30
@export var day_start_bottom_hidden_scale: Vector2 = Vector2(0.86, 0.86)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if first_run_top_seconds <= 0.0:
		errors.append("first_run_top_seconds must be greater than zero.")
	if first_run_bottom_seconds <= 0.0:
		errors.append("first_run_bottom_seconds must be greater than zero.")
	if day_start_seconds <= 0.0:
		errors.append("day_start_seconds must be greater than zero.")
	if first_run_gap_seconds < 0.0 or first_run_settle_seconds < 0.0:
		errors.append("First-run reveal pauses cannot be negative.")
	if first_run_top_hidden_scale_y <= 0.0 or first_run_top_hidden_scale_y > 1.0:
		errors.append("first_run_top_hidden_scale_y must be in the 0..1 range.")
	if day_start_top_hidden_scale_y <= 0.0 or day_start_top_hidden_scale_y > 1.0:
		errors.append("day_start_top_hidden_scale_y must be in the 0..1 range.")
	if (
		first_run_bottom_hidden_scale.x <= 0.0
		or first_run_bottom_hidden_scale.y <= 0.0
		or first_run_bottom_hidden_scale.x > 1.0
		or first_run_bottom_hidden_scale.y > 1.0
	):
		errors.append("first_run_bottom_hidden_scale components must be in the 0..1 range.")
	if (
		day_start_bottom_hidden_scale.x <= 0.0
		or day_start_bottom_hidden_scale.y <= 0.0
		or day_start_bottom_hidden_scale.x > 1.0
		or day_start_bottom_hidden_scale.y > 1.0
	):
		errors.append("day_start_bottom_hidden_scale components must be in the 0..1 range.")

	return errors
