extends "res://systems/window_manager/window_base.gd"
class_name AdaptiveScaleWindowBase

signal window_pixel_density_changed(pixel_density: int, content_size: Vector2)

const PIXEL_DENSITY_1X: int = 1
const PIXEL_DENSITY_2X: int = 2
const FIT_EPSILON: float = 0.5

@export_category("Adaptive Pixel Density")
@export var absolute_minimum_window_size: Vector2 = Vector2(96, 12)
@export var density_hysteresis: Vector2 = Vector2(16, 12)

@export_category("Adaptive Resize Hit Area")
@export var minimum_resize_border_size: float = 2.0

@onready var visual_root: Control = %VisualRoot

var current_window_pixel_density: int = PIXEL_DENSITY_2X
var _visual_scale: float = 1.0
var _density_emit_queued: bool = false
var _fit_validation_queued: bool = false
var _configured_resize_border_size: float = 8.0
var _is_configured: bool = false

var _app_content_root: Control
var _required_2x_window_size: Vector2 = Vector2.ZERO
var _blocked_2x_axes: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_configured_resize_border_size = max(1.0, border_size)
	super._ready()

	if not content_container.child_order_changed.is_connected(
		_on_content_children_changed
	):
		content_container.child_order_changed.connect(
			_on_content_children_changed
		)

	call_deferred("_bind_current_content_root")


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

	# O limite rígido da geometria externa é independente do conteúdo.
	# A troca 2x -> 1x é resolvida depois, medindo o layout renderizado.
	min_window_size = KubuOSMetrics.snap_vector(Vector2(
		max(1.0, absolute_minimum_window_size.x),
		max(1.0, absolute_minimum_window_size.y)
	))

	size = KubuOSMetrics.snap_vector(Vector2(
		max(size.x, min_window_size.x),
		max(size.y, min_window_size.y)
	))

	_is_configured = true
	_refresh_adaptive_pixel_density(true)


func get_current_window_pixel_density() -> int:
	return current_window_pixel_density


func get_visual_content_size() -> Vector2:
	if is_instance_valid(content_container):
		return KubuOSMetrics.snap_vector(content_container.size)

	return _get_internal_visual_size()


func _refresh_pivot_offset() -> void:
	super._refresh_pivot_offset()

	if _is_configured:
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
	_sync_resize_border_hit_area()

	if current_window_pixel_density == PIXEL_DENSITY_2X:
		_queue_2x_fit_validation()

	if density_changed:
		_queue_density_changed()


func _resolve_target_pixel_density() -> int:
	if is_maximized:
		return PIXEL_DENSITY_2X

	if current_window_pixel_density == PIXEL_DENSITY_1X:
		if _has_recovered_2x_space():
			return PIXEL_DENSITY_2X

		return PIXEL_DENSITY_1X

	return PIXEL_DENSITY_2X


func _has_recovered_2x_space() -> bool:
	if _blocked_2x_axes == Vector2i.ZERO:
		return true

	if (
		_blocked_2x_axes.x != 0
		and size.x
		< _required_2x_window_size.x
		+ max(0.0, density_hysteresis.x)
	):
		return false

	if (
		_blocked_2x_axes.y != 0
		and size.y
		< _required_2x_window_size.y
		+ max(0.0, density_hysteresis.y)
	):
		return false

	return true


func _sync_visual_root_geometry() -> void:
	var safe_scale: float = max(0.01, _visual_scale)

	visual_root.position = Vector2.ZERO
	visual_root.pivot_offset = Vector2.ZERO
	visual_root.scale = Vector2(safe_scale, safe_scale)
	visual_root.size = _get_internal_visual_size()


func _sync_resize_border_hit_area() -> void:
	# ResizeBorder é irmão do VisualRoot e permanece no espaço externo da janela.
	# A compensação mantém a área clicável alinhada à UI em 1x e em 2x.
	var scaled_border_size: float = round(
		_configured_resize_border_size * _visual_scale
	)
	var resolved_border_size: float = max(
		minimum_resize_border_size,
		scaled_border_size
	)

	border_size = resolved_border_size

	if is_instance_valid(resize_border):
		resize_border.border_size = resolved_border_size


func _get_internal_visual_size() -> Vector2:
	return KubuOSMetrics.get_window_internal_size(
		size,
		current_window_pixel_density
	)


func _on_content_children_changed() -> void:
	call_deferred("_bind_current_content_root")


func _bind_current_content_root() -> void:
	var new_content_root: Control

	for child in content_container.get_children():
		if child is Control:
			new_content_root = child as Control
			break

	if _app_content_root == new_content_root:
		_queue_2x_fit_validation()
		return

	if (
		is_instance_valid(_app_content_root)
		and _app_content_root.minimum_size_changed.is_connected(
			_on_app_minimum_size_changed
		)
	):
		_app_content_root.minimum_size_changed.disconnect(
			_on_app_minimum_size_changed
		)

	_app_content_root = new_content_root

	if (
		is_instance_valid(_app_content_root)
		and not _app_content_root.minimum_size_changed.is_connected(
			_on_app_minimum_size_changed
		)
	):
		_app_content_root.minimum_size_changed.connect(
			_on_app_minimum_size_changed
		)

	_queue_2x_fit_validation()


func _on_app_minimum_size_changed() -> void:
	_queue_2x_fit_validation()


func _queue_2x_fit_validation() -> void:
	if _fit_validation_queued:
		return

	_fit_validation_queued = true
	call_deferred("_validate_2x_fit_after_layout")


func _validate_2x_fit_after_layout() -> void:
	# Containers atualizam seus filhos de forma adiada. Esperar um frame garante
	# que a medição use o layout final, não o tamanho da frame anterior.
	await get_tree().process_frame
	_fit_validation_queued = false

	if not is_inside_tree():
		return

	if current_window_pixel_density != PIXEL_DENSITY_2X:
		return

	if is_maximized or not is_instance_valid(_app_content_root):
		return

	var minimum_deficit: Vector2 = _measure_minimum_size_deficit(
		_app_content_root
	)
	var blocked_axes := Vector2i(
		1 if minimum_deficit.x > FIT_EPSILON else 0,
		1 if minimum_deficit.y > FIT_EPSILON else 0
	)

	if blocked_axes == Vector2i.ZERO:
		_required_2x_window_size = Vector2.ZERO
		_blocked_2x_axes = Vector2i.ZERO
		return

	_required_2x_window_size = KubuOSMetrics.snap_vector(
		size + minimum_deficit
	)
	_blocked_2x_axes = blocked_axes

	current_window_pixel_density = PIXEL_DENSITY_1X
	_refresh_adaptive_pixel_density(true)


func _measure_minimum_size_deficit(control: Control) -> Vector2:
	if not control.visible:
		return Vector2.ZERO

	var combined_minimum: Vector2 = control.get_combined_minimum_size()
	var largest_deficit := Vector2(
		max(0.0, combined_minimum.x - control.size.x),
		max(0.0, combined_minimum.y - control.size.y)
	)

	for child in control.get_children():
		if not child is Control:
			continue

		var child_deficit: Vector2 = _measure_minimum_size_deficit(
			child as Control
		)
		largest_deficit.x = max(
			largest_deficit.x,
			child_deficit.x
		)
		largest_deficit.y = max(
			largest_deficit.y,
			child_deficit.y
		)

	return largest_deficit


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
