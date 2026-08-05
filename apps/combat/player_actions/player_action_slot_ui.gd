extends PanelContainer
class_name PlayerActionSlotUI


signal tooltip_requested(text: String)
signal tooltip_hidden
signal assignment_requested(slot_index: int, action: PlayerActionData)
signal module_assignment_requested(slot_index: int, module: ModuleData)
signal clear_requested(slot_index: int)


enum ContentKind {
	EMPTY,
	MODULE,
	PLAYER_ACTION
}


@export var ui_style: CombatUIStyleData = preload(
	"res://data/content/combat/default_combat_ui_style.tres"
)

@onready var row: HBoxContainer = %Row
@onready var icon_rect: TextureRect = %ActionIcon
@onready var label: Label = %ActionName


var slot_index: int = -1
var current_action: PlayerActionData
var current_module: ModuleData
var target_uid: int = -1
var is_assigned_slot: bool = false
var content_kind: ContentKind = ContentKind.EMPTY


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
	setup_effective_slot(
		action,
		null,
		index,
		assigned_slot,
		assigned_target_uid,
		style
	)


func setup_effective_slot(
	action: PlayerActionData,
	module: ModuleData,
	index: int,
	assigned_slot: bool,
	assigned_target_uid: int = -1,
	style: CombatUIStyleData = null
) -> void:
	current_action = action
	current_module = module
	slot_index = index
	is_assigned_slot = assigned_slot
	target_uid = assigned_target_uid

	if style != null:
		ui_style = style

	_apply_style()
	_refresh_content()


func setup_player_action_inventory(
	action: PlayerActionData,
	style: CombatUIStyleData = null
) -> void:
	setup_effective_slot(
		action,
		null,
		-1,
		false,
		-1,
		style
	)


func _refresh_content() -> void:
	if current_action != null:
		content_kind = ContentKind.PLAYER_ACTION
		label.text = current_action.display_name
		icon_rect.texture = current_action.icon
		return

	if current_module != null:
		content_kind = ContentKind.MODULE
		label.text = current_module.module_name
		icon_rect.texture = current_module.module_icon
		return

	content_kind = ContentKind.EMPTY
	label.text = "EMPTY SLOT"
	icon_rect.texture = null


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
	match content_kind:
		ContentKind.PLAYER_ACTION:
			_set_drag_preview(current_action.display_name)
			return {
				"payload_kind": &"player_action",
				"source_slot": self,
				"player_action": current_action
			}

		ContentKind.MODULE:
			_set_drag_preview(current_module.module_name)
			return {
				"payload_kind": &"module",
				"source_slot": self,
				"module": current_module
			}

	return null


func _set_drag_preview(display_text: String) -> void:
	var preview := Label.new()
	preview.text = " %s " % display_text

	if ui_style != null:
		ui_style.apply_font(
			preview,
			ui_style.module_font,
			ui_style.module_font_size
		)

	set_drag_preview(preview)


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	if data is not Dictionary:
		return false

	if is_assigned_slot:
		return (
			data.get("player_action") is PlayerActionData
			or data.get("module") is ModuleData
		)

	return (
		data.get("player_action") is PlayerActionData
		and data.get("source_slot") is PlayerActionSlotUI
	)


func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:
	if is_assigned_slot:
		var action := data.get("player_action") as PlayerActionData

		if action != null:
			assignment_requested.emit(slot_index, action)
			return

		var module := data.get("module") as ModuleData

		if module != null:
			module_assignment_requested.emit(slot_index, module)
		return

	var source := data.get("source_slot") as PlayerActionSlotUI

	if source != null \
		and source.is_assigned_slot \
		and source.current_action != null:
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
	match content_kind:
		ContentKind.PLAYER_ACTION:
			tooltip_requested.emit(
				CombatManager.get_player_action_tooltip(
					current_action,
					target_uid
				)
			)

		ContentKind.MODULE:
			tooltip_requested.emit(
				CombatManager.get_module_tooltip(current_module)
			)


func _on_hover_out() -> void:
	tooltip_hidden.emit()
