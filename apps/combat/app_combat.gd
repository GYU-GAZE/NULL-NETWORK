extends Control
class_name CombatApp


signal combat_finished(result: CombatResult)


var floating_offsets: Dictionary = {}
var actor_nodes: Dictionary = {}

@onready var menu_box: VBoxContainer = %MenuBox
@onready var execute_btn: Button = %ExecuteBtn
@onready var change_modules_btn: Button = %ChangeModulesBtn
@onready var run_away_btn: Button = %RunAwayBtn
@onready var module_swap_ui: VBoxContainer = %ModuleSwapUI
@onready var equipped_list: VBoxContainer = %EquippedModulesList
@onready var inventory_list: VBoxContainer = %InventoryModulesList

@onready var timeline_bar: HBoxContainer = %TimelineBar
@onready var enemies_container: HBoxContainer = %EnemiesContainer
@onready var allies_container: HBoxContainer = %AlliesContainer
@onready var combat_log: RichTextLabel = %CombatLog

@onready var overlay_layer: Control = %OverlayLayer
@onready var floating_text_layer: Control = %FloatingTextLayer
@onready var hover_tooltip: PanelContainer = %HoverTooltip
@onready var tooltip_label: Label = %TooltipLabel

@onready var resolution_screen: PanelContainer = %ResolutionScreen
@onready var resolution_title: Label = %ResolutionTitle
@onready var continue_button: Button = %ContinueButton


var _current_encounter: CombatEncounter
var _pending_outcome: CombatResult.Outcome = (
	CombatResult.Outcome.CANCELLED
)
var _encounter_active: bool = false


func _ready() -> void:
	add_to_group("CombatUI")
	_connect_manager_signals()
	_connect_ui_signals()

	resolution_screen.hide()
	module_swap_ui.hide()
	hide_tooltip()
	refresh_combat_field()


func start_encounter(
	encounter: CombatEncounter
) -> bool:
	if encounter == null:
		push_error(
			"CombatApp: cannot start a null encounter."
		)
		return false

	_current_encounter = encounter
	_pending_outcome = CombatResult.Outcome.CANCELLED
	_encounter_active = true

	combat_log.clear()
	floating_offsets.clear()
	resolution_screen.hide()
	module_swap_ui.hide()
	hide_tooltip()

	execute_btn.disabled = false
	change_modules_btn.disabled = false
	run_away_btn.disabled = false
	continue_button.disabled = false

	if not CombatManager.load_encounter(
		_current_encounter
	):
		_encounter_active = false
		_current_encounter = null
		return false

	refresh_combat_field()
	show()
	return true


func is_encounter_active() -> bool:
	return _encounter_active


func _connect_manager_signals() -> void:
	if not CombatManager.timeline_generated.is_connected(
		_on_timeline_generated
	):
		CombatManager.timeline_generated.connect(
			_on_timeline_generated
		)

	if not CombatManager.stats_updated.is_connected(
		_update_field_ui
	):
		CombatManager.stats_updated.connect(
			_update_field_ui
		)

	if not CombatManager.action_executed.is_connected(
		_on_action_executed
	):
		CombatManager.action_executed.connect(
			_on_action_executed
		)

	if not CombatManager.combat_log_added.is_connected(
		_update_log
	):
		CombatManager.combat_log_added.connect(
			_update_log
		)

	if not CombatManager.floating_text_requested.is_connected(
		_spawn_floating_text
	):
		CombatManager.floating_text_requested.connect(
			_spawn_floating_text
		)

	if not CombatManager.combat_victory.is_connected(
		_on_victory
	):
		CombatManager.combat_victory.connect(
			_on_victory
		)

	if not CombatManager.combat_defeat.is_connected(
		_on_defeat
	):
		CombatManager.combat_defeat.connect(
			_on_defeat
		)

	if not CombatManager.cycle_ended_ready_for_next.is_connected(
		_on_cycle_ended
	):
		CombatManager.cycle_ended_ready_for_next.connect(
			_on_cycle_ended
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

	if not run_away_btn.pressed.is_connected(
		_on_run_away_pressed
	):
		run_away_btn.pressed.connect(
			_on_run_away_pressed
		)

	if not continue_button.pressed.is_connected(
		_on_continue_pressed
	):
		continue_button.pressed.connect(
			_on_continue_pressed
		)


func _update_log(message: String) -> void:
	if not _encounter_active:
		return

	combat_log.append_text(message + "\n")


func refresh_combat_field() -> void:
	_update_field_ui()


func _spawn_floating_text(
	actor: Dictionary,
	text: String,
	color: Color
) -> void:
	if not _encounter_active:
		return

	var key: int = int(actor.get("uid", -1))

	if not actor_nodes.has(key):
		return

	var target_node := actor_nodes[key] as Control

	if target_node == null:
		return

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)
	label.add_theme_constant_override(
		"shadow_outline_size",
		4
	)
	floating_text_layer.add_child(label)

	var current_offset: int = int(
		floating_offsets.get(key, 0)
	)

	label.position = (
		_global_point_to_control_local(
			floating_text_layer,
			target_node.get_global_rect().get_center()
		)
		- Vector2(20, 20 + current_offset)
	)
	floating_offsets[key] = current_offset + 35

	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		label,
		"position",
		label.position
		+ Vector2(randf_range(-15, 15), -60),
		0.8
	).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_property(
		label,
		"modulate:a",
		0.0,
		0.8
	).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)


