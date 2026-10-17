extends OperatorCreationPage
class_name OperatorCreationRevampedPage


signal onboarding_handoff_requested(operator_id: String)

const TENDENCY_CATALOG: TendencyCatalogData = preload(
	"res://data/content/tendencies/default_tendency_catalog.tres"
)
const RESULT_TENDENCY_ORDER := ["valour", "logic", "sync", "self"]

var _result_summary: AssessmentResultSummary
var _result_actions: Control

var _completion_stage: PartnerArrivalStage
var _complete_body: Label

var _pending_completion_candidate: CompatibilityCandidateData
var _pending_primary_trait: Dictionary = {}


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


func _configure_result_presentation() -> void:
	var legacy_title := result_content.get_node_or_null("ResultTitle") as Control
	if legacy_title != null:
		legacy_title.hide()

	result_tendencies.hide()
	_result_summary = result_content.get_node_or_null(
		"AssessmentResultSummary"
	) as AssessmentResultSummary
	if _result_summary == null:
		push_error(
			"OperatorCreationRevampedPage requires AssessmentResultSummary in ResultContent."
		)

	_result_actions = accept_result_button.get_parent() as Control
	accept_result_button.text = "ACCEPT PARTNER"
	retake_assessment_button.text = "RETAKE ASSESSMENT"
	result_manual_button.text = "CHOOSE MANUALLY"
	accept_result_button.custom_minimum_size = Vector2(190, 40)
	retake_assessment_button.custom_minimum_size = Vector2(190, 40)
	result_manual_button.custom_minimum_size = Vector2(170, 40)


func _build_tendency_rows(tendencies: Dictionary) -> void:
	if _result_summary == null:
		return
	_result_summary.render(tendencies, TENDENCY_CATALOG, RESULT_TENDENCY_ORDER)


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

	await _enter_presentation_control(loading_label, 0.11)
	for child: Node in result_status_lines.get_children():
		if not _result_sequence_is_current(generation):
			return
		var status_line := child as Control
		if status_line == null:
			continue
		status_line.show()
		await _enter_presentation_control(status_line, 0.09)
		await get_tree().create_timer(0.045).timeout

	if not _result_sequence_is_current(generation):
		return
	await get_tree().create_timer(0.1).timeout
	loading_label.text = "MATCH FOUND"
	await _motion_player.flash_control(
		loading_label,
		Color(1.2, 1.3, 1.4, 1.0),
		0.08
	)
	await get_tree().create_timer(0.22).timeout
	if not _result_sequence_is_current(generation):
		return

	_show_result_content(false)
	if _result_summary != null:
		_result_summary.tendency_title.show()
		await _enter_presentation_control(_result_summary.tendency_title, 0.11)
		await get_tree().create_timer(0.12).timeout

		for row: Control in _result_summary.get_tendency_rows():
			if not _result_sequence_is_current(generation):
				return
			row.show()
			await _enter_presentation_control(row, 0.09)
			await get_tree().create_timer(0.17).timeout

		if not _result_sequence_is_current(generation):
			return
		_result_summary.context_panel.show()
		await _enter_presentation_control(_result_summary.context_panel, 0.08)
		await get_tree().create_timer(0.24).timeout

		_result_summary.assignment_intro.show()
		await _enter_presentation_control(_result_summary.assignment_intro, 0.11)
		await get_tree().create_timer(0.4).timeout
		if not _result_sequence_is_current(generation):
			return

		_result_summary.assigned_species.show()
		await _enter_presentation_control(_result_summary.assigned_species, 0.13)
		await _motion_player.flash_control(
			_result_summary.assigned_species,
			Color(1.18, 1.28, 1.34, 1.0),
			0.08
		)
	await get_tree().create_timer(0.28).timeout
	if not _result_sequence_is_current(generation):
		return

	result_partner_preview_host.show()
	await _enter_presentation_control(result_partner_preview_host, 0.11)
	if _result_preview != null:
		for step: Control in _result_preview.get_reveal_steps():
			if not _result_sequence_is_current(generation):
				return
			if step == null:
				continue
			step.show()
			await _enter_presentation_control(step, 0.08)
			await get_tree().create_timer(0.055).timeout

	await get_tree().create_timer(0.12).timeout
	if not _result_sequence_is_current(generation):
		return
	if _result_actions != null:
		_result_actions.show()
		await _enter_presentation_control(_result_actions, 0.11)
	_unlock_result_actions()


