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

	startup.stop_and_hide()
	_check(not startup.visible, "Startup presentation did not hide on shutdown.")
	startup.queue_free()
	await get_tree().process_frame
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("STARTUP_PRESENTATION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("STARTUP_PRESENTATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
