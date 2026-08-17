extends CanvasLayer


signal transition_started(kind: StringName)
signal transition_finished(kind: StringName)


const TRANSITION_SCREEN: StringName = &"screen"
const TRANSITION_PERIOD: StringName = &"period"
const TRANSITION_DAY: StringName = &"day"

@export var presentation_data: KubuTransitionPresentationData
@export var day_theme: Theme
@export var night_theme: Theme

@onready var screen_root: Control = %ScreenTransitionRoot
@onready var blocks_root: Control = %BlocksRoot
@onready var time_root: Control = %TimeTransitionRoot
@onready var background: ColorRect = %Background
@onready var countdown_label: Label = %CountdownLabel
@onready var kubu_logo_texture: TextureRect = %KubuLogoTexture
@onready var kubu_logo_fallback: Label = %KubuLogoFallback
@onready var symbol_clip: Control = %SymbolClip
@onready var old_symbol_root: Control = %OldSymbolRoot
@onready var old_symbol_texture: TextureRect = %OldSymbolTexture
@onready var old_symbol_fallback: Label = %OldSymbolFallback
@onready var new_symbol_root: Control = %NewSymbolRoot
@onready var new_symbol_texture: TextureRect = %NewSymbolTexture
@onready var new_symbol_fallback: Label = %NewSymbolFallback
@onready var period_label_clip: Control = %PeriodLabelClip
@onready var old_period_label: Label = %OldPeriodLabel
@onready var new_period_label: Label = %NewPeriodLabel
@onready var day_label: Label = %DayLabel
@onready var trail_hbox: HBoxContainer = %TrailHBox
@onready var trail_cursor: Label = %TrailCursor
@onready var day_change_audio: AudioStreamPlayer = %DayChangeAudio

var _busy: bool = false
var _screen_covered: bool = false
var _runtime_active: bool = false
var _last_period: int = TimeManager.TimePeriod.DAY
var _last_day: int = 1
var _last_days_until_update: int = 0
var _time_queue: Array[Dictionary] = []
var _draining_time_queue: bool = false


func _ready() -> void:
	screen_root.hide()
	time_root.hide()
	_last_period = int(TimeManager.current_period)
	_last_day = TimeManager.days_passed
	_last_days_until_update = TimeManager.days_until_update

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	_apply_period_theme(_last_period)


func set_runtime_active(active: bool) -> void:
	_runtime_active = active
	_last_period = int(TimeManager.current_period)
	_last_day = TimeManager.days_passed
	_last_days_until_update = TimeManager.days_until_update
	_apply_period_theme(_last_period)

	if not active:
		_time_queue.clear()


func is_transitioning() -> bool:
	return _busy


func cover_screen() -> void:
	await _wait_until_idle()

	if presentation_data == null:
		return

	_busy = true
	_screen_covered = false
	transition_started.emit(TRANSITION_SCREEN)
	_build_screen_blocks()
	screen_root.show()
	await _animate_screen_blocks(true)
	_screen_covered = true


func uncover_screen() -> void:
	if not _busy or not _screen_covered:
		return

	if presentation_data != null:
		await _wait_seconds(presentation_data.screen_covered_hold_seconds)

	await _animate_screen_blocks(false)
	_clear_screen_blocks()
	screen_root.hide()
	_screen_covered = false
	_busy = false
	transition_finished.emit(TRANSITION_SCREEN)


func play_screen_transition(midpoint: Callable = Callable()) -> void:
	await cover_screen()

	if midpoint.is_valid():
		midpoint.call()

	await get_tree().process_frame
	await uncover_screen()


func _wait_until_idle() -> void:
	while _busy:
		await transition_finished


func _wait_seconds(seconds: float) -> void:
	if seconds <= 0.0:
		return

	await get_tree().create_timer(seconds).timeout


