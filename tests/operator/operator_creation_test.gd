extends Node

const REGISTRATION_URL: String = "null.net/register"
const ASSESSMENT_DATA: CompatibilityAssessmentData = preload(
	"res://data/content/onboarding/compatibility_assessment_v1_1.tres"
)
const OCCUPATION_IDS: Array[String] = [
	"neet",
	"high_school_student",
	"salaryperson"
]
const EXPECTED_MANUAL_CANDIDATES: Array[String] = [
	"REVQUIRE", "VOCALYTE", "WIZIP", "PABUBU", "TROJAW"
]

var _failures := PackedStringArray()
var _test_root: String

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	_test_root = "user://null_network/tests/operator_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var registry_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(registry_errors.is_empty(), "Default catalog failed: %s" % registry_errors)

	await _test_registration_route()
	_test_assessment_contract()
	_test_invalid_tendency_total()
	_test_all_occupations()
	_test_persistence_and_schedule()
	await _wait_frames(8)
	_finish_test()

func _test_registration_route() -> void:
	var page: WebsitePage = SimulatedDNS.fetch_page(REGISTRATION_URL)
	_check(page != null, "NULL NETWORK registration route is missing.")
	if page == null:
		return
	_check(page.site_scene != null, "Registration route has no scene.")
	if page.site_scene == null:
		return

	var page_instance: Node = page.site_scene.instantiate()
	var page_control := page_instance as Control
	if page_control != null:
		page_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		page_control.size = Vector2(832, 393)
	add_child(page_instance)
	await _wait_frames(3)
	_check(page_instance is OperatorCreationPage, "Registration route did not instantiate OperatorCreationPage.")
	_check(page_instance.find_child("PortalHeader", true, false) != null, "Registration lost the shared NULL NETWORK portal header.")
	_check(page_instance.find_child("RegistrationStepper", true, false) == null, "Registration must not retain the legacy visual stepper.")
	_check(page_instance.find_child("StateLabels", true, false) == null, "Registration must not retain hidden StateLabels.")
	_check(page_instance.find_child("AssessmentAbout", true, false) != null, "Compatibility Assessment lost its category context rail.")
	_check(page_instance.find_child("AssessmentProgressPips", true, false) != null, "Compatibility Assessment lost its 18-question progress rail.")

	var occupation_option := page_instance.find_child("OccupationOption", true, false) as OptionButton
	_check(
		occupation_option != null and occupation_option.item_count == 3,
		"Registration page did not render all three occupations."
	)
	_check(page_instance.find_child("PronounOption", true, false) == null, "Pronouns must no longer be exposed as a standalone registration field.")
	_check(page_instance.find_child("WritingStyleOptions", true, false) != null, "Registration lost Writing Style selection.")
	_check(page_instance.find_child("KaomojiOptions", true, false) != null, "Registration lost Kaomoji preference selection.")
	_check(page_instance.find_child("AppearancePage", true, false) != null, "Registration lost its appearance page.")
	_check(page_instance.find_child("AppearanceGrid", true, false) != null, "Appearance page must expose a visual option grid.")
	_check(page_instance.find_child("PortraitLayers", true, false) != null, "Appearance page lost layered portrait preview support.")
	_check(page_instance.find_child("OverworldLayers", true, false) != null, "Appearance page lost layered overworld preview support.")
	_check(page_instance.find_child("MethodPage", true, false) != null, "Registration lost the Compatibility method page.")
	_check(page_instance.find_child("ManualPage", true, false) != null, "Registration lost Manual Allocation.")
	_check(page_instance.find_child("AssessmentPage", true, false) != null, "Registration lost the Compatibility Assessment page.")
	_check(page_instance.find_child("ResultPage", true, false) != null, "Registration lost its Assessment result page.")
	_check(page_instance.find_child("LoadingPulse", true, false) == null, "Assessment result must not use the legacy ProgressBar.")
	_check(page_instance.find_child("ResultStatusLines", true, false) != null, "Assessment result lost its staged resolution sequence.")
	_check(page_instance.find_child("RetakeAssessmentButton", true, false) != null, "Assessment result must expose Retake Assessment.")
	_check(page_instance.find_child("ResultManualButton", true, false) != null, "Assessment result must expose Manual Allocation fallback.")
	_check(page_instance.find_child("BodyPanel", true, false) is NullNetworkFrame, "Registration body must use the stepped NULL NETWORK frame renderer.")
	var operator_page := page_instance as OperatorCreationPage
	if operator_page != null:
		_check_layout_fits_canvas(operator_page, "account")
		await operator_page._show_page(OperatorCreationPage.FlowPage.APPEARANCE)
		_check(operator_page.get_current_flow_page() == OperatorCreationPage.FlowPage.APPEARANCE, "FlowPage transition did not settle on Appearance.")
		_check(not operator_page.is_page_transitioning(), "FlowPage transition left navigation locked.")
		operator_page.master_scroll.scroll_vertical = 100000
		await _wait_frames(2)
		_check_appearance_navigation_is_clear(operator_page)
		await operator_page._show_page(OperatorCreationPage.FlowPage.METHOD)
		_check_layout_fits_canvas(operator_page, "compatibility method")
		operator_page._on_participate_pressed()
		await get_tree().create_timer(0.35).timeout
		_check_layout_fits_canvas(operator_page, "assessment")
		var first_answer := operator_page.answer_container.get_child(0) as AssessmentAnswerButton
		_check(first_answer != null and first_answer.disabled, "Assessment answers became interactive before prompt reveal.")
		operator_page._assessment_typewriter.complete()
		await get_tree().create_timer(0.9).timeout
		_check(operator_page.are_assessment_answers_ready(), "Assessment answers did not unlock after staggered reveal.")
		if first_answer != null:
			first_answer.button_pressed = true
			first_answer.pressed.emit()
			await get_tree().create_timer(0.2).timeout
			var question := ASSESSMENT_DATA.questions[0] as CompatibilityQuestionData
			_check(
				question != null and operator_page._assessment_session.final_answer_by_question.has(question.question_id),
				"Assessment did not retain the selected response in CompatibilitySessionData."
			)
		await _test_assessment_result_presentation(operator_page)
	page_instance.queue_free()
	await _wait_frames(2)


