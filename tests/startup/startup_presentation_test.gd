extends Node


const STARTUP_SCENE: PackedScene = preload(
	"res://systems/startup/startup_presentation.tscn"
)

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var startup := STARTUP_SCENE.instantiate() as StartupPresentation
	_check(startup != null, "Startup presentation scene failed to instantiate.")

	if startup == null:
		_finish_test()
		return

	add_child(startup)
	startup.set_anchors_preset(Control.PRESET_TOP_LEFT)
	startup.size = Vector2(640.0, 360.0)
	await get_tree().process_frame
	_check(
		startup.presentation_data != null,
		"Startup presentation has no presentation data."
	)
	_check(
		startup.get_node_or_null("BootLayer/NullBrandAnchor") != null,
		"NULL NETWORK branding no longer belongs to the persistent boot presentation."
	)

	if startup.presentation_data != null:
		startup.presentation_data = (
			startup.presentation_data.duplicate(true)
			as StartupPresentationData
		)
		_check(
			startup.presentation_data != null
			and startup.presentation_data.splashes.size() == 2,
			"Default startup must contain exactly two custom splash entries."
		)

		if startup.presentation_data != null:
			for splash: StartupSplashData in startup.presentation_data.splashes:
				if splash == null:
					continue

				splash.fade_in_seconds = 0.01
				splash.hold_seconds = 0.0
				splash.fade_out_seconds = 0.01

			startup.presentation_data.logo_ignite_seconds = 0.01
			startup.presentation_data.null_logo_build_seconds = 0.01
			startup.presentation_data.logo_hold_seconds = 0.0
			startup.presentation_data.screen_power_seconds = 0.01
			startup.presentation_data.reveal_seconds = 0.02

	startup.play(TimeManager.TimePeriod.DAY)
	await startup.boot_completed
	_check(startup.visible, "Startup backdrop should remain available after boot.")

	var kubu_anchor := startup.get_node_or_null(
		"BootLayer/BootLogoAnchor"
	) as Control
	var null_anchor := startup.get_node_or_null(
		"BootLayer/NullBrandAnchor"
	) as Control

	if kubu_anchor != null and null_anchor != null:
		_check(
		null_anchor.position.y < kubu_anchor.position.y,
			"NULL NETWORK did not finish above the displaced KubuOS logo."
		)
		var null_center_x: float = null_anchor.position.x + null_anchor.size.x * 0.5
		_check(
			is_equal_approx(null_center_x, startup.size.x * 0.5),
			"NULL NETWORK final branding is no longer horizontally centered."
		)
		_check_brand_bounds(startup, kubu_anchor, "KubuOS default")
		_check_brand_bounds(startup, null_anchor, "NULL NETWORK default")
		_check(kubu_anchor.scale == Vector2.ONE, "Silver KubuOS fallback ended on a non-native scale.")
		_check(null_anchor.scale == Vector2.ONE, "Silver NULL fallback ended on a non-native scale.")

		startup.size = Vector2(480.0, 270.0)
		startup._on_viewport_size_changed()
		await startup.show_login_state(TimeManager.TimePeriod.DAY)
		_check_brand_bounds(startup, kubu_anchor, "KubuOS minimum")
		_check_brand_bounds(startup, null_anchor, "NULL NETWORK minimum")

	startup.stop_and_hide()
	_check(not startup.visible, "Startup presentation did not hide on shutdown.")
	startup.queue_free()
	await get_tree().process_frame
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _check_brand_bounds(startup: StartupPresentation, control: Control, label: String) -> void:
	var rect := control.get_rect()
	_check(rect.position.x >= 0.0 and rect.position.y >= 0.0, "%s starts outside the canvas." % label)
	_check(rect.end.x <= startup.size.x and rect.end.y <= startup.size.y, "%s ends outside the canvas." % label)
	_check(
		is_equal_approx(control.position.x, round(control.position.x))
		and is_equal_approx(control.position.y, round(control.position.y)),
		"%s no longer rests on the logical pixel grid." % label
	)


func _finish_test() -> void:
	if _failures.is_empty():
		print("STARTUP_PRESENTATION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("STARTUP_PRESENTATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
