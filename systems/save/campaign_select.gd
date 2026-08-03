extends Control
class_name CampaignSelect


signal campaign_load_requested(campaign_id: String, checkpoint_file_id: String)
signal campaign_create_requested(
	campaign_id: String,
	display_name: String,
	save_mode: CampaignState.SaveMode
)


@onready var campaign_list: ItemList = %CampaignList
@onready var empty_label: Label = %EmptyLabel
@onready var campaign_name_label: Label = %CampaignNameLabel
@onready var mode_label: Label = %ModeLabel
@onready var updated_label: Label = %UpdatedLabel
@onready var checkpoint_label: Label = %CheckpointLabel
@onready var checkpoint_select: OptionButton = %CheckpointSelect
@onready var mode_notice: RichTextLabel = %ModeNotice
@onready var load_button: Button = %LoadButton
@onready var error_label: Label = %ErrorLabel
@onready var new_campaign_panel: NewCampaignPanel = %NewCampaignPanel
@onready var modal_shade: ColorRect = %ModalShade

var _campaigns: Array[Dictionary] = []
var _checkpoints: Array[Dictionary] = []
var _busy: bool = false


func _ready() -> void:
	campaign_list.item_selected.connect(_on_campaign_selected)
	load_button.pressed.connect(_on_load_pressed)
	%NewCampaignButton.pressed.connect(_open_new_campaign)
	new_campaign_panel.create_requested.connect(_on_create_requested)
	new_campaign_panel.cancelled.connect(_close_new_campaign)
	modal_shade.hide()
	refresh_campaigns()


func refresh_campaigns() -> void:
	_campaigns = SaveManager.list_campaigns()
	campaign_list.clear()

	for metadata: Dictionary in _campaigns:
		var display_name: String = str(
			metadata.get("display_name", metadata.get("campaign_id", "Campaign"))
		)
		var save_mode: int = int(
			metadata.get("save_mode", CampaignState.SaveMode.UNSET)
		)
		campaign_list.add_item(
			"%s  [%s]" % [display_name, _mode_name(save_mode)]
		)

	empty_label.visible = _campaigns.is_empty()
	campaign_list.visible = not _campaigns.is_empty()

	if _campaigns.is_empty():
		_clear_details()
	else:
		campaign_list.select(0)
		_show_campaign(0)


func show_error(message: String) -> void:
	error_label.text = message.strip_edges()
	error_label.visible = not error_label.text.is_empty()
	new_campaign_panel.show_error(message)


func set_busy(value: bool) -> void:
	_busy = value
	load_button.disabled = value or campaign_list.get_selected_items().is_empty()
	%NewCampaignButton.disabled = value


func _show_campaign(index: int) -> void:
	if index < 0 or index >= _campaigns.size():
		_clear_details()
		return

	var metadata: Dictionary = _campaigns[index]
	var campaign_id: String = str(metadata.get("campaign_id", ""))
	var save_mode: int = int(metadata.get("save_mode", CampaignState.SaveMode.UNSET))
	campaign_name_label.text = str(
		metadata.get("display_name", campaign_id)
	)
	mode_label.text = "%s · %s" % [_mode_name(save_mode), campaign_id]
	updated_label.text = "Last update: %s" % str(
		metadata.get("updated_at", "unknown")
	)
	checkpoint_select.clear()
	_checkpoints.clear()

	if save_mode == CampaignState.SaveMode.SAFE:
		checkpoint_label.show()
		checkpoint_select.show()
		checkpoint_select.add_item("Latest checkpoint")
		_checkpoints = SaveManager.list_checkpoints(campaign_id)

		for checkpoint: Dictionary in _checkpoints:
			checkpoint_select.add_item(
				"%s · %s" % [
					str(checkpoint.get("last_checkpoint", "checkpoint")),
					str(checkpoint.get("updated_at", ""))
				]
			)

		mode_notice.text = (
			"[color=#68d6ff]SAFE MODE[/color] keeps historical "
			+ "checkpoints. Loading history replaces the active runtime "
			+ "with that earlier state."
		)
	else:
		checkpoint_label.hide()
		checkpoint_select.hide()
		mode_notice.text = (
			"[color=#ff7068]COMMIT MODE[/color] exposes only the living "
			+ "record. The technical recovery backup is never offered as "
			+ "player rollback."
		)

	load_button.disabled = _busy


func _clear_details() -> void:
	campaign_name_label.text = "NO CAMPAIGN SELECTED"
	mode_label.text = ""
	updated_label.text = ""
	checkpoint_label.hide()
	checkpoint_select.hide()
	mode_notice.text = "Create a campaign to initialize KubuOS."
	load_button.disabled = true


func _on_campaign_selected(index: int) -> void:
	show_error("")
	_show_campaign(index)


func _on_load_pressed() -> void:
	if _busy:
		return

	var selected := campaign_list.get_selected_items()

	if selected.is_empty():
		return

	var index: int = selected[0]
	var metadata: Dictionary = _campaigns[index]
	var checkpoint_file_id: String = ""

	if (
		int(metadata.get("save_mode", CampaignState.SaveMode.UNSET))
		== CampaignState.SaveMode.SAFE
		and checkpoint_select.selected > 0
	):
		checkpoint_file_id = str(
			_checkpoints[checkpoint_select.selected - 1].get(
				"checkpoint_file_id",
				""
			)
		)

	campaign_load_requested.emit(
		str(metadata.get("campaign_id", "")),
		checkpoint_file_id
	)


func _on_create_requested(
	campaign_id: String,
	display_name: String,
	save_mode: CampaignState.SaveMode
) -> void:
	campaign_create_requested.emit(campaign_id, display_name, save_mode)


func _open_new_campaign() -> void:
	modal_shade.show()
	new_campaign_panel.open()


func _close_new_campaign() -> void:
	modal_shade.hide()


func _mode_name(save_mode: int) -> String:
	return "COMMIT" if save_mode == CampaignState.SaveMode.COMMIT else "SAFE"
