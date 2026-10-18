@tool
extends Resource
class_name SpawnTable

enum RefreshPolicy { PERIOD, DAY, ACTION_BLOCK, CAMPAIGN }
@export var refresh_policy: RefreshPolicy = RefreshPolicy.PERIOD
@export var table_id: String = ""
@export_range(0, 16, 1, "or_greater")
var rolls_per_population: int = 1
@export var entries: Array[SpawnEntry] = []
## Lookup-only migration content; never rolled as ambient population.
@export var retired_entries: Array[SpawnEntry] = []
@export var field_population: FieldPopulationData


func get_display_id() -> String:
	return table_id.strip_edges()


func get_entry(spawn_id: String) -> SpawnEntry:
	var clean_id: String = spawn_id.strip_edges()

	for entry: SpawnEntry in entries + retired_entries:
		if entry != null and entry.get_display_id() == clean_id:
			return entry

	return null


func get_available_entries(context: Dictionary = {}) -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []

	for entry: SpawnEntry in entries:
		if entry != null \
			and (entry.encounter != null or entry.environmental_apk != null) \
			and entry.weight > 0 \
			and entry.is_available(context):
			result.append(entry)

	return result


func roll_entries(
	seed_value: int,
	context: Dictionary = {}
) -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []
	var available: Array[SpawnEntry] = get_available_entries(context)
	var desired := rolls_per_population
	if field_population != null:
		if field_population.conditions != null and not field_population.conditions.is_met(context):
			return result
		desired = clampi(desired, field_population.minimum_units, field_population.maximum_units)
		for id: String in field_population.guaranteed_spawn_ids:
			var entry := get_entry(id)
			if entry != null and entry in available and result.size() < desired:
				result.append(entry)

	if available.is_empty() or rolls_per_population <= 0:
		return result

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	for _roll_index: int in range(maxi(0, desired - result.size())):
		var selected: SpawnEntry = _roll_one(available, rng)

		if selected != null:
			result.append(selected)

	return result


func roll_encounter() -> CombatEncounter:
	var rolled: Array[SpawnEntry] = roll_entries(randi())

	if rolled.is_empty():
		return null

	return rolled[0].encounter


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if field_population != null:
		errors.append_array(field_population.validate_data())
		for id: String in field_population.guaranteed_spawn_ids:
			if get_entry(id) == null:
				errors.append("Guaranteed field spawn ID is not in this table: " + id)
	var spawn_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("table_id cannot be empty.")

	var all_entries: Array[SpawnEntry] = entries + retired_entries
	for index: int in range(all_entries.size()):
		var entry: SpawnEntry = all_entries[index]

		if entry == null:
			errors.append("Entry %d is null." % index)
			continue

		var spawn_id: String = entry.get_display_id()

		if spawn_ids.has(spawn_id):
			errors.append("Duplicate spawn_id '%s'." % spawn_id)
		else:
			spawn_ids[spawn_id] = true

		for error: String in entry.validate_data():
			errors.append("Entry %d: %s" % [index, error])

	return errors


func _roll_one(
	available: Array[SpawnEntry],
	rng: RandomNumberGenerator
) -> SpawnEntry:
	var total_weight: int = 0

	for entry: SpawnEntry in available:
		total_weight += entry.weight

	if total_weight <= 0:
		return null

	var roll: int = rng.randi_range(1, total_weight)

	for entry: SpawnEntry in available:
		roll -= entry.weight

		if roll <= 0:
			return entry

	return available[available.size() - 1]
