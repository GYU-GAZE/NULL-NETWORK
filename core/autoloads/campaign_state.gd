extends Node


signal campaign_created(campaign_id: String)
signal campaign_reset
signal campaign_changed(section: StringName)
signal app_installed(app_id: String)
signal location_changed(location_id: String)
signal story_event_state_changed(event_id: String, step_index: int)


enum CampaignPhase {
	NO_CAMPAIGN,
	PROLOGUE,
	MAIN_CAMPAIGN,
	OPERATOR_CREATION,
	OPERATOR_LOSS,
	CAMPAIGN_COMPLETE
}

enum SaveMode {
	UNSET,
	SAFE,
	COMMIT
}

const STATE_SCHEMA_VERSION: int = 3
const MIN_SUPPORTED_STATE_SCHEMA_VERSION: int = 1
const SOCIAL_AFFINITY_KEY: String = "affinity_by_npc"

var campaign_id: String = ""
var campaign_phase: CampaignPhase = CampaignPhase.NO_CAMPAIGN
var save_mode: SaveMode = SaveMode.UNSET

var operator: OperatorStateData = OperatorStateData.new()
var partner_id: String = ""
var tendencies: TendencyStateData = TendencyStateData.new()
var money: int = 0
var inventory: InventoryStateData = InventoryStateData.new()

var known_module_ids: PackedStringArray = PackedStringArray()
var installed_app_ids: PackedStringArray = PackedStringArray()
var discovered_location_ids: PackedStringArray = PackedStringArray()
var current_location_id: String = ""
var active_lead_ids: PackedStringArray = PackedStringArray()
var completed_lead_ids: PackedStringArray = PackedStringArray()

var queued_story_event_ids: PackedStringArray = PackedStringArray()
var active_story_event_id: String = ""
var active_story_event_step_index: int = 0
var active_story_event_step_id: String = ""
var active_story_event_waiting: bool = false
var completed_story_event_ids: PackedStringArray = PackedStringArray()
var story_event_repeat_state: Dictionary = {}

var social_state: Dictionary = {}
var encyclopedia_state: Dictionary = {}
var world_state: WorldStateData = WorldStateData.new()
var operator_history: Array[Dictionary] = []


func create_campaign(
	new_campaign_id: String,
	new_save_mode: SaveMode,
	initial_phase: CampaignPhase = CampaignPhase.PROLOGUE
) -> bool:
	var clean_id: String = new_campaign_id.strip_edges()

	if clean_id.is_empty() \
		or new_save_mode == SaveMode.UNSET \
		or initial_phase == CampaignPhase.NO_CAMPAIGN:
		return false

	reset_campaign(false)
	campaign_id = clean_id
	save_mode = new_save_mode
	campaign_phase = initial_phase
	campaign_created.emit(campaign_id)
	campaign_changed.emit(&"campaign")
	return true


func reset_campaign(emit_signal: bool = true) -> void:
	campaign_id = ""
	campaign_phase = CampaignPhase.NO_CAMPAIGN
	save_mode = SaveMode.UNSET
	operator = OperatorStateData.new()
	partner_id = ""
	tendencies = TendencyStateData.new()
	money = 0
	inventory = InventoryStateData.new()
	known_module_ids.clear()
	installed_app_ids.clear()
	discovered_location_ids.clear()
	current_location_id = ""
	active_lead_ids.clear()
	completed_lead_ids.clear()
	queued_story_event_ids.clear()
	active_story_event_id = ""
	active_story_event_step_index = 0
	active_story_event_step_id = ""
	active_story_event_waiting = false
	completed_story_event_ids.clear()
	story_event_repeat_state.clear()
	social_state.clear()
	encyclopedia_state.clear()
	world_state = WorldStateData.new()
	operator_history.clear()

	if emit_signal:
		campaign_reset.emit()
		campaign_changed.emit(&"campaign")


