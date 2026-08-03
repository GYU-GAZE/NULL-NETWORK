extends Resource
class_name PartnerStateData


enum IntegrityState {
	REGISTERED,
	PURIFIED,
	EXE,
	DEVIL,
	TURD,
	LOST
}

const ACTIVE_SLOT_COUNT: int = 4
const MAX_STABILITY: int = 100
const ALLOCATABLE_STATS: Array[String] = [
	"hp",
	"atk",
	"def",
	"matk",
	"mdef"
]

var apk_id: String = ""
var nickname: String = ""
var level: int = 1
var current_exp: int = 0
var current_hp: int = 1
var current_stability: int = MAX_STABILITY
var affinity: int = 0
var personality_id: String = ""
var address_term_id: String = ""
var active_module_ids: PackedStringArray = PackedStringArray()
var known_active_module_ids: PackedStringArray = PackedStringArray()
var secondary_passive_module_id: String = ""
var allocation_points: int = 0
var allocated_stats: Dictionary = {}
var growth_lineage: String = ""
var integrity_state: IntegrityState = IntegrityState.REGISTERED


func reset() -> void:
	apk_id = ""
	nickname = ""
	level = 1
	current_exp = 0
	current_hp = 1
	current_stability = MAX_STABILITY
	affinity = 0
	personality_id = ""
	address_term_id = ""
	active_module_ids.clear()
	known_active_module_ids.clear()
	secondary_passive_module_id = ""
	allocation_points = 0
	allocated_stats.clear()
	growth_lineage = ""
	integrity_state = IntegrityState.REGISTERED


func is_empty() -> bool:
	return apk_id.strip_edges().is_empty()


func duplicate_state() -> PartnerStateData:
	var copy := PartnerStateData.new()
	copy.load_save_data(to_save_data())
	return copy


func get_allocated_stat(stat_id: String) -> int:
	return maxi(0, int(allocated_stats.get(stat_id.strip_edges().to_lower(), 0)))


func get_total_allocated_points() -> int:
	var total: int = 0

	for stat_id: String in ALLOCATABLE_STATS:
		total += get_allocated_stat(stat_id)

	return total


func get_total_received_allocation_points() -> int:
	return maxi(0, level - 1)


func get_maximum_allocation_per_stat() -> int:
	return ceili(float(get_total_received_allocation_points()) / 2.0)


func validate_state() -> PackedStringArray:
	var errors := PackedStringArray()

	if apk_id.strip_edges().is_empty():
		errors.append("PartnerStateData has an empty apk_id.")

	if level < 1 or level > 100:
		errors.append("Partner level must be between 1 and 100.")

	if current_exp < 0:
		errors.append("Partner EXP cannot be negative.")

	if current_hp < 0:
		errors.append("Partner HP cannot be negative.")

	if current_stability < 0 or current_stability > MAX_STABILITY:
		errors.append("Partner Stability must remain between 0 and 100.")

	if personality_id.strip_edges().is_empty():
		errors.append("Partner personality_id cannot be empty.")

	if address_term_id.strip_edges().is_empty():
		errors.append("Partner address_term_id cannot be empty.")

	if active_module_ids.size() != ACTIVE_SLOT_COUNT:
		errors.append("Partner must equip exactly four active Modules.")

	for module_id: String in active_module_ids:
		if module_id.strip_edges().is_empty():
			errors.append("Partner has an empty active Module slot.")
		elif not known_active_module_ids.has(module_id):
			errors.append("Equipped Module '%s' is not known by the partner." % module_id)

	var received: int = get_total_received_allocation_points()
	var allocated: int = get_total_allocated_points()

	if allocation_points < 0 or allocation_points + allocated != received:
		errors.append("Partner allocation points do not match its level history.")

	var per_stat_limit: int = get_maximum_allocation_per_stat()

	for raw_stat: Variant in allocated_stats:
		var stat_id: String = str(raw_stat).strip_edges().to_lower()
		var amount: int = int(allocated_stats[raw_stat])

		if not ALLOCATABLE_STATS.has(stat_id):
			errors.append("Partner allocation contains unknown stat '%s'." % stat_id)
		elif amount < 0 or amount > per_stat_limit:
			errors.append("Partner allocation for '%s' exceeds its legal range." % stat_id)

	return errors


func to_save_data() -> Dictionary:
	return {
		"apk_id": apk_id,
		"nickname": nickname,
		"level": level,
		"current_exp": current_exp,
		"current_hp": current_hp,
		"current_stability": current_stability,
		"affinity": affinity,
		"personality_id": personality_id,
		"address_term_id": address_term_id,
		"active_module_ids": Array(active_module_ids),
		"known_active_module_ids": Array(known_active_module_ids),
		"secondary_passive_module_id": secondary_passive_module_id,
		"allocation_points": allocation_points,
		"allocated_stats": allocated_stats.duplicate(true),
		"growth_lineage": growth_lineage,
		"integrity_state": int(integrity_state)
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	apk_id = str(data.get("apk_id", "")).strip_edges()
	nickname = str(data.get("nickname", "")).strip_edges()
	level = clampi(int(data.get("level", 1)), 1, 100)
	current_exp = maxi(0, int(data.get("current_exp", 0)))
	current_hp = maxi(0, int(data.get("current_hp", 1)))
	current_stability = clampi(int(data.get("current_stability", 100)), 0, 100)
	affinity = int(data.get("affinity", 0))
	personality_id = str(data.get("personality_id", "")).strip_edges()
	address_term_id = str(data.get("address_term_id", "")).strip_edges()
	active_module_ids = _read_ids(data.get("active_module_ids", []), false)
	known_active_module_ids = _read_ids(data.get("known_active_module_ids", []), true)
	secondary_passive_module_id = str(data.get("secondary_passive_module_id", "")).strip_edges()
	allocation_points = maxi(0, int(data.get("allocation_points", 0)))
	allocated_stats = _read_allocations(data.get("allocated_stats", {}))
	growth_lineage = str(data.get("growth_lineage", "")).strip_edges()
	integrity_state = clampi(
		int(data.get("integrity_state", IntegrityState.REGISTERED)),
		IntegrityState.REGISTERED,
		IntegrityState.LOST
	)


func _read_ids(value: Variant, unique_only: bool) -> PackedStringArray:
	var result := PackedStringArray()

	if value is not Array and value is not PackedStringArray:
		return result

	for raw_id: Variant in value:
		var clean_id: String = str(raw_id).strip_edges()

		if clean_id.is_empty():
			continue

		if not unique_only or not result.has(clean_id):
			result.append(clean_id)

	return result


func _read_allocations(value: Variant) -> Dictionary:
	var result: Dictionary = {}

	if value is not Dictionary:
		return result

	for stat_id: String in ALLOCATABLE_STATS:
		var amount: int = maxi(0, int(value.get(stat_id, 0)))

		if amount > 0:
			result[stat_id] = amount

	return result
