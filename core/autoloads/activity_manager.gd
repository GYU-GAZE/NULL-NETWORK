extends Node


signal activity_started(
	transaction_id: String,
	activity_id: String,
	source_id: String,
	request_id: String
)
signal activity_completed(
	transaction_id: String,
	activity_id: String,
	source_id: String
)
signal activity_failed(
	transaction_id: String,
	activity_id: String,
	source_id: String,
	reason: String
)
signal activity_rejected(
	request_id: String,
	activity_id: String,
	source_id: String,
	reason: String
)
signal activity_cancelled(
	request_id: String,
	activity_id: String,
	source_id: String,
	reason: String
)


const REQUEST_PREFIX: String = "activity_request_"
const TRANSACTION_PREFIX: String = "activity_transaction_"


var _pending_requests: Dictionary = {}
var _active_transactions: Dictionary = {}
var _availability_providers: Dictionary = {}

var _next_request_number: int = 1
var _next_transaction_number: int = 1


func _ready() -> void:
	if not GlobalSignals.activity_confirmation_resolved.is_connected(
		_on_confirmation_resolved
	):
		GlobalSignals.activity_confirmation_resolved.connect(
			_on_confirmation_resolved
		)


func request_activity(
	definition: ActivityDefinitionData,
	source_id: String = "",
	parent_transaction_id: String = ""
) -> String:
	var request_id: String = _make_request_id()

	if definition == null:
		call_deferred(
			"_emit_invalid_definition_rejection",
			request_id,
			source_id
		)
		return request_id

	_pending_requests[request_id] = {
		"definition": definition,
		"source_id": source_id.strip_edges(),
		"parent_transaction_id": (
			parent_transaction_id.strip_edges()
		)
	}

	call_deferred("_evaluate_request", request_id)
	return request_id


func create_preview(
	definition: ActivityDefinitionData,
	source_id: String = "",
	parent_transaction_id: String = ""
) -> ActivityPreviewData:
	return _build_preview(
		definition,
		"",
		source_id.strip_edges(),
		parent_transaction_id.strip_edges()
	)


func cancel_request(
	request_id: String,
	reason: String = "Activity cancelled."
) -> bool:
	var clean_request_id: String = request_id.strip_edges()

	if not _pending_requests.has(clean_request_id):
		return false

	_cancel_pending_request(clean_request_id, reason)
	return true


func cancel_requests_for_source(
	source_id: String,
	reason: String = "Activity source closed."
) -> int:
	var clean_source_id: String = source_id.strip_edges()
	var request_ids: Array = _pending_requests.keys()
	var cancelled_count: int = 0

	for request_value in request_ids:
		var request_id: String = str(request_value)
		var request: Dictionary = _pending_requests.get(
			request_id,
			{}
		)

		if str(request.get("source_id", "")) != clean_source_id:
			continue

		_cancel_pending_request(request_id, reason)
		cancelled_count += 1

	return cancelled_count


func complete_activity(
	transaction_id: String,
	activity_id: String = ""
) -> bool:
	var clean_transaction_id: String = (
		transaction_id.strip_edges()
	)

	if not _active_transactions.has(clean_transaction_id):
		return false

	var transaction: Dictionary = _active_transactions[
		clean_transaction_id
	]
	var root_activity_id: String = str(
		transaction.get("root_activity_id", "")
	)
	var completed_activity_id: String = activity_id.strip_edges()

	if completed_activity_id.is_empty():
		completed_activity_id = root_activity_id

	var source_id: String = str(
		transaction.get("source_id", "")
	)

	if completed_activity_id == root_activity_id:
		_active_transactions.erase(clean_transaction_id)
	else:
		var completed_children: Array = transaction.get(
			"completed_activity_ids",
			[]
		)

		if not completed_children.has(completed_activity_id):
			completed_children.append(completed_activity_id)

		transaction["completed_activity_ids"] = completed_children
		_active_transactions[clean_transaction_id] = transaction

	activity_completed.emit(
		clean_transaction_id,
		completed_activity_id,
		source_id
	)
	return true


