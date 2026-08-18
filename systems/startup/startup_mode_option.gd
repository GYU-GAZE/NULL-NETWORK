extends PanelContainer
class_name StartupModeOption


signal toggle_requested(mode_value: int)
signal start_requested(mode_value: int)


@export var collapsed_height: float = 48.0
@export var expanded_height: float = 168.0
@export var expand_seconds: float = 0.18
@export var collapsed_style: StyleBox
@export var expanded_style: StyleBox

@onready var header_button: Button = %HeaderButton
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var body: Control = %Body
@onready var start_button: Button = %StartButton

var mode_value: int = 0
var _expanded: bool = false
var _interaction_enabled: bool = true
var _active_tween: Tween


func _ready() -> void:
	header_button.pressed.connect(_on_header_pressed)
	start_button.pressed.connect(_on_start_pressed)
	_apply_collapsed_state_immediately()


func configure(
	value: int,
	title: String,
	description: String
) -> void:
	mode_value = value
	header_button.text = title.strip_edges()
	description_label.text = description.strip_edges()


func is_expanded() -> bool:
	return _expanded


func set_interaction_enabled(value: bool) -> void:
	_interaction_enabled = value
	header_button.disabled = not value
	start_button.disabled = not value or not _expanded


func set_expanded(value: bool, animated: bool = true) -> void:
	if _expanded == value and (_active_tween == null or not _active_tween.is_valid()):
		return

	_kill_active_tween()
	_expanded = value
	header_button.disabled = not _interaction_enabled
	start_button.disabled = not _interaction_enabled or not _expanded

	if not animated or not is_inside_tree():
		if _expanded:
			_apply_expanded_state_immediately()
		else:
			_apply_collapsed_state_immediately()
		return

	if _expanded:
		body.show()
		body.modulate.a = 0.0
		_apply_panel_style(expanded_style)
	else:
		start_button.disabled = true

	_active_tween = create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.set_ease(Tween.EASE_OUT if _expanded else Tween.EASE_IN_OUT)
	_active_tween.tween_method(
		_set_animated_height,
		custom_minimum_size.y,
		expanded_height if _expanded else collapsed_height,
		expand_seconds
	)
	_active_tween.tween_property(
		body,
		"modulate:a",
		1.0 if _expanded else 0.0,
		expand_seconds * (0.72 if _expanded else 0.45)
	).set_delay(expand_seconds * 0.16 if _expanded else 0.0)
	await _active_tween.finished
	_active_tween = null

	if not _expanded:
		body.hide()
		_apply_panel_style(collapsed_style)


func reset_immediately() -> void:
	_kill_active_tween()
	_expanded = false
	_apply_collapsed_state_immediately()


func _on_header_pressed() -> void:
	if not _interaction_enabled:
		return

	toggle_requested.emit(mode_value)


func _on_start_pressed() -> void:
	if not _interaction_enabled or not _expanded:
		return

	start_requested.emit(mode_value)


func _apply_collapsed_state_immediately() -> void:
	_expanded = false
	custom_minimum_size.y = collapsed_height
	body.modulate.a = 0.0
	body.hide()
	start_button.disabled = true
	_apply_panel_style(collapsed_style)


func _apply_expanded_state_immediately() -> void:
	_expanded = true
	custom_minimum_size.y = expanded_height
	body.show()
	body.modulate.a = 1.0
	start_button.disabled = not _interaction_enabled
	_apply_panel_style(expanded_style)


func _apply_panel_style(style: StyleBox) -> void:
	if style != null:
		add_theme_stylebox_override("panel", style)


func _kill_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = null


func _set_animated_height(value: float) -> void:
	custom_minimum_size.y = round(value)
