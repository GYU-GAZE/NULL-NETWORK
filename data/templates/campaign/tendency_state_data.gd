extends Resource
class_name TendencyStateData


enum Tendency {
	VALOUR,
	LOGIC,
	SYNC,
	SELF
}


var valour: int = 0
var logic: int = 0
var sync: int = 0
var self: int = 0


func reset() -> void:
	valour = 0
	logic = 0
	sync = 0
	self = 0


func get_value(tendency: Tendency) -> int:
	match tendency:
		Tendency.VALOUR:
			return valour
		Tendency.LOGIC:
			return logic
		Tendency.SYNC:
			return sync
		Tendency.SELF:
			return self

	return 0


func set_value(tendency: Tendency, value: int) -> void:
	var safe_value: int = maxi(0, value)

	match tendency:
		Tendency.VALOUR:
			valour = safe_value
		Tendency.LOGIC:
			logic = safe_value
		Tendency.SYNC:
			sync = safe_value
		Tendency.SELF:
			self = safe_value


func add_value(tendency: Tendency, amount: int) -> int:
	set_value(tendency, get_value(tendency) + amount)
	return get_value(tendency)


func get_total() -> int:
	return valour + logic + sync + self


func to_save_data() -> Dictionary:
	return {
		"valour": valour,
		"logic": logic,
		"sync": sync,
		"self": self
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	valour = maxi(0, int(data.get("valour", 0)))
	logic = maxi(0, int(data.get("logic", 0)))
	sync = maxi(0, int(data.get("sync", 0)))
	self = maxi(0, int(data.get("self", 0)))