func fail_activity(
	transaction_id: String,
	reason: String,
	activity_id: String = ""
) -> bool:
	var clean_transaction_id: String = (
		transaction_id.strip_edges()
	)

	if not _active_transactions.has(clean_transaction_id):
		return false

	var transaction: Dictionary = _active_transactions[
		clean_transaction_id
	]
	var failed_activity_id: String = activity_id.strip_edges()

	if failed_activity_id.is_empty():
		failed_activity_id = str(
			transaction.get("root_activity_id", "")
		)

	var source_id: String = str(
		transaction.get("source_id", "")
	)

	if failed_activity_id == str(
		transaction.get("root_activity_id", "")
	):
		_active_transactions.erase(clean_transaction_id)

	activity_failed.emit(
		clean_transaction_id,
		failed_activity_id,
		source_id,
		reason.strip_edges()
	)
	return true


func has_active_transaction(transaction_id: String) -> bool:
	return _active_transactions.has(
		transaction_id.strip_edges()
	)


func get_active_transaction(
	transaction_id: String
) -> Dictionary:
	var clean_transaction_id: String = (
		transaction_id.strip_edges()
	)

	if not _active_transactions.has(clean_transaction_id):
		return {}

	return (
		_active_transactions[clean_transaction_id]
		as Dictionary
	).duplicate(true)


func register_availability_provider(
	provider_id: StringName,
	provider: Callable
) -> bool:
	if provider_id.is_empty() or not provider.is_valid():
		return false

	_availability_providers[provider_id] = provider
	return true


func unregister_availability_provider(
	provider_id: StringName
) -> void:
	_availability_providers.erase(provider_id)


func reset_runtime_state() -> void:
	var request_ids: Array = _pending_requests.keys()

	for request_value in request_ids:
		_cancel_pending_request(
			str(request_value),
			"ActivityManager reset."
		)

	_pending_requests.clear()
	_active_transactions.clear()
	_next_request_number = 1
	_next_transaction_number = 1


func _evaluate_request(request_id: String) -> void:
	if not _pending_requests.has(request_id):
		return

	var request: Dictionary = _pending_requests[request_id]
	var definition := (
		request.get("definition") as ActivityDefinitionData
	)
	var source_id: String = str(
		request.get("source_id", "")
	)
	var parent_transaction_id: String = str(
		request.get("parent_transaction_id", "")
	)
	var preview: ActivityPreviewData = _build_preview(
		definition,
		request_id,
		source_id,
		parent_transaction_id
	)

	request["preview"] = preview
	_pending_requests[request_id] = request

	if not preview.is_valid():
		_reject_pending_request(
			request_id,
			preview.denial_reason
		)
		return

	if preview.requires_confirmation:
		GlobalSignals.activity_confirmation_requested.emit(
			request_id,
			definition,
			preview,
			source_id
		)
		return

	_start_pending_request(request_id)


