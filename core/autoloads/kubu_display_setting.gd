extends Node
class_name KubuDisplaySettings

enum ScaleMode {
	AUTO,
	SCALE_1X,
	SCALE_2X
}

enum DisplayMode {
	WINDOWED,
	BORDERLESS_FULLSCREEN,
	EXCLUSIVE_FULLSCREEN
}

signal display_scale_changed(scale: int, physical_size: Vector2i)
signal display_geometry_changed(
	scale: int,
	physical_size: Vector2i,
	logical_size: Vector2i,
	display_mode: DisplayMode
)

const CONFIG_PATH: String = "user://display_settings.cfg"
const MIN_PIXEL_SCALE: int = 1
const MAX_PIXEL_SCALE: int = 2

@export_category("Defaults")
@export var default_scale_mode: ScaleMode = ScaleMode.SCALE_2X
@export var default_display_mode: DisplayMode = DisplayMode.WINDOWED
@export var default_windowed_size: Vector2i = Vector2i(1280, 720)

@export_category("Logical Workspace")
@export var minimum_logical_window_size: Vector2i = Vector2i(640, 360)
@export var center_window_after_apply: bool = false

@export_category("Automatic Pixel Scale")
@export var minimum_auto_workspace: Vector2i = Vector2i(640, 360)

var current_scale_mode: ScaleMode = ScaleMode.SCALE_2X
var current_display_mode: DisplayMode = DisplayMode.WINDOWED
var current_scale: int = 2
var current_windowed_size: Vector2i = Vector2i(1280, 720)
var current_physical_size: Vector2i = Vector2i.ZERO
var current_logical_size: Vector2i = Vector2i.ZERO

var _root_window: Window
var _is_applying: bool = false
var _geometry_refresh_queued: bool = false
var _save_revision: int = 0


func _ready() -> void:
	_root_window = get_tree().root
	_load_settings()

	if not _root_window.size_changed.is_connected(_on_root_window_size_changed):
		_root_window.size_changed.connect(_on_root_window_size_changed)

	call_deferred("apply_display_settings")


func set_scale_mode(mode: ScaleMode) -> void:
	if mode < 0 or mode >= ScaleMode.size():
		push_error("KubuDisplaySettings: invalid ScaleMode %s." % mode)
		return

	current_scale_mode = mode
	_schedule_save()
	apply_display_settings()


func set_display_mode(mode: DisplayMode) -> void:
	if mode < 0 or mode >= DisplayMode.size():
		push_error("KubuDisplaySettings: invalid DisplayMode %s." % mode)
		return

	if current_display_mode == DisplayMode.WINDOWED and _root_window != null:
		current_windowed_size = _sanitize_windowed_size(_root_window.size)

	current_display_mode = mode
	_schedule_save()
	apply_display_settings()


func set_windowed_size(requested_size: Vector2i) -> void:
	current_windowed_size = _sanitize_windowed_size(requested_size)
	_schedule_save()

	if current_display_mode == DisplayMode.WINDOWED:
		apply_display_settings()


func apply_display_settings() -> void:
	if _root_window == null:
		_root_window = get_tree().root

	_is_applying = true
	current_scale = _resolve_scale()
	_apply_window_mode()
	_apply_content_scale()
	_apply_minimum_window_size()

	if current_display_mode == DisplayMode.WINDOWED:
		var target_size: Vector2i = _sanitize_windowed_size(current_windowed_size)
		_root_window.size = target_size
		current_windowed_size = target_size

		if center_window_after_apply:
			_center_window_on_current_screen(target_size)

	_is_applying = false
	_queue_geometry_refresh()


func get_current_scale() -> int:
	return current_scale


func get_current_physical_size() -> Vector2i:
	if current_physical_size != Vector2i.ZERO:
		return current_physical_size

	if _root_window != null:
		return _root_window.size

	return current_windowed_size


func get_current_logical_size() -> Vector2i:
	if current_logical_size != Vector2i.ZERO:
		return current_logical_size

	return _calculate_logical_size(
		get_current_physical_size(),
		max(MIN_PIXEL_SCALE, current_scale)
	)


func get_current_display_mode() -> DisplayMode:
	return current_display_mode


func _apply_window_mode() -> void:
	match current_display_mode:
		DisplayMode.WINDOWED:
			_root_window.mode = Window.MODE_WINDOWED
			_root_window.borderless = false
		DisplayMode.BORDERLESS_FULLSCREEN:
			_root_window.borderless = true
			_root_window.mode = Window.MODE_FULLSCREEN
		DisplayMode.EXCLUSIVE_FULLSCREEN:
			_root_window.borderless = false
			_root_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN


func _apply_content_scale() -> void:
	## O framebuffer lógico cresce e encolhe com a janela. Apenas a densidade
	## visual muda entre 1x e 2x, mantendo todos os tamanhos de UI em inteiros.
	_root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_root_window.content_scale_size = Vector2i.ZERO
	_root_window.content_scale_factor = float(current_scale)
	_root_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER


func _apply_minimum_window_size() -> void:
	if _root_window == null:
		return

	if current_display_mode != DisplayMode.WINDOWED:
		_root_window.min_size = Vector2i.ZERO
		return

	_root_window.min_size = _get_physical_minimum_window_size()