func has_campaign() -> bool:
	return (
		campaign_phase != CampaignPhase.NO_CAMPAIGN
		and not campaign_id.is_empty()
	)


func get_save_section_id() -> String:
	return str(SaveConstants.SECTION_CAMPAIGN_STATE)


func import_save_data(data: Dictionary) -> void:
	var errors: PackedStringArray = restore_save_data(data)

	for error: String in errors:
		push_error("CampaignState import: %s" % error)


func reset_save_data() -> void:
	reset_campaign()


func set_money(value: int) -> void:
	money = maxi(0, value)
	campaign_changed.emit(&"money")


func add_money(amount: int) -> int:
	set_money(money + amount)
	return money


func set_tendency(
	tendency: TendencyStateData.Tendency,
	value: int
) -> int:
	tendencies.set_value(tendency, value)
	campaign_changed.emit(&"tendencies")
	return tendencies.get_value(tendency)


func modify_tendency(
	tendency: TendencyStateData.Tendency,
	amount: int
) -> int:
	return set_tendency(
		tendency,
		tendencies.get_value(tendency) + amount
	)


func set_operator_state(new_operator: OperatorStateData) -> bool:
	if new_operator == null or new_operator.is_empty():
		return false

	operator = OperatorStateData.new()
	operator.load_save_data(new_operator.to_save_data())
	campaign_changed.emit(&"operator")
	return true


func set_operator_last_income_day(game_day: int) -> bool:
	if operator.is_empty():
		return false

	operator.last_income_day = maxi(operator.registration_day, game_day)
	campaign_changed.emit(&"operator")
	return true


func set_initial_tendencies(
	valour: int,
	logic: int,
	sync: int,
	self_value: int
) -> bool:
	var values: Array[int] = [valour, logic, sync, self_value]

	for value: int in values:
		if value < 0:
			return false

	if valour + logic + sync + self_value != 15:
		return false

	tendencies = TendencyStateData.new()
	tendencies.valour = valour
	tendencies.logic = logic
	tendencies.sync = sync
	tendencies.self_value = self_value
	campaign_changed.emit(&"tendencies")
	return true


func grant_item(item_id: String, amount: int = 1) -> int:
	var clean_id: String = item_id.strip_edges()

	if clean_id.is_empty() or amount <= 0:
		return inventory.get_item_count(clean_id)

	var new_amount: int = inventory.add_item(clean_id, amount)
	campaign_changed.emit(&"inventory")
	return new_amount


func get_affinity(npc_id: String) -> int:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty():
		return 0

	var affinities: Dictionary = _get_affinity_map()
	return int(affinities.get(clean_id, 0))


func set_affinity(npc_id: String, value: int) -> int:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty():
		return 0

	var affinities: Dictionary = _get_affinity_map()
	affinities[clean_id] = value
	social_state[SOCIAL_AFFINITY_KEY] = affinities
	campaign_changed.emit(&"social")
	return value


func modify_affinity(npc_id: String, amount: int) -> int:
	return set_affinity(npc_id, get_affinity(npc_id) + amount)


func learn_module(module_id: String) -> bool:
	return _add_unique_id(known_module_ids, module_id, &"known_modules")


func install_app(app_id: String) -> bool:
	var clean_id: String = app_id.strip_edges()
	var installed: bool = _add_unique_id(
		installed_app_ids,
		clean_id,
		&"installed_apps"
	)

	if installed:
		app_installed.emit(clean_id)

	return installed


func has_installed_app(app_id: String) -> bool:
	var clean_id: String = app_id.strip_edges()
	return not clean_id.is_empty() and installed_app_ids.has(clean_id)


func discover_location(location_id: String) -> bool:
	return _add_unique_id(
		discovered_location_ids,
		location_id,
		&"discovered_locations"
	)


