extends Node

signal changelog_changed
signal unread_state_changed(has_unread: bool)

const DATABASE_PATH: String = "res://data/content/updates/changelog_database.tres"

var database: ChangelogDatabase


func _ready() -> void:
	reload_database()
	_prime_existing_entries_as_notified()

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	if not GameState.game_state_changed.is_connected(_on_game_state_changed):
		GameState.game_state_changed.connect(_on_game_state_changed)


func reload_database() -> void:
	var resource: Resource = ResourceLoader.load(DATABASE_PATH)

	if resource is ChangelogDatabase:
		database = resource as ChangelogDatabase
	else:
		database = null
		push_warning("ChangelogManager: database não encontrado ou inválido em %s" % DATABASE_PATH)


func get_visible_entries() -> Array[ChangelogEntryData]:
	if database == null:
		return []

	return database.get_visible_entries()


func get_visibility_signature() -> String:
	if database == null:
		return ""

	return database.get_visibility_signature()


func has_unread_updates() -> bool:
	var signature: String = get_visibility_signature()

	if signature.is_empty():
		return false

	return not GameState.has_read_changelog_signature(signature)


func mark_visible_updates_as_read() -> void:
	GameState.mark_changelog_as_read(get_visibility_signature())
	unread_state_changed.emit(has_unread_updates())


func refresh() -> void:
	_notify_new_visible_entries()
	changelog_changed.emit()
	unread_state_changed.emit(has_unread_updates())


func _on_time_advanced(_period: int, _days_passed: int, _cal_day: int, _cal_month: String) -> void:
	refresh()


func _on_game_state_changed() -> void:
	refresh()


func _prime_existing_entries_as_notified() -> void:
	if database == null:
		return

	var visible_entries: Array[ChangelogEntryData] = get_visible_entries()

	for i in range(visible_entries.size()):
		var entry: ChangelogEntryData = visible_entries[i]

		if entry == null:
			continue

		GameState.mark_changelog_entry_as_notified(entry.get_notification_key(i))


func _notify_new_visible_entries() -> void:
	if database == null:
		return

	var visible_entries: Array[ChangelogEntryData] = get_visible_entries()

	for i in range(visible_entries.size()):
		var entry: ChangelogEntryData = visible_entries[i]

		if entry == null:
			continue

		if not entry.should_notify:
			continue

		var notification_key: String = entry.get_notification_key(i)

		if GameState.was_changelog_entry_notified(notification_key):
			continue

		GameState.mark_changelog_entry_as_notified(notification_key)

		UniversalNotifications.push(
			entry.get_notification_title(),
			entry.get_notification_message()
		)
