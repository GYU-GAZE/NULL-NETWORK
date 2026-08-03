extends Node


signal operator_registered(operator_id: String, occupation_id: String)
signal operator_registration_rejected(errors: PackedStringArray)
signal occupation_income_received(occupation_id: String, amount: int)


const AVAILABILITY_PROVIDER_ID: StringName = &"occupation_schedule"
const INITIAL_TENDENCY_TOTAL: int = 15
const SUPPORTED_SERVER_ID: String = "tokyo_japan"


func _ready() -> void:
	ActivityManager.register_availability_provider(
		AVAILABILITY_PROVIDER_ID,
		_evaluate_activity_availability
	)

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)


func register_operator(
	profile: OperatorProfileData,
	appearance: AppearanceData,
	tendency_values: Dictionary
) -> PackedStringArray:
	var errors: PackedStringArray = validate_registration(
		profile,
		appearance,
		tendency_values
	)

	if not errors.is_empty():
		operator_registration_rejected.emit(errors)
		return errors

	var occupation: OccupationData = ContentRegistry.get_occupation(
		profile.occupation_id
	)
	var operator_state := OperatorStateData.new()
	operator_state.set_registration_data(profile, appearance)
	operator_state.registration_day = TimeManager.days_passed
	operator_state.last_income_day = TimeManager.days_passed

	var valour: int = int(tendency_values.get("valour", 0))
	var logic: int = int(tendency_values.get("logic", 0))
	var sync: int = int(tendency_values.get("sync", 0))
	var self_value: int = int(tendency_values.get("self", 0))

	if not CampaignState.set_operator_state(operator_state):
		errors.append("CampaignState rejected the Operator profile.")
	elif not CampaignState.set_initial_tendencies(
		valour,
		logic,
		sync,
		self_value
	):
		errors.append("CampaignState rejected the initial tendencies.")

	if not errors.is_empty():
		operator_registration_rejected.emit(errors)
		return errors

	CampaignState.set_money(occupation.initial_money)
	CampaignState.discover_location(occupation.starting_location_id)
	CampaignState.set_current_location(occupation.starting_location_id)
	GameState.set_flag("operator.registered", true)
	GameState.set_flag("prologue.registration_completed", true)
	SaveManager.request_checkpoint(&"operator.registered", true)
	operator_registered.emit(
		CampaignState.operator.operator_id,
		occupation.get_display_id()
	)
	return errors


func validate_registration(
	profile: OperatorProfileData,
	appearance: AppearanceData,
	tendency_values: Dictionary
) -> PackedStringArray:
	var errors := PackedStringArray()

	if not CampaignState.has_campaign():
		errors.append("An active campaign is required.")

	if not CampaignState.operator.is_empty():
		errors.append("This campaign already has an active Operator.")

	if profile == null:
		errors.append("Operator profile is missing.")
	else:
		errors.append_array(profile.validate_data())

		if profile.server_id.strip_edges() != SUPPORTED_SERVER_ID:
			errors.append("This build is bound to the TOKYO, JAPAN server.")

		var occupation: OccupationData = ContentRegistry.get_occupation(
			profile.occupation_id
		)

		if occupation == null:
			errors.append("Selected occupation is not registered.")
		elif ContentRegistry.get_location(
			occupation.starting_location_id
		) == null:
			errors.append("Occupation starting location is not registered.")

	if appearance == null:
		errors.append("Operator appearance is missing.")
	else:
		errors.append_array(appearance.validate_data())

	var tendency_keys: Array[String] = ["valour", "logic", "sync", "self"]
	var tendency_total: int = 0

	for key: String in tendency_keys:
		var value: int = int(tendency_values.get(key, -1))

		if value < 0:
			errors.append("Tendency '%s' cannot be negative." % key)
		else:
			tendency_total += value

	if tendency_total != INITIAL_TENDENCY_TOTAL:
		errors.append(
			"Initial tendencies must total exactly %d points; received %d."
			% [INITIAL_TENDENCY_TOTAL, tendency_total]
		)

	return _deduplicate_errors(errors)


func get_current_occupation() -> OccupationData:
	if CampaignState.operator.is_empty():
		return null

	return ContentRegistry.get_occupation(
		CampaignState.operator.occupation_id
	)


