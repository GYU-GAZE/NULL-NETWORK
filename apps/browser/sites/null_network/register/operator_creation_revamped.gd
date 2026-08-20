extends OperatorCreationPage
class_name OperatorCreationRevampedPage


signal onboarding_handoff_requested(operator_id: String)

const TENDENCY_CATALOG: TendencyCatalogData = preload(
	"res://data/content/tendencies/default_tendency_catalog.tres"
)
const PARTNER_COMMENT_CATALOG: PartnerOnboardingCommentCatalogData = preload(
	"res://data/content/onboarding/partner_first_sync_comments.tres"
)
const RESULT_TENDENCY_ORDER := ["valour", "logic", "sync", "self"]

var _result_tendency_rows: VBoxContainer
var _result_tendency_context: PanelContainer
var _result_tendency_context_label: Label
var _result_assignment_intro: Label
var _result_assigned_species: Label
var _result_actions: Control
var _result_tendency_controls: Array[Control] = []

var _completion_stage: VBoxContainer
var _completion_status: Label
var _arrival_visual: Control
var _arrival_particle_field: Control
var _arrival_sprite: TextureRect
var _arrival_name: Label
var _arrival_comment: RichTextLabel
var _complete_body: Label
var _pixel_materializer: PixelMaterializer
var _partner_typewriter: TypewriterReveal

var _pending_completion_candidate: CompatibilityCandidateData
var _pending_completion_tendencies: Dictionary = {}
var _pending_completion_mode: String = ""


func _ready() -> void:
	super._ready()
	_validate_presentation_catalogs()
	_configure_result_presentation()
	_configure_completion_presentation()
	if not CampaignState.operator.is_empty() and not CampaignState.partner.is_empty():
		_show_existing_completion_state()


func _validate_presentation_catalogs() -> void:
	for validation_error: String in TENDENCY_CATALOG.validate_data():
		push_error("Tendency presentation: %s" % validation_error)
	for validation_error: String in PARTNER_COMMENT_CATALOG.validate_data():
		push_error("Partner onboarding presentation: %s" % validation_error)


func _configure_result_presentation() -> void:
	var legacy_title := result_content.get_node_or_null("ResultTitle") as Control
	if legacy_title != null:
		legacy_title.hide()

	result_content.add_theme_constant_override("separation", 7)
	result_tendencies.text = "YOUR TENDENCIES ARE:"
	result_tendencies.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	result_tendencies.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0, 1.0))

	_result_tendency_rows = VBoxContainer.new()
	_result_tendency_rows.name = "ResultTendencyRows"
	_result_tendency_rows.add_theme_constant_override("separation", 4)
	result_content.add_child(_result_tendency_rows)
	result_content.move_child(
		_result_tendency_rows,
		result_tendencies.get_index() + 1
	)

	_result_tendency_context = PanelContainer.new()
	_result_tendency_context.name = "ResultTendencyContext"
	_result_tendency_context.custom_minimum_size = Vector2(0, 48)
	_result_tendency_context.add_theme_stylebox_override(
		"panel",
		_make_context_style()
	)
	_result_tendency_context_label = Label.new()
	_result_tendency_context_label.name = "ContextLabel"
	_result_tendency_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_tendency_context_label.add_theme_color_override(
		"font_color",
		Color(0.64, 0.78, 0.86, 1.0)
	)
	_result_tendency_context.add_child(_result_tendency_context_label)
	result_content.add_child(_result_tendency_context)
	result_content.move_child(
		_result_tendency_context,
		_result_tendency_rows.get_index() + 1
	)
	_reset_tendency_context()

	_result_assignment_intro = Label.new()
	_result_assignment_intro.name = "ResultAssignmentIntro"
	_result_assignment_intro.text = "YOU HAVE BEEN ASSIGNED TO..."
	_result_assignment_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_assignment_intro.add_theme_color_override(
		"font_color",
		Color(0.58, 0.78, 0.9, 1.0)
	)
	result_content.add_child(_result_assignment_intro)
	result_content.move_child(
		_result_assignment_intro,
		_result_tendency_context.get_index() + 1
	)

	_result_assigned_species = Label.new()
	_result_assigned_species.name = "ResultAssignedSpecies"
	_result_assigned_species.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_assigned_species.add_theme_font_size_override("font_size", 22)
	_result_assigned_species.add_theme_color_override(
		"font_color",
		Color(0.9, 0.98, 1.0, 1.0)
	)
	result_content.add_child(_result_assigned_species)
	result_content.move_child(
		_result_assigned_species,
		_result_assignment_intro.get_index() + 1
	)

	_result_actions = accept_result_button.get_parent() as Control
	accept_result_button.text = "ACCEPT PARTNER"
	retake_assessment_button.text = "RETAKE ASSESSMENT"
	result_manual_button.text = "CHOOSE MANUALLY"
	accept_result_button.custom_minimum_size = Vector2(190, 40)
	retake_assessment_button.custom_minimum_size = Vector2(190, 40)
	result_manual_button.custom_minimum_size = Vector2(170, 40)
	_apply_primary_result_button_style(accept_result_button)


