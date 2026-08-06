extends PanelContainer
class_name OperatorProfileApp


@onready var operator_avatar: TextureRect = %OperatorAvatar
@onready var operator_name: Label = %OperatorName
@onready var username_label: Label = %UsernameLabel
@onready var real_name_label: Label = %RealNameLabel
@onready var occupation_label: Label = %OccupationLabel
@onready var rank_label: Label = %RankLabel
@onready var server_label: Label = %ServerLabel
@onready var tendency_list: VBoxContainer = %TendencyList

@onready var partner_panel: PanelContainer = %PartnerPanel
@onready var partner_portrait: TextureRect = %PartnerPortrait
@onready var partner_name: Label = %PartnerName
@onready var partner_species: Label = %PartnerSpecies
@onready var partner_form: Label = %PartnerForm
@onready var partner_level: Label = %PartnerLevel
@onready var partner_identity: Label = %PartnerIdentity
@onready var partner_affinity: Label = %PartnerAffinity
@onready var partner_exp_label: Label = %PartnerExpLabel
@onready var partner_exp_bar: ProgressBar = %PartnerExpBar
@onready var hp_label: Label = %HPLabel
@onready var stability_label: Label = %StabilityLabel
@onready var allocation_label: Label = %AllocationLabel
@onready var stats_grid: GridContainer = %StatsGrid

@onready var equipped_module_list: VBoxContainer = %EquippedModuleList
@onready var known_module_list: VBoxContainer = %KnownModuleList
@onready var money_label: Label = %MoneyLabel
@onready var inventory_list: VBoxContainer = %InventoryList
@onready var status_label: Label = %StatusLabel


var _snapshot: Dictionary = {}
var _rendered_equipped_module_count: int = 0
var _rendered_inventory_count: int = 0
var _refresh_queued: bool = false


func _ready() -> void:
	_connect_signals()
	refresh_profile()


func refresh_profile() -> void:
	_refresh_queued = false
	_snapshot = ProfileProjectionService.build_snapshot()
	_render_snapshot()


func get_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func get_rendered_equipped_module_count() -> int:
	return _rendered_equipped_module_count


func get_rendered_inventory_count() -> int:
	return _rendered_inventory_count


func get_operator_name_text() -> String:
	return operator_name.text


func get_partner_level_text() -> String:
	return partner_level.text


func _connect_signals() -> void:
	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_changed
	):
		CampaignState.campaign_changed.connect(_on_campaign_changed)

	if not NetworkUserDatabase.player_user_changed.is_connected(
		_on_player_user_changed
	):
		NetworkUserDatabase.player_user_changed.connect(
			_on_player_user_changed
		)

	if not ContentRegistry.registry_rebuilt.is_connected(
		_on_registry_rebuilt
	):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)


func _queue_refresh() -> void:
	if _refresh_queued or is_queued_for_deletion():
		return

	_refresh_queued = true
	call_deferred("refresh_profile")


func _render_snapshot() -> void:
	_clear_container(tendency_list)
	_clear_container(stats_grid)
	_clear_container(equipped_module_list)
	_clear_container(known_module_list)
	_clear_container(inventory_list)
	_rendered_equipped_module_count = 0
	_rendered_inventory_count = 0

	if not bool(_snapshot.get("has_campaign", false)):
		_render_no_campaign()
		return

	_render_operator(_snapshot.get("operator", {}) as Dictionary)
	_render_tendencies(_snapshot.get("tendencies", []) as Array)
	_render_partner(_snapshot.get("partner", {}) as Dictionary)
	_render_modules(
		_snapshot.get("equipped_modules", []) as Array,
		_snapshot.get("known_modules", []) as Array
	)
	_render_inventory(
		_snapshot.get("inventory", []) as Array,
		int(_snapshot.get("money", 0))
	)
	status_label.text = "PROFILE SYNCHRONIZED"


func _render_no_campaign() -> void:
	operator_avatar.texture = null
	operator_name.text = "NO ACTIVE OPERATOR"
	username_label.text = "@---"
	real_name_label.text = "NO CAMPAIGN DATA"
	occupation_label.text = "OCCUPATION —"
	rank_label.text = "RANK —"
	server_label.text = "SERVER —"
	partner_panel.visible = false
	money_label.text = "¥0"
	_add_empty_label(tendency_list, "NO TENDENCY DATA")
	_add_empty_label(equipped_module_list, "NO PARTNER")
	_add_empty_label(known_module_list, "NO MODULES")
	_add_empty_label(inventory_list, "NO ITEMS")
	status_label.text = "PROFILE UNAVAILABLE"


func _render_operator(data: Dictionary) -> void:
	if data.is_empty():
		operator_avatar.texture = null
		operator_name.text = "UNREGISTERED OPERATOR"
		username_label.text = "@---"
		real_name_label.text = "REGISTRATION REQUIRED"
		occupation_label.text = "OCCUPATION —"
		rank_label.text = "RANK —"
		server_label.text = "SERVER —"
		return

	operator_avatar.texture = data.get("avatar") as Texture2D
	operator_name.text = str(data.get("display_name", "OPERATOR"))
	username_label.text = "@%s" % str(data.get("username", "---"))
	real_name_label.text = str(data.get("full_name", ""))
	occupation_label.text = "OCCUPATION  %s" % str(
		data.get("occupation_name", "—")
	)
	rank_label.text = "RANK  %s" % str(data.get("rank_text", "UNRANKED"))
	server_label.text = "SERVER  %s" % str(data.get("server_name", "—"))