func _build_screen_blocks() -> void:
	_clear_screen_blocks()

	var columns: int = maxi(1, presentation_data.screen_grid_columns)
	var rows: int = maxi(1, presentation_data.screen_grid_rows)
	var viewport_size: Vector2 = screen_root.size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(get_viewport().get_visible_rect().size)

	var cell_size := Vector2(
		ceilf(viewport_size.x / float(columns)),
		ceilf(viewport_size.y / float(rows))
	)
	var overlap: float = presentation_data.screen_block_overlap_pixels

	for row in range(rows):
		for column in range(columns):
			var block: Control

			if presentation_data.screen_block_texture != null:
				var texture_block := TextureRect.new()
				texture_block.texture = presentation_data.screen_block_texture
				texture_block.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture_block.stretch_mode = TextureRect.STRETCH_SCALE
				texture_block.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				block = texture_block
			else:
				var color_block := ColorRect.new()
				color_block.color = presentation_data.screen_block_fallback_color
				block = color_block

			block.mouse_filter = Control.MOUSE_FILTER_IGNORE
			block.position = Vector2(
				float(column) * cell_size.x - overlap,
				float(row) * cell_size.y - overlap
			)
			block.size = cell_size + Vector2(overlap * 2.0, overlap * 2.0)
			block.pivot_offset = block.size * 0.5
			block.scale = Vector2.ZERO
			block.set_meta(
				"transition_order",
				_get_screen_block_order(column, row, columns, rows)
			)
			blocks_root.add_child(block)


func _get_screen_block_order(
	column: int,
	row: int,
	columns: int,
	rows: int
) -> int:
	var x: int = column
	var y: int = row

	match presentation_data.screen_start_corner:
		KubuTransitionPresentationData.ScreenStartCorner.TOP_RIGHT:
			x = columns - 1 - column
		KubuTransitionPresentationData.ScreenStartCorner.BOTTOM_LEFT:
			y = rows - 1 - row
		KubuTransitionPresentationData.ScreenStartCorner.BOTTOM_RIGHT:
			x = columns - 1 - column
			y = rows - 1 - row

	return x + y


func _animate_screen_blocks(covering: bool) -> void:
	var max_order: int = 0
	var duration: float = (
		presentation_data.screen_block_grow_seconds
		if covering
		else presentation_data.screen_block_shrink_seconds
	)
	var target_scale: Vector2 = Vector2.ONE if covering else Vector2.ZERO

	for child: Node in blocks_root.get_children():
		if child is not Control:
			continue

		var block := child as Control
		var order: int = int(block.get_meta("transition_order", 0))
		max_order = maxi(max_order, order)
		var delay: float = float(order) * presentation_data.screen_diagonal_stagger_seconds
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(block, "scale", target_scale, duration).set_trans(
			Tween.TRANS_BACK if covering else Tween.TRANS_QUAD
		).set_ease(Tween.EASE_OUT if covering else Tween.EASE_IN)

	var total_duration: float = (
		float(max_order) * presentation_data.screen_diagonal_stagger_seconds
		+ duration
	)
	await _wait_seconds(total_duration)


func _clear_screen_blocks() -> void:
	for child: Node in blocks_root.get_children():
		child.free()


func _on_time_advanced(
	period: int,
	days_passed: int,
	_calendar_day: int,
	_calendar_month: String
) -> void:
	var previous_period: int = _last_period
	var previous_day: int = _last_day
	var previous_countdown: int = _last_days_until_update
	var current_countdown: int = TimeManager.days_until_update

	_last_period = period
	_last_day = days_passed
	_last_days_until_update = current_countdown

	if not _runtime_active:
		_apply_period_theme(period)
		return

	var day_changed: bool = days_passed != previous_day
	var period_changed: bool = period != previous_period

	if not day_changed and not period_changed:
		return

	_time_queue.append({
		"old_period": previous_period,
		"new_period": period,
		"old_day": previous_day,
		"new_day": days_passed,
		"old_countdown": previous_countdown,
		"new_countdown": current_countdown,
		"day_changed": day_changed
	})
	call_deferred("_drain_time_transitions")


func _drain_time_transitions() -> void:
	if _draining_time_queue:
		return

	_draining_time_queue = true

	while not _time_queue.is_empty():
		var transition: Dictionary = _time_queue.pop_front()
		await _wait_until_idle()
		await _play_time_transition(transition)

	_draining_time_queue = false


