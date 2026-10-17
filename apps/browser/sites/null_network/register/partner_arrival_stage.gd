extends VBoxContainer
class_name PartnerArrivalStage


@export var materialize_accent_a: Color = Color(0.14, 0.78, 1.0, 1.0)
@export var materialize_accent_b: Color = Color(0.68, 0.34, 1.0, 1.0)

@onready var status_label: Label = %StatusLabel
@onready var visual: Control = %ArrivalVisual
@onready var particle_field: Control = %ParticleField
@onready var sprite: TextureRect = %ArrivalSprite
@onready var name_label: Label = %NameLabel
@onready var comment_label: RichTextLabel = %CommentLabel
@onready var pixel_materializer: PixelMaterializer = %PixelMaterializer
@onready var typewriter: TypewriterReveal = %TypewriterReveal


func prepare(partner_name: String) -> void:
	show()
	status_label.text = "SYNCHRONIZING PARTNER INSTANCE..."
	status_label.show()
	status_label.modulate = Color.WHITE
	sprite.texture = null
	sprite.modulate.a = 0.0
	name_label.text = partner_name if not partner_name.strip_edges().is_empty() else "PARTNER"
	name_label.hide()
	comment_label.text = ""
	comment_label.hide()


func set_status(text: String) -> void:
	status_label.text = text


func reveal_name() -> void:
	name_label.show()


func show_comment() -> void:
	comment_label.show()


func play_comment(text: String) -> void:
	comment_label.show()
	typewriter.play(comment_label, text)


func materialize(texture: Texture2D) -> void:
	_layout_sprite(texture)
	await pixel_materializer.materialize(
		texture,
		sprite,
		particle_field,
		materialize_accent_a,
		materialize_accent_b
	)


func _layout_sprite(texture: Texture2D) -> void:
	if texture == null:
		sprite.texture = null
		sprite.size = Vector2(64, 64)
		sprite.position = KubuOSMetrics.snap_vector(
			(visual.size - sprite.size) * 0.5
		)
		return

	var source_size := texture.get_size()
	var largest_dimension := maxf(source_size.x, source_size.y)
	var integer_scale := 1
	if largest_dimension > 0.0:
		integer_scale = clampi(floori(96.0 / largest_dimension), 1, 4)
	sprite.size = KubuOSMetrics.snap_vector(
		source_size * float(integer_scale)
	)
	sprite.position = KubuOSMetrics.snap_vector(
		(visual.size - sprite.size) * 0.5
	)
