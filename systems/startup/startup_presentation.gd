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
@onready var power_line: ColorRect = %PowerLine
@onready var screen_flash: ColorRect = %ScreenFlash
@onready var skip_hint: Label = %SkipHint

var _active_tween: Tween
var _is_playing: bool = false
var _parallax_enabled: bool = false
var _backdrop_base_position: Vector2 = Vector2.ZERO
var _backdrop_parallax_offset: Vector2 = Vector2.ZERO
var _current_period: int = TimeManager.TimePeriod.DAY


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_apply_static_styling()
	await _play_custom_splashes()
	await _play_kubuos_boot()
	_active_tween = null
	_is_playing = false
	_parallax_enabled = true
	set_process(true)
	skip_hint.hide()
	boot_completed.emit()


func stop_and_hide() -> void:
	_is_playing = false
	_parallax_enabled = false
	set_process(false)

	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = null
	hide()


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
	_configure_kubuos_logo()

	boot_logo_anchor.modulate.a = 0.0
	boot_logo_anchor.scale = Vector2(0.94, 0.94)
	boot_logo_anchor.pivot_offset = boot_logo_anchor.size * 0.5
	power_line.scale = Vector2(0.0, 1.0)
	power_line.modulate.a = 1.0
	power_line.pivot_offset = power_line.size * 0.5
	screen_flash.modulate.a = 0.0
	backdrop_clip.modulate.a = 0.0

	var intro_distance: float = size.y * presentation_data.background_intro_pan_ratio
	backdrop_root.position = _backdrop_base_position + Vector2(0.0, -intro_distance)

	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_QUAD)
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(
		boot_logo_anchor,
		"modulate:a",
		1.0,
		presentation_data.logo_ignite_seconds
	)
	_active_tween.parallel().tween_property(
		boot_logo_anchor,
		"scale",
		Vector2.ONE,
		presentation_data.logo_ignite_seconds
	)
	_active_tween.tween_interval(presentation_data.logo_hold_seconds)
	await _active_tween.finished

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


func _get_boot_logo_target_position() -> Vector2:
	var target_center := Vector2(
		size.x * presentation_data.logo_target_screen_x_ratio,
		size.y * presentation_data.logo_target_screen_y_ratio
	)
	return target_center - boot_logo_anchor.size * 0.5


func _on_viewport_size_changed() -> void:
	if presentation_data == null:
		return

	_layout_backdrop()

	if not _is_playing:
		boot_logo_anchor.position = _get_boot_logo_target_position()
		backdrop_root.position = _backdrop_base_position + _backdrop_parallax_offset


func _reset_visual_state() -> void:
	show()
	splash_layer.hide()
	boot_layer.hide()
	backdrop_clip.modulate.a = 0.0
	screen_flash.modulate.a = 0.0
	skip_hint.hide()
