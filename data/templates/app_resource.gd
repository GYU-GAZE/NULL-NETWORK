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

@export_category("Dock")
@export var show_in_dock: bool = true
@export var available_while_locked: bool = false

@export_category("Window Presentation")
@export var window_profile: WindowPresentationProfile

@export_category("Legacy Window Settings")
## Mantidos para Resources antigos. Novos apps devem usar window_profile.
@export var default_window_size: Vector2 = Vector2(900, 600)
@export var min_window_size: Vector2 = Vector2(400, 300)
@export var can_resize: bool = false


func resolve_window_profile() -> WindowPresentationProfile:
	if window_profile != null:
		return window_profile

	var legacy_profile := WindowPresentationProfile.new()
	legacy_profile.compact_size = min_window_size
	legacy_profile.preferred_size = default_window_size
	legacy_profile.minimum_custom_size = min_window_size
	legacy_profile.allow_compact = false
	legacy_profile.allow_preferred = true
	legacy_profile.allow_maximized = can_resize
	legacy_profile.allow_manual_resize = can_resize
	legacy_profile.initial_presentation = WindowPresentationProfile.InitialPresentation.PREFERRED
	return legacy_profile
