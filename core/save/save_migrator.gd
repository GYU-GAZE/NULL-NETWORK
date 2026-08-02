extends RefCounted
class_name SaveMigrator


func migrate_document(document: Dictionary) -> Dictionary:
	var source: Dictionary = document.duplicate(true)
	var source_version: int = int(source.get("save_version", -1))

	if source_version < SaveConstants.MIN_SUPPORTED_SAVE_VERSION:
		return {
			"ok": false,
			"errors": PackedStringArray([
				"Save version %d is older than the minimum supported version %d."
				% [
					source_version,
					SaveConstants.MIN_SUPPORTED_SAVE_VERSION
				]
			])
		}

	if source_version > SaveConstants.SAVE_VERSION:
		return {
			"ok": false,
			"errors": PackedStringArray([
				"Save version %d is newer than the supported version %d."
				% [source_version, SaveConstants.SAVE_VERSION]
			])
		}

	while source_version < SaveConstants.SAVE_VERSION:
		var migration_result: Dictionary = _migrate_one_version(
			source,
			source_version
		)

		if not bool(migration_result.get("ok", false)):
			return migration_result

		source = migration_result.get("document", {})
		source_version = int(source.get("save_version", -1))

	return {
		"ok": true,
		"document": source,
		"errors": PackedStringArray()
	}


func _migrate_one_version(
	_document: Dictionary,
	version: int
) -> Dictionary:
	return {
		"ok": false,
		"errors": PackedStringArray([
			"No migration is registered from save version %d." % version
		])
	}
