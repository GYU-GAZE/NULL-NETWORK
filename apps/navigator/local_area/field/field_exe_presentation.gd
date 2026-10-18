extends Node2D
class_name FieldEXEPresentation

const FALLBACK_PATH := "res://data/assets/field/field_exe_fallback.svg"
var _fallback: Texture2D
var _fallback_step: Texture2D
var definition: FieldPresentationData
var moving: bool = false
var facing_left: bool = false
var signal_text: String = ""
var tint: Color = Color.WHITE
var _clock: float = 0.0

func _ready() -> void:
	_fallback = load(FALLBACK_PATH)
	_fallback_step = load("res://data/assets/field/field_exe_step_fallback.svg")

func configure(data: FieldPresentationData) -> void:
	definition = data
	queue_redraw()

func advance(delta: float, motion: Vector2, active: bool) -> void:
	if active:
		_clock += delta
	moving = motion.length_squared() > 1.0
	if absf(motion.x) > 1:
		facing_left = motion.x < 0
	# Presentation snap only. CharacterBody2D keeps its subpixel position.
	global_position = get_parent().global_position.round()
	queue_redraw()

func _draw() -> void:
	var texture := _fallback
	if texture == null:
		return
	var origin := Vector2(12, 20)
	var factor := 1.0
	var color := tint
	var flip := facing_left
	var fps := definition.frames_per_second if definition != null else 6.0
	var stepping := moving and int(_clock * fps) % 2 == 1
	if stepping:
		texture = _fallback_step
	if definition != null:
		var frame := definition.field_step if stepping else definition.field_idle
		if frame != null:
			texture = frame
		origin = definition.sprite_origin
		factor = definition.visual_scale
		color *= definition.tint
		flip = facing_left == definition.faces_right
	var rect := Rect2(-origin * factor, texture.get_size() * factor)
	if flip:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	var bob := -1.0 if moving and int(_clock * 8) % 2 == 0 else 0.0
	if definition == null or definition.digital_effect:
		draw_line(Vector2(-8, 4), Vector2(8, 4), Color(0.3, 0.85, 1.0, 0.35), 1)
		rect.position.y += bob
	draw_texture_rect(texture, rect, false, color)
	if not signal_text.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(-28, -28), signal_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.85, 0.25))
