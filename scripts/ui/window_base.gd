extends MarginContainer
class_name WindowBase

@export_category("Window Animation (Juice)")
@export var tween_duration: float = 0.25
@export var bounce_intensity: float = 1.05

var app_id: String = ""
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var content_container: MarginContainer = %ContentContainer
@onready var top_bar: PanelContainer = %TopBar

func _ready() -> void:
	# Conecta os sinais da própria UI
	close_button.pressed.connect(_on_close_button_pressed)
	top_bar.gui_input.connect(_on_top_bar_gui_input)
	self.gui_input.connect(_on_window_gui_input)
	
	# Animação de entrada (Juice)
	pivot_offset = size / 2.0 # Garante que o scale venha do centro
	scale = Vector2.ZERO
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, tween_duration)

# Injeta o conteúdo do app dentro do espaço vazio
func setup(id: String, window_name: String, content_scene: PackedScene) -> void:
	app_id = id
	title_label.text = window_name
	
	if content_scene:
		var content_instance = content_scene.instantiate()
		content_container.add_child(content_instance)

# Clicar no botão de fechar da Top Bar fecha a janela
func _on_close_button_pressed() -> void:
	GlobalSignals.request_close_app.emit(app_id)

# Lógica rústica de Drag & Drop para arrastar a janela pela Top Bar
func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			move_to_front() # Traz pro topo ao começar a arrastar
		else:
			is_dragging = false
			
	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

# Traz a janela para frente se clicar em qualquer lugar do corpo dela
func _on_window_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		move_to_front()

# Animação de saída antes de deletar o Node
func close_window() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, tween_duration * 0.8)
	tween.tween_callback(queue_free) # Destrói a cena de forma segura ao final do tween
