extends Control
class_name WindowManager

@export_category("Dependencies")
@export var window_base_scene: PackedScene 
@export var combat_app_scene: PackedScene # <--- ARRASTE O SEU app_combat.tscn AQUI!

var active_windows: Dictionary = {}

func _ready() -> void:
	GlobalSignals.request_open_app.connect(_on_request_open_app)
	GlobalSignals.request_close_app.connect(_on_request_close_app)
	
	# O NOVO ELO: Escuta o pedido de combate do Navigator!
	GlobalSignals.request_combat.connect(_on_request_combat)

func _on_request_open_app(app_id: String, app_name: String, content_scene: PackedScene) -> void:
	if active_windows.has(app_id):
		_on_request_close_app(app_id)
		return
		
	var new_window: WindowBase = window_base_scene.instantiate() as WindowBase
	add_child(new_window)
	
	new_window.setup(app_id, app_name, content_scene)
	new_window.global_position = (get_viewport_rect().size / 2.0) - (new_window.size / 2.0)
	
	active_windows[app_id] = new_window

func _on_request_close_app(app_id: String) -> void:
	if active_windows.has(app_id):
		var window_to_close: WindowBase = active_windows[app_id]
		window_to_close.close_window() 
		active_windows.erase(app_id)

# ==========================================
# O INTERCEPTADOR DE COMBATE
# ==========================================
func _on_request_combat(encounter: CombatEncounter) -> void:
	# 1. Carrega o encontro no cérebro do jogo (Autoload)
	CombatManager.load_encounter(encounter)
	
	# 2. Opcional: Fecha o Navigator para focar na luta (Assumindo que o ID dele seja "app_navigator")
	if active_windows.has("app_navigator"):
		_on_request_close_app("app_navigator")
		
	# 3. Abre o Combate como se fosse um aplicativo forçado pelo SO!
	_on_request_open_app("sys_combat", "Intercept_Combat.exe", combat_app_scene)
