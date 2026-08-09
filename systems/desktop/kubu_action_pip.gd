extends TextureRect
class_name KubuActionPip


enum PipState {
	CURRENT,
	AVAILABLE,
	USED,
	UNAVAILABLE
}

@export_category("State Textures")
@export var current_texture: Texture2D
@export var available_texture: Texture2D
@export var used_texture: Texture2D
@export var unavailable_texture: Texture2D

@export_category("Period Tint")
## State textures stay grayscale; period identity is projected here so every
## pip keeps the same hue while its texture luminance still communicates state.
@export var day_tint: Color = Color(0.38, 0.68, 1.0, 1.0)
@export var night_tint: Color = Color(0.68, 0.46, 0.94, 1.0)

var slot_index: int = 0
var slot_hour: int = 6
var current_state: PipState = PipState.UNAVAILABLE
var current_period: int = TimeManager.TimePeriod.DAY


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_texture()
	set_period_tint(TimeManager.current_period)


func setup_pip(new_slot_index: int, new_slot_hour: int) -> void:
	slot_index = new_slot_index
	slot_hour = posmod(new_slot_hour, 24)

	tooltip_text = "Slot %02d — %s" % [
		slot_index + 1,
		TimeManager.format_hour_12(slot_hour)
	]


func set_state(new_state: PipState) -> void:
	current_state = new_state
	_apply_texture()


func set_period_tint(period: int) -> void:
	current_period = (
		TimeManager.TimePeriod.NIGHT
		if period == TimeManager.TimePeriod.NIGHT
		else TimeManager.TimePeriod.DAY
	)
	self_modulate = night_tint if current_period == TimeManager.TimePeriod.NIGHT else day_tint


func _apply_texture() -> void:
	match current_state:
		PipState.CURRENT:
			texture = current_texture

		PipState.AVAILABLE:
			texture = available_texture

		PipState.USED:
			texture = used_texture

		PipState.UNAVAILABLE:
			texture = unavailable_texture
