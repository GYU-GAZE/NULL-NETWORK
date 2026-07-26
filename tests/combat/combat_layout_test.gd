extends Control

const COMBAT_SCENE: PackedScene = preload(
	"res://apps/combat/app_combat.tscn"
)
const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)
const ENCOUNTER_2X_BREAKPOINT := Vector2(530, 377)
const LARGE_2X_COMBAT_SIZE := Vector2(640, 360)
const DEFAULT_OUTER_COMBAT_SIZE := Vector2(640, 255)
const LAYOUT_EPSILON: float = 1.0
const DENSITY_1X_VISUAL_SCALE := Vector2(0.5, 0.5)
const KUBU_DEFAULT_FONT_SIZE: int = 19


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var kubu_density_theme := Theme.new()
	kubu_density_theme.default_font_size = (
		KUBU_DEFAULT_FONT_SIZE
	)
	theme = kubu_density_theme

	var adaptive_visual_root := Control.new()
	adaptive_visual_root.name = "AdaptiveVisualRoot"
	adaptive_visual_root.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)
	adaptive_visual_root.position = Vector2.ZERO
	adaptive_visual_root.size = LARGE_2X_COMBAT_SIZE
	add_child(adaptive_visual_root)

	var combat_app := COMBAT_SCENE.instantiate() as CombatApp

	if combat_app == null:
		_fail("Combat scene did not instantiate CombatApp.")
		return

	adaptive_visual_root.add_child(combat_app)
	combat_app.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)
	combat_app.position = Vector2.ZERO
	combat_app.size = LARGE_2X_COMBAT_SIZE

	if not combat_app.start_encounter(TEST_ENCOUNTER):
		_fail("CombatApp rejected the layout test encounter.")
		return

	await get_tree().process_frame
	await get_tree().process_frame

	if not await _status_icons_render(combat_app):
		return

	if not _combat_uses_kubu_font_density(combat_app):
		return

	var combined_minimum: Vector2 = (
		combat_app.get_combined_minimum_size()
	)

	if (
		combined_minimum.x
		> ENCOUNTER_2X_BREAKPOINT.x
		+ LAYOUT_EPSILON
		or combined_minimum.y
		> ENCOUNTER_2X_BREAKPOINT.y
		+ LAYOUT_EPSILON
	):
		_fail(
			"Combat minimum %s exceeds its 2x breakpoint %s."
			% [
				combined_minimum,
				ENCOUNTER_2X_BREAKPOINT
			]
		)
		return

	if not combat_app.size.is_equal_approx(
		LARGE_2X_COMBAT_SIZE
	):
		_fail(
			"CombatApp expanded to %s instead of staying at %s."
			% [
				combat_app.size,
				LARGE_2X_COMBAT_SIZE
			]
		)
		return

	var required_paths: Array[NodePath] = [
		NodePath("ContentMargin/BattleBox/EnemiesContainer"),
		NodePath("ContentMargin/BattleBox/CenterHBox"),
		NodePath("ContentMargin/BattleBox/AlliesContainer")
	]

	for node_path in required_paths:
		var control := combat_app.get_node_or_null(
			node_path
		) as Control

		if control == null:
			_fail(
				"Required combat layout node '%s' is missing."
				% node_path
			)
			return

		if not _control_fits_inside(
			control,
			combat_app
		):
			_fail(
				"Combat layout node '%s' escaped the app: %s."
				% [
					node_path,
					control.get_global_rect()
				]
			)
			return

	var team_paths: Array[NodePath] = [
		NodePath("ContentMargin/BattleBox/EnemiesContainer"),
		NodePath("ContentMargin/BattleBox/AlliesContainer")
	]

	for team_path in team_paths:
		var team := combat_app.get_node(team_path) as Control

		for child in team.get_children():
			if (
				child is Control
				and not _control_fits_inside(
					child as Control,
					combat_app
				)
			):
				_fail(
					"Character slot in '%s' escaped the app."
					% team_path
				)
				return

	if not _timeline_is_centered(combat_app):
		return

	if not _timeline_slots_are_square(combat_app):
		return

	if not await _combat_inherits_adaptive_scale(
		combat_app,
		adaptive_visual_root
	):
		return

	var desktop_size := Vector2(640, 360)
	var work_area: Rect2 = (
		KubuOSMetrics.get_work_area_rect(desktop_size)
	)
	var expected_work_area := Rect2(
		Vector2(0, KubuOSMetrics.taskbar_height),
		Vector2(
			desktop_size.x,
			desktop_size.y
			- KubuOSMetrics.taskbar_height
			- KubuOSMetrics.dock_height
		)
	)

	if work_area != expected_work_area:
		_fail(
			"Workspace %s does not preserve the dock area %s."
			% [work_area, expected_work_area]
		)
		return

	print("COMBAT_LAYOUT_TEST: PASS")
	get_tree().quit(0)