func _build_tendency_rows(tendencies: Dictionary) -> void:
	_clear_container(_result_tendency_rows)
	_result_tendency_controls.clear()
	for tendency_id: String in RESULT_TENDENCY_ORDER:
		var definition := TENDENCY_CATALOG.get_definition(tendency_id)
		if definition == null:
			continue
		var row := Button.new()
		row.name = "Tendency%s" % definition.display_name.capitalize().replace(" ", "")
		row.custom_minimum_size = Vector2(0, 34)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.focus_mode = Control.FOCUS_ALL
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.text = "%s  //  %02d" % [
			definition.display_name,
			int(tendencies.get(tendency_id, 0))
		]
		row.tooltip_text = definition.description
		row.add_theme_color_override("font_color", definition.accent_color)
		row.add_theme_color_override("font_hover_color", Color(0.94, 0.98, 1.0, 1.0))
		row.add_theme_stylebox_override(
			"normal",
			_make_tendency_row_style(definition.accent_color, false)
		)
		row.add_theme_stylebox_override(
			"hover",
			_make_tendency_row_style(definition.accent_color, true)
		)
		row.add_theme_stylebox_override(
			"focus",
			_make_tendency_row_style(definition.accent_color, true)
		)
		row.add_theme_stylebox_override(
			"pressed",
			_make_tendency_row_style(definition.accent_color, true)
		)
		row.mouse_entered.connect(_show_tendency_context.bind(definition))
		row.mouse_exited.connect(_reset_tendency_context)
		row.focus_entered.connect(_show_tendency_context.bind(definition))
		row.focus_exited.connect(_reset_tendency_context)
		_result_tendency_rows.add_child(row)
		_result_tendency_controls.append(row)


func _show_tendency_context(definition: TendencyDefinitionData) -> void:
	if definition == null or _result_tendency_context_label == null:
		return
	_result_tendency_context_label.text = "%s // %s" % [
		definition.display_name,
		definition.description
	]
	_result_tendency_context_label.add_theme_color_override(
		"font_color",
		definition.accent_color.lightened(0.28)
	)


func _reset_tendency_context() -> void:
	if _result_tendency_context_label == null:
		return
	_result_tendency_context_label.text = "HOVER A TENDENCY FOR CONTEXT."
	_result_tendency_context_label.add_theme_color_override(
		"font_color",
		Color(0.48, 0.64, 0.74, 1.0)
	)


