extends Control
class_name StartupPresentation


signal boot_completed


@export var presentation_data: StartupPresentationData

@onready var backdrop_clip: Control = %BackdropClip
@onready var backdrop_root: Control = %BackdropRoot
@onready var backdrop_color: ColorRect = %BackdropColor
@onready var backdrop_texture: TextureRect = %BackdropTexture
@onready var splash_layer: Control = %SplashLayer
@onready var splash_background: ColorRect = %SplashBackground
@onready var splash_content: Control = %SplashContent
@onready var splash_logo: TextureRect = %SplashLogo
@onready var splash_fallback: Label = %SplashFallback
@onready var boot_layer: Control = %BootLayer
@onready var boot_logo_anchor: Control = %BootLogoAnchor
@onready var boot_logo: TextureRect = %BootLogo
@onready var boot_fallback: Label = %BootFallback
@onready var null_brand_anchor: Control = %NullBrandAnchor
@onready var null_logo_root: Control = %NullLogoRoot
@onready var null_logo_texture: TextureRect = %NullLogoTexture
@onready var null_logo_texture_ghost_a: TextureRect = %NullLogoTextureGhostA
@onready var null_logo_texture_ghost_b: TextureRect = %NullLogoTextureGhostB
@onready var null_logo_label: Label = %NullLogoLabel
@onready var null_logo_label_ghost_a: Label = %NullLogoLabelGhostA
@onready var null_logo_label_ghost_b: Label = %NullLogoLabelGhostB
@onready var pixel_field: Control = %PixelField
@onready var power_line: ColorRect = %PowerLine
@onready var screen_flash: ColorRect = %ScreenFlash
@onready var skip_hint: Label = %SkipHint

var _active_tween: Tween
var _glitch_tween: Tween
var _is_playing: bool = false
var _parallax_enabled: bool = false
var _backdrop_base_position: Vector2 = Vector2.ZERO
var _backdrop_parallax_offset: Vector2 = Vector2.ZERO
var _current_period: int = TimeManager.TimePeriod.DAY
var _glitch_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 0x4E554C4C
	set_process(false)
	_reset_visual_state()

	if get_viewport() != null and not get_viewport().size_changed.is_connected(
		_on_viewport_size_changed
	):
		get_viewport().size_changed.connect(_on_viewport_size_changed)


func play(period: int = TimeManager.TimePeriod.DAY) -> void:
	if _is_playing:
		return

	if presentation_data == null:
		push_error("StartupPresentation requires StartupPresentationData.")
		boot_completed.emit()
		return

	_is_playing = true
	_parallax_enabled = false
	set_process(false)
	show()
	_set_backdrop_period(period)
	await get_tree().process_frame
	_layout_backdrop()
	_layout_boot_logo_centered()
	_layout_null_brand_above_boot_logo()
	_apply_static_styling()
	_configure_kubuos_logo()
	_configure_null_brand()
	await _play_custom_splashes()
	await _play_kubuos_boot()
	_active_tween = null
	_is_playing = false
	_parallax_enabled = true
	_schedule_next_glitch()
	set_process(true)
	skip_hint.hide()
	boot_completed.emit()


func stop_and_hide() -> void:
	_is_playing = false
	_parallax_enabled = false
	set_process(false)
	_kill_active_tweens()
	hide()