func _combat_uses_kubu_font_density(
	combat_app: CombatApp
) -> bool:
	var text_controls: Array[Control] = [
		combat_app.get_node(
			"ContentMargin/BattleBox/CenterHBox/MenuBox/ChangeModulesBtn"
		) as Control,
		combat_app.get_node(
			"ContentMargin/BattleBox/CenterHBox/MenuBox/ExecuteBtn"
		) as Control,
		combat_app.get_node(
			"ContentMargin/BattleBox/CenterHBox/MenuBox/RunAwayBtn"
		) as Control,
		combat_app.get_node(
			"OverlayLayer/ModuleSwapUI/Title"
		) as Control,
		combat_app.get_node(
			"OverlayLayer/ResolutionScreen/ResolutionCenter/ResolutionBox/ResolutionTitle"
		) as Control
	]

	var timeline_bar := combat_app.get_node(
		"ContentMargin/BattleBox/CenterHBox/TimelineScroll/TimelineBar"
	) as HBoxContainer
	var first_timeline_card := (
		timeline_bar.get_child(0) as PanelContainer
	)
	var timeline_box := (
		first_timeline_card.get_child(0) as VBoxContainer
	)
	var timeline_label := (
		timeline_box.get_child(
			timeline_box.get_child_count() - 1
		) as Label
	)
	text_controls.append(timeline_label)

	var allies := combat_app.get_node(
		"ContentMargin/BattleBox/AlliesContainer"
	) as HBoxContainer
	var player_slot := (
		allies.get_child(0) as CharacterSlotUI
	)
	var actor_frame := (
		player_slot.get_child(0) as PanelContainer
	)
	var actor_content := (
		actor_frame.get_child(0) as VBoxContainer
	)
	var actor_header := (
		actor_content.get_child(0) as Label
	)
	var hp_bar := (
		player_slot.get_child(1) as ProgressBar
	)
	var hp_label := hp_bar.get_child(0) as Label
	text_controls.append(actor_header)
	text_controls.append(hp_label)

	for control in text_controls:
		if control == null:
			_fail("A required combat text control is missing.")
			return false

		if control.has_theme_font_size_override(
			"font_size"
		):
			_fail(
				"Combat text '%s' still overrides the global font size."
				% control.name
			)
			return false

		if control.get_theme_font_size(
			"font_size"
		) != KUBU_DEFAULT_FONT_SIZE:
			_fail(
				"Combat text '%s' resolved font size %d instead of KubuOS %d."
				% [
					control.name,
					control.get_theme_font_size(
						"font_size"
					),
					KUBU_DEFAULT_FONT_SIZE
				]
			)
			return false

	return true


func _status_icons_render(
	combat_app: CombatApp
) -> bool:
	var player: Variant = CombatManager.get_player_actor()
	var barrier := load(
		"res://data/content/combat/status_effects/defense_up.tres"
	) as StatusEffectData

	if player == null or barrier == null:
		_fail("Barrier status UI fixture did not load.")
		return false

	player["active_statuses"].append(
		CombatStatusInstance.create(
			barrier,
			3,
			int(player.get("uid", -1)),
			CombatManager.current_cycle
		)
	)
	combat_app.refresh_combat_field()
	await get_tree().process_frame

	var allies := combat_app.get_node(
		"ContentMargin/BattleBox/AlliesContainer"
	) as HBoxContainer
	var player_slot := (
		allies.get_child(0) as CharacterSlotUI
	)
	var status_row := player_slot.find_child(
		"StatusRow",
		true,
		false
	) as HBoxContainer

	if status_row == null or status_row.get_child_count() != 1:
		_fail("BARRIER status icon did not render above the actor.")
		return false

	var status_icon := status_row.get_child(0) as Control
	var tooltip := status_icon.tooltip_text

	if (
		not tooltip.contains("BARRIER")
		or not tooltip.contains("Stacks: 3/99")
		or not tooltip.contains("Duration: permanent")
	):
		_fail(
			"Status tooltip does not explain name, stacks and duration."
		)
		return false

	return true