func _build_preview(
	definition: ActivityDefinitionData,
	request_id: String,
	source_id: String,
	parent_transaction_id: String
) -> ActivityPreviewData:
	var preview := ActivityPreviewData.new()
	preview.request_id = request_id
	preview.source_id = source_id
	preview.parent_transaction_id = parent_transaction_id
	preview.initial_day = TimeManager.days_passed
	preview.initial_period = int(TimeManager.current_period)
	preview.initial_action_block = (
		TimeManager.current_action_block
	)
	preview.final_day = preview.initial_day
	preview.final_period = preview.initial_period
	preview.final_action_block = preview.initial_action_block

	if definition == null:
		preview.denial_reason = "Activity definition is missing."
		return preview

	preview.activity_id = definition.get_display_id()
	preview.display_name = definition.get_display_name()
	preview.action_cost = definition.action_cost
	preview.requires_confirmation = (
		definition.requires_confirmation
	)

	var validation_errors: PackedStringArray = (
		definition.validate_data()
	)

	if not validation_errors.is_empty():
		preview.denial_reason = "; ".join(validation_errors)
		return preview

	if not parent_transaction_id.is_empty():
		if not has_active_transaction(parent_transaction_id):
			preview.denial_reason = (
				"Parent activity transaction is not active."
			)
			return preview

		preview.is_included_activity = true
		preview.charged_action_cost = 0
		preview.requires_confirmation = false
		preview.can_start = true
		return preview

	preview.charged_action_cost = definition.action_cost
	preview.available_blocks_in_period = (
		TimeManager.get_actions_left_in_period()
	)
	var initial_day_block: int = (
		TimeManager.get_current_day_block_index()
	)
	preview.available_blocks_in_day = (
		TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY
		- initial_day_block
	)

	var final_absolute_day_block: int = (
		initial_day_block
		+ preview.charged_action_cost
	)
	var day_offset: int = int(
		final_absolute_day_block
		/ TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY
	)
	var final_day_block: int = posmod(
		final_absolute_day_block,
		TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY
	)

	preview.final_day = preview.initial_day + day_offset

	if final_day_block >= TimeManager.ACTION_BLOCKS_PER_PERIOD:
		preview.final_period = TimeManager.TimePeriod.NIGHT
		preview.final_action_block = (
			final_day_block
			- TimeManager.ACTION_BLOCKS_PER_PERIOD
		)
	else:
		preview.final_period = TimeManager.TimePeriod.DAY
		preview.final_action_block = final_day_block

	preview.crosses_day = (
		preview.final_day != preview.initial_day
	)
	preview.crosses_period = (
		preview.crosses_day
		or preview.final_period != preview.initial_period
	)

	var consumes_next_day_blocks: bool = (
		preview.charged_action_cost
		> preview.available_blocks_in_day
	)

	if consumes_next_day_blocks and not definition.allow_cross_day:
		preview.denial_reason = (
			definition.get_insufficient_time_message(
				preview.charged_action_cost,
				preview.available_blocks_in_day
			)
		)
		return preview

	var consumes_next_period_blocks: bool = (
		preview.charged_action_cost
		> preview.available_blocks_in_period
	)

	if (
		consumes_next_period_blocks
		and not definition.allow_cross_period
	):
		preview.denial_reason = (
			"This activity cannot cross the current period."
		)
		return preview

	_apply_availability_providers(definition, preview)

	if preview.denial_reason.is_empty():
		preview.can_start = true

	return preview


func _apply_availability_providers(
	definition: ActivityDefinitionData,
	preview: ActivityPreviewData
) -> void:
	var provider_ids: Array = _availability_providers.keys()

	for provider_id in provider_ids:
		var provider: Callable = _availability_providers.get(
			provider_id,
			Callable()
		)

		if not provider.is_valid():
			_availability_providers.erase(provider_id)
			continue

		var result: Variant = provider.call(
			definition,
			preview
		)

		if result is bool:
			if not bool(result):
				preview.denial_reason = (
					"Activity is unavailable."
				)
				return
			continue

		if result is String:
			var reason: String = str(result).strip_edges()

			if not reason.is_empty():
				preview.denial_reason = reason
				return
			continue

		if not result is Dictionary:
			continue

		var provider_result := result as Dictionary
		var warnings_value: Variant = provider_result.get(
			"expiration_warnings",
			PackedStringArray()
		)

		if warnings_value is PackedStringArray:
			preview.expiration_warnings.append_array(
				warnings_value as PackedStringArray
			)
		elif warnings_value is Array:
			for warning_value in warnings_value:
				var warning: String = str(
					warning_value
				).strip_edges()

				if not warning.is_empty():
					preview.expiration_warnings.append(
						warning
					)

		if bool(provider_result.get("allowed", true)):
			continue

		preview.denial_reason = str(
			provider_result.get(
				"reason",
				"Activity is unavailable."
			)
		).strip_edges()
		return


func _on_confirmation_resolved(
	request_id: String,
	confirmed: bool
) -> void:
	var clean_request_id: String = request_id.strip_edges()

	if not _pending_requests.has(clean_request_id):
		return

	if not confirmed:
		_cancel_pending_request(
			clean_request_id,
			"Player cancelled activity."
		)
		return

	var request: Dictionary = _pending_requests[
		clean_request_id
	]
	var definition := (
		request.get("definition") as ActivityDefinitionData
	)
	var preview: ActivityPreviewData = _build_preview(
		definition,
		clean_request_id,
		str(request.get("source_id", "")),
		str(request.get("parent_transaction_id", ""))
	)

	request["preview"] = preview
	_pending_requests[clean_request_id] = request

	if not preview.is_valid():
		_reject_pending_request(
			clean_request_id,
			preview.denial_reason
		)
		return

	_start_pending_request(clean_request_id)


