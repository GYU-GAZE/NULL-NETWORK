extends MarginContainer
class_name WindowBase

signal window_closed
signal window_focused

@export_category("Juice & Anims")
@export var tween_duration: float = 0.25

var app_id: String = ""
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# Lembre-se de clicar com o botão direito nestes nós na árvore e marcar "Access as Unique Name"
@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var content_container: MarginContainer = %ContentContainer
@onready var top_bar: Control = %TopBar

func _ready() -> void:
	# Animação de entrada suave (Pop up)
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, tween_duration)
	tween.tween_property(self, "modulate:a", 1.0, tween_duration)
	
	close_button.pressed.connect(close)
	top_bar.gui_input.connect(_on_top_bar_gui_input)

func setup(id: String, window_name: String) -> void:
	app_id = id
	title_label.text = window_name

# Captura cliques na janela inteira para "Puxar pra frente"
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		window_focused.emit()

# Lógica de arrastar (Drag) a janela pela TopBar
func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
				window_focused.emit() # Foca ao clicar na TopBar também
			else:
				is_dragging = false
				
	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

# Um pequeno pulso visual para dar peso quando a janela ganha foco (Alt-Tab ou Clique)
func pulse() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

# Lógica de Fechar
func close() -> void:
	close_button.disabled = true # Impede duplo clique acidental
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), tween_duration)
	tween.tween_property(self, "modulate:a", 0.0, tween_duration)
	
	# Quando o tween acaba, acionamos o emit do sinal diretamente. Limpo e direto!
	tween.chain().tween_callback(window_closed.emit)