func _timeline_slots_are_square(
	combat_app: CombatApp
) -> bool:
	var timeline_bar := combat_app.get_node(
		"ContentMargin/BattleBox/CenterHBox/TimelineScroll/TimelineBar"
	) as HBoxContainer
	var found_module_icon: bool = false

	for child in timeline_bar.get_children():
		var panel := child as PanelContainer

		if panel == null:
			continue

		if (
			not is_equal_approx(
				panel.custom_minimum_size.x,
				panel.custom_minimum_size.y
			)
			or not is_equal_approx(
				panel.size.x,
				panel.size.y
			)
		):
			_fail(
				"Timeline action slot is not square: min=%s size=%s."
				% [
					panel.custom_minimum_size,
					panel.size
				]
			)
			return false

		var box := panel.get_child(0) as VBoxContainer

		if (
			box != null
			and box.get_child_count() >= 2
			and box.get_child(0) is TextureRect
		):
			found_module_icon = true

	if not found_module_icon:
		_fail(
			"No timeline action rendered its Module icon above the name."
		)
		return false

	return true


func _combat_inherits_adaptive_scale(
	combat_app: CombatApp,
	adaptive_visual_root: Control
) -> bool:
	var overlay_controls: Array[Control] = [
		combat_app,
		combat_app.get_node("OverlayLayer") as Control,
		combat_app.get_node(
			"OverlayLayer/ModuleSwapUI"
		) as Control,
		combat_app.get_node(
			"OverlayLayer/HoverTooltip"
		) as Control,
		combat_app.get_node(
			"OverlayLayer/ResolutionScreen"
		) as Control
	]

	adaptive_visual_root.size = DEFAULT_OUTER_COMBAT_SIZE
	adaptive_visual_root.scale = (
		DENSITY_1X_VISUAL_SCALE
	)
	combat_app.size = (
		DEFAULT_OUTER_COMBAT_SIZE
		/ DENSITY_1X_VISUAL_SCALE
	)

	await get_tree().process_frame

	for control in overlay_controls:
		if control == null:
			_fail("A required combat overlay is missing.")
			return false

		var inherited_scale: Vector2 = (
			control.get_global_transform().get_scale()
		)

		if not inherited_scale.is_equal_approx(
			DENSITY_1X_VISUAL_SCALE
		):
			_fail(
				"Combat control '%s' escaped adaptive 1x scale: %s."
				% [control.name, inherited_scale]
			)
			return false

	var visual_combat_size: Vector2 = (
		combat_app.get_global_rect().size
	)

	if not visual_combat_size.is_equal_approx(
		DEFAULT_OUTER_COMBAT_SIZE
	):
		_fail(
			"Combat 1x visual size %s does not match outer area %s."
			% [
				visual_combat_size,
				DEFAULT_OUTER_COMBAT_SIZE
			]
		)
		return false

	if not _combat_overlay_coordinates_are_transform_safe(
		combat_app
	):
		return false

	adaptive_visual_root.scale = Vector2.ONE
	adaptive_visual_root.size = LARGE_2X_COMBAT_SIZE
	combat_app.size = LARGE_2X_COMBAT_SIZE
	await get_tree().process_frame
	return true


