extends Resource
class_name AppResource


enum PresentationMode {
	WINDOW,
	WORKSPACE
}

@export_category("App Identification")
@export var app_id: String = ""
@export var app_name: String = "App Desconhecido"

@export_category("App Visuals")
@export var app_icon: Texture2D

@export_category("App Content")
@export var app_scene: PackedScene
@export var presentation_mode: PresentationMode = PresentationMode.WINDOW

@export_category("Installation")
@export var installed_by_default: bool = false
@export var unlock_conditions: ConditionSetData
@export_range(0, 100000, 1) var sort_order: int = 0
@export var installation_effects: Array[GameEffectData] = []
@export var notification_data: KubuNotificationData

@export_category("Dock")
@export var show_in_dock: bool = true
@export var available_while_locked: bool = false

@export_category("Window Settings")
@export var default_window_size: Vector2 = Vector2(900, 600)

## Breakpoint da janela adaptativa.
## Em 2x enquanto largura e altura forem iguais ou maiores que este valor;
## em 1x quando qualquer eixo ficar abaixo dele.
@export var min_window_size: Vector2 = Vector2(400, 300)

@export var can_resize: bool = false


func can_install(context: GameEffectContext = null) -> bool:
	if unlock_conditions == null:
		return true

	var condition_context: Dictionary = {}

	if context != null:
		condition_context = context.to_condition_context()

	return unlock_conditions.is_met(condition_context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if app_id.strip_edges().is_empty():
		errors.append("app_id cannot be empty.")

	if app_name.strip_edges().is_empty():
		errors.append("app_name cannot be empty.")

	if app_scene == null:
		errors.append("app_scene cannot be null.")

	if unlock_conditions != null:
		for error: String in unlock_conditions.validate_data():
			errors.append("Unlock condition: %s" % error)

	for index: int in range(installation_effects.size()):
		var effect: GameEffectData = installation_effects[index]

		if effect == null:
			errors.append("Installation effect %d is null." % index)
			continue

		for error: String in effect.validate_data():
			errors.append("Installation effect %d: %s" % [index, error])

	return errors
