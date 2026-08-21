extends OperatorCreationRevampedPage
class_name OperatorSuccessionRegistrationPage


## Operator Loss reuses the same registration and starter-selection flow as a
## first-time account. Succession-specific state transitions remain owned by
## OperatorService; this page intentionally contains no player-facing variant.
##
## Browser-session restoration is deliberately presentation-silent for ordinary
## form pages. The one exception is an interrupted *initial* partner arrival: if
## the starter was already persisted but the Navigator world reveal never
## completed, the arrival/first-impression beat is reconstructed from the saved
## onboarding metadata and replayed instead of stranding the campaign on the old
## COMPLETE fallback.

@export var onboarding_presentation_data: PrologueOnboardingPresentationData

var _restoring_browser_presentation: bool = false
var _completion_resume_queued: bool = false


func restore_browser_state(state: Dictionary) -> void:
	_restoring_browser_presentation = true
	await super.restore_browser_state(state)
	_restoring_browser_presentation = false


func _show_page(
	page: int,
	scroll_to_top: bool = true,
	animated: bool = true
) -> void:
	await super._show_page(
		page,
		scroll_to_top,
		animated and not _restoring_browser_presentation
	)


func _render_assessment_question(track_visit: bool) -> void:
	super._render_assessment_question(track_visit)
	if not _restoring_browser_presentation:
		return
	if _assessment_typewriter != null and _assessment_typewriter.is_running():
		_assessment_typewriter.complete()


func _on_assessment_prompt_revealed() -> void:
	if not _restoring_browser_presentation:
		await super._on_assessment_prompt_revealed()
		return

	_assessment_reveal_generation += 1
	_assessment_answers_ready = true
	for child: Node in answer_container.get_children():
		var answer_button := child as AssessmentAnswerButton
		if answer_button == null:
			continue
		answer_button.disabled = false
		answer_button.scale = Vector2.ONE
		answer_button.modulate = Color.WHITE
	_refresh_assessment_next_state()


func _show_existing_completion_state() -> void:
	if _should_resume_initial_partner_arrival():
		_restore_completion_context_from_campaign()
		_completion_resume_queued = true
		call_deferred("_resume_initial_partner_arrival")
		return

	super._show_existing_completion_state()


func _should_resume_initial_partner_arrival() -> bool:
	return (
		onboarding_presentation_data != null
		and CampaignState.has_campaign()
		and not CampaignState.operator.is_empty()
		and not CampaignState.partner.is_empty()
		and not GameState.get_flag(
			onboarding_presentation_data.world_revealed_flag,
			false
		)
	)


func _restore_completion_context_from_campaign() -> void:
	var metadata: Dictionary = CampaignState.operator.onboarding_metadata
	var candidate_id := str(metadata.get("candidate_id", "")).strip_edges()
	_pending_completion_candidate = (
		assessment_data.get_candidate(candidate_id)
		if assessment_data != null and not candidate_id.is_empty()
		else null
	)

	var mode := str(metadata.get("mode", "")).strip_edges()
	if mode != "assessment":
		_pending_primary_trait = {}
		return

	var axis_values: Dictionary = _dictionary_value(
		metadata.get("axis_values", {})
	)
	var axis_confidence: Dictionary = _dictionary_value(
		metadata.get("axis_confidence", {})
	)
	_pending_primary_trait = CompatibilityAssessmentService.calculate_primary_trait(
		axis_values,
		axis_confidence
	)


func _resume_initial_partner_arrival() -> void:
	if not _completion_resume_queued:
		return
	_completion_resume_queued = false
	if not is_inside_tree() or not _should_resume_initial_partner_arrival():
		return
	await _play_registration_complete()