func _test_assessment_result_presentation(page: OperatorCreationPage) -> void:
	for question_value: Variant in ASSESSMENT_DATA.questions:
		var question := question_value as CompatibilityQuestionData
		if question == null:
			continue
		var order := CompatibilityAssessmentService.get_or_create_visual_order(
			question,
			page._assessment_session
		)
		if order.is_empty():
			continue
		var answer := question.get_answer(order[0])
		if answer != null:
			page._assessment_session.record_answer(question.question_id, answer.answer_id, 0)
	var expected := CompatibilityAssessmentService.evaluate(
		ASSESSMENT_DATA,
		page._assessment_session,
		page._selected_writing_style,
		page._selected_kaomoji,
		str(page.avatar_variant_hints.get(page._selected_avatar_id, ""))
	)
	page._question_index = ASSESSMENT_DATA.questions.size() - 1
	page._calculate_and_show_result(true)
	await get_tree().create_timer(0.35).timeout
	_check(page.accept_result_button.disabled, "Assessment result unlocked ACCEPT before the payoff stabilized.")
	_check(page.retake_assessment_button.disabled, "Assessment result unlocked RETAKE before the payoff stabilized.")
	_check(page.result_manual_button.disabled, "Assessment result unlocked MANUAL before the payoff stabilized.")
	await get_tree().create_timer(1.35).timeout
	_check(page.get_current_flow_page() == OperatorCreationPage.FlowPage.RESULT, "Assessment payoff did not settle on Result.")
	_check(page._assessment_result == expected, "Result presentation changed CompatibilityAssessmentService output.")
	_check(not page.retake_assessment_button.disabled, "Assessment payoff did not unlock RETAKE after stabilization.")
	_check(not page.result_manual_button.disabled, "Assessment payoff did not unlock MANUAL after stabilization.")

func _check_appearance_navigation_is_clear(page: OperatorCreationPage) -> void:
	var footer := page.find_child("PortalFooter", true, false) as Control
	var back := page.find_child("BackButton", true, false) as Button
	var next := page.find_child("NextButton", true, false) as Button
	_check(footer != null and back != null and next != null, "Appearance navigation controls are incomplete.")
	if footer == null or back == null or next == null:
		return
	for button: Button in [back, next]:
		_check(
			button.size.y >= 32.0,
			"Appearance %s button is shorter than its readable 14 px Silver frame." % button.name
		)
		_check(
			button.get_global_rect().end.y <= footer.get_global_rect().position.y + 0.5,
			"Appearance %s button is clipped by the fixed portal footer." % button.name
		)

func _check_layout_fits_canvas(page: OperatorCreationPage, state_name: String) -> void:
	var footer := page.find_child("PortalFooter", true, false) as Control
	_check(footer != null, "%s page lost the shared portal footer." % state_name)
	if footer == null:
		return
	var footer_bottom: float = footer.position.y + footer.size.y
	_check(
		footer_bottom <= page.size.y + 0.5,
		"%s layout overflows the canonical 832x393 browser canvas." % state_name
	)

