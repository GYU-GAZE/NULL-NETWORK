extends Control

const TOP_TASKBAR_SCENE: PackedScene = preload(
	"res://systems/desktop/kubu_top_taskbar.tscn"
)
const BOTTOM_DOCK_SCENE: PackedScene = preload(
	"res://systems/desktop/dock/kubu_bottom_dock.tscn"
)
const PRESENTATION_DATA: KubuShellPresentationData = preload(
	"res://data/content/desktop/default_kubu_shell_presentation.tres"
)

var _failures := PackedStringArray()

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	size = Vector2(1280, 720)
	var data_errors: PackedStringArray = PRESENTATION_DATA.validate_data()
	_check(data_errors.is_empty(), "Default shell presentation data is invalid.")

	var top := TOP_TASKBAR_SCENE.instantiate() as KubuTopTaskbar
	var bottom := BOTTOM_DOCK_SCENE.instantiate() as KubuBottomDock
	_check(top != null, "Top taskbar failed to instantiate.")
	_check(bottom != null, "App rail failed to instantiate.")

	if top != null and bottom != null:
		add_child(top)
		add_child(bottom)
		await get_tree().process_frame

		top.prepare_shell_reveal(PRESENTATION_DATA.first_run_top_hidden_scale_y)
		bottom.prepare_shell_reveal(PRESENTATION_DATA.first_run_bottom_hidden_scale)
		_check(top.modulate.a == 0.0, "Prepared top taskbar is not visually hidden.")
		_check(
			is_equal_approx(top.scale.y, PRESENTATION_DATA.first_run_top_hidden_scale_y),
			"Prepared top taskbar lost its authored reveal scale."
		)
		_check(
			bottom.dock_panel.modulate.a == 0.0,
			"Prepared app rail is not visually hidden."
		)
		_check(
			bottom.dock_panel.scale.is_equal_approx(Vector2(
				PRESENTATION_DATA.first_run_bottom_hidden_scale.x,
				1.0
			)),
			"Prepared app rail lost its authored horizontal reveal scale."
		)

		top.start_shell_reveal(0.05)
		bottom.start_shell_reveal(0.05)
		await get_tree().create_timer(0.07).timeout
		top.finish_shell_reveal()
		bottom.finish_shell_reveal()
		_check(
			top.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(top.modulate.a, 1.0),
			"Top taskbar reveal did not settle at its stable transform."
		)
		_check(
			bottom.dock_panel.scale.is_equal_approx(Vector2.ONE)
			and is_equal_approx(bottom.dock_panel.modulate.a, 1.0),
			"App rail reveal did not settle at its stable transform."
		)

		top.queue_free()
		bottom.queue_free()

	await get_tree().process_frame
	_finish_test()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish_test() -> void:
	if _failures.is_empty():
		print("KUBU_SHELL_PRESENTATION_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("KUBU_SHELL_PRESENTATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
