extends Control

const APP_RAIL_SCENE: PackedScene = preload(
	"res://systems/desktop/dock/kubu_bottom_dock.tscn"
)
const APP_RAIL_ITEM_SCENE: PackedScene = preload(
	"res://systems/desktop/dock/kubu_dock_item.tscn"
)

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var test_size := Vector2(1280, 720)
	var original_left_width: float = KubuOSMetrics.reserved_left_width
	var original_right_width: float = KubuOSMetrics.reserved_right_width
	KubuOSMetrics.reserved_left_width = 0.0
	KubuOSMetrics.reserved_right_width = 0.0

	var rail := APP_RAIL_SCENE.instantiate() as KubuBottomDock
	_check(rail != null, "App rail failed to instantiate.")

	if rail != null:
		rail.dock_item_scene = APP_RAIL_ITEM_SCENE
		add_child(rail)
		await get_tree().process_frame

		_check(
			is_equal_approx(rail.rail_width, 30.0),
			"App rail no longer uses the compact 30 logical-unit width."
		)
		_check(
			is_zero_approx(KubuOSMetrics.reserved_left_width),
			"Right app rail left a legacy left-side workspace reservation."
		)
		_check(
			is_equal_approx(KubuOSMetrics.reserved_right_width, rail.rail_width),
			"App rail did not reserve its logical width on the right side."
		)
		_check(
			is_equal_approx(rail.sidebar_margin.offset_top, KubuOSMetrics.taskbar_height),
			"App rail does not begin directly below the top taskbar."
		)
		_check(
			is_equal_approx(rail.sidebar_margin.anchor_left, 1.0)
			and is_equal_approx(rail.sidebar_margin.anchor_right, 1.0),
			"App rail is not anchored to the right edge."
		)
		_check(
			is_equal_approx(rail.sidebar_margin.offset_left, -rail.rail_width)
			and is_zero_approx(rail.sidebar_margin.offset_right),
			"App rail scene width disagrees with its right-side reservation."
		)

		var work_rect: Rect2 = KubuOSMetrics.get_work_area_rect(test_size)
		_check(
			is_zero_approx(work_rect.position.x),
			"Right app rail incorrectly shifted the workspace origin."
		)
		_check(
			is_equal_approx(work_rect.end.x, test_size.x - rail.rail_width),
			"Workspace did not stop before the right app rail."
		)
		_check(
			is_equal_approx(work_rect.position.y, KubuOSMetrics.taskbar_height),
			"Workspace did not remain below the top taskbar."
		)
		_check(
			is_equal_approx(work_rect.end.y, test_size.y),
			"Removed bottom dock still reserves vertical workspace."
		)

		rail.queue_free()
		await get_tree().process_frame

	var item := APP_RAIL_ITEM_SCENE.instantiate() as KubuDockItem
	_check(item != null, "App rail item failed to instantiate.")

	if item != null:
		add_child(item)
		await get_tree().process_frame

		var app := AppResource.new()
		app.app_id = "test_app"
		app.app_name = "Test App"
		item.setup(app)
		await get_tree().process_frame

		_check(
			item.icon_button.tooltip_text.is_empty(),
			"Generic tooltip still competes with the custom app-name callout."
		)
		_check(
			item.hover_callout.position.x < item.position.x,
			"Hover callout is not positioned to the left of the right-side app icon."
		)

		item._on_mouse_entered()
		_check(item.hover_callout.visible, "Hover callout did not become visible on hover.")
		if item._hover_tween != null:
			item._hover_tween.custom_step(1.0)
		_check(item.app_name_label.text == "TEST APP", "Hover callout lost the app name.")
		_check(
			item.hover_line.scale.x > 0.95 and item.hover_line.modulate.a > 0.95,
			"Hover connector line did not finish its reveal animation."
		)

		item._on_mouse_exited()
		if item._hover_tween != null:
			item._hover_tween.custom_step(1.0)
		_check(not item.hover_callout.visible, "Hover callout did not hide after mouse exit.")

		item.set_badge_count(3)
		_check(item.badge_panel.visible, "Count badge did not become visible.")
		_check(item.badge_label.visible, "Count badge label did not become visible.")
		_check(item.badge_label.text == "3", "Count badge did not preserve its value.")
		_check(not item.badge_dot.visible, "Count badge incorrectly exposed the dot badge.")

		item.set_badge_dot()
		_check(item.badge_dot.visible, "Dot badge did not become visible.")
		_check(not item.badge_panel.visible, "Dot badge incorrectly exposed the count panel.")

		var badge_image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		badge_image.fill(Color.WHITE)
		var badge_texture := ImageTexture.create_from_image(badge_image)
		item.set_badge_icon(badge_texture)
		_check(item.badge_panel.visible, "Icon badge panel did not become visible.")
		_check(item.badge_icon.visible, "Icon badge did not become visible.")
		_check(item.badge_icon.texture == badge_texture, "Icon badge lost its supplied texture.")

		item.clear_badge()
		_check(
			not item.badge_panel.visible and not item.badge_dot.visible,
			"Clearing an app badge left badge chrome visible."
		)

		item.queue_free()
		await get_tree().process_frame

	KubuOSMetrics.reserved_left_width = original_left_width
	KubuOSMetrics.reserved_right_width = original_right_width
	KubuOSMetrics.emit_changed()
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("KUBU_APP_RAIL_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("KUBU_APP_RAIL_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
