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

@export_category("Window Settings")
@export var default_window_size: Vector2 = Vector2(900, 600)

## Limite onde a janela deixa de renderizar em 2x e passa para 1x.
## Não bloqueia mais o resize; o limite rígido pertence à WindowBase.
@export var min_window_size: Vector2 = Vector2(400, 300)

@export var can_resize: bool = false