func set_current_location(location_id: String) -> bool:
	var clean_id: String = location_id.strip_edges()

	if current_location_id == clean_id:
		return false

	current_location_id = clean_id
	campaign_changed.emit(&"current_location")
	location_changed.emit(current_location_id)
	return true


func enqueue_story_event(event_id: String, at_front: bool = false) -> bool:
	var clean_id: String = event_id.strip_edges()

	if clean_id.is_empty() \
		or clean_id == active_story_event_id \
		or queued_story_event_ids.has(clean_id):
		return false

	if at_front:
		queued_story_event_ids.insert(0, clean_id)
	else:
		queued_story_event_ids.append(clean_id)

	_emit_story_event_state_changed(clean_id)
	return true


func remove_queued_story_event(event_id: String) -> bool:
	var clean_id: String = event_id.strip_edges()
	var index: int = queued_story_event_ids.find(clean_id)

	if index < 0:
		return false

	queued_story_event_ids.remove_at(index)
	_emit_story_event_state_changed(clean_id)
	return true


func reorder_queued_story_events(ordered_ids: PackedStringArray) -> bool:
	if ordered_ids.size() != queued_story_event_ids.size():
		return false

	var validated := PackedStringArray()

	for raw_id: String in ordered_ids:
		var clean_id: String = raw_id.strip_edges()

		if clean_id.is_empty() \
			or validated.has(clean_id) \
			or not queued_story_event_ids.has(clean_id):
			return false

		validated.append(clean_id)

	queued_story_event_ids = validated
	_emit_story_event_state_changed(active_story_event_id)
	return true


func begin_story_event(event_id: String) -> bool:
	var clean_id: String = event_id.strip_edges()

	if clean_id.is_empty() or not active_story_event_id.is_empty():
		return false

	remove_queued_story_event(clean_id)
	active_story_event_id = clean_id
	active_story_event_step_index = 0
	active_story_event_step_id = ""
	active_story_event_waiting = false
	_emit_story_event_state_changed(clean_id)
	return true


func set_active_story_event_step(
	step_index: int,
	step_id: String,
	waiting: bool
) -> bool:
	if active_story_event_id.is_empty() or step_index < 0:
		return false

	active_story_event_step_index = step_index
	active_story_event_step_id = step_id.strip_edges()
	active_story_event_waiting = waiting
	_emit_story_event_state_changed(active_story_event_id)
	return true


func clear_active_story_event() -> void:
	var previous_id: String = active_story_event_id
	active_story_event_id = ""
	active_story_event_step_index = 0
	active_story_event_step_id = ""
	active_story_event_waiting = false
	_emit_story_event_state_changed(previous_id)


func record_story_event_completion(
	event_id: String,
	completed_day: int,
	completed_action_index: int
) -> void:
	var clean_id: String = event_id.strip_edges()

	if clean_id.is_empty():
		return

	var state: Dictionary = _read_dictionary(
		story_event_repeat_state.get(clean_id, {})
	)
	state["completion_count"] = maxi(
		0,
		int(state.get("completion_count", 0))
	) + 1
	state["last_completed_day"] = maxi(1, completed_day)
	state["last_completed_action_index"] = maxi(
		0,
		completed_action_index
	)
	story_event_repeat_state[clean_id] = state

	if not completed_story_event_ids.has(clean_id):
		completed_story_event_ids.append(clean_id)

	_emit_story_event_state_changed(clean_id)


func get_story_event_repeat_state(event_id: String) -> Dictionary:
	var clean_id: String = event_id.strip_edges()

	if clean_id.is_empty():
		return {}

	return _read_dictionary(story_event_repeat_state.get(clean_id, {}))


func has_completed_story_event(event_id: String) -> bool:
	return completed_story_event_ids.has(event_id.strip_edges())


func activate_lead(lead_id: String) -> bool:
	var clean_id: String = lead_id.strip_edges()

	if clean_id.is_empty() or completed_lead_ids.has(clean_id):
		return false

	return _add_unique_id(active_lead_ids, clean_id, &"active_leads")


