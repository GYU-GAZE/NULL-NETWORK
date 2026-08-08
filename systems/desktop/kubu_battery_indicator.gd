extends Control
class_name KubuBatteryIndicator


enum BatteryVisualState {
	FULL,
	PERCENT_75,
	PERCENT_50,
	PERCENT_25,
	PERCENT_10
}

@export_category("Optional Textures")
@export var full_texture: Texture2D
@export var percent_75_texture: Texture2D
@export var percent_50_texture: Texture2D
@export var percent_25_texture: Texture2D
@export var percent_10_texture: Texture2D

@export_category("Fallback Drawing")
@export var outline_color: Color = Color(0.82, 0.9, 1.0, 0.92)
@export var fill_color: Color = Color(0.82, 0.9, 1.0, 0.92)
@export var empty_color: Color = Color(0.18, 0.24, 0.34, 0.7)

@onready var texture_rect: TextureRect = %TextureRect

var battery_percent: int = 100
var visual_state: BatteryVisualState = BatteryVisualState.FULL


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_battery_percent(battery_percent)


func set_battery_percent(value: int) -> void:
	battery_percent = clampi(value, 0, 100)
	visual_state = _resolve_visual_state(battery_percent)
	_refresh_texture()
	queue_redraw()


func _resolve_visual_state(value: int) -> BatteryVisualState:
	if value >= 88:
		return BatteryVisualState.FULL
	if value >= 63:
		return BatteryVisualState.PERCENT_75
	if value >= 38:
		return BatteryVisualState.PERCENT_50
	if value >= 18:
		return BatteryVisualState.PERCENT_25
	return BatteryVisualState.PERCENT_10


func _refresh_texture() -> void:
	if texture_rect == null:
		return

	var texture: Texture2D = _get_state_texture(visual_state)
	texture_rect.texture = texture
	texture_rect.visible = texture != null


func _get_state_texture(state: BatteryVisualState) -> Texture2D:
	match state:
		BatteryVisualState.FULL:
			return full_texture
		BatteryVisualState.PERCENT_75:
			return percent_75_texture
		BatteryVisualState.PERCENT_50:
			return percent_50_texture
		BatteryVisualState.PERCENT_25:
			return percent_25_texture
		BatteryVisualState.PERCENT_10:
			return percent_10_texture
	return null


func _draw() -> void:
	if texture_rect != null and texture_rect.visible:
		return

	# Pixel-friendly fallback. Final art can replace this simply by assigning
	# the five textures above; taskbar code never needs to change.
	var body := Rect2(Vector2(1.0, 2.0), Vector2(maxf(8.0, size.x - 5.0), maxf(5.0, size.y - 4.0)))
	var terminal := Rect2(Vector2(body.end.x, body.position.y + 2.0), Vector2(3.0, maxf(1.0, body.size.y - 4.0)))
	draw_rect(body, outline_color, false, 1.0)
	draw_rect(terminal, outline_color, true)

	var inner := Rect2(body.position + Vector2(2.0, 2.0), body.size - Vector2(4.0, 4.0))
	draw_rect(inner, empty_color, true)

	var fill_ratio: float = 1.0
	match visual_state:
		BatteryVisualState.FULL:
			fill_ratio = 1.0
		BatteryVisualState.PERCENT_75:
			fill_ratio = 0.75
		BatteryVisualState.PERCENT_50:
			fill_ratio = 0.5
		BatteryVisualState.PERCENT_25:
			fill_ratio = 0.25
		BatteryVisualState.PERCENT_10:
			fill_ratio = 0.1

	var fill_width: float = maxf(1.0, floor(inner.size.x * fill_ratio))
	draw_rect(Rect2(inner.position, Vector2(fill_width, inner.size.y)), fill_color, true)
