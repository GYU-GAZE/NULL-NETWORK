extends Resource
class_name GlobalTextCatalog


enum TextCategory {
	BUTTONS,
	LABELS,
	ERRORS,
	CONFIRMATIONS,
	MENUS,
	MESSAGES,
	TABS
}

const DEFAULT_CATALOG_PATH: String = (
	"res://data/content/text/global_text_catalog.tres"
)

static var _default_catalog: Resource

@export var buttons: Dictionary = {}
@export var labels: Dictionary = {}
@export var errors: Dictionary = {}
@export var confirmations: Dictionary = {}
@export var menus: Dictionary = {}
@export var messages: Dictionary = {}
@export var tabs: Dictionary = {}


func get_text(
	category: TextCategory,
	text_id: String,
	fallback: String = ""
) -> String:
	var clean_id: String = text_id.strip_edges()

	if clean_id.is_empty():
		return fallback

	var category_entries: Dictionary = _get_category_entries(category)
	var value: Variant = category_entries.get(clean_id, fallback)
	return str(value)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	for category_info: Dictionary in _get_category_definitions():
		var category_name: String = str(category_info["name"])
		var entries: Dictionary = category_info["entries"]

		for raw_key: Variant in entries.keys():
			var key: String = str(raw_key).strip_edges()
			var value: Variant = entries[raw_key]

			if key.is_empty():
				errors.append("%s contains an empty text ID." % category_name)
			elif value is not String:
				errors.append(
					"%s.%s must contain a String value."
					% [category_name, key]
				)

	return errors


static func get_default() -> GlobalTextCatalog:
	if _default_catalog == null:
		_default_catalog = load(DEFAULT_CATALOG_PATH)

	return _default_catalog as GlobalTextCatalog


static func get_default_text(
	category: TextCategory,
	text_id: String,
	fallback: String = ""
) -> String:
	var catalog: GlobalTextCatalog = get_default()

	if catalog == null:
		return fallback

	return catalog.get_text(category, text_id, fallback)


func _get_category_entries(category: TextCategory) -> Dictionary:
	match category:
		TextCategory.BUTTONS:
			return buttons
		TextCategory.LABELS:
			return labels
		TextCategory.ERRORS:
			return errors
		TextCategory.CONFIRMATIONS:
			return confirmations
		TextCategory.MENUS:
			return menus
		TextCategory.MESSAGES:
			return messages
		TextCategory.TABS:
			return tabs

	return {}


func _get_category_definitions() -> Array[Dictionary]:
	return [
		{"name": "buttons", "entries": buttons},
		{"name": "labels", "entries": labels},
		{"name": "errors", "entries": errors},
		{"name": "confirmations", "entries": confirmations},
		{"name": "menus", "entries": menus},
		{"name": "messages", "entries": messages},
		{"name": "tabs", "entries": tabs}
	]
