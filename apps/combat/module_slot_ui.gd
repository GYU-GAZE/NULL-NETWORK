extends PanelContainer
class_name ModuleSlotUI


signal tooltip_requested(text: String)
signal tooltip_hidden
signal modules_changed


@export var ui_style: CombatUIStyleData = preload(
	"res://data/content/combat/default_combat_ui_style.tres"
)

@onready var row: HBoxContainer = %Row
@onready var icon_rect: TextureRect = %ModuleIcon
@onready var label: Label = %ModuleName


var slot_index: int = -1
var current_module: ModuleData
var is_equipped_slot: bool = false


func _ready() -> void:
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)


func setup(
	module: ModuleData,
	index: int,
	is_equipped: bool,
	style: CombatUIStyleData = null
) -> void:
	current_module = module
	slot_index = index
	is_equipped_slot = is_equipped

	if style != null:
		ui_style = style

	_apply_style()
	label.text = (
		module.module_name
		if module != null
		else "EMPTY"
	)
	icon_rect.texture = (
		module.module_icon
		if module != null
		else null
	)


func _apply_style() -> void:
	if ui_style == null:
		return

	custom_minimum_size = ui_style.module_slot_size
	icon_rect.custom_minimum_size = (
		ui_style.module_icon_size
	)
	row.add_theme_constant_override(
		"separation",
		ui_style.module_separation
	)
	add_theme_stylebox_override(
		"panel",
		ui_style.copy_style(
			ui_style.module_slot_style
		)
	)
	ui_style.apply_font(
		label,
		ui_style.module_font,
		ui_style.module_font_size
	)


func _get_drag_data(
	_at_position: Vector2
) -> Variant:
	if current_module == null:
		return null

	var preview := Label.new()
	preview.text = " %s " % current_module.module_name

	if ui_style != null:
		ui_style.apply_font(
			preview,
			ui_style.module_font,
			ui_style.module_font_size
		)

	set_drag_preview(preview)
	return {
		"source_slot": self,
		"module": current_module
	}


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	return (
		data is Dictionary
		and data.get("module") is ModuleData
	)


func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:
	var source := (
		data.get("source_slot") as ModuleSlotUI
	)
	var dragged_module := (
		data.get("module") as ModuleData
	)

	if source == null or dragged_module == null:
		return

	if is_equipped_slot:
		if source.is_equipped_slot:
			CombatManager.set_player_module(
				source.slot_index,
				current_module
			)

		CombatManager.set_player_module(
			slot_index,
			dragged_module
		)
	elif source.is_equipped_slot:
		CombatManager.set_player_module(
			source.slot_index,
			null
		)

	modules_changed.emit()


func _on_hover_in() -> void:
	if current_module == null:
		return

	tooltip_requested.emit(
		CombatManager.get_module_tooltip(
			current_module
		)
	)


func _on_hover_out() -> void:
	tooltip_hidden.emit()
