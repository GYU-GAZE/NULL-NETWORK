extends PanelContainer
class_name ForumPostUI

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var username_label: Label = %UsernameLabel
@onready var title_label: Label = %TitleLabel
@onready var location_label: Label = %LocationLabel

@onready var text_content: RichTextLabel = %TextContent
@onready var image_content: TextureRect = %ImageContent

signal link_clicked(url: String)

func setup(data: ForumPost) -> void:
	# Perfil
	if data.avatar:
		avatar_rect.texture = data.avatar
	username_label.text = data.username
	title_label.text = data.user_title
	location_label.text = data.location
	
	# Conteúdo
	text_content.text = data.text_content
	text_content.bbcode_enabled = true
	if not text_content.meta_clicked.is_connected(_on_meta_clicked):
		text_content.meta_clicked.connect(_on_meta_clicked)
	
	# Lógica da imagem opcional
	if data.image_content:
		image_content.texture = data.image_content
		image_content.show()
	else:
		image_content.hide()

func _on_meta_clicked(meta: Variant) -> void:
	var target_url := str(meta)

	if target_url.is_empty():
		return

	link_clicked.emit(target_url)
