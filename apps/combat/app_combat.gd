extends Control
class_name CombatApp


signal combat_finished(result: CombatResult)


const CHARACTER_SLOT_SCENE: PackedScene = preload(
	"res://apps/combat/character_slot_ui.tscn"
)
const TIMELINE_CARD_SCENE: PackedScene = preload(
	"res://apps/combat/timeline_action_card_ui.tscn"
)
const MODULE_SLOT_SCENE: PackedScene = preload(
	"res://apps/combat/module_slot_ui.tscn"
)


@export var ui_style: CombatUIStyleData = preload(
	"res://data/content/combat/default_combat_ui_style.tres"
)


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
	_apply_static_ui_style()
	_connect_manager_signals()
	_connect_ui_signals()

	resolution_screen.hide()
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
		execute_btn,
		run_away_btn,
		tooltip_label,
		resolution_title,
		continue_button,
		module_swap_ui.get_node("Title") as Label
	]

	for control in interface_controls:
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


func resume_saved_encounter() -> bool:
	var encounter := CombatManager.get_current_encounter()

	if encounter == null or not CombatManager.is_encounter_active():
		return false

	_current_encounter = encounter
	_pending_outcome = CombatResult.Outcome.CANCELLED
	_encounter_active = true
	resolution_screen.hide()
	module_swap_ui.hide()
	hide_tooltip()
	execute_btn.disabled = false
	change_modules_btn.disabled = false
	run_away_btn.disabled = false
	continue_button.disabled = false
	refresh_combat_field()
	show()
	return true


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
	ui_style.apply_font(
		label,
		ui_style.floating_text_font,
		ui_style.floating_text_font_size
	)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override(
		"font_shadow_color",
		ui_style.floating_text_shadow_color
	)
	label.add_theme_constant_override(
		"shadow_outline_size",
		ui_style.floating_text_outline_size
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
		- ui_style.floating_text_origin_offset
		- Vector2(0, current_offset)
	)
	floating_offsets[key] = (
		current_offset
		+ ui_style.floating_text_stack_spacing
	)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		label,
		"position",
		label.position
		+ ui_style.floating_text_travel
		+ Vector2(randf_range(-15, 15), 0),
		ui_style.floating_text_duration
	).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_property(
		label,
		"modulate:a",
		0.0,
		ui_style.floating_text_duration
	).set_delay(ui_style.floating_text_fade_delay)
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
		var slot := (
			CHARACTER_SLOT_SCENE.instantiate()
			as CharacterSlotUI
		)

		if slot == null:
			push_error(
				"CombatApp: CharacterSlotUI scene "
				+ "did not instantiate correctly."
			)
			continue

		container.add_child(slot)
		slot.tooltip_requested.connect(show_tooltip)
		slot.tooltip_hidden.connect(hide_tooltip)
		slot.field_refresh_requested.connect(
			refresh_combat_field
		)
		slot.setup(
			team_array[index],
			index,
			is_ally,
			CombatManager.get_position_slot(
				is_ally,
				index
			),
			ui_style
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
		var card := (
			TIMELINE_CARD_SCENE.instantiate()
			as TimelineActionCardUI
		)

		if card == null:
			push_error(
				"CombatApp: TimelineActionCardUI scene "
				+ "did not instantiate correctly."
			)
			continue

		timeline_bar.add_child(card)
		card.tooltip_requested.connect(show_tooltip)
		card.tooltip_hidden.connect(hide_tooltip)
		card.preview_requested.connect(
			func(preview_action: Dictionary) -> void:
				get_tree().call_group(
					"CombatUI",
					"preview_timeline_action",
					preview_action
				)
		)
		card.preview_cleared.connect(
			func() -> void:
				get_tree().call_group(
					"CombatUI",
					"clear_timeline_preview"
				)
		)
		card.setup(action, ui_style)


func _on_action_executed(
	index: int,
	_action_data: Dictionary
) -> void:
	floating_offsets.clear()

	if index >= timeline_bar.get_child_count():
		return

	var card := (
		timeline_bar.get_child(index)
		as TimelineActionCardUI
	)

	if card == null:
		return

	card.play_execution_feedback()


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
		var slot := (
			MODULE_SLOT_SCENE.instantiate()
			as ModuleSlotUI
		)

		if slot == null:
			continue

		equipped_list.add_child(slot)
		_connect_module_slot(slot)
		slot.setup(
			player.modules[index],
			index,
			true,
			ui_style
		)


func _populate_inventory_list() -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	var player_loadout := _get_player_loadout()

	if player_loadout == null:
		return

	for module in player_loadout.module_pool:
		var slot := (
			MODULE_SLOT_SCENE.instantiate()
			as ModuleSlotUI
		)

		if slot == null:
			continue

		inventory_list.add_child(slot)
		_connect_module_slot(slot)
		slot.setup(module, -1, false, ui_style)


func _connect_module_slot(slot: ModuleSlotUI) -> void:
	slot.tooltip_requested.connect(show_tooltip)
	slot.tooltip_hidden.connect(hide_tooltip)
	slot.modules_changed.connect(refresh_module_ui)


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

	var commit_errors: PackedStringArray = (
		CombatManager.commit_player_partner_state()
	)

	if not commit_errors.is_empty():
		for error: String in commit_errors:
			push_error("Combat partner write-back: %s" % error)
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
