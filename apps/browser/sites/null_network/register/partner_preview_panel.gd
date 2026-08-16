extends PanelContainer
class_name PartnerPreviewPanel

@export var module_chip_scene: PackedScene = preload("res://apps/browser/sites/null_network/register/module_info_chip.tscn")

@onready var portrait: TextureRect = %Portrait
@onready var partner_name: Label = %PartnerName
@onready var status_label: Label = %StatusLabel
@onready var level_label: Label = %LevelLabel
@onready var stats_label: Label = %StatsLabel
@onready var description_label: Label = %DescriptionLabel
@onready var passive_container: VBoxContainer = %PassiveContainer
@onready var modules_container: HFlowContainer = %ModulesContainer
@onready var tooltip_panel: PanelContainer = %TooltipPanel
@onready var tooltip_label: Label = %TooltipLabel
@onready var variant_placeholder: Label = %VariantPlaceholder

var candidate: CompatibilityCandidateData
var apk_data: APKData

func _ready() -> void:
	tooltip_panel.hide()

func setup(
	candidate_data: CompatibilityCandidateData,
	starter_level: int = 3,
	variant_id: String = ""
) -> void:
	candidate = candidate_data
	apk_data = ContentRegistry.get_apk(candidate.apk_id) if candidate != null else null
	_clear_container(passive_container)
	_clear_container(modules_container)
	if candidate == null:
		_show_missing("NO PARTNER SELECTED", starter_level, variant_id)
		return
	partner_name.text = candidate.display_name
	level_label.text = "INITIAL LEVEL %d" % starter_level
	variant_placeholder.text = (
		"VARIANT NODE: %s // INTEGRATION PENDING" % variant_id
		if not variant_id.strip_edges().is_empty()
		else "VARIANT NODE: STANDARD // NODE INTEGRATION PENDING"
	)
	if apk_data == null or not apk_data.validate_data().is_empty():
		_show_missing(candidate.display_name, starter_level, variant_id)
		return
	status_label.text = "COMPATIBILITY DATA READY"
	status_label.modulate = Color(0.17, 0.58, 0.47)
	portrait.texture = _get_portrait(apk_data)
	var preview_state := PartnerStateData.new()
	preview_state.apk_id = apk_data.apk_id
	preview_state.level = starter_level
	preview_state.current_exp = APKProgressionService.get_total_exp_for_level(starter_level)
	preview_state.allocated_stats = {}
	var stats := APKStatCalculator.calculate_stats(apk_data, preview_state)
	stats_label.text = "HP %d   ATK %d   DEF %d   MATK %d   MDEF %d\nSTB REC %d   DODGE %d%%   CRIT %d%%" % [
		int(stats.get("max_hp", 0)), int(stats.get("atk", 0)), int(stats.get("def", 0)),
		int(stats.get("matk", 0)), int(stats.get("mdef", 0)), int(stats.get("stability_recovery", 0)),
		roundi(float(stats.get("dodge", 0.0)) * 100.0), roundi(float(stats.get("crit", 0.0)) * 100.0)
	]
	description_label.text = apk_data.description.strip_edges() if not apk_data.description.strip_edges().is_empty() else "Description data has not been authored for this APK yet."
	if apk_data.signature_passive != null:
		_add_module_chip(passive_container, apk_data.signature_passive)
	else:
		_add_pending_label(passive_container, "PASSIVE MODULE DATA PENDING")
	for module: ModuleData in apk_data.default_active_modules:
		_add_module_chip(modules_container, module)

func has_resolved_apk() -> bool:
	return apk_data != null and apk_data.validate_data().is_empty()

func get_apk_id() -> String:
	return apk_data.apk_id if has_resolved_apk() else ""

func _show_missing(display_name: String, starter_level: int, variant_id: String) -> void:
	partner_name.text = display_name
	level_label.text = "INITIAL LEVEL %d" % starter_level
	status_label.text = "APK CONTENT DATA PENDING"
	status_label.modulate = Color(0.72, 0.32, 0.34)
	portrait.texture = null
	stats_label.text = "HP --   ATK --   DEF --   MATK --   MDEF --\nSTB REC --   DODGE --   CRIT --"
	description_label.text = "This Compatibility profile is canonical, but its runtime APKData has not been registered in the current content catalog yet."
	variant_placeholder.text = (
		"VARIANT NODE: %s // INTEGRATION PENDING" % variant_id
		if not variant_id.strip_edges().is_empty()
		else "VARIANT NODE: -- // INTEGRATION PENDING"
	)
	_add_pending_label(passive_container, "PASSIVE MODULE DATA PENDING")
	_add_pending_label(modules_container, "STARTING MODULE DATA PENDING")

func _get_portrait(apk: APKData) -> Texture2D:
	if apk == null:
		return null
	if not apk.portraits.is_empty() and apk.portraits[0] != null:
		return apk.portraits[0]
	return apk.combat_icon

func _add_module_chip(parent: Container, module: ModuleData) -> void:
	if module_chip_scene == null:
		return
	var chip := module_chip_scene.instantiate() as ModuleInfoChip
	if chip == null:
		return
	parent.add_child(chip)
	chip.setup(module)
	chip.tooltip_requested.connect(_show_module_tooltip)
	chip.tooltip_hidden.connect(_hide_module_tooltip)

func _add_pending_label(parent: Container, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.modulate = Color(0.45, 0.52, 0.6)
	parent.add_child(label)

func _show_module_tooltip(text_value: String) -> void:
	tooltip_label.text = text_value
	tooltip_panel.show()

func _hide_module_tooltip() -> void:
	tooltip_panel.hide()

func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		child.queue_free()