func _show_result_content(unlock_actions: bool = true) -> void:
	result_loading.hide()
	result_content.show()
	var tendencies := _dictionary_value(_assessment_result.get("tendencies", {}))
	_build_tendency_rows(tendencies)

	var candidate: CompatibilityCandidateData = null
	if assessment_data != null:
		candidate = assessment_data.get_candidate(
			str(_assessment_result.get("candidate_id", ""))
		)
	if _result_summary != null:
		_result_summary.set_assigned_species(
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
	if _result_summary != null:
		_result_summary.show()
		_result_summary.set_reveal_state(settled)
	result_partner_preview_host.visible = settled
	if _result_actions != null:
		_result_actions.visible = settled
	if _result_preview != null:
		_result_preview.set_reveal_state(settled)

	if settled:
		_unlock_result_actions()
	else:
		# These controls remain under a hidden parent until the reveal finishes.
		# Keeping the secondary choices logically available preserves the existing
		# result contract without allowing the player to interrupt presentation.
		retake_assessment_button.disabled = false
		result_manual_button.disabled = false
		accept_result_button.disabled = true


func _unlock_result_actions() -> void:
	if _result_actions != null:
		_result_actions.show()
	super._unlock_result_actions()


func _result_sequence_is_current(generation: int) -> bool:
	return (
		generation == _result_sequence_generation
		and _current_page == FlowPage.RESULT
	)


func _enter_presentation_control(control: Control, duration: float) -> void:
	if control == null:
		return
	# Result rows and partner-card blocks belong to Containers. Use the
	# container-safe motion path so presentation never owns layout coordinates.
	await _motion_player.enter_scaled_control(
		control,
		Vector2(1.0, 0.88),
		Vector2.ZERO,
		duration
	)


func _finalize_registration(
	candidate: CompatibilityCandidateData,
	tendencies: Dictionary,
	mode: String
) -> void:
	_pending_completion_candidate = candidate
	_pending_primary_trait = (
		_dictionary_value(_assessment_result.get("primary_trait", {})).duplicate(true)
		if mode == "assessment"
		else {}
	)
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

	_completion_stage = registered_panel.get_node_or_null(
		"PartnerArrivalStage"
	) as PartnerArrivalStage
	if _completion_stage == null:
		push_error(
			"OperatorCreationRevampedPage requires PartnerArrivalStage in RegisteredPanel."
		)

	open_channel_button.text = "OPEN NULL CHANNEL"


func _play_registration_complete() -> void:
	open_channel_button.disabled = true
	open_channel_button.hide()
	registered_label.hide()
	if _complete_body != null:
		_complete_body.hide()
	var candidate := _pending_completion_candidate
	var apk: APKData = null
	if candidate != null:
		apk = ContentRegistry.get_apk(candidate.apk_id)
	var partner_name := candidate.display_name if candidate != null else "PARTNER"
	var sprite_texture := _get_partner_overworld_sprite(apk)

	if _completion_stage == null:
		push_error("Registration completion cannot run without PartnerArrivalStage.")
		return

	_completion_stage.prepare(partner_name)
	await _enter_presentation_control(_completion_stage.status_label, 0.11)
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	await _completion_stage.materialize(sprite_texture)

	_completion_stage.set_status("PARTNER INSTANCE // ONLINE")
	await _motion_player.flash_control(
		_completion_stage.status_label,
		Color(1.16, 1.26, 1.3, 1.0),
		0.08
	)
	_completion_stage.reveal_name()
	await _enter_presentation_control(_completion_stage.name_label, 0.11)
	await get_tree().create_timer(0.24).timeout

	var personality: APKPersonalityData = null
	if apk != null and not CampaignState.partner.is_empty():
		personality = apk.get_personality(CampaignState.partner.personality_id)
	var trait_id := str(_pending_primary_trait.get("trait_id", ""))
	var comment_line := (
		personality.get_first_impression_line(trait_id)
		if personality != null
		else "We're linked now. Let's see what happens next."
	)
	if comment_line.strip_edges().is_empty():
		comment_line = "We're linked now. Let's see what happens next."
	_completion_stage.play_comment(comment_line)
	await _completion_stage.typewriter.reveal_completed
	await get_tree().create_timer(0.3).timeout

	registered_label.text = "PARTNER LINK ESTABLISHED"
	registered_label.show()
	registered_label.modulate.a = 0.0
	await _enter_presentation_control(registered_label, 0.12)
	if _complete_body != null:
		_complete_body.show()
		_complete_body.modulate.a = 0.0
		await _enter_presentation_control(_complete_body, 0.1)

	await get_tree().create_timer(0.24).timeout
	onboarding_handoff_requested.emit(CampaignState.operator.operator_id)
	await get_tree().process_frame
	if not is_inside_tree():
		return

	# Until the Navigator/world handoff is wired by the onboarding coordinator,
	# preserve the old forum continuation as a non-blocking fallback. The result
	# page itself never closes or opens another app directly.
	open_channel_button.show()
	open_channel_button.modulate.a = 0.0
	await _enter_presentation_control(open_channel_button, 0.1)
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


func _get_partner_overworld_sprite(apk: APKData) -> Texture2D:
	if apk == null:
		return null
	for sprite: Texture2D in apk.sprites:
		if sprite != null:
			return sprite
	if not apk.portraits.is_empty() and apk.portraits[0] != null:
		return apk.portraits[0]
	return apk.combat_icon

