extends Button
class_name NavigatorLocationMarker

signal marker_selected(location: MapLocation)

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel

var _location: MapLocation
var _selected: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	_apply_visual_state()


func setup(location: MapLocation) -> void:
	_location = location

	if _location == null:
		return

	title_label.text = _location.get_marker_title()
	subtitle_label.text = _location.get_marker_subtitle()
	subtitle_label.visible = not subtitle_label.text.strip_edges().is_empty()

	if _location.marker_icon != null:
		icon_rect.texture = _location.marker_icon
		icon_rect.modulate = _location.marker_tint
		icon_rect.show()
	else:
		icon_rect.hide()


func get_location() -> MapLocation:
	return _location


func set_selected(value: bool) -> void:
	_selected = value
	_apply_visual_state()


func _apply_visual_state() -> void:
	scale = Vector2.ONE * (1.06 if _selected else 1.0)
	z_index = 10 if _selected else 0


func _on_pressed() -> void:
	if _location == null:
		return

	marker_selected.emit(_location)