func complete_lead(lead_id: String) -> bool:
	var clean_id: String = lead_id.strip_edges()

	if clean_id.is_empty():
		return false

	active_lead_ids.erase(clean_id)
	var changed: bool = _add_unique_id(
		completed_lead_ids,
		clean_id,
		&"completed_leads"
	)

	if not changed:
		campaign_changed.emit(&"active_leads")

	return true


func archive_current_operator() -> bool:
	if operator.is_empty():
		return false

	var archived_data: Dictionary = operator.to_save_data()
	archived_data["archived"] = true
	operator_history.append(archived_data)
	operator = OperatorStateData.new()
	campaign_changed.emit(&"operator")
	return true


func export_save_data() -> Dictionary:
	return {
		"schema_version": STATE_SCHEMA_VERSION,
		"campaign_id": campaign_id,
		"campaign_phase": int(campaign_phase),
		"save_mode": int(save_mode),
		"operator": operator.to_save_data(),
		"partner_id": partner_id,
		"tendencies": tendencies.to_save_data(),
		"money": money,
		"inventory": inventory.to_save_data(),
		"known_module_ids": _string_array_to_array(known_module_ids),
		"installed_app_ids": _string_array_to_array(installed_app_ids),
		"discovered_location_ids": _string_array_to_array(
			discovered_location_ids
		),
		"current_location_id": current_location_id,
		"active_lead_ids": _string_array_to_array(active_lead_ids),
		"completed_lead_ids": _string_array_to_array(
			completed_lead_ids
		),
		"queued_story_event_ids": _string_array_to_array(
			queued_story_event_ids
		),
		"active_story_event_id": active_story_event_id,
		"active_story_event_step_index": active_story_event_step_index,
		"active_story_event_step_id": active_story_event_step_id,
		"active_story_event_waiting": active_story_event_waiting,
		"completed_story_event_ids": _string_array_to_array(
			completed_story_event_ids
		),
		"story_event_repeat_state": story_event_repeat_state.duplicate(true),
		"social_state": social_state.duplicate(true),
		"encyclopedia_state": encyclopedia_state.duplicate(true),
		"world_state": world_state.to_save_data(),
		"operator_history": operator_history.duplicate(true)
	}