func _combat_overlay_coordinates_are_transform_safe(
	combat_app: CombatApp
) -> bool:
	var overlay_layer := combat_app.get_node(
		"OverlayLayer"
	) as Control
	var menu_box := combat_app.get_node(
		"ContentMargin/BattleBox/CenterHBox/MenuBox"
	) as VBoxContainer
	var module_swap_ui := combat_app.get_node(
		"OverlayLayer/ModuleSwapUI"
	) as VBoxContainer
	var floating_text_layer := combat_app.get_node(
		"OverlayLayer/FloatingTextLayer"
	) as Control

	if (
		overlay_layer == null
		or menu_box == null
		or module_swap_ui == null
		or floating_text_layer == null
	):
		_fail("Required transform-safe combat overlays are missing.")
		return false

	combat_app._on_change_modules_pressed()

	if not module_swap_ui.visible:
		_fail("Module inventory did not open.")
		return false

	var expected_swap_position: Vector2 = (
		overlay_layer.get_global_transform().affine_inverse()
		* menu_box.global_position
		+ Vector2(menu_box.size.x + 10, 0)
	)

	if not module_swap_ui.position.is_equal_approx(
		expected_swap_position
	):
		_fail(
			"Module inventory local position %s does not match %s at 1x."
			% [
				module_swap_ui.position,
				expected_swap_position
			]
		)
		return false

	combat_app._on_change_modules_pressed()

	if module_swap_ui.visible:
		_fail("Module inventory did not close after coordinate test.")
		return false

	var actor_uids: Array = combat_app.actor_nodes.keys()

	if actor_uids.is_empty():
		_fail("Combat actor map is empty during floating text test.")
		return false

	var actor_uid: int = int(actor_uids[0])
	var target_node := combat_app.actor_nodes.get(
		actor_uid
	) as Control

	if target_node == null:
		_fail("Floating text target is missing.")
		return false

	var previous_child_count: int = (
		floating_text_layer.get_child_count()
	)
	combat_app._spawn_floating_text(
		{"uid": actor_uid},
		"TEST",
		Color.WHITE
	)

	if floating_text_layer.get_child_count() != (
		previous_child_count + 1
	):
		_fail("Floating text was not added to its overlay layer.")
		return false

	var floating_label := floating_text_layer.get_child(
		previous_child_count
	) as Label

	if floating_label == null:
		_fail("Floating text overlay did not create a Label.")
		return false

	var expected_floating_position: Vector2 = (
		floating_text_layer.get_global_transform().affine_inverse()
		* target_node.get_global_rect().get_center()
		- Vector2(20, 20)
	)

	if not floating_label.position.is_equal_approx(
		expected_floating_position
	):
		_fail(
			"Floating text local position %s does not match %s at 1x."
			% [
				floating_label.position,
				expected_floating_position
			]
		)
		return false

	floating_label.queue_free()
	combat_app.floating_offsets.clear()
	return true


func _timeline_is_centered(
	combat_app: CombatApp
) -> bool:
	var timeline_scroll := combat_app.get_node_or_null(
		"ContentMargin/BattleBox/CenterHBox/TimelineScroll"
	) as ScrollContainer
	var timeline_bar := combat_app.get_node_or_null(
		"ContentMargin/BattleBox/CenterHBox/TimelineScroll/TimelineBar"
	) as HBoxContainer

	if timeline_scroll == null or timeline_bar == null:
		_fail("Timeline nodes are missing.")
		return false

	if timeline_bar.get_child_count() != 8:
		_fail(
			"Expected 8 timeline modules, got %d."
			% timeline_bar.get_child_count()
		)
		return false

	var scroll_center_x: float = (
		timeline_scroll.get_global_rect().get_center().x
	)
	var timeline_center_x: float = (
		timeline_bar.get_global_rect().get_center().x
	)
	var combat_center_x: float = (
		combat_app.get_global_rect().get_center().x
	)

	if absf(timeline_center_x - scroll_center_x) > LAYOUT_EPSILON:
		_fail(
			"Timeline center %.2f does not match its available area %.2f."
			% [timeline_center_x, scroll_center_x]
		)
		return false

	if absf(scroll_center_x - combat_center_x) > LAYOUT_EPSILON:
		_fail(
			"Timeline area center %.2f does not match app center %.2f."
			% [scroll_center_x, combat_center_x]
		)
		return false

	return true


func _control_fits_inside(
	control: Control,
	container: Control
) -> bool:
	var inner_rect: Rect2 = control.get_global_rect()
	var outer_rect: Rect2 = container.get_global_rect()

	return (
		inner_rect.position.x
		>= outer_rect.position.x - LAYOUT_EPSILON
		and inner_rect.position.y
		>= outer_rect.position.y - LAYOUT_EPSILON
		and inner_rect.end.x
		<= outer_rect.end.x + LAYOUT_EPSILON
		and inner_rect.end.y
		<= outer_rect.end.y + LAYOUT_EPSILON
	)


func _fail(message: String) -> void:
	push_error("COMBAT_LAYOUT_TEST: " + message)
	get_tree().quit(1)