func show_login_state(period: int = TimeManager.TimePeriod.DAY) -> void:
	# Logout returns directly to the already-booted KubuOS login surface. The
	# final boot composition is restored without replaying studio/Godot splashes.
	_is_playing = false
	_parallax_enabled = false
	set_process(false)
	_kill_active_tweens()

	show()
	_set_backdrop_period(period)
	_apply_static_styling()
	_configure_kubuos_logo()
	_configure_null_brand()
	await get_tree().process_frame
	_layout_backdrop()
	boot_layer.show()
	splash_layer.hide()
	backdrop_clip.modulate.a = 1.0
	boot_logo_anchor.modulate.a = 1.0
	boot_logo_anchor.position = _get_boot_logo_target_position()
	boot_logo_anchor.scale = Vector2.ONE * presentation_data.logo_target_scale
	null_brand_anchor.position = _get_null_brand_target_position()
	null_brand_anchor.scale = Vector2.ONE * presentation_data.null_logo_target_scale
	null_brand_anchor.modulate.a = 1.0
	null_logo_root.modulate.a = 1.0
	_clear_null_pixels()
	_reset_logo_glitch()
	power_line.modulate.a = 0.0
	screen_flash.modulate.a = 0.0
	skip_hint.hide()
	_backdrop_parallax_offset = Vector2.ZERO
	backdrop_root.position = _backdrop_base_position
	_parallax_enabled = true
	_schedule_next_glitch()
	set_process(true)


func _input(event: InputEvent) -> void:
	if not _is_playing:
		return

	var should_accelerate: bool = false

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		should_accelerate = mouse_event.pressed
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		should_accelerate = key_event.pressed and not key_event.echo

	if not should_accelerate:
		return

	if _active_tween != null and _active_tween.is_valid():
		_active_tween.set_speed_scale(
			maxf(1.0, presentation_data.skip_speed_multiplier)
		)

	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _parallax_enabled or presentation_data == null:
		return

	_update_backdrop_parallax(delta)
	_glitch_timer -= delta

	if _glitch_timer <= 0.0:
		_play_logo_glitch()
		_schedule_next_glitch()


func _update_backdrop_parallax(delta: float) -> void:
	var viewport_size: Vector2 = size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var normalized := Vector2(
		clampf((mouse_position.x / viewport_size.x) * 2.0 - 1.0, -1.0, 1.0),
		clampf((mouse_position.y / viewport_size.y) * 2.0 - 1.0, -1.0, 1.0)
	)
	var target_offset := Vector2(
		normalized.x * presentation_data.mouse_parallax_pixels.x,
		normalized.y * presentation_data.mouse_parallax_pixels.y
	)
	var follow_weight: float = 1.0 - exp(
		-presentation_data.parallax_follow_speed * delta
	)
	_backdrop_parallax_offset = _backdrop_parallax_offset.lerp(
		target_offset,
		follow_weight
	)
	backdrop_root.position = _backdrop_base_position + _backdrop_parallax_offset


func _play_custom_splashes() -> void:
	splash_layer.show()
	boot_layer.hide()
	backdrop_clip.modulate.a = 0.0

	for splash: StartupSplashData in presentation_data.splashes:
		if splash == null:
			continue

		_configure_splash(splash)
		splash_content.modulate.a = 0.0
		_active_tween = create_tween()
		_active_tween.set_trans(Tween.TRANS_QUAD)
		_active_tween.set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(
			splash_content,
			"modulate:a",
			1.0,
			splash.fade_in_seconds
		)
		_active_tween.tween_interval(splash.hold_seconds)
		_active_tween.set_ease(Tween.EASE_IN)
		_active_tween.tween_property(
			splash_content,
			"modulate:a",
			0.0,
			splash.fade_out_seconds
		)
		await _active_tween.finished

	splash_layer.hide()