func _update_field_ui() -> void:
	actor_nodes.clear()
	_draw_team(
		CombatManager.enemy_team,
		enemies_container,
		false
	)
	_draw_team(
		CombatManager.ally_team,
		allies_container,
		true
	)


func _draw_team(
	team_array: Array,
	container: Control,
	is_ally: bool
) -> void:
	for child in container.get_children():
		child.queue_free()

	for index in range(4):
		var slot := CharacterSlotUI.new()
		container.add_child(slot)
		slot.setup(
			team_array[index],
			index,
			is_ally,
			CombatManager.get_position_slot(
				is_ally,
				index
			)
		)

		if team_array[index] != null:
			var actor_uid: int = int(
				team_array[index].get("uid", -1)
			)
			actor_nodes[actor_uid] = slot.icon_rect


func _on_timeline_generated(actions: Array) -> void:
	for child in timeline_bar.get_children():
		child.queue_free()

	for action in actions:
		var slot_center := CenterContainer.new()
		slot_center.custom_minimum_size = Vector2(48, 48)
		slot_center.size_flags_horizontal = (
			Control.SIZE_SHRINK_CENTER
		)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(48, 48)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var module: ModuleData = action.module

		if module != null:
			var tooltip_text: String = (
				CombatManager.get_module_tooltip(
					module,
					action
				)
			)
			panel.mouse_entered.connect(
				func() -> void:
					show_tooltip(tooltip_text)
					get_tree().call_group(
						"CombatUI",
						"preview_timeline_action",
						action
					)
			)
			panel.mouse_exited.connect(
				func() -> void:
					hide_tooltip()
					get_tree().call_group(
						"CombatUI",
						"clear_timeline_preview"
					)
			)

		var background_color := Color.CRIMSON

		if action.actor.is_ally:
			background_color = (
				Color.DODGER_BLUE
				if action.actor.is_player
				else Color.LIME_GREEN
			)

		var style := StyleBoxFlat.new()
		style.bg_color = background_color.darkened(0.4)
		style.border_width_bottom = 4
		style.border_color = background_color
		panel.add_theme_stylebox_override("panel", style)

		var module_box := VBoxContainer.new()
		module_box.alignment = BoxContainer.ALIGNMENT_CENTER
		module_box.add_theme_constant_override(
			"separation",
			1
		)

		if module != null and module.module_icon != null:
			var icon := TextureRect.new()
			icon.texture = module.module_icon
			icon.expand_mode = (
				TextureRect.EXPAND_IGNORE_SIZE
			)
			icon.stretch_mode = (
				TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			)
			icon.custom_minimum_size = Vector2(18, 18)
			module_box.add_child(icon)
		else:
			var icon_fallback := Label.new()
			icon_fallback.text = (
				module.module_name.left(1)
				if module != null
				else "?"
			)
			icon_fallback.custom_minimum_size = (
				Vector2(18, 18)
			)
			icon_fallback.horizontal_alignment = (
				HORIZONTAL_ALIGNMENT_CENTER
			)
			icon_fallback.vertical_alignment = (
				VERTICAL_ALIGNMENT_CENTER
			)
			module_box.add_child(icon_fallback)

		var label := Label.new()
		label.text = (
			(
				"%s ×%d"
				% [
					module.module_name,
					module.execution_count
				]
				if module.execution_count > 1
				else module.module_name
			)
			if module != null
			else "VAZIO"
		)
		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		label.clip_text = true
		label.text_overrun_behavior = (
			TextServer.OVERRUN_TRIM_ELLIPSIS
		)
		module_box.add_child(label)

		panel.add_child(module_box)
		slot_center.add_child(panel)
		timeline_bar.add_child(slot_center)