func _play_time_transition(transition: Dictionary) -> void:
	if presentation_data == null:
		return

	_busy = true
	var day_changed: bool = bool(transition.get("day_changed", false))
	var kind: StringName = TRANSITION_DAY if day_changed else TRANSITION_PERIOD
	transition_started.emit(kind)

	var old_period: int = int(transition.get("old_period", TimeManager.TimePeriod.DAY))
	var new_period: int = int(transition.get("new_period", TimeManager.TimePeriod.DAY))
	var old_day: int = maxi(1, int(transition.get("old_day", 1)))
	var new_day: int = maxi(1, int(transition.get("new_day", old_day)))
	var old_countdown: int = maxi(0, int(transition.get("old_countdown", 0)))
	var new_countdown: int = maxi(0, int(transition.get("new_countdown", old_countdown)))

	_configure_time_transition(
		old_period,
		new_period,
		old_day,
		old_countdown
	)
	time_root.modulate.a = 0.0
	time_root.show()
	await get_tree().process_frame
	await _position_trail_cursor(old_day)

	# Stage 1: the system screen itself arrives and is allowed to settle.
	var intro := create_tween()
	intro.set_trans(Tween.TRANS_QUAD)
	intro.set_ease(Tween.EASE_OUT)
	intro.tween_property(
		time_root,
		"modulate:a",
		1.0,
		presentation_data.time_intro_seconds
	)
	await intro.finished
	await _wait_seconds(presentation_data.time_pre_period_pause_seconds)

	# Stage 2: period identity changes as one coherent beat. Background, symbol
	# and period text move together, but day/countdown progression waits.
	var background_tween := create_tween()
	background_tween.set_trans(Tween.TRANS_SINE)
	background_tween.set_ease(Tween.EASE_IN_OUT)
	background_tween.tween_property(
		background,
		"color",
		_get_period_background(new_period),
		presentation_data.time_background_seconds
	)

	var symbol_tween := create_tween()
	symbol_tween.set_trans(Tween.TRANS_CUBIC)
	symbol_tween.set_ease(Tween.EASE_IN_OUT)
	symbol_tween.tween_property(
		old_symbol_root,
		"position:y",
		symbol_clip.size.y,
		presentation_data.time_symbol_seconds
	)
	symbol_tween.parallel().tween_property(
		new_symbol_root,
		"position:y",
		0.0,
		presentation_data.time_symbol_seconds
	)

	var label_tween := create_tween()
	label_tween.set_trans(Tween.TRANS_CUBIC)
	label_tween.set_ease(Tween.EASE_IN_OUT)
	label_tween.tween_property(
		old_period_label,
		"position:x",
		-period_label_clip.size.x,
		presentation_data.time_label_seconds
	)
	label_tween.parallel().tween_property(
		new_period_label,
		"position:x",
		0.0,
		presentation_data.time_label_seconds
	)

	var period_stage_duration: float = maxf(
		presentation_data.time_background_seconds,
		maxf(
			presentation_data.time_symbol_seconds,
			presentation_data.time_label_seconds
		)
	)
	await _wait_seconds(period_stage_duration)
	_apply_period_theme(new_period)
	_apply_time_foreground_after_period(new_period)
	await _wait_seconds(presentation_data.time_post_period_pause_seconds)

	# Stage 3: only after the second pause does campaign progression visibly
	# advance. DAY->NIGHT has no day/countdown change, while NIGHT->DAY updates
	# the day number, countdown, check mark and cursor together.
	if day_changed:
		_play_countdown_pulse(old_countdown, new_countdown, true)
		_play_day_change(old_day, new_day, new_period)
		await _wait_seconds(presentation_data.time_progress_seconds)
		await _finalize_day_trail(old_day, new_day)
	elif old_countdown != new_countdown:
		_play_countdown_pulse(old_countdown, new_countdown, false)
		await _wait_seconds(presentation_data.time_progress_seconds)

	await _wait_seconds(presentation_data.time_hold_seconds)

	var outro := create_tween()
	outro.set_trans(Tween.TRANS_QUAD)
	outro.set_ease(Tween.EASE_IN)
	outro.tween_property(
		time_root,
		"modulate:a",
		0.0,
		presentation_data.time_outro_seconds
	)
	await outro.finished

	time_root.hide()
	time_root.modulate.a = 1.0
	_busy = false
	transition_finished.emit(kind)