func _play_kubuos_boot() -> void:
	boot_layer.show()
	skip_hint.show()
	_layout_boot_logo_centered()
	_layout_null_brand_above_boot_logo()
	_configure_kubuos_logo()
	_configure_null_brand()

	boot_logo_anchor.modulate.a = 0.0
	boot_logo_anchor.scale = Vector2(0.94, 0.94)
	boot_logo_anchor.pivot_offset = boot_logo_anchor.size * 0.5
	null_brand_anchor.modulate.a = 1.0
	null_brand_anchor.scale = Vector2(0.96, 0.96)
	null_brand_anchor.pivot_offset = null_brand_anchor.size * 0.5
	null_logo_root.modulate.a = 0.0
	_reset_logo_glitch()
	var particles: Array[Control] = _spawn_null_boot_particles()

	power_line.scale = Vector2(0.0, 1.0)
	power_line.modulate.a = 1.0
	power_line.pivot_offset = power_line.size * 0.5
	screen_flash.modulate.a = 0.0
	backdrop_clip.modulate.a = 0.0

	var intro_distance: float = size.y * presentation_data.background_intro_pan_ratio
	backdrop_root.position = _backdrop_base_position + Vector2(0.0, -intro_distance)

	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUAD)
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(
		boot_logo_anchor,
		"modulate:a",
		1.0,
		presentation_data.logo_ignite_seconds
	)
	_active_tween.tween_property(
		boot_logo_anchor,
		"scale",
		Vector2.ONE,
		presentation_data.logo_ignite_seconds
	)
	_active_tween.tween_property(
		null_logo_root,
		"modulate:a",
		1.0,
		presentation_data.null_logo_build_seconds
	)
	_active_tween.tween_property(
		null_brand_anchor,
		"scale",
		Vector2.ONE,
		presentation_data.null_logo_build_seconds
	)

	for particle: Control in particles:
		var target: Vector2 = particle.get_meta("target_position", particle.position)
		_active_tween.tween_property(
			particle,
			"position",
			target,
			presentation_data.null_logo_build_seconds
		)
		_active_tween.tween_property(
			particle,
			"modulate:a",
			0.08,
			presentation_data.null_logo_build_seconds
		)

	await _active_tween.finished
	_clear_null_pixels()

	if presentation_data.logo_hold_seconds > 0.0:
		await get_tree().create_timer(presentation_data.logo_hold_seconds).timeout

	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_EXPO)
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(
		power_line,
		"scale:x",
		1.0,
		presentation_data.screen_power_seconds
	)
	_active_tween.parallel().tween_property(
		backdrop_clip,
		"modulate:a",
		1.0,
		presentation_data.screen_power_seconds
	)
	_active_tween.parallel().tween_property(
		screen_flash,
		"modulate:a",
		0.42,
		presentation_data.screen_power_seconds
	)
	await _active_tween.finished

	var target_position: Vector2 = _get_boot_logo_target_position()
	var null_target_position: Vector2 = _get_null_brand_target_position()
	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(
		backdrop_root,
		"position",
		_backdrop_base_position,
		presentation_data.reveal_seconds
	)
	_active_tween.parallel().tween_property(
		boot_logo_anchor,
		"position",
		target_position,
		presentation_data.reveal_seconds
	)
	_active_tween.parallel().tween_property(
		boot_logo_anchor,
		"scale",
		Vector2.ONE * presentation_data.logo_target_scale,
		presentation_data.reveal_seconds
	)
	_active_tween.parallel().tween_property(
		null_brand_anchor,
		"position",
		null_target_position,
		presentation_data.reveal_seconds
	)
	_active_tween.parallel().tween_property(
		null_brand_anchor,
		"scale",
		Vector2.ONE * presentation_data.null_logo_target_scale,
		presentation_data.reveal_seconds
	)
	_active_tween.parallel().tween_property(
		power_line,
		"modulate:a",
		0.0,
		presentation_data.reveal_seconds * 0.45
	)
	_active_tween.parallel().tween_property(
		screen_flash,
		"modulate:a",
		0.0,
		presentation_data.reveal_seconds * 0.6
	)
	await _active_tween.finished

	backdrop_root.position = _backdrop_base_position
	_backdrop_parallax_offset = Vector2.ZERO
	_play_logo_glitch()


func _configure_splash(splash: StartupSplashData) -> void:
	splash_background.color = splash.background_color
	splash_logo.custom_minimum_size = splash.logo_minimum_size
	splash_logo.texture = splash.logo_texture
	splash_logo.visible = splash.logo_texture != null
	splash_fallback.text = splash.fallback_text
	splash_fallback.visible = splash.logo_texture == null


