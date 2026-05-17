extends Control
class_name BrowserApp

@onready var url_line_edit: LineEdit = %UrlLineEdit
@onready var go_button: Button = %GoButton
@onready var browser_back_btn: Button = %BrowserBackBtn

var url_history: Array[String] = []

@onready var normal_site_scroll: ScrollContainer = %NormalSiteScroll
@onready var normal_site_content: VBoxContainer = %NormalSiteContent

@onready var custom_site_container: MarginContainer = %CustomSiteContainer

func _ready() -> void:
	# Conecta os sinais de UI (apertar Enter ou clicar em Ir)
	go_button.pressed.connect(_on_go_pressed)
	url_line_edit.text_submitted.connect(_load_page)
	
	browser_back_btn.pressed.connect(_on_browser_back_pressed)

func _on_go_pressed() -> void:
	_load_page(url_line_edit.text)

func _load_page(target_url: String, is_history_nav: bool = false) -> void:
	url_line_edit.text = target_url 
	
	# Salva no histórico se for uma navegação nova
	if not is_history_nav:
		# Só adiciona se o histórico estiver vazio ou se a última URL for diferente desta
		if url_history.is_empty() or url_history.back() != target_url:
			url_history.push_back(target_url)
	
	_clear_containers()
	var page: WebsitePage = SimulatedDNS.fetch_page(target_url)
	
	if page == null:
		_render_403_error()
		return
		
	if page.custom_site_scene != null:
		_render_custom_site(page.custom_site_scene)
	else:
		_render_normal_site(page)

# ==========================================
# A MÁGICA DO BOTÃO VOLTAR
# ==========================================
func _on_browser_back_pressed() -> void:
	# 1. Tenta delegar a ação para o Site Customizado (O Fórum)
	if custom_site_container.get_child_count() > 0:
		var current_app = custom_site_container.get_child(0)
		
		# Duck Typing: "Se o app tiver essa função, execute-a"
		if current_app.has_method("handle_browser_back"):
			var handled_by_app: bool = current_app.handle_browser_back()
			if handled_by_app == true:
				return # O Fórum fechou a thread. O Browser encerra o trabalho aqui!

	# 2. Se não tem app, ou se o app disse 'false', navegamos na URL
	if url_history.size() > 1:
		url_history.pop_back() # Remove a página atual do topo do histórico
		var previous_url: String = url_history.back() # Pega a anterior
		_load_page(previous_url, true) # Carrega passando true para não bugar o histórico
	else:
		print("Histórico vazio, não há para onde voltar.")
# ==========================================
# ROTINAS DE RENDERIZAÇÃO
# ==========================================

func _clear_containers() -> void:
	for child in normal_site_content.get_children():
		child.queue_free()
	for child in custom_site_container.get_children():
		child.queue_free()

func _render_403_error() -> void:
	custom_site_container.hide()
	normal_site_scroll.show()
	
	var error_label: Label = Label.new()
	error_label.text = "ERRO 403: CONNECTION REFUSED\n\nO servidor recusou a conexão ou o domínio não existe."
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	normal_site_content.add_child(error_label)

func _render_custom_site(scene: PackedScene) -> void:
	normal_site_scroll.hide()
	custom_site_container.show()
	
	var instance = scene.instantiate()
	custom_site_container.add_child(instance)

func _render_normal_site(page: WebsitePage) -> void:
	custom_site_container.hide()
	normal_site_scroll.show()
	
	# 1. Constrói o Header
	match page.header_type:
		WebsitePage.HeaderType.TEXT:
			var header_label := Label.new()
			header_label.text = page.header_text
			header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			normal_site_content.add_child(header_label)

		WebsitePage.HeaderType.IMAGE:
			if page.header_image:
				var header_rect := TextureRect.new()
				header_rect.texture = page.header_image
				header_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				header_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				header_rect.custom_minimum_size.y = 150
				normal_site_content.add_child(header_rect)
		
	# 2. Constrói a Navbar
	if not page.navbar_links.is_empty():
		var nav_box = HBoxContainer.new()
		nav_box.alignment = BoxContainer.ALIGNMENT_CENTER
		for link_name in page.navbar_links:
			var dest_url: String = page.navbar_links[link_name]
			var btn = Button.new()
			btn.text = link_name
			nav_box.add_child(btn)
			# Lambda capta a URL de destino e manda o browser carregar
			btn.pressed.connect(func(): _load_page(dest_url))
		normal_site_content.add_child(nav_box)
		
	# 3. Adiciona um separador antes do conteúdo
	normal_site_content.add_child(HSeparator.new())
	
	# 4. Inicia a Recursão de Blocos
	for block in page.content_blocks:
		_build_block(block, normal_site_content)

# O Motor Recursivo Perigoso!
func _build_block(block: PageBlock, parent_node: Control) -> void:
	if block == null:
		return
	
	var new_node: Control = null
	
	match block.type:
		PageBlock.BlockType.ROW:
			new_node = HBoxContainer.new()
			new_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
		PageBlock.BlockType.COLUMN:
			new_node = VBoxContainer.new()
			new_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
		PageBlock.BlockType.TEXT:
			var text_label = RichTextLabel.new()
			text_label.text = block.text_content
			text_label.fit_content = true
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_label.custom_minimum_size.x = 10
			new_node = text_label
			
		PageBlock.BlockType.IMAGE:
			var img_rect = TextureRect.new()
			img_rect.texture = block.image_content
			img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			img_rect.custom_minimum_size.y = 200
			new_node = img_rect
			
		PageBlock.BlockType.BUTTON:
			var btn = Button.new()
			btn.text = block.text_content
			btn.pressed.connect(func(): _handle_block_button(block))
			new_node = btn
			
		PageBlock.BlockType.SPACING:
			var spacer = Control.new()
			spacer.custom_minimum_size.y = block.spacing_size
			new_node = spacer
	
	if new_node != null:
		parent_node.add_child(new_node)
		
		if block.type == PageBlock.BlockType.ROW or block.type == PageBlock.BlockType.COLUMN:
			for child_block in block.child_blocks:
				_build_block(child_block, new_node)

func _handle_block_button(block: PageBlock) -> void:
	match block.button_action:
		PageBlock.ButtonAction.NONE:
			return
			
		PageBlock.ButtonAction.NAVIGATE:
			if not block.target_url.is_empty():
				_load_page(block.target_url)
			
		PageBlock.ButtonAction.SET_FLAG:
			if not block.story_flag.is_empty():
				GameState.story_flags[block.story_flag] = block.flag_value
			
		PageBlock.ButtonAction.TOGGLE_FLAG:
			if not block.story_flag.is_empty():
				var current_value: bool = GameState.story_flags.get(block.story_flag, false)
				GameState.story_flags[block.story_flag] = not current_value
