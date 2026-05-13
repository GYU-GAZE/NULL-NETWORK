extends Resource
class_name PageBlock

@export_enum("Text", "Image", "Row", "Column") var block_type: String = "Text"

@export_category("Content")
@export_multiline var text_content: String = ""
@export var image_content: Texture2D

@export_category("Children")
# Aqui mora a recursividade! Blocos dentro de blocos.
@export var child_blocks: Array[PageBlock] = []
