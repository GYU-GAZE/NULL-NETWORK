extends Resource
class_name EncyclopediaRecordData


const MILESTONE_KEYS: PackedStringArray = PackedStringArray([
	"seen",
	"scanned",
	"defeated",
	"purged",
	"purified",
	"tamed",
	"lost"
])

var entry_id: String = ""
var seen: bool = false
var scanned: bool = false
var defeated: bool = false
var purged: bool = false
var purified: bool = false
var tamed: bool = false
var lost: bool = false

var encounter_count: int = 0
var scan_count: int = 0
var defeat_count: int = 0
var purge_count: int = 0
var purify_count: int = 0
var tame_count: int = 0
var loss_count: int = 0

var known_module_ids: PackedStringArray = PackedStringArray()
var known_location_ids: PackedStringArray = PackedStringArray()
var known_evolution_ids: PackedStringArray = PackedStringArray()
var first_seen_action_index: int = -1
var last_updated_action_index: int = -1
var observation_ids: PackedStringArray = PackedStringArray()
var metadata: Dictionary = {}


func has_any_progress() -> bool:
	return seen or scanned or defeated or purged or purified or tamed or lost


func has_milestone(milestone: String) -> bool:
	match milestone.strip_edges().to_lower():
		"seen", "encountered", "discovered":
			return seen
		"scanned":
			return scanned
		"defeated":
			return defeated
		"purged":
			return purged
		"purified":
			return purified
		"tamed":
			return tamed
		"lost":
			return lost

	return false


func merge_observation(
	data: Dictionary,
	observation_id: String = "",
	action_index: int = -1
) -> bool:
	var clean_observation_id: String = observation_id.strip_edges()

	if not clean_observation_id.is_empty() \
		and observation_ids.has(clean_observation_id):
		return false

	var changed: bool = false
	var saw_seen: bool = _read_any_bool(
		data,
		PackedStringArray(["seen", "encountered", "discovered"])
	)
	var saw_scanned: bool = bool(data.get("scanned", false))
	var saw_defeated: bool = bool(data.get("defeated", false))
	var saw_purged: bool = bool(data.get("purged", false))
	var saw_purified: bool = bool(data.get("purified", false))
	var saw_tamed: bool = bool(data.get("tamed", false))
	var saw_lost: bool = bool(data.get("lost", false))

	if saw_scanned or saw_defeated or saw_purged \
		or saw_purified or saw_tamed or saw_lost:
		saw_seen = true

	if saw_seen:
		encounter_count += 1
		_set_flag(&"seen")
		changed = true

	if saw_scanned:
		scan_count += 1
		_set_flag(&"scanned")
		changed = true

	if saw_defeated:
		defeat_count += 1
		_set_flag(&"defeated")
		changed = true

	if saw_purged:
		purge_count += 1
		_set_flag(&"purged")
		changed = true

	if saw_purified:
		purify_count += 1
		_set_flag(&"purified")
		changed = true

	if saw_tamed:
		tame_count += 1
		_set_flag(&"tamed")
		changed = true

	if saw_lost:
		loss_count += 1
		_set_flag(&"lost")
		changed = true

	changed = _merge_ids(
		known_module_ids,
		_read_ids(data, "known_modules", "known_module_ids")
	) or changed
	changed = _merge_ids(
		known_location_ids,
		_read_ids(data, "known_locations", "known_location_ids")
	) or changed
	changed = _merge_ids(
		known_evolution_ids,
		_read_ids(data, "known_evolutions", "known_evolution_ids")
	) or changed

	var supplied_metadata: Variant = data.get("metadata", {})

	if supplied_metadata is Dictionary:
		for raw_key: Variant in supplied_metadata:
			var key: String = str(raw_key)
			var value: Variant = (supplied_metadata as Dictionary)[raw_key]

			if metadata.get(key) != value:
				metadata[key] = value
				changed = true

	if not clean_observation_id.is_empty():
		observation_ids.append(clean_observation_id)
		changed = true

	if seen and first_seen_action_index < 0 and action_index >= 0:
		first_seen_action_index = action_index
		changed = true

	if changed and action_index >= 0:
		last_updated_action_index = action_index

	return changed


