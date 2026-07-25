extends Button
class_name NavigatorLocationMarker


signal marker_selected(location: MapLocation)


@export_category("Discovery Animation")
@export var discovery_start_scale: Vector2 = Vector2(
	0.72,
	0.72
)

@export var discovery_peak_scale: Vector2 = Vector2(
	1.16,
	1.16
)

@export_range(0.01, 1.0, 0.01)
var discovery_fade_duration: float = 0.10

@export_range(0.01, 1.0, 0.01)
var discovery_pop_duration: float = 0.20

@export_range(0.01, 1.0, 0.01)
var discovery_settle_duration: float = 0.18


@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var notice_badge_label: Label = (
	%NoticeBadgeLabel
)
@onready var danger_badge_label: Label = (
	%DangerBadgeLabel
)


var _location: MapLocation
var _runtime_state: NavigatorLocationRuntimeState
var _new_location_badge: NavigatorMarkerBadge
var _selected: bool = false

var _visual_tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	_apply_visual_state()


func setup(
	location: MapLocation,
	runtime_state: NavigatorLocationRuntimeState,
	new_location_badge: NavigatorMarkerBadge
) -> void:
	_location = location
	_new_location_badge = new_location_badge

	apply_runtime_state(runtime_state)


func apply_runtime_state(
	runtime_state: NavigatorLocationRuntimeState
) -> void:
	_runtime_state = runtime_state

	if _location == null or _runtime_state == null:
		hide()
		return

	visible = _runtime_state.should_show
	disabled = not _runtime_state.can_select()

	if not visible:
		return

	_apply_identity()
	_apply_icon()
	_apply_badges()
	_apply_visual_state()


func get_location() -> MapLocation:
	return _location


func set_selected(value: bool) -> void:
	_selected = value
	_apply_visual_state()


func play_discovery_animation() -> void:
	if not is_inside_tree():
		return

	if not visible:
		return

	_kill_visual_tween()

	pivot_offset = size * 0.5
	z_index = 20

	modulate.a = 0.0
	scale = discovery_start_scale

	var target_scale := Vector2.ONE * (
		1.06 if _selected else 1.0
	)

	_visual_tween = create_tween()

	_visual_tween.set_trans(
		Tween.TRANS_BACK
	)

	_visual_tween.set_ease(
		Tween.EASE_OUT
	)

	_visual_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		discovery_fade_duration
	)

	_visual_tween.parallel().tween_property(
		self,
		"scale",
		discovery_peak_scale,
		discovery_pop_duration
	)

	_visual_tween.tween_property(
		self,
		"scale",
		target_scale,
		discovery_settle_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await _visual_tween.finished

	_visual_tween = null
	_apply_visual_state()


func _apply_identity() -> void:
	var reveal_identity: bool = (
		_runtime_state.is_discovered
		or _runtime_state.is_progression_unlocked
		or _location.reveal_identity_when_locked
	)

	if reveal_identity:
		title_label.text = (
			_location.get_marker_title()
		)

		subtitle_label.text = (
			_location.get_marker_subtitle()
		)
	else:
		title_label.text = "UNKNOWN LOCATION"
		subtitle_label.text = ""

	if not _runtime_state.availability_message.is_empty():
		subtitle_label.text = (
			_runtime_state.availability_message
		)

	subtitle_label.visible = (
		not subtitle_label.text.strip_edges().is_empty()
	)


func _apply_icon() -> void:
	if _location.marker_icon == null:
		icon_rect.hide()
		return

	icon_rect.texture = _location.marker_icon
	icon_rect.modulate = _location.marker_tint
	icon_rect.show()


func _apply_badges() -> void:
	var notice_badge: NavigatorMarkerBadge = (
		_location.activity_badge
	)

	if (
		_runtime_state.is_new
		and _new_location_badge != null
	):
		notice_badge = _new_location_badge

	_apply_badge_to_label(
		notice_badge_label,
		notice_badge
	)

	_apply_badge_to_label(
		danger_badge_label,
		_location.danger_badge
	)


func _apply_badge_to_label(
	label: Label,
	badge: NavigatorMarkerBadge
) -> void:
	if badge == null or badge.is_empty():
		label.hide()
		label.text = ""
		label.tooltip_text = ""
		return

	label.text = badge.text
	label.modulate = badge.tint
	label.tooltip_text = badge.tooltip_text
	label.show()


func _apply_visual_state() -> void:
	pivot_offset = size * 0.5
	z_index = 10 if _selected else 0

	if (
		_visual_tween != null
		and _visual_tween.is_valid()
	):
		return

	scale = Vector2.ONE * (
		1.06 if _selected else 1.0
	)

	modulate.a = 1.0


func _kill_visual_tween() -> void:
	if (
		_visual_tween != null
		and _visual_tween.is_valid()
	):
		_visual_tween.kill()

	_visual_tween = null


func _on_pressed() -> void:
	if _location == null:
		return

	if _runtime_state == null:
		return

	if not _runtime_state.can_select():
		return

	marker_selected.emit(_location)
