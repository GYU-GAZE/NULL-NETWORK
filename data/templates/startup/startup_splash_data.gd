@tool
extends Resource
class_name StartupSplashData


@export_category("Identity")
@export var splash_id: StringName = &"startup_splash"
@export var fallback_text: String = ""
@export var logo_texture: Texture2D

@export_category("Presentation")
@export var background_color: Color = Color.BLACK
@export_range(0.01, 2.0, 0.01) var fade_in_seconds: float = 0.14
@export_range(0.0, 3.0, 0.01) var hold_seconds: float = 0.65
@export_range(0.01, 2.0, 0.01) var fade_out_seconds: float = 0.14
@export var logo_minimum_size: Vector2 = Vector2(360.0, 180.0)
