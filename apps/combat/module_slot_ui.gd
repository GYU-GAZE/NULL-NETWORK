extends PanelContainer
class_name ModuleSlotUI


var slot_index: int = -1
var current_module: ModuleData
var is_equipped_slot: bool = false
var label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(100, 60)
	label = Label.new()
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD
	)
	add_child(label)
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)


func setup(
	module: ModuleData,
	index: int,
	is_equipped: bool
) -> void:
	current_module = module
	slot_index = index
	is_equipped_slot = is_equipped
	label.text = (
		module.module_name
		if module != null
		else "EMPTY"
	)


func _get_drag_data(
	_at_position: Vector2
) -> Variant:
	if current_module == null:
		return null

	var preview := Label.new()
	preview.text = " %s " % current_module.module_name
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

	get_tree().call_group(
		"CombatUI",
		"refresh_module_ui"
	)


func _on_hover_in() -> void:
	if current_module == null:
		return

	get_tree().call_group(
		"CombatUI",
		"show_tooltip",
		CombatManager.get_module_tooltip(
			current_module
		)
	)


func _on_hover_out() -> void:
	get_tree().call_group(
		"CombatUI",
		"hide_tooltip"
	)