func _refresh_display_geometry() -> void:
	_geometry_refresh_queued = false

	if _root_window == null:
		return

	current_physical_size = _root_window.size
	current_scale = _resolve_scale()
	_apply_content_scale()
	_apply_minimum_window_size()
	current_logical_size = _calculate_logical_size(
		current_physical_size,
		current_scale
	)

	if current_display_mode == DisplayMode.WINDOWED:
		current_windowed_size = current_physical_size

	if KubuOSMetrics != null and KubuOSMetrics.has_method("set_display_state"):
		KubuOSMetrics.set_display_state(
			current_scale,
			current_physical_size,
			current_logical_size
		)

	display_scale_changed.emit(current_scale, current_physical_size)
	display_geometry_changed.emit(
		current_scale,
		current_physical_size,
		current_logical_size,
		current_display_mode
	)


func _queue_geometry_refresh() -> void:
	if _geometry_refresh_queued:
		return

	_geometry_refresh_queued = true
	call_deferred("_refresh_display_geometry")


func _on_root_window_size_changed() -> void:
	if _is_applying:
		return

	if current_display_mode == DisplayMode.WINDOWED and _root_window != null:
		current_windowed_size = _sanitize_windowed_size(_root_window.size)
		_schedule_save()

	_queue_geometry_refresh()


func _resolve_scale() -> int:
	match current_scale_mode:
		ScaleMode.AUTO:
			return _get_best_auto_scale_for_current_screen()
		ScaleMode.SCALE_1X:
			return 1
		ScaleMode.SCALE_2X:
			return 2

	return 2


func _get_best_auto_scale_for_current_screen() -> int:
	var screen_index: int = DisplayServer.window_get_current_screen()
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	var available_physical_size: Vector2i = usable_rect.size
	var required_for_2x := Vector2i(
		minimum_auto_workspace.x * 2,
		minimum_auto_workspace.y * 2
	)

	if (
		available_physical_size.x >= required_for_2x.x
		and available_physical_size.y >= required_for_2x.y
	):
		return 2

	return 1


func _calculate_logical_size(physical_size: Vector2i, scale: int) -> Vector2i:
	var safe_scale: int = max(MIN_PIXEL_SCALE, scale)

	return Vector2i(
		max(1, physical_size.x / safe_scale),
		max(1, physical_size.y / safe_scale)
	)


func _get_physical_minimum_window_size() -> Vector2i:
	var screen_index: int = DisplayServer.window_get_current_screen()
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	var requested := Vector2i(
		minimum_logical_window_size.x * current_scale,
		minimum_logical_window_size.y * current_scale
	)

	return Vector2i(
		min(requested.x, max(1, usable_rect.size.x)),
		min(requested.y, max(1, usable_rect.size.y))
	)


func _sanitize_windowed_size(requested_size: Vector2i) -> Vector2i:
	var minimum_size: Vector2i = _get_physical_minimum_window_size()

	return Vector2i(
		max(minimum_size.x, requested_size.x),
		max(minimum_size.y, requested_size.y)
	)


func _center_window_on_current_screen(window_size: Vector2i) -> void:
	var screen_index: int = DisplayServer.window_get_current_screen()
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	var centered_position: Vector2i = usable_rect.position + (
		(usable_rect.size - window_size) / 2
	)
	_root_window.position = centered_position


func _load_settings() -> void:
	current_scale_mode = default_scale_mode
	current_display_mode = default_display_mode
	current_scale = 2 if default_scale_mode != ScaleMode.SCALE_1X else 1
	current_windowed_size = default_windowed_size

	var config := ConfigFile.new()
	var err: Error = config.load(CONFIG_PATH)

	if err != OK:
		current_windowed_size = _sanitize_windowed_size(current_windowed_size)
		return

	var saved_scale_mode: int = int(config.get_value(
		"display",
		"scale_mode",
		int(default_scale_mode)
	))

	if saved_scale_mode >= 0 and saved_scale_mode < ScaleMode.size():
		current_scale_mode = saved_scale_mode as ScaleMode

	current_scale = _resolve_scale()

	var saved_display_mode: int = int(config.get_value(
		"display",
		"display_mode",
		int(default_display_mode)
	))

	if saved_display_mode >= 0 and saved_display_mode < DisplayMode.size():
		current_display_mode = saved_display_mode as DisplayMode

	var saved_windowed_size: Vector2i = config.get_value(
		"display",
		"windowed_size",
		default_windowed_size
	)

	current_windowed_size = _sanitize_windowed_size(saved_windowed_size)


func _schedule_save() -> void:
	_save_revision += 1
	var scheduled_revision: int = _save_revision
	_save_after_delay(scheduled_revision)


func _save_after_delay(scheduled_revision: int) -> void:
	await get_tree().create_timer(0.25).timeout

	if scheduled_revision != _save_revision:
		return

	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "scale_mode", int(current_scale_mode))
	config.set_value("display", "display_mode", int(current_display_mode))
	config.set_value("display", "windowed_size", current_windowed_size)

	var err: Error = config.save(CONFIG_PATH)

	if err != OK:
		push_error(
			"KubuDisplaySettings: failed to save settings. Error %s." % err
		)