func _configure_kubuos_logo() -> void:
	boot_logo.texture = presentation_data.kubuos_logo_texture
	boot_logo.visible = presentation_data.kubuos_logo_texture != null
	boot_fallback.text = presentation_data.kubuos_fallback_text
	boot_fallback.visible = presentation_data.kubuos_logo_texture == null


func _configure_null_brand() -> void:
	var texture: Texture2D = presentation_data.null_network_logo_texture
	var has_texture: bool = texture != null

	for node: TextureRect in [
		null_logo_texture,
		null_logo_texture_ghost_a,
		null_logo_texture_ghost_b
	]:
		node.texture = texture
		node.visible = has_texture

	for node: Label in [
		null_logo_label,
		null_logo_label_ghost_a,
		null_logo_label_ghost_b
	]:
		node.text = presentation_data.null_network_fallback_text
		node.visible = not has_texture

	null_logo_label.add_theme_color_override(
		"font_color",
		presentation_data.null_logo_text_color
	)
	null_logo_label_ghost_a.add_theme_color_override(
		"font_color",
		presentation_data.null_logo_glitch_color_a
	)
	null_logo_label_ghost_b.add_theme_color_override(
		"font_color",
		presentation_data.null_logo_glitch_color_b
	)
	null_logo_texture_ghost_a.modulate = presentation_data.null_logo_glitch_color_a
	null_logo_texture_ghost_b.modulate = presentation_data.null_logo_glitch_color_b
	_reset_logo_glitch()


func _set_backdrop_period(period: int) -> void:
	_current_period = (
		TimeManager.TimePeriod.NIGHT
		if period == TimeManager.TimePeriod.NIGHT
		else TimeManager.TimePeriod.DAY
	)
	var is_night: bool = _current_period == TimeManager.TimePeriod.NIGHT
	var texture: Texture2D = (
		presentation_data.night_background_texture
		if is_night
		else presentation_data.day_background_texture
	)
	backdrop_color.color = (
		presentation_data.night_background_color
		if is_night
		else presentation_data.day_background_color
	)
	backdrop_texture.texture = texture
	backdrop_texture.visible = texture != null


func _apply_static_styling() -> void:
	splash_fallback.add_theme_color_override(
		"font_color",
		presentation_data.splash_text_color
	)
	boot_fallback.add_theme_color_override(
		"font_color",
		presentation_data.kubuos_text_color
	)
	power_line.color = presentation_data.power_line_color


func _layout_backdrop() -> void:
	if presentation_data == null:
		return

	var overscan: float = presentation_data.backdrop_overscan_pixels
	_backdrop_base_position = Vector2(-overscan, -overscan)
	backdrop_root.position = _backdrop_base_position
	backdrop_root.size = size + Vector2(overscan * 2.0, overscan * 2.0)


func _layout_boot_logo_centered() -> void:
	boot_logo_anchor.position = (size - boot_logo_anchor.size) * 0.5


func _layout_null_brand_above_boot_logo() -> void:
	var boot_center_x: float = boot_logo_anchor.position.x + boot_logo_anchor.size.x * 0.5
	null_brand_anchor.position = Vector2(
		boot_center_x - null_brand_anchor.size.x * 0.5,
		boot_logo_anchor.position.y
		- null_brand_anchor.size.y
		- presentation_data.null_logo_boot_gap_pixels
	)


func _get_boot_logo_target_position() -> Vector2:
	var target_center := Vector2(
		size.x * presentation_data.logo_target_screen_x_ratio,
		size.y * presentation_data.logo_target_screen_y_ratio
	)
	return target_center - boot_logo_anchor.size * 0.5


func _get_null_brand_target_position() -> Vector2:
	var target_center := Vector2(
		size.x * 0.5,
		size.y * presentation_data.null_logo_target_screen_y_ratio
	)
	return target_center - null_brand_anchor.size * 0.5