func _play_result_loading() -> void:
	_result_sequence_generation += 1
	var generation := _result_sequence_generation
	result_loading.show()
	result_content.hide()
	loading_label.text = "CALCULATING COMPATIBILITY..."
	accept_result_button.disabled = true
	retake_assessment_button.disabled = true
	result_manual_button.disabled = true
	for child: Node in result_status_lines.get_children():
		if child is Control:
			(child as Control).hide()

	await _motion_player.enter_control(loading_label, Vector2(0, 3), 0.13)
	for child: Node in result_status_lines.get_children():
		if not _result_sequence_is_current(generation):
			return
		var status_line := child as Control
		if status_line == null:
			continue
		status_line.show()
		await _motion_player.enter_control(status_line, Vector2(0, 3), 0.11)
		await get_tree().create_timer(0.07).timeout

	if not _result_sequence_is_current(generation):
		return
	await get_tree().create_timer(0.16).timeout
	loading_label.text = "MATCH FOUND"
	await _motion_player.flash_control(
		loading_label,
		Color(1.2, 1.3, 1.4, 1.0),
		0.1
	)
	await get_tree().create_timer(0.34).timeout
	if not _result_sequence_is_current(generation):
		return

	_show_result_content(false)
	result_tendencies.show()
	await _motion_player.enter_control(result_tendencies, Vector2(0, 3), 0.14)
	await get_tree().create_timer(0.18).timeout

	for row: Control in _result_tendency_controls:
		if not _result_sequence_is_current(generation):
			return
		row.show()
		await _motion_player.enter_control(row, Vector2(0, 3), 0.12)
		await get_tree().create_timer(0.22).timeout

	if not _result_sequence_is_current(generation):
		return
	_result_tendency_context.show()
	await _motion_player.enter_control(
		_result_tendency_context,
		Vector2(0, 2),
		0.11
	)
	await get_tree().create_timer(0.46).timeout

	_result_assignment_intro.show()
	await _motion_player.enter_control(
		_result_assignment_intro,
		Vector2(0, 3),
		0.14
	)
	await get_tree().create_timer(0.62).timeout
	if not _result_sequence_is_current(generation):
		return

	_result_assigned_species.show()
	await _motion_player.enter_control(
		_result_assigned_species,
		Vector2(0, 4),
		0.16
	)
	await _motion_player.flash_control(
		_result_assigned_species,
		Color(1.18, 1.28, 1.34, 1.0),
		0.1
	)
	await get_tree().create_timer(0.42).timeout
	if not _result_sequence_is_current(generation):
		return

	result_partner_preview_host.show()
	await _motion_player.enter_control(
		result_partner_preview_host,
		Vector2(0, 4),
		0.14
	)
	if _result_preview != null:
		for step: Control in _result_preview.get_reveal_steps():
			if not _result_sequence_is_current(generation):
				return
			if step == null:
				continue
			step.show()
			await _motion_player.enter_control(step, Vector2(0, 3), 0.11)
			await get_tree().create_timer(0.09).timeout

	await get_tree().create_timer(0.2).timeout
	if not _result_sequence_is_current(generation):
		return
	if _result_actions != null:
		_result_actions.show()
		await _motion_player.enter_control(_result_actions, Vector2(0, 3), 0.14)
	_unlock_result_actions()


func _show_result_content(unlock_actions: bool = true) -> void:
	result_loading.hide()
	result_content.show()
	var tendencies := _dictionary_value(_assessment_result.get("tendencies", {}))
	_build_tendency_rows(tendencies)
	_reset_tendency_context()

	var candidate: CompatibilityCandidateData = null
	if assessment_data != null:
		candidate = assessment_data.get_candidate(
			str(_assessment_result.get("candidate_id", ""))
		)
	_result_assigned_species.text = (
		candidate.display_name if candidate != null else "UNRESOLVED"
	)

	var variant_info := _dictionary_value(
		_assessment_result.get("variant_placeholder", {})
	)
	var variant_id := str(variant_info.get("selected_variant_id", ""))
	_result_preview = _replace_partner_preview(
		result_partner_preview_host,
		candidate,
		variant_id
	)

	var settled := unlock_actions
	result_tendencies.visible = settled
	_result_tendency_context.visible = settled
	_result_assignment_intro.visible = settled
	_result_assigned_species.visible = settled
	result_partner_preview_host.visible = settled
	if _result_actions != null:
		_result_actions.visible = settled
	for row: Control in _result_tendency_controls:
		row.visible = settled
	if _result_preview != null:
		_result_preview.set_reveal_state(settled)

	if settled:
		_unlock_result_actions()


func _unlock_result_actions() -> void:
	if _result_actions != null:
		_result_actions.show()
	super._unlock_result_actions()


func _result_sequence_is_current(generation: int) -> bool:
	return (
		generation == _result_sequence_generation
		and _current_page == FlowPage.RESULT
	)


func _finalize_registration(
	candidate: CompatibilityCandidateData,
	tendencies: Dictionary,
	mode: String
) -> void:
	_pending_completion_candidate = candidate
	_pending_completion_tendencies = tendencies.duplicate(true)
	_pending_completion_mode = mode
	accept_result_button.disabled = true
	retake_assessment_button.disabled = true
	result_manual_button.disabled = true
	manual_synchronize_button.disabled = true
	await super._finalize_registration(candidate, tendencies, mode)
	if CampaignState.partner.is_empty():
		if mode == "assessment":
			_unlock_result_actions()
		else:
			_refresh_manual_state()


