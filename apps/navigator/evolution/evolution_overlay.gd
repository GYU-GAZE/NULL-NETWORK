extends PanelContainer
class_name EvolutionOverlay


signal evolution_accepted
signal evolution_declined


@onready var title_label: Label = %TitleLabel
@onready var route_label: Label = %RouteLabel
@onready var evolve_button: Button = %EvolveButton
@onready var hold_button: Button = %HoldButton


func _ready() -> void:
	evolve_button.pressed.connect(func() -> void: evolution_accepted.emit())
	hold_button.pressed.connect(func() -> void: evolution_declined.emit())


func setup(branch: EvolutionBranchData) -> void:
	if branch == null:
		hide()
		return

	title_label.text = "LINK SURGE DETECTED"
	route_label.text = "ROUTE: %s\nYour APK is responding to your combat pattern." % branch.target_apk_id
	evolve_button.visible = branch.prompt_player or branch.forced_if_valid
	hold_button.visible = branch.prompt_player and not branch.forced_if_valid
	show()
