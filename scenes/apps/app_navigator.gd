extends Control 
class_name NavigatorApp

@export var all_locations: Array[MapLocation] = [] # Arraste os seus resources de mapa pra cá no Inspector!

@onready var location_list: VBoxContainer = %LocationList
@onready var details_container: VBoxContainer = %LocationDetails
@onready var location_name_label: Label = %LocationDetails.get_node("NameLabel") # Ajuste o caminho se precisar
@onready var btn_scan: Button = %BtnScan

var current_selected_location: MapLocation = null

func _ready() -> void:
	# super._ready() FOI REMOVIDO DAQUI!
	details_container.hide()
	_populate_locations()
	
	btn_scan.pressed.connect(_on_scan_pressed)

func _populate_locations() -> void:
	for c in location_list.get_children(): c.queue_free()
	
	for loc in all_locations:
		# BYPASS: Ignora o TimeManager temporariamente e mostra tudo!
		var btn = Button.new()
		btn.text = loc.location_name
		btn.pressed.connect(func(): _select_location(loc))
		location_list.add_child(btn)

func _select_location(loc: MapLocation) -> void:
	current_selected_location = loc
	location_name_label.text = "Sinal em: " + loc.location_name
	details_container.show()

func _on_scan_pressed() -> void:
	if current_selected_location == null or current_selected_location.spawn_table == null:
		print("Nenhum sinal encontrado (Tabela de Spawn vazia).")
		return
		
	# Rola a Roleta Viciada!
	var encounter = current_selected_location.spawn_table.roll_encounter()
	
	if encounter:
		print("SINAL DETECTADO! Iniciando combate...")
		GlobalSignals.request_combat.emit(encounter)
		# Nota opcional: Se quiser que o próprio app do Navigator feche ao achar combate, use:
		# GlobalSignals.request_close_app.emit("app_navigator")
	else:
		print("Sinal perdido. Tente novamente.")
