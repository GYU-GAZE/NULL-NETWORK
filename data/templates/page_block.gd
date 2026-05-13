# data/templates/page_block.gd
extends Resource
class_name PageBlock

enum BlockType { TEXT, IMAGE, BUTTON, SPACING }

@export var type: BlockType = BlockType.TEXT

@export_group("Conteúdo")
@export_multiline var text_content: String
@export var image_content: Texture2D

@export_group("Ações de Botão")
@export var target_url: String = "" # Se for para navegar
@export var story_flag: String = ""  # Nome da variável bool (ex: "aceitou_termos")
@export var flag_value: bool = true  # Vai para true ou false?