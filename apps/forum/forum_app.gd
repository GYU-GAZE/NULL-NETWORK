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

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

func _generate_thread_list() -> void:
	for child in thread_list_container.get_children():
		child.queue_free()

	var active_threads: Array[ThreadButtonData] = []
	var archived_threads: Array[ThreadButtonData] = []

	for data in thread_list:
		if data == null or data.thread_ref == null:
			continue

		if not data.is_visible():
			continue

		if data.is_archived():
			archived_threads.append(data)
		else:
			active_threads.append(data)

	_add_thread_section("ATIVAS", active_threads)
	_add_thread_section("ARQUIVADAS", archived_threads)

func _add_thread_section(section_title: String, threads: Array[ThreadButtonData]) -> void:
	if threads.is_empty():
		return

	var title_label := Label.new()
	title_label.text = section_title
	thread_list_container.add_child(title_label)

	for data in threads:
		var btn := Button.new()

		var new_prefix := ""

		if not GameState.has_read_thread(data.thread_ref.thread_id):
			new_prefix = "[NEW!] "

		btn.text = "%s[%s] %s" % [
			new_prefix,
			data.thread_ref.board_name,
			data.thread_ref.thread_title
		]

		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		thread_list_container.add_child(btn)
		btn.pressed.connect(func(): _open_thread(data.thread_ref))

	thread_list_container.add_child(HSeparator.new())

func _on_time_advanced(_period: int, _days_passed: int, _cal_day: int, _cal_month: String) -> void:
	_generate_thread_list()

func _open_thread(thread: ForumThread) -> void:
	GameState.mark_thread_as_read(thread.thread_id)
	_generate_thread_list()
	
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