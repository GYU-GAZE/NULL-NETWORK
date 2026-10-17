extends Button
class_name AssessmentResultTendencyRow


var definition: TendencyDefinitionData


func setup(tendency_definition: TendencyDefinitionData, value: int) -> void:
	definition = tendency_definition
	if definition == null:
		text = "UNRESOLVED  //  %02d" % value
		return

	name = "Tendency%s" % definition.display_name.capitalize().replace(" ", "")
	text = "%s  //  %02d" % [definition.display_name, value]
	tooltip_text = definition.description
	add_theme_color_override("font_color", definition.accent_color)
	add_theme_color_override("font_hover_color", Color(0.94, 0.98, 1.0, 1.0))
	add_theme_stylebox_override("normal", _make_style(false))
	add_theme_stylebox_override("hover", _make_style(true))
	add_theme_stylebox_override("focus", _make_style(true))
	add_theme_stylebox_override("pressed", _make_style(true))


func _make_style(hovered: bool) -> StyleBoxFlat:
	var accent := (
		definition.accent_color
		if definition != null
		else Color(0.12, 0.68, 1.0, 1.0)
	)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(
		accent.r * (0.12 if hovered else 0.055),
		accent.g * (0.12 if hovered else 0.055),
		accent.b * (0.12 if hovered else 0.055),
		0.94
	)
	style.border_width_left = 2 if hovered else 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(
		accent.r,
		accent.g,
		accent.b,
		0.88 if hovered else 0.5
	)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	style.corner_radius_bottom_left = 1
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	return style
