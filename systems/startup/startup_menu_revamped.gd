extends "res://systems/startup/startup_menu.gd"
class_name RevampedStartupMenu

## Presentation-only refinement for the startup menu. StartupMenu remains the
## authoritative owner of campaign/profile state; this subclass only changes
## how the already-existing surfaces are staged and revealed.

const SURFACE_ENTER_SECONDS: float = 0.16
const CONTENT_ENTER_SECONDS: float = 0.11
const PROFILE_ENTER_SECONDS: float = 0.10
const PROFILE_STAGGER_SECONDS: float = 0.028
const MODE_OPTION_ENTER_SECONDS: float = 0.10
const MODE_OPTION_STAGGER_SECONDS: float = 0.035


func _reveal_main_controls() -> void:
	account_surface.hide()
	user_panel.hide()
	_prepare_profile_entry_reveal_state()

	account_surface.pivot_offset = account_surface.size * 0.5
	motion_player.enter_scaled_control(
		account_surface,
		Vector2(0.985, 0.985),
		Vector2(8, 0),
		SURFACE_ENTER_SECONDS
	)
	await get_tree().create_timer(0.035).timeout

	user_panel.pivot_offset = user_panel.size * 0.5
	await motion_player.enter_scaled_control(
		user_panel,
		Vector2(0.995, 0.995),
		Vector2.ZERO,
		CONTENT_ENTER_SECONDS
	)
	await _reveal_profile_entries()


func _show_new_user_modes() -> void:
	if not _input_enabled or _busy or _surface_transitioning:
		return

	_surface_transitioning = true
	_set_user_entries_enabled(false)
	_set_mode_options_enabled(false)
	show_error("")
	_clear_profile_selection()
	_selected_mode = CampaignState.SaveMode.UNSET
	back_button.disabled = true

	for option: StartupModeOption in _get_mode_options():
		option.reset_immediately()
		option.modulate.a = 0.0
		option.scale = Vector2.ONE

	var header_controls: Array[Control] = [
		back_button,
		new_user_title,
		mode_hint,
	]
	for control: Control in header_controls:
		control.modulate.a = 0.0
		control.scale = Vector2.ONE

	mode_scroll.scroll_vertical = 0
	await motion_player.transition_between(user_panel, mode_panel, true)

	# Header elements settle first, then the two save-mode cards arrive as one
	# compact decision block. enter_scaled_control is intentionally used here:
	# mode cards are Container-managed children and their layout position must
	# remain owned by the VBoxContainer.
	motion_player.enter_scaled_control(
		back_button,
		Vector2(0.94, 0.94),
		Vector2.ZERO,
		0.09
	)
	motion_player.enter_scaled_control(
		new_user_title,
		Vector2(0.985, 0.985),
		Vector2.ZERO,
		0.10
	)
	await get_tree().create_timer(0.025).timeout
	await motion_player.enter_scaled_control(
		mode_hint,
		Vector2(0.99, 0.99),
		Vector2.ZERO,
		0.08
	)

	for option: StartupModeOption in _get_mode_options():
		option.pivot_offset = option.size * 0.5
		motion_player.enter_scaled_control(
			option,
			Vector2(0.985, 0.985),
			Vector2.ZERO,
			MODE_OPTION_ENTER_SECONDS
		)
		await get_tree().create_timer(MODE_OPTION_STAGGER_SECONDS).timeout

	await get_tree().create_timer(MODE_OPTION_ENTER_SECONDS).timeout
	_surface_transitioning = false
	_set_mode_options_enabled(true)
	back_button.disabled = false


func _show_user_list() -> void:
	if _busy or _surface_transitioning:
		return

	_surface_transitioning = true
	_set_mode_options_enabled(false)
	back_button.disabled = true

	_selected_mode = CampaignState.SaveMode.UNSET
	for option: StartupModeOption in _get_mode_options():
		option.reset_immediately()

	_clear_profile_selection()
	show_error("")
	_prepare_profile_entry_reveal_state()
	await motion_player.transition_between(mode_panel, user_panel, false)
	await _reveal_profile_entries()

	_surface_transitioning = false
	_set_user_entries_enabled(true)


func _prepare_profile_entry_reveal_state() -> void:
	for child: Node in profile_list.get_children():
		if child is not StartupUserEntry:
			continue
		var entry := child as StartupUserEntry
		entry.modulate.a = 0.0
		entry.scale = Vector2.ONE


func _reveal_profile_entries() -> void:
	var entries: Array[StartupUserEntry] = []
	for child: Node in profile_list.get_children():
		if child is StartupUserEntry:
			entries.append(child as StartupUserEntry)

	for entry: StartupUserEntry in entries:
		entry.pivot_offset = entry.size * 0.5
		motion_player.enter_scaled_control(
			entry,
			Vector2(0.985, 0.985),
			Vector2.ZERO,
			PROFILE_ENTER_SECONDS
		)
		await get_tree().create_timer(PROFILE_STAGGER_SECONDS).timeout

	if not entries.is_empty():
		await get_tree().create_timer(PROFILE_ENTER_SECONDS).timeout
