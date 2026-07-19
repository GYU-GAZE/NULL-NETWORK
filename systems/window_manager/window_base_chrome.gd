extends "res://systems/window_manager/window_base.gd"
class_name WindowBaseChrome

signal pixel_density_changed(pixel_density: int, content_size: Vector2)

const WINDOW_PIXEL_DENSITY_1X: int = 1
const WINDOW_PIXEL_DENSITY_2X: int = 2

@export_category("Pixel Focus Feedback")
@export var focus_flash_modulate: Color = Color(1.15, 1.08, 1.25, 1.0)

@onready var visual_root: Control = %VisualRoot

var current_window_pixel_density: int = WINDOW_PIXEL_DENSITY_2X
var _visual_scale: float = 1.0
var _density_emit_queued: bool = false


func _ready() -> void:
	super._ready()
	_refresh_adaptive_pixel_density(true)


func setup(
	id: String,
	window_name: String,
	profile: WindowPresentationProfile
) -> void:
	super.setup(id, window_name, profile)
	_refresh_adaptive_pixel_density(true)


func get_current_pixel_density() -> int:
	return current_window_pixel_density


func get_visual_content_size() -> Vector2:
	if is_instance_valid(content_container):
		return KubuOSMetrics.snap_vector(content_container.size)

	return _get_internal_visual_size()


func pulse() -> void:
	if _is_closing:
		return

	_kill_animation_tween()
	top_bar.self_modulate = focus_flash_modulate

	_animation_tween = create_tween()
	_animation_tween.tween_property(
		top_bar,
		"self_modulate",
		Color.WHITE,
		focus_pulse_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_control_resized() -> void:
	_refresh_adaptive_pixel_density()
	_refresh_pivot_offset()
	_queue_presentation_changed()


func _refresh_adaptive_pixel_density(force: bool = false) -> void:
	var target_density: int = _resolve_target_pixel_density()
	var density_changed: bool = (
		force
		or target_density != current_window_pixel_density
	)

	current_window_pixel_density = target_density
	_visual_scale = KubuOSMetrics.get_window_visual_scale(
		current_window_pixel_density
	)
	_sync_visual_root_geometry()

	if density_changed:
		_queue_density_changed()

	_queue_presentation_changed()


func _resolve_target_pixel_density() -> int:
	if window_profile == null:
		return WINDOW_PIXEL_DENSITY_2X

	if not window_profile.allow_adaptive_pixel_density:
		return WINDOW_PIXEL_DENSITY_2X

	if is_maximized:
		return WINDOW_PIXEL_DENSITY_2X

	var switch_size: Vector2 = window_profile.get_scale_switch_size()
	var hysteresis: Vector2 = window_profile.get_density_hysteresis()

	if current_window_pixel_density == WINDOW_PIXEL_DENSITY_1X:
		var recovery_size: Vector2 = switch_size + hysteresis

		if size.x >= recovery_size.x and size.y >= recovery_size.y:
			return WINDOW_PIXEL_DENSITY_2X

		return WINDOW_PIXEL_DENSITY_1X

	if size.x < switch_size.x or size.y < switch_size.y:
		return WINDOW_PIXEL_DENSITY_1X

	return WINDOW_PIXEL_DENSITY_2X


func _sync_visual_root_geometry() -> void:
	if not is_instance_valid(visual_root):
		return

	var safe_scale: float = max(0.01, _visual_scale)
	visual_root.position = Vector2.ZERO
	visual_root.pivot_offset = Vector2.ZERO
	visual_root.scale = Vector2(safe_scale, safe_scale)
	visual_root.size = _get_internal_visual_size()


func _get_internal_visual_size() -> Vector2:
	return KubuOSMetrics.get_window_internal_size(
		size,
		current_window_pixel_density
	)


func _queue_density_changed() -> void:
	if _density_emit_queued:
		return

	_density_emit_queued = true
	call_deferred("_emit_density_changed")


func _emit_density_changed() -> void:
	_density_emit_queued = false

	if not is_inside_tree():
		return

	pixel_density_changed.emit(
		current_window_pixel_density,
		get_visual_content_size()
	)
