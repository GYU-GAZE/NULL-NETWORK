extends Resource
class_name NPCPersonalityData


@export_category("Identity")
@export var personality_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_category("Interaction Vocabulary")
@export var interaction_tags: PackedStringArray = PackedStringArray()


func get_display_id() -> String:
	return personality_id.strip_edges()


func get_display_name() -> String:
	var clean_name: String = display_name.strip_edges()

	if not clean_name.is_empty():
		return clean_name

	return get_display_id()


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_tags: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("personality_id cannot be empty.")

	if get_display_name().is_empty():
		errors.append("display_name cannot be empty.")

	for raw_tag: String in interaction_tags:
		var tag: String = raw_tag.strip_edges()

		if tag.is_empty():
			errors.append("interaction_tags cannot contain an empty tag.")
		elif seen_tags.has(tag):
			errors.append("Duplicate interaction tag '%s'." % tag)
		else:
			seen_tags[tag] = true

	return errors