func to_save_data() -> Dictionary:
	return {
		"entry_id": entry_id,
		"discovered": seen,
		"encountered": seen,
		"seen": seen,
		"scanned": scanned,
		"defeated": defeated,
		"purged": purged,
		"purified": purified,
		"tamed": tamed,
		"lost": lost,
		"encounter_count": encounter_count,
		"scan_count": scan_count,
		"defeat_count": defeat_count,
		"purge_count": purge_count,
		"purify_count": purify_count,
		"tame_count": tame_count,
		"loss_count": loss_count,
		"known_modules": Array(known_module_ids),
		"known_locations": Array(known_location_ids),
		"known_evolutions": Array(known_evolution_ids),
		"first_seen_action_index": first_seen_action_index,
		"last_updated_action_index": last_updated_action_index,
		"observation_ids": Array(observation_ids),
		"metadata": metadata.duplicate(true)
	}


func load_save_data(new_entry_id: String, data: Dictionary) -> void:
	entry_id = new_entry_id.strip_edges()
	seen = _read_any_bool(
		data,
		PackedStringArray(["seen", "encountered", "discovered"])
	)
	scanned = bool(data.get("scanned", false))
	defeated = bool(data.get("defeated", false))
	purged = bool(data.get("purged", false))
	purified = bool(data.get("purified", false))
	tamed = bool(data.get("tamed", false))
	lost = bool(data.get("lost", false))

	if scanned or defeated or purged or purified or tamed or lost:
		seen = true

	encounter_count = maxi(
		1 if seen else 0,
		int(data.get("encounter_count", 1 if seen else 0))
	)
	scan_count = maxi(
		1 if scanned else 0,
		int(data.get("scan_count", 1 if scanned else 0))
	)
	defeat_count = maxi(
		1 if defeated else 0,
		int(data.get("defeat_count", 1 if defeated else 0))
	)
	purge_count = maxi(
		1 if purged else 0,
		int(data.get("purge_count", 1 if purged else 0))
	)
	purify_count = maxi(
		1 if purified else 0,
		int(data.get("purify_count", 1 if purified else 0))
	)
	tame_count = maxi(
		1 if tamed else 0,
		int(data.get("tame_count", 1 if tamed else 0))
	)
	loss_count = maxi(
		1 if lost else 0,
		int(data.get("loss_count", 1 if lost else 0))
	)

	known_module_ids = _read_ids(data, "known_modules", "known_module_ids")
	known_location_ids = _read_ids(
		data,
		"known_locations",
		"known_location_ids"
	)
	known_evolution_ids = _read_ids(
		data,
		"known_evolutions",
		"known_evolution_ids"
	)
	first_seen_action_index = int(data.get("first_seen_action_index", -1))
	last_updated_action_index = int(
		data.get("last_updated_action_index", first_seen_action_index)
	)
	observation_ids = _read_single_id_array(data.get("observation_ids", []))
	metadata = {}
	var metadata_value: Variant = data.get("metadata", {})

	if metadata_value is Dictionary:
		metadata = (metadata_value as Dictionary).duplicate(true)


func duplicate_state() -> EncyclopediaRecordData:
	var result := EncyclopediaRecordData.new()
	result.load_save_data(entry_id, to_save_data())
	return result


func _set_flag(flag_name: StringName) -> bool:
	match flag_name:
		&"seen":
			if seen:
				return false
			seen = true
		&"scanned":
			if scanned:
				return false
			scanned = true
		&"defeated":
			if defeated:
				return false
			defeated = true
		&"purged":
			if purged:
				return false
			purged = true
		&"purified":
			if purified:
				return false
			purified = true
		&"tamed":
			if tamed:
				return false
			tamed = true
		&"lost":
			if lost:
				return false
			lost = true
		_:
			return false

	return true


func _read_any_bool(data: Dictionary, keys: PackedStringArray) -> bool:
	for key: String in keys:
		if bool(data.get(key, false)):
			return true

	return false


func _read_ids(
	data: Dictionary,
	primary_key: String,
	legacy_key: String
) -> PackedStringArray:
	var value: Variant = data.get(primary_key, data.get(legacy_key, []))
	return _read_single_id_array(value)


func _read_single_id_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()

	if value is not Array and value is not PackedStringArray:
		return result

	for raw_id: Variant in value:
		var clean_id: String = str(raw_id).strip_edges()

		if not clean_id.is_empty() and not result.has(clean_id):
			result.append(clean_id)

	return result


func _merge_ids(
	target: PackedStringArray,
	incoming: PackedStringArray
) -> bool:
	var changed: bool = false

	for value: String in incoming:
		if not target.has(value):
			target.append(value)
			changed = true

	return changed
