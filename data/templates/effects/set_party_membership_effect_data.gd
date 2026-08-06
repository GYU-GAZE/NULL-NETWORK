extends GameEffectData
class_name SetPartyMembershipEffectData


enum Operation {
	JOIN,
	LEAVE
}

@export var npc_id: String = ""
@export var use_context_target_when_empty: bool = true
@export var owner_id: String = ""
@export var use_context_source_when_owner_empty: bool = true
@export var operation: Operation = Operation.JOIN


func _apply_effect(context: GameEffectContext) -> bool:
	var resolved_npc_id: String = _resolve_npc_id(context)
	var resolved_owner_id: String = _resolve_owner_id(context)

	if resolved_npc_id.is_empty():
		return false

	var membership: Dictionary = SocialService.get_party_membership(
		resolved_npc_id
	)

	match operation:
		Operation.JOIN:
			if resolved_owner_id.is_empty():
				return false

			if not membership.is_empty():
				return str(membership.get("owner_id", "")) \
					== resolved_owner_id

			return SocialService.add_party_member(
				resolved_npc_id,
				resolved_owner_id
			)

		Operation.LEAVE:
			# Cleanup Effects are replay-safe. An already absent member means the
			# requested final state has already been reached.
			if membership.is_empty():
				return true

			if not resolved_owner_id.is_empty() \
				and str(membership.get("owner_id", "")) \
				!= resolved_owner_id:
				return false

			return SocialService.remove_party_member(
				resolved_npc_id,
				resolved_owner_id
			)

	return false


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()

	if npc_id.strip_edges().is_empty() and not use_context_target_when_empty:
		errors.append(
			"npc_id cannot be empty when context target fallback is disabled."
		)

	if operation == Operation.JOIN \
		and owner_id.strip_edges().is_empty() \
		and not use_context_source_when_owner_empty:
		errors.append(
			"JOIN requires owner_id or context source fallback."
		)

	return errors


func _resolve_npc_id(context: GameEffectContext) -> String:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty() and use_context_target_when_empty and context != null:
		clean_id = context.target_id.strip_edges()

	return clean_id


func _resolve_owner_id(context: GameEffectContext) -> String:
	var clean_id: String = owner_id.strip_edges()

	if clean_id.is_empty() \
		and use_context_source_when_owner_empty \
		and context != null:
		clean_id = context.source_id.strip_edges()

	return clean_id
