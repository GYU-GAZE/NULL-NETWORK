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
## Installs the app as soon as unlock_conditions becomes true. This keeps
## progression-driven app delivery in data instead of coupling domain systems
## such as APK progression or Encyclopedia to the desktop.
@export var auto_install_when_unlocked: bool = false
@export var unlock_conditions: ConditionSetData
@export_range(0, 100000, 1) var sort_order: int = 0
@export var installation_effects: Array[GameEffectData] = []
@export var notification_data: KubuNotificationData

@export_category("Dock")
@export var show_in_dock: bool = true
@export var available_while_locked: bool = false

@export_category("Window Settings")
## Intended outer window size in logical desktop units (1 unit = 2 screen pixels).
## Used directly, then fitted to the available work area; never proportional.
@export var default_window_size: Vector2 = Vector2(600, 400)

## Real minimum outer size in the same units, including chrome. When the display
## cannot fit it, the effective minimum is capped per axis to the work area.
## Content keeps its scale and uses the window's overflow scroll surface.
@export var min_window_size: Vector2 = Vector2(400, 250)

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

	if not default_window_size.is_finite() or default_window_size.x <= 0 or default_window_size.y <= 0:
		errors.append("default_window_size must contain positive finite logical dimensions.")
	if not min_window_size.is_finite() or min_window_size.x <= 0 or min_window_size.y <= 0:
		errors.append("min_window_size must contain positive finite logical dimensions.")
	if default_window_size.x < min_window_size.x or default_window_size.y < min_window_size.y:
		errors.append("default_window_size must be at least min_window_size.")

	if app_scene == null:
		errors.append("app_scene cannot be null.")

	if auto_install_when_unlocked and unlock_conditions == null:
		errors.append(
			"auto_install_when_unlocked requires unlock_conditions."
		)

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
