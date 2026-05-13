extends PanelContainer
class_name ForumPostUI

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var username_label: Label = %UsernameLabel
@onready var title_label: Label = %TitleLabel
@onready var location_label: Label = %LocationLabel

@onready var text_content: RichTextLabel = %TextContent
@onready var image_content: TextureRect = %ImageContent

func setup(data: ForumPost) -> void:
	# Perfil
	if data.avatar:
		avatar_rect.texture = data.avatar
	username_label.text = data.username
	title_label.text = data.user_title
	location_label.text = data.location
	
	# Conteúdo
	text_content.text = data.text_content
	
	# Lógica da imagem opcional
	if data.image_content:
		image_content.texture = data.image_content
		image_content.show()
	else:
		image_content.hide()