func restore_save_data(data: Dictionary) -> PackedStringArray:
	var errors := validate_save_data(data)

	if not errors.is_empty():
		return errors

	reset_campaign(false)
	campaign_id = str(data.get("campaign_id", "")).strip_edges()
	campaign_phase = int(data.get("campaign_phase", CampaignPhase.NO_CAMPAIGN))
	save_mode = int(data.get("save_mode", SaveMode.UNSET))
	operator.load_save_data(_read_dictionary(data.get("operator", {})))
	partner_id = str(data.get("partner_id", "")).strip_edges()
	tendencies.load_save_data(_read_dictionary(data.get("tendencies", {})))
	money = maxi(0, int(data.get("money", 0)))
	inventory.load_save_data(_read_dictionary(data.get("inventory", {})))
	known_module_ids = _read_id_array(data.get("known_module_ids", []))
	installed_app_ids = _read_id_array(data.get("installed_app_ids", []))
	discovered_location_ids = _read_id_array(
		data.get("discovered_location_ids", [])
	)
	current_location_id = str(
		data.get("current_location_id", "")
	).strip_edges()
	active_lead_ids = _read_id_array(data.get("active_lead_ids", []))
	completed_lead_ids = _read_id_array(
		data.get("completed_lead_ids", [])
	)
	queued_story_event_ids = _read_id_array(
		data.get("queued_story_event_ids", [])
	)
	active_story_event_id = str(
		data.get("active_story_event_id", "")
	).strip_edges()
	active_story_event_step_index = maxi(
		0,
		int(data.get("active_story_event_step_index", 0))
	)
	active_story_event_step_id = str(
		data.get("active_story_event_step_id", "")
	).strip_edges()
	active_story_event_waiting = bool(
		data.get("active_story_event_waiting", false)
	)
	completed_story_event_ids = _read_id_array(
		data.get("completed_story_event_ids", [])
	)
	story_event_repeat_state = _read_dictionary(
		data.get("story_event_repeat_state", {})
	)
	social_state = _read_dictionary(data.get("social_state", {}))
	encyclopedia_state = _read_dictionary(
		data.get("encyclopedia_state", {})
	)
	world_state.load_save_data(
		_read_dictionary(data.get("world_state", {}))
	)
	operator_history = _read_dictionary_array(
		data.get("operator_history", [])
	)
	campaign_changed.emit(&"campaign")
	return errors


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var version: int = int(data.get("schema_version", -1))

	if version < MIN_SUPPORTED_STATE_SCHEMA_VERSION \
		or version > STATE_SCHEMA_VERSION:
		errors.append(
			"Unsupported CampaignState schema version: %d." % version
		)

	var restored_id: String = str(data.get("campaign_id", "")).strip_edges()
	var restored_phase: int = int(
		data.get("campaign_phase", CampaignPhase.NO_CAMPAIGN)
	)
	var restored_mode: int = int(data.get("save_mode", SaveMode.UNSET))

	if restored_phase < CampaignPhase.NO_CAMPAIGN \
		or restored_phase > CampaignPhase.CAMPAIGN_COMPLETE:
		errors.append("CampaignState contains an invalid campaign phase.")

	if restored_mode < SaveMode.UNSET or restored_mode > SaveMode.COMMIT:
		errors.append("CampaignState contains an invalid save mode.")

	if restored_phase != CampaignPhase.NO_CAMPAIGN and restored_id.is_empty():
		errors.append("An active campaign requires a campaign_id.")

	var queued_events: PackedStringArray = _read_id_array(
		data.get("queued_story_event_ids", [])
	)
	var restored_active_event: String = str(
		data.get("active_story_event_id", "")
	).strip_edges()

	if not restored_active_event.is_empty() and queued_events.has(
		restored_active_event
	):
		errors.append("The active StoryEvent cannot also be queued.")

	if restored_active_event.is_empty() and (
		int(data.get("active_story_event_step_index", 0)) != 0
		or not str(data.get("active_story_event_step_id", "")).is_empty()
		or bool(data.get("active_story_event_waiting", false))
	):
		errors.append("StoryEvent step state requires an active event ID.")

	return errors


func _add_unique_id(
	target: PackedStringArray,
	raw_id: String,
	section: StringName
) -> bool:
	var clean_id: String = raw_id.strip_edges()

	if clean_id.is_empty() or target.has(clean_id):
		return false

	target.append(clean_id)
	campaign_changed.emit(section)
	return true


func _read_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)

	return {}


func _get_affinity_map() -> Dictionary:
	var value: Variant = social_state.get(SOCIAL_AFFINITY_KEY, {})

	if value is Dictionary:
		return (value as Dictionary).duplicate(true)

	return {}


func _read_id_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()

	if value is not Array and value is not PackedStringArray:
		return result

	for raw_id: Variant in value:
		var clean_id: String = str(raw_id).strip_edges()

		if not clean_id.is_empty() and not result.has(clean_id):
			result.append(clean_id)

	return result


func _read_dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if value is not Array:
		return result

	for entry: Variant in value:
		if entry is Dictionary:
			result.append(entry.duplicate(true))

	return result


func _string_array_to_array(value: PackedStringArray) -> Array[String]:
	var result: Array[String] = []

	for entry: String in value:
		result.append(entry)

	return result


func _emit_story_event_state_changed(event_id: String) -> void:
	campaign_changed.emit(&"story_events")
	story_event_state_changed.emit(
		event_id.strip_edges(),
		active_story_event_step_index
	)
