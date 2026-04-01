extends PanelContainer
class_name ModuleSlotUI

var slot_index: int = -1
var current_module: ModuleData
var is_equipped_slot: bool = false

@onready var label: Label = Label.new()

func _ready() -> void:
	custom_minimum_size = Vector2(100, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(label)
	
	# JUNTAMOS AQUI: Os sinais de hover do Tooltip nativo!
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)

func setup(module: ModuleData, index: int, is_equipped: bool) -> void:
	current_module = module
	slot_index = index
	is_equipped_slot = is_equipped
	
	if module:
		label.text = module.module_name
	else:
		label.text = "VAZIO"

# ==========================================
# DRAG & DROP NATIVO
# ==========================================
func _get_drag_data(at_position: Vector2) -> Variant:
	if current_module == null: return null
	
	var preview = Label.new()
	preview.text = " " + current_module.module_name + " "
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.add_child(bg)
	preview.move_child(bg, 0)
	
	set_drag_preview(preview)
	return {"source_slot": self, "module": current_module}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("module")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var source: ModuleSlotUI = data["source_slot"]
	var dragged_mod: ModuleData = data["module"]
	
	var player_modules = CombatManager.ally_team[0].modules
	
	if is_equipped_slot:
		if source.is_equipped_slot:
			player_modules[source.slot_index] = self.current_module
		player_modules[self.slot_index] = dragged_mod
	elif source.is_equipped_slot and not self.is_equipped_slot:
		player_modules[source.slot_index] = null
	
	CombatManager._build_timeline() 
	get_tree().call_group("CombatUI", "refresh_module_ui")

# ==========================================
# O NOVO TOOLTIP INSTANTÂNEO
# ==========================================
func _on_hover_in() -> void:
	if current_module:
		var txt = "[%s]\n%s\nPower: %d | Custo: %d STB" % [current_module.module_name, current_module.description, current_module.power, current_module.stability_cost]
		get_tree().call_group("CombatUI", "show_tooltip", txt)

func _on_hover_out() -> void:
	get_tree().call_group("CombatUI", "hide_tooltip")
