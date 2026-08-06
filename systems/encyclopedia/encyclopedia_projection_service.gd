extends RefCounted
class_name EncyclopediaProjectionService


static func build_entries(
	filter_text: String = "",
	kind_filter: int = -1
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var clean_filter: String = filter_text.strip_edges().to_lower()

	for record: EncyclopediaRecordData in EncyclopediaService.get_discovered_records():
		var snapshot: Dictionary = build_entry_snapshot(record.entry_id)

		if snapshot.is_empty():
			continue

		if kind_filter >= 0 and int(snapshot.get("entry_kind", -1)) != kind_filter:
			continue

		if not clean_filter.is_empty():
			var searchable: String = "%s %s %s" % [
				str(snapshot.get("display_name", "")),
				str(snapshot.get("subtitle", "")),
				str(snapshot.get("entry_id", ""))
			]

			if not searchable.to_lower().contains(clean_filter):
				continue

		result.append(snapshot)

	result.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			var left_order: int = int(left.get("sort_order", 0))
			var right_order: int = int(right.get("sort_order", 0))

			if left_order != right_order:
				return left_order < right_order

			return str(left.get("display_name", "")).naturalnocasecmp_to(
				str(right.get("display_name", ""))
			) < 0
	)
	return result


static func build_entry_snapshot(entry_id: String) -> Dictionary:
	var record: EncyclopediaRecordData = EncyclopediaService.get_record(entry_id)

	if record == null or not record.seen:
		return {}

	var entry: EncyclopediaEntryData = EncyclopediaService.get_entry(entry_id)
	var apk: APKData = (
		ContentRegistry.get_apk(entry.subject_apk_id)
		if entry != null and not entry.subject_apk_id.strip_edges().is_empty()
		else null
	)
	var display_name: String = (
		entry.get_display_name()
		if entry != null
		else entry_id.strip_edges()
	)
	var kind: int = (
		int(entry.entry_kind)
		if entry != null
		else EncyclopediaEntryData.EntryKind.LORE
	)

	return {
		"entry_id": record.entry_id,
		"entry_kind": kind,
		"kind_label": (
			entry.get_kind_label()
			if entry != null
			else "UNKNOWN"
		),
		"display_name": display_name,
		"subtitle": entry.subtitle.strip_edges() if entry != null else "",
		"summary": entry.summary.strip_edges() if entry != null else "",
		"sort_order": entry.sort_order if entry != null else 100000,
		"texture": entry.get_primary_texture() if entry != null else null,
		"subject": _build_subject_snapshot(apk),
		"milestones": _build_milestones(record),
		"sections": _build_sections(entry, record),
		"known_modules": _build_module_entries(record.known_module_ids),
		"known_locations": _build_location_entries(record.known_location_ids),
		"known_evolutions": _build_evolution_entries(record.known_evolution_ids),
		"counts": {
			"encountered": record.encounter_count,
			"scanned": record.scan_count,
			"defeated": record.defeat_count,
			"purged": record.purge_count,
			"purified": record.purify_count,
			"tamed": record.tame_count,
			"lost": record.loss_count
		},
		"first_seen_action_index": record.first_seen_action_index,
		"last_updated_action_index": record.last_updated_action_index
	}


static func _build_subject_snapshot(apk: APKData) -> Dictionary:
	if apk == null:
		return {}

	return {
		"apk_id": apk.apk_id,
		"display_name": apk.display_name,
		"species_line_id": apk.species_line_id,
		"form_id": apk.form_id,
		"form_name": APKData.FormType.keys()[apk.form_type]
	}


static func _build_milestones(
	record: EncyclopediaRecordData
) -> Array[Dictionary]:
	return [
		{"id": "seen", "label": "SEEN", "unlocked": record.seen},
		{"id": "scanned", "label": "SCANNED", "unlocked": record.scanned},
		{"id": "defeated", "label": "DEFEATED", "unlocked": record.defeated},
		{"id": "purged", "label": "PURGED", "unlocked": record.purged},
		{"id": "purified", "label": "PURIFIED", "unlocked": record.purified},
		{"id": "tamed", "label": "TAMED", "unlocked": record.tamed},
		{"id": "lost", "label": "LOST", "unlocked": record.lost}
	]


static func _build_sections(
	entry: EncyclopediaEntryData,
	record: EncyclopediaRecordData
) -> Array[Dictionary]:
	if entry == null:
		return []

	return [
		_section("scan", "SCAN DATA", record.scanned, entry.scan_notes),
		_section("defeat", "DEFEAT RECORD", record.defeated, entry.defeat_notes),
		_section("purge", "PURGE RECORD", record.purged, entry.purge_notes),
		_section("purify", "PURIFICATION RECORD", record.purified, entry.purify_notes),
		_section("tame", "TAME RECORD", record.tamed, entry.tame_notes),
		_section("loss", "LOSS RECORD", record.lost, entry.loss_notes)
	]


static func _section(
	section_id: String,
	title: String,
	unlocked: bool,
	text: String
) -> Dictionary:
	return {
		"id": section_id,
		"title": title,
		"unlocked": unlocked,
		"text": text.strip_edges()
	}


static func _build_module_entries(ids: PackedStringArray) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for module_id: String in ids:
		var module: ModuleData = ContentRegistry.get_module(module_id)
		result.append({
			"id": module_id,
			"display_name": module.module_name if module != null else module_id,
			"classification": str(module.classification) if module != null else ""
		})

	return _sort_display_entries(result)


static func _build_location_entries(ids: PackedStringArray) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for location_id: String in ids:
		var location: MapLocation = ContentRegistry.get_location(location_id)
		result.append({
			"id": location_id,
			"display_name": (
				location.location_name
				if location != null
				else location_id
			)
		})

	return _sort_display_entries(result)


static func _build_evolution_entries(ids: PackedStringArray) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for apk_id: String in ids:
		var apk: APKData = ContentRegistry.get_apk(apk_id)
		result.append({
			"id": apk_id,
			"display_name": apk.display_name if apk != null else apk_id,
			"form_name": (
				APKData.FormType.keys()[apk.form_type]
				if apk != null
				else "UNKNOWN"
			)
		})

	return _sort_display_entries(result)


static func _sort_display_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	entries.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return str(left.get("display_name", "")).naturalnocasecmp_to(
				str(right.get("display_name", ""))
			) < 0
	)
	return entries
