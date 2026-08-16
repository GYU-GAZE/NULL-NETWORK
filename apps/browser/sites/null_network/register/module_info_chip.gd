extends PanelContainer
class_name ModuleInfoChip

signal tooltip_requested(text: String)
signal tooltip_hidden

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %Name

var module_data: ModuleData

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(module: ModuleData) -> void:
	module_data = module
	name_label.text = module.module_name if module != null else "DATA PENDING"
	icon_rect.texture = module.module_icon if module != null else null
	tooltip_text = ModuleDescriptionService.build_tooltip(module) if module != null else "Module content is not registered yet."

func _on_mouse_entered() -> void:
	if module_data != null:
		tooltip_requested.emit(ModuleDescriptionService.build_tooltip(module_data))

func _on_mouse_exited() -> void:
	tooltip_hidden.emit()