func _configure_time_transition(
	old_period: int,
	new_period: int,
	old_day: int,
	old_countdown: int
) -> void:
	background.color = _get_period_background(old_period)
	countdown_label.text = _format_countdown(old_countdown)
	countdown_label.add_theme_color_override(
		"font_color",
		presentation_data.countdown_color
	)
	countdown_label.scale = Vector2.ONE
	countdown_label.pivot_offset = countdown_label.size * 0.5

	kubu_logo_texture.texture = presentation_data.kubuos_logo_texture
	kubu_logo_texture.visible = presentation_data.kubuos_logo_texture != null
	kubu_logo_fallback.text = presentation_data.kubuos_fallback_text
	kubu_logo_fallback.visible = presentation_data.kubuos_logo_texture == null

	_configure_symbol(
		old_period,
		old_symbol_texture,
		old_symbol_fallback
	)
	_configure_symbol(
		new_period,
		new_symbol_texture,
		new_symbol_fallback
	)

	var old_foreground: Color = _get_period_foreground(old_period)
	var new_foreground: Color = _get_period_foreground(new_period)
	kubu_logo_fallback.add_theme_color_override("font_color", old_foreground)
	old_symbol_fallback.add_theme_color_override("font_color", old_foreground)
	new_symbol_fallback.add_theme_color_override("font_color", new_foreground)
	old_period_label.add_theme_color_override("font_color", old_foreground)
	new_period_label.add_theme_color_override("font_color", new_foreground)
	day_label.add_theme_color_override("font_color", old_foreground)

	old_period_label.text = TimeManager.get_period_name(
		old_period as TimeManager.TimePeriod
	)
	new_period_label.text = TimeManager.get_period_name(
		new_period as TimeManager.TimePeriod
	)
	day_label.text = "DAY %02d" % old_day
	old_symbol_root.position = Vector2.ZERO
	new_symbol_root.position = Vector2(0.0, symbol_clip.size.y)
	old_period_label.position = Vector2.ZERO
	new_period_label.position = Vector2(period_label_clip.size.x, 0.0)
	day_label.modulate.a = 1.0
	_rebuild_trail(old_day)

	trail_cursor.add_theme_color_override(
		"font_color",
		presentation_data.trail_active_color
	)

	day_change_audio.stream = presentation_data.day_change_tick_stream
	day_change_audio.volume_db = presentation_data.day_change_tick_volume_db


func _apply_time_foreground_after_period(period: int) -> void:
	var foreground: Color = _get_period_foreground(period)
	kubu_logo_fallback.add_theme_color_override("font_color", foreground)
	day_label.add_theme_color_override("font_color", foreground)


func _configure_symbol(
	period: int,
	texture_rect: TextureRect,
	fallback: Label
) -> void:
	var is_night: bool = period == TimeManager.TimePeriod.NIGHT
	var texture: Texture2D = (
		presentation_data.night_symbol_texture
		if is_night
		else presentation_data.day_symbol_texture
	)
	texture_rect.texture = texture
	texture_rect.visible = texture != null
	fallback.text = (
		presentation_data.night_symbol_fallback
		if is_night
		else presentation_data.day_symbol_fallback
	)
	fallback.visible = texture == null


func _play_countdown_pulse(
	old_countdown: int,
	new_countdown: int,
	day_changed: bool
) -> void:
	var progress_seconds: float = presentation_data.time_progress_seconds
	var pulse := create_tween()
	pulse.set_trans(Tween.TRANS_SINE)
	pulse.set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(
		countdown_label,
		"scale",
		Vector2.ONE * presentation_data.countdown_pulse_scale,
		progress_seconds * 0.5
	)

	if day_changed:
		pulse.tween_callback(func() -> void:
			countdown_label.text = _format_countdown(new_countdown)
			if day_change_audio.stream != null:
				day_change_audio.play()
		)
	elif old_countdown != new_countdown:
		pulse.tween_callback(func() -> void:
			countdown_label.text = _format_countdown(new_countdown)
		)

	pulse.tween_property(
		countdown_label,
		"scale",
		Vector2.ONE,
		progress_seconds * 0.5
	)