func _render_tendencies(entries: Array) -> void:
	if entries.is_empty():
		_add_empty_label(tendency_list, "NO TENDENCY DATA")
		return

	for entry_value: Variant in entries:
		if entry_value is not Dictionary:
			continue

		var entry: Dictionary = entry_value as Dictionary
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var tendency_name := Label.new()
		tendency_name.custom_minimum_size.x = 86.0
		tendency_name.text = str(entry.get("display_name", "—"))
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(120, 18)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = clampf(float(entry.get("share", 0.0)) * 100.0, 0.0, 100.0)
		bar.show_percentage = false
		var value := Label.new()
		value.custom_minimum_size.x = 48.0
		value.text = str(int(entry.get("value", 0)))
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(tendency_name)
		row.add_child(bar)
		row.add_child(value)
		tendency_list.add_child(row)


func _render_partner(data: Dictionary) -> void:
	partner_panel.visible = not data.is_empty()

	if data.is_empty():
		return

	partner_portrait.texture = data.get("portrait") as Texture2D
	partner_name.text = str(data.get("nickname", "PARTNER"))
	partner_species.text = str(data.get("species_name", "UNKNOWN APK"))
	partner_form.text = "%s // %s" % [
		str(data.get("form_name", "UNKNOWN")),
		str(data.get("integrity_name", "UNKNOWN"))
	]
	partner_level.text = "LEVEL %d" % int(data.get("level", 1))
	partner_identity.text = "PERSONALITY  %s   ·   CALLS YOU  %s" % [
		str(data.get("personality_name", "—")),
		str(data.get("address_term", "—"))
	]
	partner_affinity.text = "AFFINITY  %d" % int(data.get("affinity", 0))
	var exp_required: int = int(data.get("exp_required", 0))
	var exp_into_level: int = int(data.get("exp_into_level", 0))
	partner_exp_label.text = (
		"MAX LEVEL"
		if exp_required <= 0
		else "EXP  %d / %d" % [exp_into_level, exp_required]
	)
	partner_exp_bar.value = clampf(
		float(data.get("exp_ratio", 0.0)) * 100.0,
		0.0,
		100.0
	)
	hp_label.text = "HP  %d / %d" % [
		int(data.get("current_hp", 0)),
		int(data.get("max_hp", 1))
	]
	stability_label.text = "STABILITY  %d / %d" % [
		int(data.get("current_stability", 0)),
		int(data.get("max_stability", 100))
	]
	allocation_label.text = "ALLOCATION POINTS  %d" % int(
		data.get("allocation_points", 0)
	)

	for stat_value: Variant in data.get("stats", []):
		if stat_value is not Dictionary:
			continue

		var stat: Dictionary = stat_value as Dictionary
		var stat_name := Label.new()
		stat_name.text = str(stat.get("display_name", "—"))
		var stat_value_label := Label.new()
		var stat_id: String = str(stat.get("id", ""))

		if stat_id in ["dodge", "crit"]:
			stat_value_label.text = "%.1f%%" % (
				float(stat.get("value", 0.0)) * 100.0
			)
		else:
			stat_value_label.text = str(int(stat.get("value", 0)))

		stat_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(stat_name)
		stats_grid.add_child(stat_value_label)


func _render_modules(equipped_entries: Array, known_entries: Array) -> void:
	for entry_value: Variant in equipped_entries:
		if entry_value is not Dictionary:
			continue

		var entry: Dictionary = entry_value as Dictionary
		var slot_index: int = int(entry.get("slot_index", 0)) + 1
		var classification: String = str(entry.get("classification", ""))
		var suffix: String = (
			"  [%s]" % classification.to_upper()
			if not classification.is_empty()
			else ""
		)
		_add_value_row(
			equipped_module_list,
			"SLOT %d" % slot_index,
			"%s%s" % [str(entry.get("display_name", "—")), suffix]
		)
		_rendered_equipped_module_count += 1

	if _rendered_equipped_module_count == 0:
		_add_empty_label(equipped_module_list, "NO EQUIPPED MODULES")

	for entry_value: Variant in known_entries:
		if entry_value is not Dictionary:
			continue

		var entry: Dictionary = entry_value as Dictionary
		var prefix: String = (
			"PASSIVE · "
			if bool(entry.get("secondary_passive", false))
			else ""
		)
		var label := Label.new()
		label.text = "• %s%s" % [
			prefix,
			str(entry.get("display_name", "—"))
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		known_module_list.add_child(label)

	if known_entries.is_empty():
		_add_empty_label(known_module_list, "NO KNOWN MODULES")


func _render_inventory(entries: Array, money: int) -> void:
	money_label.text = "¥%d" % money

	for entry_value: Variant in entries:
		if entry_value is not Dictionary:
			continue

		var entry: Dictionary = entry_value as Dictionary
		_add_value_row(
			inventory_list,
			str(entry.get("display_name", "UNKNOWN ITEM")),
			"×%d" % int(entry.get("amount", 0))
		)
		_rendered_inventory_count += 1

	if _rendered_inventory_count == 0:
		_add_empty_label(inventory_list, "INVENTORY EMPTY")


func _add_value_row(
	container: VBoxContainer,
	left_text: String,
	right_text: String
) -> void:
	var row := HBoxContainer.new()
	var left := Label.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.text = left_text
	left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var right := Label.new()
	right.text = right_text
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(left)
	row.add_child(right)
	container.add_child(row)


func _add_empty_label(container: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(label)


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_campaign_changed(_section: StringName) -> void:
	_queue_refresh()


func _on_player_user_changed(_player_user: NetworkUserData) -> void:
	_queue_refresh()


func _on_registry_rebuilt() -> void:
	_queue_refresh()
