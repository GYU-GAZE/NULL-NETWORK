extends Node
class_name PixelMaterializer


@export_range(12, 160, 1) var particle_count: int = 58
@export_range(0.1, 2.0, 0.05) var duration: float = 0.72
@export var spread: Vector2 = Vector2(54.0, 38.0)
@export_range(1.0, 6.0, 1.0) var minimum_particle_size: float = 2.0
@export_range(1.0, 8.0, 1.0) var maximum_particle_size: float = 4.0

var _generation: int = 0
var _active_tween: Tween
var _spawned_particles: Array[Control] = []
var _rng := RandomNumberGenerator.new()


func materialize(
	texture: Texture2D,
	target: TextureRect,
	particle_parent: Control,
	accent_a: Color = Color(0.16, 0.78, 1.0, 1.0),
	accent_b: Color = Color(0.62, 0.34, 1.0, 1.0)
) -> void:
	_generation += 1
	var generation := _generation
	_cancel_active_effect()

	if texture == null or target == null or particle_parent == null:
		return

	_rng.seed = hash(texture.resource_path) ^ 0x4E554C4C
	target.texture = texture
	target.show()
	target.modulate = Color(1.0, 1.0, 1.0, 0.0)
	await get_tree().process_frame
	if generation != _generation or not is_instance_valid(target):
		return

	var target_rect := Rect2(target.position, target.size)
	for index: int in range(particle_count):
		var pixel := ColorRect.new()
		var pixel_size: float = roundf(_rng.randf_range(
			minimum_particle_size,
			maximum_particle_size
		))
		pixel.size = Vector2.ONE * maxf(1.0, pixel_size)
		pixel.color = accent_a if index % 2 == 0 else accent_b
		pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var target_position := Vector2(
			_rng.randf_range(target_rect.position.x, target_rect.end.x),
			_rng.randf_range(target_rect.position.y, target_rect.end.y)
		)
		pixel.position = KubuOSMetrics.snap_vector(target_position + Vector2(
			_rng.randf_range(-spread.x, spread.x),
			_rng.randf_range(-spread.y, spread.y)
		))
		pixel.set_meta("materialize_target", KubuOSMetrics.snap_vector(target_position))
		particle_parent.add_child(pixel)
		_spawned_particles.append(pixel)

	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUAD)
	_active_tween.set_ease(Tween.EASE_OUT)

	for index: int in range(_spawned_particles.size()):
		var particle := _spawned_particles[index]
		if not is_instance_valid(particle):
			continue
		var target_position: Vector2 = particle.get_meta(
			"materialize_target",
			particle.position
		)
		var delay := _rng.randf_range(0.0, duration * 0.22)
		_active_tween.tween_property(
			particle,
			"position",
			target_position,
			duration * 0.72
		).set_delay(delay)
		_active_tween.tween_property(
			particle,
			"modulate:a",
			0.0,
			duration * 0.34
		).set_delay(delay + duration * 0.42)

	_active_tween.tween_method(
		_set_target_alpha_quantized.bind(target),
		0.0,
		1.0,
		duration * 0.58
	).set_delay(duration * 0.28)

	await _active_tween.finished
	if generation != _generation or not is_instance_valid(target):
		return

	target.modulate = Color.WHITE
	_clear_particles()
	_active_tween = null


func cancel() -> void:
	_generation += 1
	_cancel_active_effect()


func _set_target_alpha_quantized(value: float, target: TextureRect) -> void:
	if not is_instance_valid(target):
		return
	var snapped_alpha: float = roundf(
		clampf(value, 0.0, 1.0) * 8.0
	) / 8.0
	target.modulate = Color(1.0, 1.0, 1.0, snapped_alpha)


func _cancel_active_effect() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	_clear_particles()


func _clear_particles() -> void:
	for particle: Control in _spawned_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	_spawned_particles.clear()
