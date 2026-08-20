@tool
extends Resource
class_name PrologueOnboardingPresentationData


@export_category("Apps")
@export var browser_app_id: String = "browser"
@export var navigator_app_id: String = "navigator"

@export_category("World Reveal")
@export var onboarding_location_id: String = "operator_safehouse"
@export var world_revealed_flag: String = "prologue.onboarding_world_revealed"
@export_range(0.2, 4.0, 0.05) var reveal_duration_seconds: float = 1.35
@export_range(0.5, 3.0, 0.05) var reveal_end_radius: float = 1.45
@export_range(0.001, 0.1, 0.001) var reveal_feather: float = 0.012

@export_category("Persistence")
@export var completion_checkpoint: StringName = &"prologue.onboarding_world_revealed"


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if browser_app_id.strip_edges().is_empty():
		errors.append("browser_app_id cannot be empty.")
	if navigator_app_id.strip_edges().is_empty():
		errors.append("navigator_app_id cannot be empty.")
	if onboarding_location_id.strip_edges().is_empty():
		errors.append("onboarding_location_id cannot be empty.")
	if world_revealed_flag.strip_edges().is_empty():
		errors.append("world_revealed_flag cannot be empty.")
	if reveal_duration_seconds <= 0.0:
		errors.append("reveal_duration_seconds must be greater than zero.")
	if reveal_end_radius <= 0.0:
		errors.append("reveal_end_radius must be greater than zero.")
	if reveal_feather <= 0.0:
		errors.append("reveal_feather must be greater than zero.")
	if str(completion_checkpoint).strip_edges().is_empty():
		errors.append("completion_checkpoint cannot be empty.")

	return errors
