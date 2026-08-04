extends Resource
class_name SpawnTable

@export var table_id: String = ""
@export_range(0, 16, 1, "or_greater")
var rolls_per_population: int = 1
@export var entries: Array[SpawnEntry] = []


func get_display_id() -> String:
	return table_id.strip_edges()


func get_entry(spawn_id: String) -> SpawnEntry:
	var clean_id: String = spawn_id.strip_edges()

	for entry: SpawnEntry in entries:
		if entry != null and entry.get_display_id() == clean_id:
			return entry

	return null


func get_available_entries(context: Dictionary = {}) -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []

	for entry: SpawnEntry in entries:
		if entry != null \
			and entry.encounter != null \
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

	if available.is_empty() or rolls_per_population <= 0:
		return result

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	for _roll_index: int in range(rolls_per_population):
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
	var spawn_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("table_id cannot be empty.")

	for index: int in range(entries.size()):
		var entry: SpawnEntry = entries[index]

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