func _start_pending_request(request_id: String) -> void:
	if not _pending_requests.has(request_id):
		return

	var request: Dictionary = _pending_requests[request_id]
	var definition := (
		request.get("definition") as ActivityDefinitionData
	)
	var preview := (
		request.get("preview") as ActivityPreviewData
	)

	if definition == null or preview == null:
		_reject_pending_request(
			request_id,
			"Activity request is incomplete."
		)
		return

	_pending_requests.erase(request_id)

	var source_id: String = str(
		request.get("source_id", "")
	)
	var transaction_id: String = str(
		request.get("parent_transaction_id", "")
	)

	if transaction_id.is_empty():
		transaction_id = _make_transaction_id()
		_active_transactions[transaction_id] = {
			"transaction_id": transaction_id,
			"root_activity_id": definition.get_display_id(),
			"source_id": source_id,
			"action_cost": preview.charged_action_cost,
			"initial_day": preview.initial_day,
			"initial_period": preview.initial_period,
			"initial_action_block": (
				preview.initial_action_block
			),
			"included_activity_ids": [],
			"completed_activity_ids": []
		}
	else:
		var transaction: Dictionary = _active_transactions[
			transaction_id
		]
		var included_activity_ids: Array = transaction.get(
			"included_activity_ids",
			[]
		)

		if not included_activity_ids.has(
			definition.get_display_id()
		):
			included_activity_ids.append(
				definition.get_display_id()
			)

		transaction["included_activity_ids"] = (
			included_activity_ids
		)
		_active_transactions[transaction_id] = transaction

	if preview.charged_action_cost > 0:
		if source_id == StoryEventManager.SOURCE_ID:
			# Mandatory routines own their own authored time sequence. Do not apply
			# occupation fast-forward while that routine itself is executing.
			TimeManager.advance_action(preview.charged_action_cost)
		else:
			OperatorService.advance_player_action_time(
				preview.charged_action_cost
			)

	activity_started.emit(
		transaction_id,
		definition.get_display_id(),
		source_id,
		request_id
	)


func _reject_pending_request(
	request_id: String,
	reason: String
) -> void:
	if not _pending_requests.has(request_id):
		return

	var request: Dictionary = _pending_requests[request_id]
	var definition := (
		request.get("definition") as ActivityDefinitionData
	)
	var activity_id: String = ""

	if definition != null:
		activity_id = definition.get_display_id()

	var source_id: String = str(
		request.get("source_id", "")
	)
	_pending_requests.erase(request_id)

	GlobalSignals.activity_request_cancelled.emit(request_id)
	activity_rejected.emit(
		request_id,
		activity_id,
		source_id,
		reason.strip_edges()
	)


func _cancel_pending_request(
	request_id: String,
	reason: String
) -> void:
	if not _pending_requests.has(request_id):
		return

	var request: Dictionary = _pending_requests[request_id]
	var definition := (
		request.get("definition") as ActivityDefinitionData
	)
	var activity_id: String = ""

	if definition != null:
		activity_id = definition.get_display_id()

	var source_id: String = str(
		request.get("source_id", "")
	)
	_pending_requests.erase(request_id)

	GlobalSignals.activity_request_cancelled.emit(request_id)
	activity_cancelled.emit(
		request_id,
		activity_id,
		source_id,
		reason.strip_edges()
	)


func _emit_invalid_definition_rejection(
	request_id: String,
	source_id: String
) -> void:
	activity_rejected.emit(
		request_id,
		"",
		source_id.strip_edges(),
		"Activity definition is missing."
	)


func _make_request_id() -> String:
	var request_id: String = "%s%08d" % [
		REQUEST_PREFIX,
		_next_request_number
	]
	_next_request_number += 1
	return request_id


func _make_transaction_id() -> String:
	var transaction_id: String = "%s%08d" % [
		TRANSACTION_PREFIX,
		_next_transaction_number
	]
	_next_transaction_number += 1
	return transaction_id
