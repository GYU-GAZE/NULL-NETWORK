extends Control
class_name WindowManager

@export_category("Dependencies")
@export var window_base_scene: PackedScene

# Dicionários de Estado
var open_windows: Dictionary = {} # app_id -> Instância da WindowBase
var saved_positions: Dictionary = {} # app_id -> Vector2 (Posição exata de quando fechou)

func _ready() -> void:
	GlobalSignals.request_open_app.connect(_on_request_open_app)
	GlobalSignals.request_close_app.connect(close_window)

# Interceptador do "TAB"
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"): # Por padrão no Godot, é a tecla TAB
		cycle_windows()
		
		# O Pulo do Gato: Isso "mata" o evento aqui. 
		# O Godot não vai repassar o TAB para os botões da cena!
		get_viewport().set_input_as_handled()

func _on_request_open_app(app_id: String, app_name: String, app_scene: PackedScene) -> void:
	# 1. Se a janela já existe, trazemos para frente! (Game Feel)
	if open_windows.has(app_id):
		focus_window(app_id)
		return
		
	# 2. Se não, fabricamos uma nova janela
	var new_window: WindowBase = window_base_scene.instantiate() as WindowBase
	add_child(new_window)
	
	new_window.setup(app_id, app_name)
	open_windows[app_id] = new_window
	
	# 3. Injetamos o App de fato dentro do corpo da janela
	if app_scene:
		var app_instance = app_scene.instantiate()
		new_window.content_container.add_child(app_instance)
		
	# 4. Magia de Memória: Restaurar posição salva ou centralizar!
	if saved_positions.has(app_id):
		new_window.position = saved_positions[app_id]
	else:
		# Pequeno cálculo para o app nascer centralizado na primeira vez
		new_window.position = (size - new_window.size) / 2.0
		
	# 5. Escutadores de eventos da janela
	new_window.window_focused.connect(focus_window.bind(app_id))
	new_window.window_closed.connect(_on_window_closed.bind(app_id))

func focus_window(app_id: String) -> void:
	if open_windows.has(app_id):
		var window = open_windows[app_id]
		window.move_to_front() # Coloca a janela por último na lista de renderização (em cima de todas)
		window.pulse() # Chama o Juice de feedback visual

func close_window(app_id: String) -> void:
	if open_windows.has(app_id):
		open_windows[app_id].close()

func _on_window_closed(app_id: String) -> void:
	if open_windows.has(app_id):
		var window = open_windows[app_id]
		saved_positions[app_id] = window.position # Salva a coordenada exata para a próxima vez
		open_windows.erase(app_id)
		window.queue_free() # Destrói a janela de fato

func cycle_windows() -> void:
	# O sistema de Alt+Tab!
	if open_windows.size() <= 1:
		return
		
	# Como as janelas mais ao fundo estão primeiro na árvore,
	# pegamos a primeira WindowBase e mandamos para o final (topo). Isso cicla infinitamente!
	var children = get_children()
	for child in children:
		if child is WindowBase:
			child.move_to_front()
			child.pulse()
			break
