extends OperatorCreationPage
class_name OperatorSuccessionRegistrationPage


## Operator Loss reuses the same registration and starter-selection flow as a
## first-time account. Succession-specific state transitions remain owned by
## OperatorService; this page intentionally contains no player-facing variant.
##
## Browser-session restoration is deliberately presentation-silent. A restored
## page is already an established UI state, not a newly-entered narrative beat,
## so page transitions, typewriter and answer stagger settle immediately after
## every window reopen.

var _restoring_browser_presentation: bool = false


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