func _test_assessment_contract() -> void:
	_check(ASSESSMENT_DATA != null, "Canonical Compatibility Assessment resource is missing.")
	if ASSESSMENT_DATA == null:
		return
	_check(ASSESSMENT_DATA.questions.size() == 18, "Compatibility Assessment must contain exactly 18 questions.")
	_check(ASSESSMENT_DATA.candidates.size() >= 5, "Compatibility Assessment candidate pool is incomplete.")
	_check(ASSESSMENT_DATA.manual_candidate_ids == PackedStringArray(EXPECTED_MANUAL_CANDIDATES), "Manual Allocation must expose exactly REVQUIRE, VOCALYTE, WIZIP, PABUBU and TROJAW in the locked order.")

func _test_invalid_tendency_total() -> void:
	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"operator_invalid_total",
		CampaignState.SaveMode.SAFE,
		"Invalid Operator"
	)
	_check(create_errors.is_empty(), "Invalid-total campaign failed to create.")
	var errors: PackedStringArray = OperatorService.register_operator(
		_make_profile("neet", "invalid_total"),
		_make_appearance("invalid"),
		{"valour": 4, "logic": 4, "sync": 3, "self": 3}
	)
	_check(
		_contains_text(errors, "exactly 15") and CampaignState.operator.is_empty(),
		"A 14-point allocation was not rejected without mutation."
	)

func _test_all_occupations() -> void:
	for occupation_id: String in OCCUPATION_IDS:
		var campaign_id: String = "operator_%s" % occupation_id
		var create_errors: PackedStringArray = SaveManager.create_campaign(
			campaign_id,
			CampaignState.SaveMode.SAFE,
			campaign_id
		)
		_check(create_errors.is_empty(), "Campaign for %s failed: %s" % [occupation_id, create_errors])
		var errors: PackedStringArray = OperatorService.register_operator(
			_make_profile(occupation_id, occupation_id),
			_make_appearance(occupation_id),
			{"valour": 4, "logic": 4, "sync": 4, "self": 3}
		)
		var occupation: OccupationData = ContentRegistry.get_occupation(occupation_id)
		_check(errors.is_empty(), "%s registration failed: %s" % [occupation_id, errors])
		_check(
			occupation != null
			and CampaignState.operator.occupation_id == occupation_id
			and CampaignState.tendencies.get_total() == 15
			and CampaignState.money == occupation.initial_money
			and CampaignState.current_location_id == occupation.starting_location_id
			and OperatorService.get_current_schedule() == occupation.schedule,
			"%s did not apply its profile, economy, location and schedule." % occupation_id
		)

	var salaryperson: OccupationData = ContentRegistry.get_occupation("salaryperson")
	var high_school: OccupationData = ContentRegistry.get_occupation("high_school_student")
	var neet: OccupationData = ContentRegistry.get_occupation("neet")
	_check(
		salaryperson != null and salaryperson.schedule.get_blocks_until_available(1, 3) == 9,
		"Salaryperson schedule must fast-forward DAY block 3 through NIGHT block 0."
	)
	_check(
		high_school != null and high_school.schedule.get_blocks_until_available(1, 2) == 8,
		"High-school schedule must fast-forward the school interval to DAY block 10."
	)
	_check(
		neet != null and neet.schedule.get_blocks_until_available(1, 3) == 0,
		"NEET schedule must never invent a mandatory skip for a free block."
	)