func _spawn_null_boot_particles() -> Array[Control]:
	_clear_null_pixels()
	var particles: Array[Control] = []
	var target_rect := Rect2(Vector2.ZERO, null_brand_anchor.size)

	for index: int in range(presentation_data.null_logo_particle_count):
		var pixel := ColorRect.new()
		var pixel_size: float = _rng.randf_range(2.0, 5.0)
		pixel.size = Vector2(pixel_size, pixel_size)
		pixel.color = (
			presentation_data.null_logo_glitch_color_a
			if index % 2 == 0
			else presentation_data.null_logo_glitch_color_b
		)
		pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pixel.position = Vector2(
			_rng.randf_range(-90.0, target_rect.size.x + 90.0),
			_rng.randf_range(-55.0, target_rect.size.y + 55.0)
		)
		pixel.set_meta("target_position", Vector2(
			_rng.randf_range(12.0, maxf(13.0, target_rect.size.x - 12.0)),
			_rng.randf_range(10.0, maxf(11.0, target_rect.size.y - 10.0))
		))
		pixel_field.add_child(pixel)
		particles.append(pixel)

	return particles


func _play_logo_glitch() -> void:
	if _glitch_tween != null and _glitch_tween.is_valid():
		return

	var offset_a := Vector2(_rng.randi_range(-4, 4), _rng.randi_range(-1, 1))
	var offset_b := Vector2(_rng.randi_range(-4, 4), _rng.randi_range(-1, 1))
	null_logo_root.position.x = float(_rng.randi_range(-2, 2))
	null_logo_texture_ghost_a.position = offset_a
	null_logo_texture_ghost_b.position = offset_b
	null_logo_label_ghost_a.position = offset_a
	null_logo_label_ghost_b.position = offset_b
	null_logo_texture_ghost_a.modulate.a = 0.48
	null_logo_texture_ghost_b.modulate.a = 0.42
	null_logo_label_ghost_a.modulate.a = 0.7
	null_logo_label_ghost_b.modulate.a = 0.65
	_glitch_tween = create_tween()
	_glitch_tween.tween_interval(0.055)
	_glitch_tween.tween_callback(_reset_logo_glitch)


func _reset_logo_glitch() -> void:
	null_logo_root.position = Vector2.ZERO
	null_logo_texture_ghost_a.position = Vector2.ZERO
	null_logo_texture_ghost_b.position = Vector2.ZERO
	null_logo_label_ghost_a.position = Vector2.ZERO
	null_logo_label_ghost_b.position = Vector2.ZERO
	null_logo_texture_ghost_a.modulate.a = 0.0
	null_logo_texture_ghost_b.modulate.a = 0.0
	null_logo_label_ghost_a.modulate.a = 0.0
	null_logo_label_ghost_b.modulate.a = 0.0
	_glitch_tween = null


func _schedule_next_glitch() -> void:
	_glitch_timer = _rng.randf_range(0.65, 1.7)


func _clear_null_pixels() -> void:
	for child: Node in pixel_field.get_children():
		child.queue_free()


func _on_viewport_size_changed() -> void:
	if presentation_data == null:
		return

	_layout_backdrop()

	if not _is_playing:
		boot_logo_anchor.position = _get_boot_logo_target_position()
		null_brand_anchor.position = _get_null_brand_target_position()
		backdrop_root.position = _backdrop_base_position + _backdrop_parallax_offset


func _kill_active_tweens() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	if _glitch_tween != null and _glitch_tween.is_valid():
		_glitch_tween.kill()

	_active_tween = null
	_glitch_tween = null


func _reset_visual_state() -> void:
	show()
	splash_layer.hide()
	boot_layer.hide()
	backdrop_clip.modulate.a = 0.0
	screen_flash.modulate.a = 0.0
	skip_hint.hide()
	_clear_null_pixels()
