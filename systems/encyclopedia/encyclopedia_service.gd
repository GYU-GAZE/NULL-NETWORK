extends Node


signal encyclopedia_changed(entry_id: String)
signal encyclopedia_reloaded


const ENTRY_CATEGORY: StringName = &"encyclopedia_entries"

var _state: EncyclopediaStateData = EncyclopediaStateData.new()
var _writing_campaign_state: bool = false
var _reloading_state: bool = false


func _ready() -> void:
	if not CampaignState.campaign_reset.is_connected(_on_campaign_reset):
		CampaignState.campaign_reset.connect(_on_campaign_reset)

	if not CampaignState.campaign_changed.is_connected(_on_campaign_changed):
		CampaignState.campaign_changed.connect(_on_campaign_changed)

	if not ContentRegistry.registry_rebuilt.is_connected(_on_registry_rebuilt):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)

	_reload_from_campaign(true)


func get_entry(entry_id: String) -> EncyclopediaEntryData:
	return ContentRegistry.resolve(
		ENTRY_CATEGORY,
		entry_id
	) as EncyclopediaEntryData


func get_record(entry_id: String) -> EncyclopediaRecordData:
	_ensure_state_current()
	var record: EncyclopediaRecordData = _state.get_record(entry_id)
	return record.duplicate_state() if record != null else null


func get_discovered_entry_ids() -> PackedStringArray:
	_ensure_state_current()
	var result := PackedStringArray()

	for record: EncyclopediaRecordData in _state.get_discovered_records():
		result.append(record.entry_id)

	return result


func get_discovered_records() -> Array[EncyclopediaRecordData]:
	_ensure_state_current()
	var result: Array[EncyclopediaRecordData] = []

	for record: EncyclopediaRecordData in _state.get_discovered_records():
		result.append(record.duplicate_state())

	return result


func has_any_entry() -> bool:
	_ensure_state_current()
	return CampaignState.has_campaign() and _state.has_any_entry()


func has_entry(entry_id: String) -> bool:
	return has_milestone(entry_id, "seen")


func has_milestone(entry_id: String, milestone: String) -> bool:
	_ensure_state_current()
	return (
		CampaignState.has_campaign()
		and _state.has_milestone(entry_id, milestone)
	)


func record_observation(
	entry_id: String,
	data: Dictionary,
	observation_id: String = "",
	action_index: int = -1
) -> bool:
	var clean_id: String = entry_id.strip_edges()

	if not CampaignState.has_campaign() or clean_id.is_empty():
		return false

	_ensure_state_current()
	var resolved_action_index: int = (
		TimeManager.get_total_action_index()
		if action_index < 0
		else action_index
	)
	var changed: bool = _state.record_observation(
		clean_id,
		data,
		observation_id,
		resolved_action_index
	)

	if not changed:
		return false

	_commit(clean_id)
	return true


func record_entry(
	entry_id: String,
	entry_data: Dictionary = {},
	observation_id: String = ""
) -> bool:
	return record_observation(entry_id, entry_data, observation_id)


func mark_lost(
	entry_id: String,
	observation_id: String = ""
) -> bool:
	return record_observation(
		entry_id,
		{"seen": true, "lost": true},
		observation_id
	)


func get_state_snapshot() -> Dictionary:
	_ensure_state_current()
	return _state.to_save_data()


func synchronize_campaign_state() -> void:
	_reload_from_campaign(true)


func _ensure_state_current() -> void:
	if _reloading_state \
		or _writing_campaign_state \
		or not CampaignState.has_campaign():
		return

	if _state.to_save_data() != CampaignState.encyclopedia_state:
		_reload_from_campaign(false)


func _commit(entry_id: String, emit_domain_signal: bool = true) -> void:
	if _writing_campaign_state:
		return

	_writing_campaign_state = true
	CampaignState.encyclopedia_state = _state.to_save_data()
	CampaignState.campaign_changed.emit(&"encyclopedia")
	_writing_campaign_state = false

	if emit_domain_signal:
		encyclopedia_changed.emit(entry_id)


func _reload_from_campaign(normalize: bool) -> void:
	if _reloading_state or _writing_campaign_state:
		return

	_reloading_state = true
	_state = EncyclopediaStateData.new()

	if CampaignState.has_campaign():
		_state.load_save_data(CampaignState.encyclopedia_state)

	var normalized: Dictionary = _state.to_save_data()
	var requires_normalization: bool = (
		normalize
		and CampaignState.has_campaign()
		and normalized != CampaignState.encyclopedia_state
	)
	_reloading_state = false

	if requires_normalization:
		_commit("", false)

	encyclopedia_reloaded.emit()


func _on_campaign_reset() -> void:
	_state = EncyclopediaStateData.new()
	encyclopedia_reloaded.emit()


func _on_campaign_changed(section: StringName) -> void:
	if _writing_campaign_state:
		return

	if section in [&"campaign", &"encyclopedia"]:
		_reload_from_campaign(true)


func _on_registry_rebuilt() -> void:
	encyclopedia_reloaded.emit()
