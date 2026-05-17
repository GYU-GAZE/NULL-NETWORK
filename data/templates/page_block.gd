extends Resource
class_name PageBlock

enum BlockType {
	ROW,
	COLUMN,
	TEXT,
	IMAGE,
	BUTTON,
	SPACING
}

enum ButtonAction {
	NONE,
	NAVIGATE,
	SET_FLAG,
	TOGGLE_FLAG
}

@export var type: BlockType = BlockType.TEXT

@export_group("Layout")
@export var child_blocks: Array[PageBlock] = []

@export_group("Conteúdo")
@export_multiline var text_content: String = ""
@export var image_content: Texture2D
@export var spacing_size: int = 16

@export_group("Botão")
@export var button_action: ButtonAction = ButtonAction.NONE
@export var target_url: String = ""
@export var story_flag: String = ""
@export var flag_value: bool = true