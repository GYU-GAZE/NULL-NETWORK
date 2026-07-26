extends RefCounted
class_name CombatRuntimeSlot


enum SlotKind {
	POSITION,
	ACTION
}


var slot_id: StringName = &""
var slot_kind: SlotKind = SlotKind.POSITION
var is_ally: bool = true
var logical_index: int = 0
var order_index: int = 0
var enabled: bool = true
var is_dynamic: bool = false


static func create(
	id: StringName,
	kind: SlotKind,
	ally_slot: bool,
	index: int,
	order: int,
	dynamic: bool = false
) -> CombatRuntimeSlot:
	var slot := CombatRuntimeSlot.new()
	slot.slot_id = id
	slot.slot_kind = kind
	slot.is_ally = ally_slot
	slot.logical_index = index
	slot.order_index = order
	slot.is_dynamic = dynamic
	return slot


func describe() -> String:
	var team_name := "ally" if is_ally else "enemy"
	var kind_name := (
		"position"
		if slot_kind == SlotKind.POSITION
		else "action"
	)
	return "%s %s %d" % [
		team_name,
		kind_name,
		logical_index + 1
	]
