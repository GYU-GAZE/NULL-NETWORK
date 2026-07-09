extends Node
class_name KubuDisplaySettings

signal display_scale_changed(scale: int, physical_size: Vector2i)

enum ScaleMode {
	AUTO,
	SCALE_1X,
	SCALE_2X,
	SCALE_3X,
	SCALE_4X
}

const CONFIG_PATH: String = "user://display_settings.cfg"

@export var base_resolution: Vector2i = Vector2i(960, 540)
@export var default_scale_mode: ScaleMode = ScaleMode.SCALE_2X
@export var max_auto_scale: int = 4
@export var center_window_after_apply: bool = true

var current_scale_mode: ScaleMode = ScaleMode.SCALE_2X
var current_scale: int = 2


func _ready() -> void:
	_load_settings()
	call_deferred("apply_display_settings")


func set_scale_mode(mode: ScaleMode) -> void:
	current_scale_mode = mode
	_save_settings()
	apply_display_settings()


func apply_display_settings() -> void:
	var root_window: Window = get_tree().root

	root_window.content_scale_size = base_resolution
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER

	current_scale = _resolve_scale()
	var physical_size := Vector2i(
		base_resolution.x * current_scale,
		base_resolution.y * current_scale
	)

	root_window.size = physical_size

	if center_window_after_apply:
		_center_root_window(root_window, physical_size)

	display_scale_changed.emit(current_scale, physical_size)


func get_current_scale() -> int:
	return current_scale


func get_current_physical_size() -> Vector2i:
	return Vector2i(
		base_resolution.x * current_scale,
		base_resolution.y * current_scale
	)


func _resolve_scale() -> int:
	match current_scale_mode:
		ScaleMode.AUTO:
			return _get_best_auto_scale()

		ScaleMode.SCALE_1X:
			return 1

		ScaleMode.SCALE_2X:
			return 2

		ScaleMode.SCALE_3X:
			return 3

		ScaleMode.SCALE_4X:
			return 4

	return 2


func _get_best_auto_scale() -> int:
	var screen_index := DisplayServer.window_get_current_screen()
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	var usable_size: Vector2i = usable_rect.size

	var best_scale := 1

	for scale in range(1, max_auto_scale + 1):
		var candidate_size := Vector2i(
			base_resolution.x * scale,
			base_resolution.y * scale
		)

		if candidate_size.x <= usable_size.x and candidate_size.y <= usable_size.y:
			best_scale = scale

	return best_scale


func _center_root_window(root_window: Window, physical_size: Vector2i) -> void:
	var screen_index := DisplayServer.window_get_current_screen()
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)

	var centered_position := usable_rect.position + Vector2i(
		int((usable_rect.size.x - physical_size.x) * 0.5),
		int((usable_rect.size.y - physical_size.y) * 0.5)
	)

	root_window.position = centered_position


func _load_settings() -> void:
	current_scale_mode = default_scale_mode

	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err != OK:
		return

	var saved_mode: int = int(config.get_value(
		"display",
		"scale_mode",
		int(default_scale_mode)
	))

	if saved_mode < 0 or saved_mode >= ScaleMode.size():
		current_scale_mode = default_scale_mode
		return

	current_scale_mode = saved_mode as ScaleMode


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "scale_mode", int(current_scale_mode))
	config.save(CONFIG_PATH)