func _play_day_change(old_day: int, new_day: int, new_period: int) -> void:
	var progress_seconds: float = presentation_data.time_progress_seconds
	var day_tween := create_tween()
	day_tween.set_trans(Tween.TRANS_QUAD)
	day_tween.set_ease(Tween.EASE_IN_OUT)
	day_tween.tween_property(
		day_label,
		"modulate:a",
		0.0,
		progress_seconds * 0.45
	)
	day_tween.tween_callback(func() -> void:
		day_label.text = "DAY %02d" % new_day
		day_label.add_theme_color_override(
			"font_color",
			_get_period_foreground(new_period)
		)
	)
	day_tween.tween_property(
		day_label,
		"modulate:a",
		1.0,
		progress_seconds * 0.55
	)

	var old_week_start: int = _get_week_start_day(old_day)
	var new_week_start: int = _get_week_start_day(new_day)

	if old_week_start != new_week_start:
		return

	var cursor_target: float = _get_trail_cursor_x(new_day)
	var cursor_tween := create_tween()
	cursor_tween.set_trans(Tween.TRANS_CUBIC)
	cursor_tween.set_ease(Tween.EASE_IN_OUT)
	cursor_tween.tween_property(
		trail_cursor,
		"position:x",
		cursor_target,
		progress_seconds
	)


func _finalize_day_trail(_old_day: int, new_day: int) -> void:
	_rebuild_trail(new_day)
	await get_tree().process_frame
	_position_trail_cursor_now(new_day)


func _rebuild_trail(current_day: int) -> void:
	for child: Node in trail_hbox.get_children():
		child.free()

	var week_start: int = _get_week_start_day(current_day)

	for index in range(7):
		var day_number: int = week_start + index
		var label := Label.new()
		label.custom_minimum_size = Vector2(54.0, 34.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)

		if day_number < current_day:
			label.text = "✓%02d" % day_number
		else:
			label.text = "%02d" % day_number

		var color: Color = presentation_data.trail_inactive_color
		if day_number < current_day:
			color = presentation_data.trail_completed_color
		elif day_number == current_day:
			color = presentation_data.trail_active_color

		if index == 6:
			color = presentation_data.weekend_color

		label.add_theme_color_override("font_color", color)
		trail_hbox.add_child(label)


func _position_trail_cursor(day_number: int) -> void:
	await get_tree().process_frame
	_position_trail_cursor_now(day_number)


func _position_trail_cursor_now(day_number: int) -> void:
	trail_cursor.position.x = _get_trail_cursor_x(day_number)


func _get_trail_cursor_x(day_number: int) -> float:
	if trail_hbox.get_child_count() == 0:
		return 0.0

	var week_start: int = _get_week_start_day(day_number)
	var index: int = clampi(day_number - week_start, 0, trail_hbox.get_child_count() - 1)
	var label := trail_hbox.get_child(index) as Label

	if label == null:
		return 0.0

	return (
		trail_hbox.position.x
		+ label.position.x
		+ (label.size.x * 0.5)
		- (trail_cursor.size.x * 0.5)
	)


func _get_week_start_day(day_number: int) -> int:
	return floori(float(maxi(1, day_number) - 1) / 7.0) * 7 + 1


func _format_countdown(days_left: int) -> String:
	var noun: String = "DAY" if days_left == 1 else "DAYS"
	return "%d %s UNTIL UPDATE 1.0" % [maxi(0, days_left), noun]


func _get_period_background(period: int) -> Color:
	return (
		presentation_data.night_background_color
		if period == TimeManager.TimePeriod.NIGHT
		else presentation_data.day_background_color
	)


func _get_period_foreground(period: int) -> Color:
	return (
		presentation_data.night_foreground_color
		if period == TimeManager.TimePeriod.NIGHT
		else presentation_data.day_foreground_color
	)


func _apply_period_theme(period: int) -> void:
	var target_theme: Theme = (
		night_theme
		if period == TimeManager.TimePeriod.NIGHT
		else day_theme
	)

	if target_theme == null or get_tree() == null or get_tree().root == null:
		return

	get_tree().root.theme = target_theme
	_apply_theme_to_kubu_branches(get_tree().root, target_theme)


func _apply_theme_to_kubu_branches(node: Node, target_theme: Theme) -> void:
	for child: Node in node.get_children():
		if child is Control:
			var control := child as Control
			var parent_is_control: bool = control.get_parent() is Control
			var uses_period_theme: bool = (
				control.theme == day_theme
				or control.theme == night_theme
			)
			var is_inheritance_root: bool = (
				not parent_is_control
				and control.theme == null
			)

			# CanvasLayer and plain Node boundaries interrupt Control theme inheritance.
			# Treat their first Control child as a KubuOS inheritance root unless that
			# branch intentionally owns another custom Theme (browser sites, etc.).
			if uses_period_theme or is_inheritance_root:
				control.theme = target_theme

		_apply_theme_to_kubu_branches(child, target_theme)
