extends PanelContainer
class_name StarterSelectionPage


signal starter_selection_completed(apk_id: String)


@onready var state_label: Label = %StateLabel
@onready var starter_list: VBoxContainer = %StarterList
@onready var portrait: TextureRect = %Portrait
@onready var partner_name: Label = %PartnerName
@onready var partner_meta: Label = %PartnerMeta
@onready var partner_summary: Label = %PartnerSummary
@onready var nickname_edit: LineEdit = %NicknameEdit
@onready var personality_option: OptionButton = %PersonalityOption
@onready var personality_description: Label = %PersonalityDescription
@onready var address_option: OptionButton = %AddressOption
@onready var address_preview: Label = %AddressPreview
@onready var error_label: Label = %ErrorLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var open_navigator_button: Button = %OpenNavigatorButton

var _starters: Array[APKData] = []
var _starter_buttons: Dictionary = {}
var _selected_apk_id: String = ""


func _ready() -> void:
	personality_option.item_selected.connect(_on_personality_selected)
	address_option.item_selected.connect(_on_address_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	open_navigator_button.pressed.connect(_open_navigator)

	if not ContentRegistry.registry_rebuilt.is_connected(_on_registry_rebuilt):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)

	_rebuild_starter_list()
	_refresh_access_state()


func get_available_starter_ids() -> PackedStringArray:
	var result := PackedStringArray()

	for apk: APKData in _starters:
		result.append(apk.apk_id)

	return result


func get_selected_apk_id() -> String:
	return _selected_apk_id


func select_starter_entry(apk_id: String) -> bool:
	var apk: APKData = _find_starter(apk_id)

	if apk == null or not _can_select_starter():
		return false

	_selected_apk_id = apk.apk_id

	for raw_id: Variant in _starter_buttons:
		var button := _starter_buttons[raw_id] as Button

		if button != null:
			button.button_pressed = str(raw_id) == _selected_apk_id

	portrait.texture = _get_primary_texture(apk)
	partner_name.text = apk.display_name
	partner_meta.text = "%s // %s" % [
		apk.species_line_id.to_upper(),
		APKData.FormType.keys()[apk.form_type]
	]
	partner_summary.text = _build_summary(apk)
	nickname_edit.text = apk.display_name
	_populate_personalities(apk)
	_populate_address_terms(apk)
	confirm_button.disabled = false
	error_label.text = ""
	return true


func confirm_selected_starter(
	nickname: String = "",
	personality_index: int = -1,
	address_index: int = -1
) -> PackedStringArray:
	var errors := PackedStringArray()

	if not _can_select_starter():
		errors.append("Starter selection is not available in the current campaign phase.")
		return errors

	var apk: APKData = _find_starter(_selected_apk_id)

	if apk == null:
		errors.append("Select a registered starter before confirming.")
		return errors

	var clean_nickname: String = nickname.strip_edges()

	if clean_nickname.is_empty():
		clean_nickname = nickname_edit.text.strip_edges()

	if clean_nickname.is_empty():
		clean_nickname = apk.display_name

	var resolved_personality_index: int = personality_index

	if resolved_personality_index < 0:
		resolved_personality_index = _selected_metadata_index(personality_option)

	var resolved_address_index: int = address_index

	if resolved_address_index < 0:
		resolved_address_index = _selected_metadata_index(address_option)

	errors = APKProgressionService.select_starter(
		apk.apk_id,
		clean_nickname,
		resolved_personality_index,
		resolved_address_index
	)

	if not errors.is_empty():
		error_label.text = "\n".join(errors)
		return errors

	_show_completed_state(apk)
	starter_selection_completed.emit(apk.apk_id)
	return errors


func _rebuild_starter_list() -> void:
	for child: Node in starter_list.get_children():
		child.queue_free()

	_starters.clear()
	_starter_buttons.clear()
	_selected_apk_id = ""

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_APKS
	):
		var apk := resource as APKData

		if apk == null \
			or not apk.selectable_as_starter \
			or not apk.validate_data().is_empty():
			continue

		_starters.append(apk)

	_starters.sort_custom(
		func(left: APKData, right: APKData) -> bool:
			if left.starter_sort_order != right.starter_sort_order:
				return left.starter_sort_order < right.starter_sort_order

			return left.display_name < right.display_name
	)

	for apk: APKData in _starters:
		var button := Button.new()
		button.text = apk.display_name
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(
			_on_starter_button_pressed.bind(apk.apk_id)
		)
		starter_list.add_child(button)
		_starter_buttons[apk.apk_id] = button

	if not _starters.is_empty() and _can_select_starter():
		select_starter_entry(_starters[0].apk_id)


func _refresh_access_state() -> void:
	var available: bool = _can_select_starter()
	var already_selected: bool = (
		CampaignState.has_campaign()
		and not CampaignState.operator.is_empty()
		and not CampaignState.partner.is_empty()
	)

	if already_selected:
		state_label.text = "PARTNER SYNCHRONIZED // %s" % (
			CampaignState.partner.nickname
			if not CampaignState.partner.nickname.is_empty()
			else CampaignState.partner.apk_id
		)
		confirm_button.disabled = true
		_set_starter_buttons_disabled(true)
		_refresh_navigator_action()
		return

	open_navigator_button.hide()
	confirm_button.disabled = not available or _selected_apk_id.is_empty()
	_set_starter_buttons_disabled(not available)

	if not CampaignState.has_campaign():
		state_label.text = "NO ACTIVE CAMPAIGN"
	elif CampaignState.operator.is_empty():
		state_label.text = "REGISTER AN OPERATOR BEFORE SELECTING A PARTNER"
	elif not _is_starter_selection_phase():
		state_label.text = "STARTER SELECTION IS NOT ACTIVE"
	elif _starters.is_empty():
		state_label.text = "NO STARTER APK IS REGISTERED"
	else:
		state_label.text = "OPERATOR READY // SELECT ONE PARTNER"


