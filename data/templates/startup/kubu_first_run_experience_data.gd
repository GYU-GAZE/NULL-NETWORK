@tool
extends Resource
class_name KubuFirstRunExperienceData


@export_category("Eligibility")
@export var completion_flag: String = "prologue.kubuchan_intro_presented"
@export var release_flag: String = "prologue.registration_unlocked"

@export_category("Browser Bootstrap")
@export var browser_app_id: String = "browser"
@export var landing_url: String = "kubuchan.net"
@export_range(0.0, 10.0, 0.05) var auto_open_delay_seconds: float = 1.8
@export_range(0.0, 2.0, 0.05) var post_open_input_delay_seconds: float = 0.25
@export var maximize_browser: bool = true

@export_category("Persistence")
@export var completion_checkpoint: StringName = &"prologue.kubuchan_intro_presented"


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if completion_flag.strip_edges().is_empty():
		errors.append("completion_flag cannot be empty.")

	if release_flag.strip_edges().is_empty():
		errors.append("release_flag cannot be empty.")

	if browser_app_id.strip_edges().is_empty():
		errors.append("browser_app_id cannot be empty.")

	if landing_url.strip_edges().is_empty():
		errors.append("landing_url cannot be empty.")

	if str(completion_checkpoint).strip_edges().is_empty():
		errors.append("completion_checkpoint cannot be empty.")

	return errors
