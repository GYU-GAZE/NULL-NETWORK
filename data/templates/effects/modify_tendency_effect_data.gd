extends GameEffectData
class_name ModifyTendencyEffectData


enum Operation {
	ADD,
	SET
}

@export var tendency: TendencyStateData.Tendency = TendencyStateData.Tendency.VALOUR
@export var operation: Operation = Operation.ADD
@export var value: int = 0


func _apply_effect(_context: GameEffectContext) -> bool:
	match operation:
		Operation.ADD:
			CampaignState.modify_tendency(tendency, value)
		Operation.SET:
			CampaignState.set_tendency(tendency, value)
	return true
