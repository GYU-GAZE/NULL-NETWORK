# res://apps/browser/components/page_block_ui.gd
extends Control

func setup(block: PageBlock):
	match block.type:
		PageBlock.BlockType.TEXT:
			$Label.text = block.text_content
			$Button.hide()
		PageBlock.BlockType.BUTTON:
			$Button.text = block.text_content
			$Button.show()
			$Button.pressed.connect(func(): _on_click(block))

func _on_click(block: PageBlock):
	# Se tiver URL, navega
	if block.target_url != "":
		GlobalSignals.emit_signal("browser_navigate_requested", block.target_url)
	
	# Se tiver flag, altera no jogo (RPG mode on)
	if block.story_flag != "":
		# Aqui você chama o seu Singleton de status (ex: GameState ou GlobalSignals)
		GlobalSignals.emit_signal("flag_changed", block.story_flag, block.flag_value)