extends Control
class_name ForumApp

signal browser_navigation_requested(url: String)
@export_category("Forum Database")
@export var thread_list: Array[ThreadButtonData] = []
@export var post_ui_scene: PackedScene 

# Referência ao novo Scroll Mestre
@onready var master_scroll: ScrollContainer = %MasterScroll

# Telas de Conteúdo
@onready var thread_list_container: VBoxContainer = %ThreadList
@onready var reader_container: VBoxContainer = %ReaderContainer

# Elementos Internos
@onready var reader_title_label: Label = %ReaderTitleLabel
@onready var post_list: VBoxContainer = %PostList
@onready var threads_btn: Button = %ThreadsBtn

func _ready() -> void:
	# Estado inicial
	reader_container.hide()
	thread_list_container.show()
	
	threads_btn.pressed.connect(_on_threads_btn_pressed)
	_generate_thread_list()

func _generate_thread_list() -> void:
	for child in thread_list_container.get_children():
		child.queue_free()
		
	for data in thread_list:
		if data == null or data.thread_ref == null:
			continue

		if not data.are_conditions_met():
			continue
			
		var btn: Button = Button.new()
		btn.text = "[%s] %s" % [data.thread_ref.board_name, data.thread_ref.thread_title]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		thread_list_container.add_child(btn)
		btn.pressed.connect(func(): _open_thread(data.thread_ref))

func _open_thread(thread: ForumThread) -> void:
	reader_title_label.text = "[%s] %s" % [thread.board_name, thread.thread_title]
	
	for child in post_list.get_children():
		child.queue_free()
		
	for post in thread.posts:
		if post == null:
			continue
		var post_instance: ForumPostUI = post_ui_scene.instantiate() as ForumPostUI
		post_list.add_child(post_instance)
		post_instance.link_clicked.connect(_on_post_link_clicked)
		post_instance.setup(post) 
	
	# Transição: Esconde a lista e mostra os posts
	thread_list_container.hide()
	reader_container.show()
	
	# THE JUICE: Reseta a barra de rolagem para o topo da página!
	master_scroll.scroll_vertical = 0

func _on_threads_btn_pressed() -> void:
	reader_container.hide()
	thread_list_container.show()
	
	# Reseta a barra de rolagem ao voltar para a lista também
	master_scroll.scroll_vertical = 0
	
# ==========================================
# INTERFACE COM O NAVEGADOR
# ==========================================
# Essa função é chamada automaticamente pelo Browser se o botão Voltar for clicado
func handle_browser_back() -> bool:
	if reader_container.visible:
		# Se estamos lendo um post, voltamos para a lista de threads
		reader_container.hide()
		thread_list_container.show()
		master_scroll.scroll_vertical = 0
		return true # Retornamos true avisando o Browser: "Eu cuidei disso!"
		
	else:
		# Se já estamos na lista de threads, não temos para onde voltar no fórum
		return false # Avisa o Browser: "Pode voltar a URL aí, chefe!"

func _on_post_link_clicked(url: String) -> void:
	browser_navigation_requested.emit(url)