func _configure_completion_presentation() -> void:
	_complete_body = registered_panel.get_node_or_null("CompleteBody") as Label
	if _complete_body != null:
		_complete_body.text = "Synchronization is complete. The partner instance is now bound to this Operator."

	_completion_stage = VBoxContainer.new()
	_completion_stage.name = "PartnerArrivalStage"
	_completion_stage.add_theme_constant_override("separation", 6)

	_completion_status = Label.new()
	_completion_status.name = "PartnerArrivalStatus"
	_completion_status.text = "SYNCHRONIZING PARTNER INSTANCE..."
	_completion_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_completion_status.add_theme_color_override(
		"font_color",
		Color(0.3, 0.78, 1.0, 1.0)
	)
	_completion_stage.add_child(_completion_status)

	_arrival_visual = Control.new()
	_arrival_visual.name = "PartnerArrivalVisual"
	_arrival_visual.custom_minimum_size = Vector2(0, 124)
	_arrival_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_completion_stage.add_child(_arrival_visual)

	_arrival_particle_field = Control.new()
	_arrival_particle_field.name = "ParticleField"
	_arrival_particle_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrival_visual.add_child(_arrival_particle_field)
	_arrival_particle_field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_arrival_sprite = TextureRect.new()
	_arrival_sprite.name = "PartnerArrivalSprite"
	_arrival_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arrival_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arrival_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrival_visual.add_child(_arrival_sprite)

	_arrival_name = Label.new()
	_arrival_name.name = "PartnerArrivalName"
	_arrival_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrival_name.add_theme_font_size_override("font_size", 18)
	_arrival_name.add_theme_color_override(
		"font_color",
		Color(0.9, 0.98, 1.0, 1.0)
	)
	_completion_stage.add_child(_arrival_name)

	_arrival_comment = RichTextLabel.new()
	_arrival_comment.name = "PartnerArrivalComment"
	_arrival_comment.custom_minimum_size = Vector2(0, 50)
	_arrival_comment.fit_content = true
	_arrival_comment.scroll_active = false
	_arrival_comment.bbcode_enabled = false
	_arrival_comment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrival_comment.add_theme_color_override(
		"default_color",
		Color(0.78, 0.88, 0.94, 1.0)
	)
	_completion_stage.add_child(_arrival_comment)

	registered_panel.add_child(_completion_stage)
	var complete_spacer := registered_panel.get_node_or_null("CompleteSpacer") as Control
	if complete_spacer != null:
		registered_panel.move_child(
			_completion_stage,
			complete_spacer.get_index() + 1
		)
	else:
		registered_panel.move_child(_completion_stage, 0)

	_pixel_materializer = PixelMaterializer.new()
	_pixel_materializer.name = "PartnerPixelMaterializer"
	add_child(_pixel_materializer)

	_partner_typewriter = TypewriterReveal.new()
	_partner_typewriter.name = "PartnerSyncTypewriter"
	_partner_typewriter.characters_per_second = 34.0
	add_child(_partner_typewriter)

	_completion_stage.hide()
	open_channel_button.text = "OPEN NULL CHANNEL"


func _play_registration_complete() -> void:
	open_channel_button.disabled = true
	open_channel_button.hide()
	registered_label.hide()
	if _complete_body != null:
		_complete_body.hide()
	_completion_stage.show()
	_completion_status.show()
	_completion_status.modulate = Color.WHITE
	_arrival_sprite.texture = null
	_arrival_sprite.modulate.a = 0.0
	_arrival_name.hide()
	_arrival_comment.text = ""
	_arrival_comment.hide()

	var candidate := _pending_completion_candidate
	var apk: APKData = null
	if candidate != null:
		apk = ContentRegistry.get_apk(candidate.apk_id)
	_arrival_name.text = candidate.display_name if candidate != null else "PARTNER"
	var sprite_texture := _get_partner_overworld_sprite(apk)

	await _motion_player.enter_control(_completion_status, Vector2(0, 3), 0.13)
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame
	_layout_arrival_sprite(sprite_texture)
	await _pixel_materializer.materialize(
		sprite_texture,
		_arrival_sprite,
		_arrival_particle_field,
		Color(0.14, 0.78, 1.0, 1.0),
		Color(0.68, 0.34, 1.0, 1.0)
	)

	_completion_status.text = "PARTNER INSTANCE // ONLINE"
	await _motion_player.flash_control(
		_completion_status,
		Color(1.16, 1.26, 1.3, 1.0),
		0.1
	)
	_arrival_name.show()
	await _motion_player.enter_control(_arrival_name, Vector2(0, 3), 0.13)
	await get_tree().create_timer(0.28).timeout

	var dominant_tendency := _get_dominant_tendency(_pending_completion_tendencies)
	var comment_line := PARTNER_COMMENT_CATALOG.get_line(
		candidate.apk_id if candidate != null else "",
		dominant_tendency
	)
	_arrival_comment.show()
	_partner_typewriter.play(_arrival_comment, comment_line)
	await _partner_typewriter.reveal_completed
	await get_tree().create_timer(0.35).timeout

	registered_label.text = "PARTNER LINK ESTABLISHED"
	registered_label.show()
	registered_label.modulate.a = 0.0
	await _motion_player.enter_control(registered_label, Vector2(0, 3), 0.14)
	if _complete_body != null:
		_complete_body.show()
		_complete_body.modulate.a = 0.0
		await _motion_player.enter_control(_complete_body, Vector2(0, 2), 0.12)

	await get_tree().create_timer(0.28).timeout
	onboarding_handoff_requested.emit(CampaignState.operator.operator_id)

	# Until the Navigator/world handoff is wired by the onboarding coordinator,
	# preserve the old forum continuation as a non-blocking fallback. The result
	# page itself never closes or opens another app directly.
	open_channel_button.show()
	open_channel_button.modulate.a = 0.0
	await _motion_player.enter_control(open_channel_button, Vector2(0, 3), 0.12)
	open_channel_button.disabled = false


