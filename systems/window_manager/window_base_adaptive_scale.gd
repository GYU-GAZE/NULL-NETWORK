extends "res://systems/window_manager/window_base.gd"
class_name AdaptiveScaleWindowBase

signal window_pixel_density_changed(pixel_density: int, content_size: Vector2)

const PIXEL_DENSITY_1X: int = 1
const PIXEL_DENSITY_2X: int = 2

@export_category("Adaptive Pixel Density")
@export var absolute_minimum_window_size: Vector2 = Vector2(96, 12)
@export var density_hysteresis: Vector2 = Vector2(16, 12)

@onready var visual_root: Control = %VisualRoot

var scale_switch_size: Vector2 = Vector2(400, 300)
var current_window_pixel_density: int = PIXEL_DENSITY_2X
var _visual_scale: float = 1.0
var _density_emit_queued: bool = false


func _ready() -> void:
	super._ready()
	_refresh_adaptive_pixel_density(true)


func setup(
	id: String,
	window_name: String,
	window_size: Vector2,
	minimum_size: Vector2,
	resize_enabled: bool
) -> void:
	super.setup(
		id,
		window_name,
		window_size,
		minimum_size,
		resize_enabled
	)

	# O antigo mínimo do AppResource passa a ser o breakpoint 2x -> 1x.
	scale_switch_size = KubuOSMetrics.snap_vector(Vector2(
		max(1.0, minimum_size.x),
		max(1.0, minimum_size.y)
	))

	# Este é o único limite rígido da geometria externa da janela.
	min_window_size = KubuOSMetrics.snap_vector(Vector2(
		max(1.0, absolute_minimum_window_size.x),
		max(1.0, absolute_minimum_window_size.y)
	))

	size = KubuOSMetrics.snap_vector(Vector2(
		max(size.x, min_window_size.x),
		max(size.y, min_window_size.y)
	))

	_refresh_adaptive_pixel_density(true)


func get_current_window_pixel_density() -> int:
	return current_window_pixel_density


func get_visual_content_size() -> Vector2:
	if is_instance_valid(content_container):
		return KubuOSMetrics.snap_vector(content_container.size)

	return _get_internal_visual_size()


func _refresh_pivot_offset() -> void:
	super._refresh_pivot_offset()
	_refresh_adaptive_pixel_density()


func _refresh_adaptive_pixel_density(force: bool = false) -> void:
	if not is_instance_valid(visual_root):
		return

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


func _resolve_target_pixel_density() -> int:
	if is_maximized:
		return PIXEL_DENSITY_2X

	if current_window_pixel_density == PIXEL_DENSITY_1X:
		var recovery_size: Vector2 = scale_switch_size + Vector2(
			max(0.0, density_hysteresis.x),
			max(0.0, density_hysteresis.y)
		)

		if size.x >= recovery_size.x and size.y >= recovery_size.y:
			return PIXEL_DENSITY_2X

		return PIXEL_DENSITY_1X

	if size.x < scale_switch_size.x or size.y < scale_switch_size.y:
		return PIXEL_DENSITY_1X

	return PIXEL_DENSITY_2X


func _sync_visual_root_geometry() -> void:
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

	window_pixel_density_changed.emit(
		current_window_pixel_density,
		get_visual_content_size()
	)
