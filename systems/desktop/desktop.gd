extends Control
class_name Desktop

@export_category("OS Data")
# Aqui é onde você vai arrastar seus arquivos .tres criados!
@export var installed_apps: Array[AppResource] = []

@export_category("Boot Animation (Juice)")
@export var icon_spawn_delay: float = 0.15
@export var fade_in_duration: float = 0.4
@export_category("Time UI Animation (Juice)")
@export var time_pulse_scale: Vector2 = Vector2(1.05, 1.05)
@export var time_tween_duration: float = 0.3

@onready var icon_grid: HBoxContainer = %IconGrid

@onready var clock_container: VBoxContainer = %ClockContainer
@onready var period_label: Label = %PeriodLabel
@onready var day_label: Label = %DayLabel
@onready var month_label: Label = %MonthLabel
@onready var days_passed_label: Label = %DaysPassedLabel

@onready var debug_time_button: Button = %DebugTimeButton

func _ready() -> void:
	_boot_desktop()
	debug_time_button.pressed.connect(_on_debug_time_pressed)
	GlobalSignals.time_advanced.connect(_on_time_advanced)
	
	# Força a primeira atualização usando as variáveis diretamente do Autoload
	TimeManager._emit_time_signal()

func _boot_desktop() -> void:
	# Para cada aplicativo instalado na nossa base de dados...
	for i in range(installed_apps.size()):
		var app: AppResource = installed_apps[i]
		
		# Validação de segurança básica do Sênior: o app é válido?
		if app == null:
			printerr("Erro: Recurso de App vazio no index ", i)
			continue
			
		_create_desktop_icon(app, i)

# Cria o botão fisicamente na tela
func _create_desktop_icon(app: AppResource, index: int) -> void:
	var btn: Button = Button.new()
	
	# Configurações visuais do botão emulando um ícone de desktop
	btn.text = app.app_name
	btn.icon = app.app_icon
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	btn.flat = true # Remove o fundo padrão de botão do Godot, deixando só ícone e texto
	
	# Adiciona à tela
	icon_grid.add_child(btn)
	
	# O BLOCKER RESOLVIDO: O uso da função Lambda "func():"
	# Isso garante que os parâmetros passados no loop sejam "congelados" para este botão específico.
	btn.gui_input.connect(_on_icon_gui_input.bind(app))
	
	# THE JUICE: Animação de entrada dos ícones
	# Escondemos o botão inicialmente
	btn.modulate.a = 0.0 
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Cada ícone demora (index * delay) para aparecer, criando o efeito cascata
	tween.tween_property(btn, "modulate:a", 1.0, fade_in_duration).set_delay(index * icon_spawn_delay)


func _on_debug_time_pressed() -> void:
	TimeManager.advance_action()

# Recebe os dados destrinchados do sinal global
func _on_time_advanced(period: int, days_passed: int, cal_day: int, cal_month: String) -> void:
	var period_name := TimeManager.get_period_name(period as TimeManager.TimePeriod)
	var current_block := TimeManager.current_action_block
	var total_blocks := TimeManager.ACTION_BLOCKS_PER_PERIOD
	var actions_left := TimeManager.get_actions_left_in_period()

	period_label.text = "%s %d/%d" % [
		period_name,
		current_block + 1,
		total_blocks
	]

	day_label.text = str(cal_day)
	month_label.text = cal_month

	days_passed_label.text = "Dia %d | Ações restantes: %d" % [
		days_passed,
		actions_left
	]

	_animate_time_change()

# O Juice (Game Feel) aplicado no container inteiro
func _animate_time_change() -> void:
	clock_container.pivot_offset = clock_container.size / 2.0
	clock_container.scale = time_pulse_scale
	clock_container.modulate = Color(1.2, 1.2, 1.5, 1.0) # Leve brilho azulado
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(clock_container, "scale", Vector2.ONE, time_tween_duration).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(clock_container, "modulate", Color.WHITE, time_tween_duration)

func _on_icon_gui_input(event: InputEvent, app: AppResource) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			GlobalSignals.request_close_app.emit(app.app_id) # Duplo Clique Fechar
		else:
			GlobalSignals.request_open_app.emit(app.app_id, app.app_name, app.app_scene) # Clique simples Foca/Abre