func _show_existing_completion_state() -> void:
	if _completion_stage != null:
		_completion_stage.hide()
	registered_label.text = "ACCOUNT ACTIVE // PARTNER SYNCHRONIZED"
	registered_label.show()
	registered_label.modulate = Color.WHITE
	if _complete_body != null:
		_complete_body.show()
		_complete_body.modulate = Color.WHITE
	open_channel_button.show()
	open_channel_button.modulate = Color.WHITE
	open_channel_button.disabled = false


func _layout_arrival_sprite(texture: Texture2D) -> void:
	if texture == null:
		_arrival_sprite.texture = null
		_arrival_sprite.size = Vector2(64, 64)
		_arrival_sprite.position = KubuOSMetrics.snap_vector(
			(_arrival_visual.size - _arrival_sprite.size) * 0.5
		)
		return

	var source_size := texture.get_size()
	var largest_dimension := maxf(source_size.x, source_size.y)
	var integer_scale := 1
	if largest_dimension > 0.0:
		integer_scale = clampi(floori(96.0 / largest_dimension), 1, 4)
	_arrival_sprite.size = KubuOSMetrics.snap_vector(
		source_size * float(integer_scale)
	)
	_arrival_sprite.position = KubuOSMetrics.snap_vector(
		(_arrival_visual.size - _arrival_sprite.size) * 0.5
	)


func _get_partner_overworld_sprite(apk: APKData) -> Texture2D:
	if apk == null:
		return null
	for sprite: Texture2D in apk.sprites:
		if sprite != null:
			return sprite
	if not apk.portraits.is_empty() and apk.portraits[0] != null:
		return apk.portraits[0]
	return apk.combat_icon


func _get_dominant_tendency(tendencies: Dictionary) -> String:
	var dominant_id := "valour"
	var dominant_value := -2147483648
	for tendency_id: String in RESULT_TENDENCY_ORDER:
		var value := int(tendencies.get(tendency_id, 0))
		if value > dominant_value:
			dominant_value = value
			dominant_id = tendency_id
	return dominant_id


func _make_tendency_row_style(accent: Color, hovered: bool) -> StyleBoxFlat:
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
	style.border_color = Color(accent.r, accent.g, accent.b, 0.88 if hovered else 0.5)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	style.corner_radius_bottom_left = 1
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	return style


func _make_context_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.004, 0.03, 0.052, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.05, 0.3, 0.5, 0.85)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	style.corner_radius_bottom_left = 1
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	return style


func _apply_primary_result_button_style(button: Button) -> void:
	if button == null:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.015, 0.18, 0.28, 0.96)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.12, 0.68, 1.0, 0.9)
	normal.corner_radius_top_left = 1
	normal.corner_radius_top_right = 1
	normal.corner_radius_bottom_right = 1
	normal.corner_radius_bottom_left = 1
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.025, 0.28, 0.4, 0.98)
	hover.border_color = Color(0.32, 0.86, 1.0, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 1.0))
