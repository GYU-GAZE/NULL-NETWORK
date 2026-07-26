extends Control

const COMBAT_SCENE: PackedScene = preload(
	"res://apps/combat/app_combat.tscn"
)
const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)
const MINIMUM_LOGICAL_COMBAT_SIZE := Vector2(480, 251)
const LAYOUT_EPSILON: float = 1.0


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var combat_app := COMBAT_SCENE.instantiate() as CombatApp

	if combat_app == null:
		_fail("Combat scene did not instantiate CombatApp.")
		return

	add_child(combat_app)
	combat_app.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)
	combat_app.position = Vector2.ZERO
	combat_app.size = MINIMUM_LOGICAL_COMBAT_SIZE

	if not combat_app.start_encounter(TEST_ENCOUNTER):
		_fail("CombatApp rejected the layout test encounter.")
		return

	await get_tree().process_frame
	await get_tree().process_frame

	var combined_minimum: Vector2 = (
		combat_app.get_combined_minimum_size()
	)

	if (
		combined_minimum.x
		> MINIMUM_LOGICAL_COMBAT_SIZE.x
		+ LAYOUT_EPSILON
		or combined_minimum.y
		> MINIMUM_LOGICAL_COMBAT_SIZE.y
		+ LAYOUT_EPSILON
	):
		_fail(
			"Combat minimum %s exceeds supported area %s."
			% [
				combined_minimum,
				MINIMUM_LOGICAL_COMBAT_SIZE
			]
		)
		return

	if not combat_app.size.is_equal_approx(
		MINIMUM_LOGICAL_COMBAT_SIZE
	):
		_fail(
			"CombatApp expanded to %s instead of staying at %s."
			% [
				combat_app.size,
				MINIMUM_LOGICAL_COMBAT_SIZE
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

	print("COMBAT_LAYOUT_TEST: PASS")
	get_tree().quit(0)


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
