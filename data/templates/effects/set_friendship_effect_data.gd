extends GameEffectData
class_name SetFriendshipEffectData


enum Operation {
	ADD,
	REMOVE
}

@export var npc_id: String = ""
@export var use_context_target_when_empty: bool = true
@export var operation: Operation = Operation.ADD


func _apply_effect(context: GameEffectContext) -> bool:
	var resolved_id: String = _resolve_npc_id(context)

	if resolved_id.is_empty():
		return false

	match operation:
		Operation.ADD:
			return SocialService.add_friend(
				resolved_id,
				context.to_condition_context()
			)
		Operation.REMOVE:
			return SocialService.remove_friend(resolved_id)

	return false


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()

	if npc_id.strip_edges().is_empty() and not use_context_target_when_empty:
		errors.append(
			"npc_id cannot be empty when context target fallback is disabled."
		)

	return errors


func _resolve_npc_id(context: GameEffectContext) -> String:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty() and use_context_target_when_empty and context != null:
		clean_id = context.target_id.strip_edges()

	return clean_id
