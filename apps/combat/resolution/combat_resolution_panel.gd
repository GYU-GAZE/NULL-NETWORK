extends PanelContainer
class_name CombatResolutionPanel


signal module_choice_requested(module_id: String)
signal continue_requested


@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var module_options: OptionButton = %ModuleOptions
@onready var confirm_choice_button: Button = %ConfirmChoiceButton
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	confirm_choice_button.pressed.connect(_on_confirm_choice)
	continue_button.pressed.connect(func() -> void: continue_requested.emit())


func show_module_choice(action_name: String, module_ids: PackedStringArray) -> void:
	show()
	title_label.text = "%s COMPLETE" % action_name.to_upper()
	summary_label.text = "Choose one Module extracted from the target."
	module_options.clear()

	for module_id: String in module_ids:
		var module: ModuleData = ContentRegistry.get_module(module_id)
		module_options.add_item(
			module.module_name if module != null else module_id
		)
		module_options.set_item_metadata(module_options.item_count - 1, module_id)

	module_options.show()
	confirm_choice_button.show()
	continue_button.hide()


func show_result(outcome: CombatResult.Outcome, metadata: Dictionary) -> void:
	show()
	module_options.hide()
	confirm_choice_button.hide()
	continue_button.show()
	continue_button.disabled = false

	if bool(metadata.get("operator_lost", false)):
		_show_operator_loss(metadata)
		return

	if bool(metadata.get("partner_lost", false)):
		_show_partner_loss(metadata)
		return

	title_label.text = CombatResult.Outcome.keys()[outcome]
	var lines := PackedStringArray()
	lines.append("EXP +%d" % int(metadata.get("experience", 0)))

	var style: Dictionary = metadata.get("combat_style", {})

	if not style.is_empty():
		lines.append("STYLE: %s" % str(style.get("style_name", "NEUTRAL")))

	for module_id: String in metadata.get("module_ids", []):
		lines.append("MODULE: %s" % module_id)

	var passive_id: String = str(metadata.get("passive_module_id", ""))

	if not passive_id.is_empty():
		lines.append("PASSIVE: %s" % passive_id)

	var tamed_id: String = str(metadata.get("tamed_apk_id", ""))

	if not tamed_id.is_empty():
		lines.append("NEW PARTNER: %s" % tamed_id)

	summary_label.text = "\n".join(lines)


func _show_partner_loss(metadata: Dictionary) -> void:
	title_label.text = "PARTNER LOSS"
	var lost_apk_id: String = str(
		metadata.get("lost_apk_id", "UNKNOWN")
	).strip_edges()
	var lines := PackedStringArray([
		"%s WAS PERMANENTLY LOST." % lost_apk_id.to_upper()
	])

	if bool(metadata.get("turd_assigned", false)):
		lines.append("TURD HAS BEEN ASSIGNED AS EMERGENCY CONTAINMENT.")

	var infestation: int = int(metadata.get("infestation_increase", 0))

	if infestation > 0:
		lines.append("LOCAL INFESTATION +%d" % infestation)

	summary_label.text = "\n".join(lines)


func _show_operator_loss(metadata: Dictionary) -> void:
	title_label.text = "OPERATOR LOSS"
	var operator_id: String = str(
		metadata.get("archived_operator_id", "UNKNOWN")
	).strip_edges()
	var legacy_site_id: String = str(
		metadata.get("legacy_site_id", "")
	).strip_edges()
	var lines := PackedStringArray([
		"OPERATOR %s HAS BEEN ARCHIVED." % operator_id.to_upper(),
		"THE COUNTDOWN AND WORLD STATE WILL CONTINUE."
	])

	if not legacy_site_id.is_empty():
		lines.append("LEGACY SITE CREATED: %s" % legacy_site_id)

	var infestation: int = int(metadata.get("infestation_increase", 0))

	if infestation > 0:
		lines.append("LOCAL INFESTATION +%d" % infestation)

	lines.append("REGISTER A NEW OPERATOR TO CONTINUE.")
	summary_label.text = "\n".join(lines)


func _on_confirm_choice() -> void:
	if module_options.selected < 0:
		return

	module_choice_requested.emit(
		str(module_options.get_item_metadata(module_options.selected))
	)
