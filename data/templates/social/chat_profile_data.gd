extends Resource
class_name ChatProfileData


@export_category("Identity")
@export var profile_id: String = ""
@export var npc_id: String = ""
@export var display_name_override: String = ""
@export var subtitle: String = ""
@export var avatar_override: Texture2D

@export_category("Presentation")
@export var pinned: bool = false
@export var sort_order: int = 0
@export var visibility_conditions: ConditionSetData


func get_display_id() -> String:
	return profile_id.strip_edges()


func get_npc_id() -> String:
	return npc_id.strip_edges()


func get_display_name(npc: NPCData) -> String:
	var override_name: String = display_name_override.strip_edges()

	if not override_name.is_empty():
		return override_name

	if npc != null:
		return npc.get_display_name()

	return get_npc_id()


func get_avatar(npc: NPCData) -> Texture2D:
	if avatar_override != null:
		return avatar_override

	if npc == null:
		return null

	if npc.network_user != null and npc.network_user.avatar != null:
		return npc.network_user.avatar

	return npc.portrait


func is_visible(context: Dictionary = {}) -> bool:
	return visibility_conditions == null \
		or visibility_conditions.is_met(context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("profile_id cannot be empty.")

	if get_npc_id().is_empty():
		errors.append("npc_id cannot be empty.")

	if visibility_conditions != null:
		for error: String in visibility_conditions.validate_data():
			errors.append("Visibility condition: %s" % error)

	return errors