func _can_select_starter() -> bool:
	return (
		CampaignState.has_campaign()
		and not CampaignState.operator.is_empty()
		and CampaignState.partner.is_empty()
		and _is_starter_selection_phase()
	)


func _is_starter_selection_phase() -> bool:
	return CampaignState.campaign_phase in [
		CampaignState.CampaignPhase.PROLOGUE,
		CampaignState.CampaignPhase.OPERATOR_CREATION
	]


func _find_starter(apk_id: String) -> APKData:
	var clean_id: String = apk_id.strip_edges()

	for apk: APKData in _starters:
		if apk.apk_id == clean_id:
			return apk

	return null


func _populate_personalities(apk: APKData) -> void:
	personality_option.clear()

	for index: int in range(apk.available_personalities.size()):
		var personality: APKPersonalityData = apk.available_personalities[index]

		if personality == null:
			continue

		personality_option.add_item(personality.display_name)
		personality_option.set_item_metadata(
			personality_option.item_count - 1,
			index
		)

	if personality_option.item_count > 0:
		personality_option.select(0)

	_update_personality_description(apk)


func _populate_address_terms(apk: APKData) -> void:
	address_option.clear()

	for index: int in range(apk.available_address_terms.size()):
		var term: AddressTermData = apk.available_address_terms[index]

		if term == null:
			continue

		var resolved_text: String = term.resolve_text(
			CampaignState.operator.profile
		)
		address_option.add_item(resolved_text)
		address_option.set_item_metadata(
			address_option.item_count - 1,
			index
		)

	if address_option.item_count > 0:
		address_option.select(0)

	_update_address_preview(apk)


func _on_starter_button_pressed(apk_id: String) -> void:
	select_starter_entry(apk_id)


func _on_personality_selected(_index: int) -> void:
	var apk: APKData = _find_starter(_selected_apk_id)

	if apk != null:
		_update_personality_description(apk)


func _on_address_selected(_index: int) -> void:
	var apk: APKData = _find_starter(_selected_apk_id)

	if apk != null:
		_update_address_preview(apk)


func _update_personality_description(apk: APKData) -> void:
	var index: int = _selected_metadata_index(personality_option)
	personality_description.text = ""

	if index >= 0 and index < apk.available_personalities.size():
		var personality: APKPersonalityData = apk.available_personalities[index]

		if personality != null:
			personality_description.text = personality.description


func _update_address_preview(apk: APKData) -> void:
	var index: int = _selected_metadata_index(address_option)
	address_preview.text = ""

	if index >= 0 and index < apk.available_address_terms.size():
		var term: AddressTermData = apk.available_address_terms[index]

		if term != null:
			address_preview.text = "This partner will address you as: %s" % (
				term.resolve_text(CampaignState.operator.profile)
			)


func _selected_metadata_index(option: OptionButton) -> int:
	if option.item_count == 0 or option.selected < 0:
		return 0

	return int(option.get_item_metadata(option.selected))


func _build_summary(apk: APKData) -> String:
	var modules := PackedStringArray()

	for module: ModuleData in apk.default_active_modules:
		if module != null:
			modules.append(module.module_name)

	return (
		"STARTING MODULES\n%s\n\n"
		+ "LEVEL 100 PROFILE\nHP %d // ATK %d // DEF %d // MATK %d // MDEF %d"
	) % [
		", ".join(modules),
		apk.level_100_stats.hp,
		apk.level_100_stats.atk,
		apk.level_100_stats.def,
		apk.level_100_stats.matk,
		apk.level_100_stats.mdef
	]


func _get_primary_texture(apk: APKData) -> Texture2D:
	if not apk.portraits.is_empty() and apk.portraits[0] != null:
		return apk.portraits[0]

	if not apk.sprites.is_empty() and apk.sprites[0] != null:
		return apk.sprites[0]

	return apk.combat_icon


func _show_completed_state(apk: APKData) -> void:
	state_label.text = "SYNCHRONIZATION COMPLETE // %s" % apk.display_name
	error_label.text = ""
	confirm_button.disabled = true
	_set_starter_buttons_disabled(true)
	_refresh_navigator_action()


func _refresh_navigator_action() -> void:
	open_navigator_button.visible = CampaignState.has_installed_app("navigator")


func _set_starter_buttons_disabled(disabled: bool) -> void:
	for raw_button: Variant in _starter_buttons.values():
		var button := raw_button as Button

		if button != null:
			button.disabled = disabled


func _on_confirm_pressed() -> void:
	confirm_selected_starter()


func _open_navigator() -> void:
	var navigator: AppResource = ContentRegistry.get_app("navigator")

	if navigator != null and CampaignState.has_installed_app("navigator"):
		GlobalSignals.request_open_app.emit(navigator)


func _on_registry_rebuilt() -> void:
	_rebuild_starter_list()
	_refresh_access_state()
