extends "res://apps/combat/app_combat.gd"
class_name DragActionCombatApp


enum LoadoutPanelMode {
	MODULES,
	PLAYER_ACTIONS
}


const PLAYER_ACTION_SLOT_SCENE: PackedScene = preload(
	"res://apps/combat/player_actions/player_action_slot_ui.tscn"
)


@onready var loadout_title: Label = (
	$OverlayLayer/ModuleSwapUI/Title
)


var _loadout_panel_mode: LoadoutPanelMode = (
	LoadoutPanelMode.MODULES
)


func _ready() -> void:
	# The base scene still owns the combat presentation, but this concrete
	# version replaces the legacy three-dropdown Player Action input.
	# Initialize explicitly so no legacy selector signal/path is touched.
	add_to_group("CombatUI")
	_apply_static_ui_style()
	_connect_manager_signals()
	_connect_ui_signals()

	player_action_selector.hide()
	resolution_panel.hide()
	evolution_overlay.hide()
	module_swap_ui.hide()
	hide_tooltip()
	refresh_combat_field()

	if CombatManager.is_encounter_active():
		resume_saved_encounter()


func _apply_static_ui_style() -> void:
	if ui_style == null:
		return

	var interface_controls: Array[Control] = [
		change_modules_btn,
		player_actions_btn,
		execute_btn,
		run_away_btn,
		tooltip_label,
		loadout_title,
		player_action_selector.get_node(
			"Margin/Rows/Title"
		) as Label,
		player_action_selector.get_node(
			"Margin/Rows/TargetOptions"
		) as OptionButton,
		player_action_selector.get_node(
			"Margin/Rows/Buttons/AssignButton"
		) as Button,
		player_action_selector.get_node(
			"Margin/Rows/Buttons/CloseButton"
		) as Button,
		resolution_panel.get_node(
			"Center/Box/TitleLabel"
		) as Label,
		resolution_panel.get_node(
			"Center/Box/SummaryLabel"
		) as Label,
		resolution_panel.get_node(
			"Center/Box/ModuleOptions"
		) as OptionButton,
		resolution_panel.get_node(
			"Center/Box/ConfirmChoiceButton"
		) as Button,
		resolution_panel.get_node(
			"Center/Box/ContinueButton"
		) as Button,
		evolution_overlay.get_node(
			"Center/Box/TitleLabel"
		) as Label,
		evolution_overlay.get_node(
			"Center/Box/RouteLabel"
		) as Label,
		evolution_overlay.get_node(
			"Center/Box/Buttons/EvolveButton"
		) as Button,
		evolution_overlay.get_node(
			"Center/Box/Buttons/HoldButton"
		) as Button
	]

	for control: Control in interface_controls:
		ui_style.apply_font(
			control,
			ui_style.interface_font,
			ui_style.interface_font_size
		)

	ui_style.apply_rich_text_font(
		combat_log,
		ui_style.interface_font,
		ui_style.interface_font_size
	)


func _connect_ui_signals() -> void:
	if not execute_btn.pressed.is_connected(
		_on_execute_pressed
	):
		execute_btn.pressed.connect(
			_on_execute_pressed
		)

	if not change_modules_btn.pressed.is_connected(
		_on_change_modules_pressed
	):
		change_modules_btn.pressed.connect(
			_on_change_modules_pressed
		)

	if not player_actions_btn.pressed.is_connected(
		_on_player_actions_pressed
	):
		player_actions_btn.pressed.connect(
			_on_player_actions_pressed
		)

	if not run_away_btn.pressed.is_connected(
		_on_run_away_pressed
	):
		run_away_btn.pressed.connect(
			_on_run_away_pressed
		)

	player_action_selector.target_selected.connect(
		_on_player_action_target_selected
	)
	player_action_selector.close_requested.connect(
		func() -> void:
			player_action_selector.hide()
	)
	resolution_panel.module_choice_requested.connect(
		_on_module_choice_requested
	)
	resolution_panel.continue_requested.connect(
		_on_continue_pressed
	)
	evolution_overlay.evolution_accepted.connect(
		_on_evolution_accepted
	)
	evolution_overlay.evolution_declined.connect(
		_on_evolution_declined
	)


func refresh_module_ui() -> void:
	if _loadout_panel_mode == LoadoutPanelMode.MODULES:
		super.refresh_module_ui()
		return

	_populate_player_action_slots()
	_populate_player_action_inventory()


func _on_change_modules_pressed() -> void:
	_toggle_loadout_panel(LoadoutPanelMode.MODULES)


func _on_player_actions_pressed() -> void:
	_toggle_loadout_panel(LoadoutPanelMode.PLAYER_ACTIONS)