func _on_action_executed(
	index: int,
	_action_data: Dictionary
) -> void:
	floating_offsets.clear()

	if index >= timeline_bar.get_child_count():
		return

	var slot_center := timeline_bar.get_child(index) as Control

	if slot_center == null or slot_center.get_child_count() == 0:
		return

	var panel := slot_center.get_child(0) as Control

	if panel == null:
		return

	panel.modulate = Color(0.3, 0.3, 0.3, 1.0)

	var tween := create_tween()
	var original_position: Vector2 = panel.position
	tween.tween_property(
		panel,
		"position",
		original_position + Vector2(5, -5),
		0.05
	)
	tween.tween_property(
		panel,
		"position",
		original_position + Vector2(-5, 5),
		0.05
	)
	tween.tween_property(
		panel,
		"position",
		original_position,
		0.05
	)


func refresh_module_ui() -> void:
	_populate_equip_list()
	_populate_inventory_list()


func _populate_equip_list() -> void:
	for child in equipped_list.get_children():
		child.queue_free()

	var player: Variant = (
		CombatManager.get_player_actor()
	)

	if player == null:
		return

	for index in range(4):
		var slot := ModuleSlotUI.new()
		equipped_list.add_child(slot)
		slot.setup(player.modules[index], index, true)


func _populate_inventory_list() -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	var player_loadout := _get_player_loadout()

	if player_loadout == null:
		return

	for module in player_loadout.module_pool:
		var slot := ModuleSlotUI.new()
		inventory_list.add_child(slot)
		slot.setup(module, -1, false)


func _get_player_loadout() -> CharacterLoadout:
	if _current_encounter == null:
		return null

	for slot_data in _current_encounter.ally_slots:
		if slot_data == null:
			continue

		if slot_data.slot_index != 0:
			continue

		if not slot_data.is_available():
			continue

		return slot_data.character

	return null


func _process(_delta: float) -> void:
	if hover_tooltip.visible:
		hover_tooltip.global_position = (
			get_global_mouse_position()
			+ Vector2(15, 15)
		)


func _global_point_to_control_local(
	control: Control,
	global_point: Vector2
) -> Vector2:
	return (
		control.get_global_transform().affine_inverse()
		* global_point
	)


func show_tooltip(text: String) -> void:
	tooltip_label.text = text
	hover_tooltip.show()


func hide_tooltip() -> void:
	hover_tooltip.hide()


func _on_execute_pressed() -> void:
	if not _encounter_active:
		return

	execute_btn.disabled = true
	change_modules_btn.disabled = true
	run_away_btn.disabled = true
	module_swap_ui.hide()
	CombatManager.execute_cycle()


func _on_change_modules_pressed() -> void:
	if not _encounter_active:
		return

	module_swap_ui.visible = not module_swap_ui.visible

	if not module_swap_ui.visible:
		return

	refresh_module_ui()
	module_swap_ui.position = (
		_global_point_to_control_local(
			overlay_layer,
			menu_box.global_position
		)
		+ Vector2(menu_box.size.x + 10, 0)
	)


func _on_run_away_pressed() -> void:
	if not _encounter_active:
		return

	execute_btn.disabled = true
	change_modules_btn.disabled = true
	run_away_btn.disabled = true

	if CombatManager.try_escape():
		_finish_encounter(
			CombatResult.Outcome.ESCAPED
		)
		return

	execute_btn.disabled = false
	change_modules_btn.disabled = false
	run_away_btn.disabled = false


func _on_cycle_ended() -> void:
	if not _encounter_active:
		return

	execute_btn.disabled = false
	change_modules_btn.disabled = false
	run_away_btn.disabled = false


func _on_victory() -> void:
	if not _encounter_active:
		return

	_pending_outcome = CombatResult.Outcome.VICTORY
	_show_resolution(
		"VITÓRIA",
		Color.LIME_GREEN
	)


func _on_defeat() -> void:
	if not _encounter_active:
		return

	_pending_outcome = CombatResult.Outcome.DEFEAT
	_show_resolution(
		"DERROTA CRÍTICA",
		Color.CRIMSON
	)


func _show_resolution(
	title: String,
	color: Color
) -> void:
	execute_btn.disabled = true
	change_modules_btn.disabled = true
	run_away_btn.disabled = true
	module_swap_ui.hide()

	resolution_title.text = title
	resolution_title.add_theme_color_override(
		"font_color",
		color
	)
	resolution_screen.show()


func _on_continue_pressed() -> void:
	if not _encounter_active:
		return

	if _pending_outcome == CombatResult.Outcome.CANCELLED:
		return

	continue_button.disabled = true
	_finish_encounter(_pending_outcome)


func _finish_encounter(
	outcome: CombatResult.Outcome
) -> void:
	if not _encounter_active:
		return

	_encounter_active = false
	resolution_screen.hide()
	module_swap_ui.hide()
	hide_tooltip()

	var encounter_id: String = ""

	if _current_encounter != null:
		encounter_id = _current_encounter.encounter_id

	var result := CombatResult.create(
		outcome,
		encounter_id,
		CombatManager.get_result_metadata()
	)
	combat_finished.emit(result)