func get_current_schedule() -> OccupationScheduleData:
	var occupation: OccupationData = get_current_occupation()
	return occupation.schedule if occupation != null else null


func _evaluate_activity_availability(
	_definition: ActivityDefinitionData,
	preview: ActivityPreviewData
) -> Dictionary:
	if preview == null or preview.charged_action_cost <= 0:
		return {"allowed": true}

	# Story Events own mandatory routine sequences. The schedule blocks voluntary
	# player activities, not the data-driven routine activity itself.
	if preview.source_id == StoryEventManager.SOURCE_ID:
		return {"allowed": true}

	var occupation: OccupationData = get_current_occupation()

	if occupation == null:
		return {"allowed": true}

	if occupation.schedule == null:
		return {
			"allowed": false,
			"reason": "The active occupation has no valid schedule."
		}

	var first_conflict: Dictionary = _find_first_schedule_conflict(
		occupation.schedule,
		preview.initial_day,
		TimeManager.get_current_day_block_index(),
		preview.charged_action_cost
	)

	if first_conflict.is_empty():
		return {"allowed": true}

	var day_block: int = int(first_conflict.get("day_block", 0))
	var period: int = TimeManager.TimePeriod.DAY
	var period_block: int = day_block

	if day_block >= TimeManager.ACTION_BLOCKS_PER_PERIOD:
		period = TimeManager.TimePeriod.NIGHT
		period_block -= TimeManager.ACTION_BLOCKS_PER_PERIOD

	return {
		"allowed": false,
		"reason": "%s Conflict: %s %d/12 (%s)." % [
			occupation.schedule.get_occupied_reason(),
			TimeManager.get_period_name(period),
			period_block + 1,
			TimeManager.format_action_block_hour(period, period_block)
		]
	}


func _find_first_schedule_conflict(
	schedule: OccupationScheduleData,
	start_game_day: int,
	start_day_block: int,
	duration: int
) -> Dictionary:
	for offset: int in range(duration):
		var absolute_block: int = start_day_block + offset
		var day_offset: int = int(
			absolute_block / TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY
		)
		var day_block: int = posmod(
			absolute_block,
			TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY
		)
		var weekday_index: int = posmod(
			TimeManager.current_weekday_index + day_offset,
			7
		)

		if schedule.is_block_occupied(weekday_index, day_block):
			return {
				"game_day": start_game_day + day_offset,
				"weekday_index": weekday_index,
				"day_block": day_block
			}

	return {}


func _on_time_advanced(
	_period: int,
	_days_passed: int,
	_calendar_day: int,
	_calendar_month: String
) -> void:
	_apply_due_income()
	_trigger_routine_at_current_block()


func _apply_due_income() -> void:
	var occupation: OccupationData = get_current_occupation()

	if occupation == null or occupation.recurring_income <= 0:
		return

	var elapsed_days: int = (
		TimeManager.days_passed - CampaignState.operator.last_income_day
	)
	var payments_due: int = int(elapsed_days / occupation.income_interval_days)

	if payments_due <= 0:
		return

	var amount: int = payments_due * occupation.recurring_income
	CampaignState.add_money(amount)
	CampaignState.set_operator_last_income_day(
		CampaignState.operator.last_income_day
		+ (payments_due * occupation.income_interval_days)
	)
	occupation_income_received.emit(occupation.get_display_id(), amount)
	SaveManager.request_checkpoint(&"occupation.income")


func _trigger_routine_at_current_block() -> void:
	var occupation: OccupationData = get_current_occupation()

	if occupation == null or occupation.schedule == null:
		return

	var current_day_block: int = TimeManager.get_current_day_block_index()
	var weekday_index: int = TimeManager.current_weekday_index

	if not occupation.schedule.is_block_occupied(
		weekday_index,
		current_day_block
	):
		return

	var previous_block: int = current_day_block - 1
	var previous_weekday: int = weekday_index

	if previous_block < 0:
		previous_block = TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY - 1
		previous_weekday = posmod(weekday_index - 1, 7)

	if occupation.schedule.is_block_occupied(previous_weekday, previous_block):
		return

	for routine_event_id: String in occupation.routine_event_ids:
		StoryEventManager.evaluate_manual_trigger(routine_event_id)


func _deduplicate_errors(errors: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()

	for error: String in errors:
		if not result.has(error):
			result.append(error)

	return result
