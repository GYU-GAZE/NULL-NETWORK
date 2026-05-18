extends Resource
class_name AppResource

@export_category("App Identification")
@export var app_id: String = ""
@export var app_name: String = "App Desconhecido"

@export_category("App Visuals")
@export var app_icon: Texture2D

@export_category("App Content")
@export var app_scene: PackedScene

@export_category("Window Settings")
@export var default_window_size: Vector2 = Vector2(900, 600)
@export var min_window_size: Vector2 = Vector2(400, 300)
@export var can_resize: bool = false