extends Resource
class_name PartnerContinuityStateData


## Persistent continuity state that exists beside the currently active partner.
##
## CampaignState.partner remains the active combat authority. This Resource owns
## only the inactive TURD reserve and the immutable history of partners that
## were permanently lost. TURD is moved between CampaignState.partner and
## turd_reserve, so its progression is never duplicated or recreated.

var turd_reserve: PartnerStateData = PartnerStateData.new()
var lost_partner_history: Array[Dictionary] = []


func reset() -> void:
	turd_reserve = PartnerStateData.new()
	lost_partner_history.clear()


func has_turd_reserve() -> bool:
	return (
		turd_reserve != null
		and not turd_reserve.is_empty()
		and turd_reserve.integrity_state == PartnerStateData.IntegrityState.TURD
	)


func stash_turd(state: PartnerStateData) -> bool:
	if state == null \
		or state.is_empty() \
		or state.integrity_state != PartnerStateData.IntegrityState.TURD:
		return false

	turd_reserve = state.duplicate_state()
	return true


func take_turd() -> PartnerStateData:
	if not has_turd_reserve():
		return null

	var result: PartnerStateData = turd_reserve.duplicate_state()
	turd_reserve = PartnerStateData.new()
	return result


func archive_lost_partner(
	state: PartnerStateData,
	reason: String,
	location_id: String,
	game_day: int,
	action_index: int,
	encounter_id: String = ""
) -> Dictionary:
	if state == null or state.is_empty():
		return {}

	var lost_state: PartnerStateData = state.duplicate_state()
	lost_state.current_hp = 0
	lost_state.integrity_state = PartnerStateData.IntegrityState.LOST
	var record: Dictionary = {
		"partner": lost_state.to_save_data(),
		"reason": reason.strip_edges(),
		"location_id": location_id.strip_edges(),
		"game_day": maxi(1, game_day),
		"action_index": maxi(0, action_index),
		"encounter_id": encounter_id.strip_edges()
	}
	lost_partner_history.append(record.duplicate(true))
	return record


func get_lost_partner_history() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for record: Dictionary in lost_partner_history:
		result.append(record.duplicate(true))

	return result


func to_save_data() -> Dictionary:
	return {
		"turd_reserve": (
			{}
			if not has_turd_reserve()
			else turd_reserve.to_save_data()
		),
		"lost_partner_history": get_lost_partner_history()
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	var reserve_value: Variant = data.get("turd_reserve", {})

	if reserve_value is Dictionary and not (reserve_value as Dictionary).is_empty():
		var loaded_reserve := PartnerStateData.new()
		loaded_reserve.load_save_data(reserve_value as Dictionary)

		if loaded_reserve.integrity_state == PartnerStateData.IntegrityState.TURD:
			turd_reserve = loaded_reserve

	var history_value: Variant = data.get("lost_partner_history", [])

	if history_value is Array:
		for raw_record: Variant in history_value:
			if raw_record is Dictionary:
				lost_partner_history.append(
					(raw_record as Dictionary).duplicate(true)
				)


func validate_state() -> PackedStringArray:
	var errors := PackedStringArray()

	if not turd_reserve.is_empty():
		if turd_reserve.integrity_state != PartnerStateData.IntegrityState.TURD:
			errors.append("The continuity reserve must contain TURD.")
		else:
			for error: String in APKProgressionService.validate_partner_state(
				turd_reserve
			):
				errors.append("TURD reserve: %s" % error)

	for index: int in range(lost_partner_history.size()):
		var record: Dictionary = lost_partner_history[index]
		var partner_value: Variant = record.get("partner", {})

		if partner_value is not Dictionary \
			or (partner_value as Dictionary).is_empty():
			errors.append("Lost partner record %d has no partner state." % index)
			continue

		var lost_state := PartnerStateData.new()
		lost_state.load_save_data(partner_value as Dictionary)

		if lost_state.integrity_state != PartnerStateData.IntegrityState.LOST:
			errors.append("Lost partner record %d is not marked LOST." % index)

	return errors
