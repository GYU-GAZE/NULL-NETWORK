extends PanelContainer
class_name PlayerActionSlotUI


signal tooltip_requested(text: String)
signal tooltip_hidden
signal assignment_requested(slot_index: int, action: PlayerActionData)
signal clear_requested(slot_index: int)


@export var ui_style: CombatUIStyleData = preload(
	"res://data/content/combat/default_combat_ui_style.tres"
)

@onready var row: HBoxContainer = %Row
@onready var icon_rect: TextureRect = %ActionIcon
@onready var label: Label = %ActionName


var slot_index: int = -1
var current_action: PlayerActionData
var target_uid: int = -1
var is_assigned_slot: bool = false


func _ready() -> void:
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)
	gui_input.connect(_on_gui_input)


func setup(
	action: PlayerActionData,
	index: int,
	assigned_slot: bool,
	assigned_target_uid: int = -1,
	style: CombatUIStyleData = null
) -> void:
	current_action = action
	slot_index = index
	is_assigned_slot = assigned_slot
	target_uid = assigned_target_uid

	if style != null:
		ui_style = style

	_apply_style()
	label.text = (
		action.display_name
		if action != null
		else "EMPTY ACTION"
	)
	icon_rect.texture = (
		action.icon
		if action != null
		else null
	)


func _apply_style() -> void:
	if ui_style == null:
		return

	custom_minimum_size = ui_style.module_slot_size
	icon_rect.custom_minimum_size = ui_style.module_icon_size
	row.add_theme_constant_override(
		"separation",
		ui_style.module_separation
	)
	add_theme_stylebox_override(
		"panel",
		ui_style.copy_style(ui_style.module_slot_style)
	)
	ui_style.apply_font(
		label,
		ui_style.module_font,
		ui_style.module_font_size
	)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if current_action == null:
		return null

	var preview := Label.new()
	preview.text = " %s " % current_action.display_name

	if ui_style != null:
		ui_style.apply_font(
			preview,
			ui_style.module_font,
			ui_style.module_font_size
		)

	set_drag_preview(preview)
	return {
		"payload_kind": &"player_action",
		"source_slot": self,
		"player_action": current_action
	}


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	return (
		data is Dictionary
		and data.get("payload_kind", &"") == &"player_action"
		and data.get("player_action") is PlayerActionData
	)


func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:
	var action := data.get("player_action") as PlayerActionData
	var source := data.get("source_slot") as PlayerActionSlotUI

	if action == null:
		return

	if is_assigned_slot:
		assignment_requested.emit(slot_index, action)
		return

	if source != null and source.is_assigned_slot:
		clear_requested.emit(source.slot_index)


func _on_gui_input(event: InputEvent) -> void:
	if not is_assigned_slot or current_action == null:
		return

	if event is not InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT \
		and mouse_event.pressed:
		clear_requested.emit(slot_index)
		accept_event()


func _on_hover_in() -> void:
	if current_action == null:
		return

	tooltip_requested.emit(
		CombatManager.get_player_action_tooltip(
			current_action,
			target_uid
		)
	)


func _on_hover_out() -> void:
	tooltip_hidden.emit()
