extends SubViewportContainer
class_name ProfilePartnerStage


@export_range(0.0, 8.0, 0.1) var idle_bob_height: float = 3.0
@export_range(0.1, 8.0, 0.1) var idle_bob_speed: float = 1.8

@onready var stage_root: Control = %StageRoot
@onready var partner_sprite: TextureRect = %PartnerSprite
@onready var partner_name: Label = %StagePartnerName
@onready var form_label: Label = %StageFormLabel
@onready var empty_label: Label = %EmptyLabel


var _elapsed: float = 0.0
var _sprite_base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_sprite_base_position = partner_sprite.position
	set_process(true)


func present(partner_data: Dictionary) -> void:
	var has_partner: bool = not partner_data.is_empty()
	stage_root.visible = true
	partner_sprite.visible = has_partner
	partner_name.visible = has_partner
	form_label.visible = has_partner
	empty_label.visible = not has_partner

	if not has_partner:
		partner_sprite.texture = null
		partner_name.text = ""
		form_label.text = ""
		return

	partner_sprite.texture = partner_data.get("portrait") as Texture2D
	partner_name.text = str(partner_data.get("nickname", "PARTNER"))
	form_label.text = "%s // %s" % [
		str(partner_data.get("form_name", "UNKNOWN")),
		str(partner_data.get("integrity_name", "UNKNOWN"))
	]


func _process(delta: float) -> void:
	if not partner_sprite.visible:
		return

	_elapsed += delta
	partner_sprite.position = _sprite_base_position + Vector2(
		0.0,
		sin(_elapsed * idle_bob_speed) * idle_bob_height
	)
