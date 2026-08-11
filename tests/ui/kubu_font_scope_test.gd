extends Node


const TYPOGRAPHY: KubuTypographyData = preload(
	"res://data/content/ui/kubuos_micro_typography.tres"
)
const FONT_SCOPE_SCENE: PackedScene = preload(
	"res://systems/ui/kubu_font_scope.tscn"
)

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_check(TYPOGRAPHY.font_size == 6, "KubuOS Micro must remain authored at 6 px.")
	_check(
		TYPOGRAPHY.get_pixel_aligned_size(19) == 18,
		"Explicit KubuOS font sizes must snap to the six-pixel design grid."
	)
	_check(
		TYPOGRAPHY.get_pixel_aligned_size(24) == 24,
		"Valid integer multiples of six must retain their hierarchy."
	)
	_check(
		not TYPOGRAPHY.use_fallback_font,
		"KubuOS Micro must not mix Silver's incompatible 19 px grid as a fallback."
	)

	var resolved_font: Font = TYPOGRAPHY.get_font()
	_check(resolved_font != null, "KubuOS Micro typography did not resolve a Font.")

	if resolved_font is FontVariation:
		var variation := resolved_font as FontVariation
		var source := variation.base_font as FontFile
		_check(source != null, "KubuOS Micro must resolve through a FontFile source.")
		_check(
			variation.fallbacks.is_empty(),
			"KubuOS Micro must not render Silver at 6/12/18 px as a glyph fallback."
		)

		if source != null:
			_check(
				source.antialiasing == TextServer.FONT_ANTIALIASING_NONE,
				"Pixel font antialiasing must stay disabled."
			)
			_check(
				source.hinting == TextServer.HINTING_NONE,
				"Pixel font hinting must stay disabled."
			)
			_check(
				source.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED,
				"Pixel font subpixel positioning must stay disabled."
			)
			_check(
				not source.multichannel_signed_distance_field,
				"Pixel font must not use MSDF rendering."
			)
			_check(not source.generate_mipmaps, "Pixel font must not generate mipmaps.")
			_check(source.has_char("A".unicode_at(0)), "Embedded KubuOS font data is invalid.")

	var root := Control.new()
	root.name = "TypographyTestRoot"
	add_child(root)

	var label := Label.new()
	label.name = "InitialLabel"
	label.text = "KUBUOS"
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override(&"shadow_offset_x", 1)
	label.add_theme_constant_override(&"shadow_offset_y", 1)
	root.add_child(label)

	var large_label := Label.new()
	large_label.name = "LargeSystemTitle"
	large_label.add_theme_font_size_override(&"font_size", 24)
	root.add_child(large_label)

	var rich_text := RichTextLabel.new()
	rich_text.name = "CombatLog"
	rich_text.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 1))
	rich_text.add_theme_constant_override(&"outline_size", 1)
	root.add_child(rich_text)

	var scope := FONT_SCOPE_SCENE.instantiate() as KubuFontScope
	root.add_child(scope)
	await get_tree().process_frame

	_check(
		label.get_theme_font(&"font") == resolved_font,
		"Font scope did not apply KubuOS Micro to Label."
	)
	_check(
		label.get_theme_font_size(&"font_size") == 6,
		"Font scope did not apply the 6 px size to Label."
	)
	_check(
		label.get_theme_color(&"font_shadow_color").a == 0.0,
		"KubuOS Micro must clear inherited Silver font shadow color."
	)
	_check(
		label.get_theme_constant(&"shadow_offset_x") == 0
		and label.get_theme_constant(&"shadow_offset_y") == 0,
		"KubuOS Micro must clear inherited Silver shadow offsets."
	)
	_check(
		large_label.get_theme_font(&"font") == resolved_font,
		"Font scope did not apply KubuOS Micro to an explicitly sized Label."
	)
	_check(
		large_label.get_theme_font_size(&"font_size") == 24,
		"Font scope must preserve explicit hierarchy when it is a multiple of six."
	)
	_check(
		rich_text.get_theme_font(&"normal_font") == resolved_font,
		"Font scope did not apply KubuOS Micro to RichTextLabel variants."
	)
	_check(
		rich_text.get_theme_font_size(&"normal_font_size") == 6,
		"Font scope did not apply the 6 px size to RichTextLabel variants."
	)
	_check(
		rich_text.get_theme_color(&"font_outline_color").a == 0.0
		and rich_text.get_theme_constant(&"outline_size") == 0,
		"KubuOS Micro must clear inherited RichText outline rendering."
	)

	var dynamic_label := Label.new()
	dynamic_label.name = "DynamicCombatLabel"
	root.add_child(dynamic_label)
	await get_tree().process_frame

	_check(
		dynamic_label.get_theme_font(&"font") == resolved_font,
		"Font scope must cover text Controls added dynamically after _ready()."
	)
	_check(
		dynamic_label.get_theme_font_size(&"font_size") == 6,
		"Dynamic text Control did not inherit the KubuOS Micro size."
	)

	root.queue_free()
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("KUBU_FONT_SCOPE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("KUBU_FONT_SCOPE_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