func _toggle_loadout_panel(mode: LoadoutPanelMode) -> void:
	if not _encounter_active:
		return

	if module_swap_ui.visible \
		and _loadout_panel_mode == mode:
		module_swap_ui.hide()
		player_action_selector.hide()
		return

	_loadout_panel_mode = mode
	loadout_title.text = (
		"INVENTORY // DRAG MODULES TO SLOTS"
		if mode == LoadoutPanelMode.MODULES
		else "PLAYER ACTIONS // DRAG ACTIONS TO SLOTS"
	)

	player_action_selector.hide()
	refresh_module_ui()
	module_swap_ui.show()
	module_swap_ui.position = (
		_global_point_to_control_local(
			overlay_layer,
			menu_box.global_position
		)
		+ Vector2(menu_box.size.x + 10.0, 0.0)
	)


func _populate_player_action_slots() -> void:
	_clear_container(equipped_list)
	var player: Variant = CombatManager.get_player_actor()

	if player is not Dictionary:
		return

	var assignments: Array = player.get(
		"player_action_assignments",
		[]
	)

	for index: int in range(4):
		var action: PlayerActionData
		var target_uid: int = -1

		if index < assignments.size() \
			and assignments[index] is Dictionary:
			var assignment := assignments[index] as Dictionary
			action = _get_player_action_by_id(
				str(assignment.get("action_id", ""))
			)
			target_uid = int(
				assignment.get("target_uid", -1)
			)

		var slot := _create_player_action_slot(
			equipped_list
		)

		if slot == null:
			continue

		slot.setup(
			action,
			index,
			true,
			target_uid,
			ui_style
		)


func _populate_player_action_inventory() -> void:
	_clear_container(inventory_list)

	for action: PlayerActionData in (
		CombatManager.get_player_actions()
	):
		var slot := _create_player_action_slot(
			inventory_list
		)

		if slot == null:
			continue

		slot.setup(
			action,
			-1,
			false,
			-1,
			ui_style
		)


func _create_player_action_slot(
	container: Control
) -> PlayerActionSlotUI:
	var slot := (
		PLAYER_ACTION_SLOT_SCENE.instantiate()
		as PlayerActionSlotUI
	)

	if slot == null:
		push_error(
			"CombatApp: PlayerActionSlotUI scene "
			+ "did not instantiate correctly."
		)
		return null

	container.add_child(slot)
	slot.tooltip_requested.connect(show_tooltip)
	slot.tooltip_hidden.connect(hide_tooltip)
	slot.assignment_requested.connect(
		_on_player_action_dropped
	)
	slot.clear_requested.connect(
		_on_player_action_clear_requested
	)
	return slot


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _get_player_action_by_id(
	action_id: String
) -> PlayerActionData:
	var clean_id: String = action_id.strip_edges()

	for action: PlayerActionData in (
		CombatManager.get_player_actions()
	):
		if action != null \
			and action.action_id == clean_id:
			return action

	return null


func _on_player_action_dropped(
	slot_index: int,
	action: PlayerActionData
) -> void:
	if action == null:
		return

	var targets: Array = (
		CombatManager.get_available_player_action_targets(
			action.action_id
		)
	)

	if targets.is_empty():
		_show_player_action_feedback(
			"No valid target for %s."
			% action.display_name,
			true
		)
		return

	if targets.size() == 1 \
		and targets[0] is Dictionary:
		_assign_player_action(
			slot_index,
			action.action_id,
			int(
				(targets[0] as Dictionary).get(
					"uid",
					-1
				)
			)
		)
		return

	player_action_selector.setup(
		action,
		slot_index,
		targets
	)
	player_action_selector.position = (
		module_swap_ui.position
		+ Vector2(
			module_swap_ui.size.x + 8.0,
			0.0
		)
	)


func _on_player_action_target_selected(
	slot_index: int,
	action_id: String,
	target_uid: int
) -> void:
	_assign_player_action(
		slot_index,
		action_id,
		target_uid
	)


func _assign_player_action(
	slot_index: int,
	action_id: String,
	target_uid: int
) -> void:
	var errors: PackedStringArray = (
		CombatManager.set_player_action(
			slot_index,
			action_id,
			target_uid
		)
	)

	if not errors.is_empty():
		_show_player_action_feedback(
			"\n".join(errors),
			true
		)
		return

	_show_player_action_feedback(
		"SLOT %d ASSIGNED"
		% (slot_index + 1),
		false
	)
	refresh_module_ui()


func _on_player_action_clear_requested(
	slot_index: int
) -> void:
	if not CombatManager.clear_player_action(
		slot_index
	):
		return

	_show_player_action_feedback(
		"SLOT %d CLEARED"
		% (slot_index + 1),
		false
	)
	refresh_module_ui()


func _show_player_action_feedback(
	message: String,
	is_error: bool
) -> void:
	combat_log.append_text(
		"\n[color=%s]> %s[/color]\n"
		% [
			"red" if is_error else "lime",
			message
		]
	)