func _test_persistence_and_schedule() -> void:
	var campaign_id: String = "operator_persistence"
	var create_errors: PackedStringArray = SaveManager.create_campaign(
		campaign_id,
		CampaignState.SaveMode.SAFE,
		"Operator Persistence"
	)
	_check(create_errors.is_empty(), "Persistence campaign failed to create.")
	var profile := _make_profile("salaryperson", "persistent_operator")
	profile.writing_style_id = "formal"
	profile.kaomoji_preference_id = "occasional"
	var errors: PackedStringArray = OperatorService.register_operator(
		profile,
		_make_appearance("persistent"),
		{"valour": 2, "logic": 7, "sync": 3, "self": 3}
	)
	_check(errors.is_empty(), "Persistent Operator registration failed: %s" % errors)

	TimeManager.import_save_data({
		"version": TimeManager.SAVE_DATA_VERSION,
		"days_passed": 5,
		"days_until_update": 3,
		"current_period": TimeManager.TimePeriod.DAY,
		"current_action_block": 3
	})
	var activity := ActivityDefinitionData.new()
	activity.activity_id = "operator.schedule.test"
	activity.display_name = "Schedule Test"
	activity.action_cost = 1
	activity.requires_confirmation = false
	var occupied_preview: ActivityPreviewData = ActivityManager.create_preview(activity)
	_check(
		not occupied_preview.is_valid() and "work shift" in occupied_preview.denial_reason.to_lower(),
		"Salaryperson activity was not blocked during the work shift."
	)

	TimeManager.current_action_block = 0
	var free_preview: ActivityPreviewData = ActivityManager.create_preview(activity)
	_check(free_preview.is_valid(), "Salaryperson could not act before work.")
	TimeManager.current_action_block = 2
	activity.action_cost = 2
	var crossing_preview: ActivityPreviewData = ActivityManager.create_preview(activity)
	_check(not crossing_preview.is_valid(), "An activity crossing into the work shift was not blocked.")

	_check(SaveManager.save_checkpoint(&"phase8.operator", true), "Could not save the Phase 8 Operator checkpoint.")
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	var load_errors: PackedStringArray = SaveManager.load_campaign(campaign_id)
	_check(load_errors.is_empty(), "Operator reload failed: %s" % load_errors)
	var restored_schedule: OccupationScheduleData = OperatorService.get_current_schedule()
	_check(
		CampaignState.operator.profile.first_name == "Gyu"
		and CampaignState.operator.profile.last_name == "Phase Eight"
		and CampaignState.operator.profile.username == "persistent_operator"
		and CampaignState.operator.profile.server_id == "tokyo_japan"
		and CampaignState.operator.profile.writing_style_id == "formal"
		and CampaignState.operator.profile.kaomoji_preference_id == "occasional"
		and CampaignState.operator.appearance.body_type_id == "body_persistent"
		and CampaignState.operator.appearance.outer_layer_id == "outer_persistent"
		and CampaignState.operator.appearance_part_ids.size() == 8
		and CampaignState.tendencies.get_total() == 15
		and restored_schedule != null
		and restored_schedule.get_display_id() == "schedule.occupation.salaryperson",
		"Profile, writing preferences, appearance, tendencies or schedule did not survive reload."
	)

	var money_before_income: int = CampaignState.money
	TimeManager.import_save_data({
		"version": TimeManager.SAVE_DATA_VERSION,
		"days_passed": 8,
		"days_until_update": 0,
		"current_period": TimeManager.TimePeriod.DAY,
		"current_action_block": 0
	})
	_check(
		CampaignState.money == money_before_income + 5000
		and CampaignState.operator.last_income_day == 8,
		"Salaryperson recurring weekly income was not applied exactly once."
	)

	TimeManager.import_save_data({
		"version": TimeManager.SAVE_DATA_VERSION,
		"days_passed": 5,
		"days_until_update": 3,
		"current_period": TimeManager.TimePeriod.DAY,
		"current_action_block": 2
	})
	OperatorService.advance_player_action_time(1)
	_check(
		TimeManager.current_period == TimeManager.TimePeriod.NIGHT
		and TimeManager.current_action_block == 0,
		"Salaryperson third daytime action did not fast-forward to NIGHT block 0."
	)

func _make_profile(occupation_id: String, username: String) -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Gyu"
	profile.last_name = "Phase Eight"
	profile.nickname = "Operator"
	profile.username = username
	profile.server_id = "tokyo_japan"
	profile.occupation_id = occupation_id
	profile.gender = "other"
	profile.resolve_pronoun_set_from_gender()
	profile.avatar_id = "avatar_01"
	return profile

func _make_appearance(suffix: String) -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_%s" % suffix
	appearance.face_id = "face_%s" % suffix
	appearance.eye_id = "eyes_%s" % suffix
	appearance.outer_layer_id = "outer_%s" % suffix
	appearance.middle_layer_id = "middle_%s" % suffix
	appearance.lower_layer_id = "lower_%s" % suffix
	appearance.hat_id = "hat_%s" % suffix
	appearance.facial_accessory_id = "accessory_%s" % suffix
	return appearance

func _contains_text(values: PackedStringArray, fragment: String) -> bool:
	for value: String in values:
		if fragment.to_lower() in value.to_lower():
			return true
	return false

func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)
	if _failures.is_empty():
		print("OPERATOR_CREATION_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("OPERATOR_CREATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)

func _remove_directory_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var child_path: String = "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_remove_directory_recursive(child_path)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child_path))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
