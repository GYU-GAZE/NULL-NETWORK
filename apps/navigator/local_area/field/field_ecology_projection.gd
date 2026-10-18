extends Node2D
class_name FieldEcologyProjection

var area: NavigatorLocalAreaScene
var predator: LocalAreaExeActor
var overlay: Control
var status_label: Label
var feedback_label: Label
var _queued: bool = false

func bind(owner_area: NavigatorLocalAreaScene) -> void:
	area = owner_area
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var box := VBoxContainer.new()
	box.position = Vector2(10, 82)
	box.size = Vector2(590, 64)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.7, 1, 0.85))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)
	feedback_label = Label.new()
	feedback_label.add_theme_font_size_override("font_size", 12)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(feedback_label)
	EcologyService.zone_changed.connect(func(zone: String, _species: PackedStringArray, _reason: String) -> void:
		if _zone_id() == zone: queue_refresh())
	EcologyService.predator_changed.connect(queue_refresh)
	EcologyService.feedback_requested.connect(func(zone: String, message: String) -> void:
		if _zone_id() == zone:
			feedback_label.text = message
			queue_refresh())
	queue_refresh()

func attach_hud(hud_root: Control) -> void:
	# The viewport owns world/camera rendering; diegetic text belongs to its
	# containing view, alongside the existing header and interaction prompt.
	overlay.reparent(hud_root, false)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _exit_tree() -> void:
	if is_instance_valid(overlay) and overlay.get_parent() != self:
		overlay.hide()
		overlay.queue_free()

func _zone_id() -> String:
	return area.map_location.ecology_zone.ecology_zone_id if area.map_location != null and area.map_location.ecology_zone != null else ""

func queue_refresh() -> void:
	if not _queued:
		_queued = true
		refresh.call_deferred()

func refresh() -> void:
	_queued = false
	if not is_inside_tree() or area.map_location == null: return
	var zone := area.map_location.ecology_zone
	if zone != null:
		status_label.text = zone.display_name + " // " + EcologyService.status_text(zone)
		if GameState.get_flag("ecology.%s.surveyed" % zone.ecology_zone_id):
			for species: EcologySpeciesData in zone.species:
				status_label.text += "\n%s // %d SIGNATURES // RESONANCE %d" % [species.species_line_id.to_upper(), EcologyService.population(zone.ecology_zone_id, species.species_line_id), EcologyService.resonance(zone.ecology_zone_id, species.species_line_id)]
		var environment := area.get_node_or_null("Environment") as CanvasItem
		if environment == null: environment = area.get_node_or_null("Ground") as CanvasItem
		if environment != null:
			environment.modulate = zone.presentation.collapsed_tint if bool(EcologyService.ensure_zone(zone).get("collapsed", false)) else Color.WHITE
	else: status_label.text = ""
	var state := EcologyService.predator_state()
	var entry := EcologyService.predator_spawn_entry()
	if entry == null or zone == null:
		if is_instance_valid(predator):
			remove_child(predator)
			predator.queue_free()
			predator = null
		return
	if is_instance_valid(predator): return
	predator = (load("res://apps/navigator/local_area/actors/local_area_exe_actor.tscn") as PackedScene).instantiate() as LocalAreaExeActor
	predator.configure_population_actor(str(state.id), entry)
	predator.persistent_ecology_actor_id = str(state.id)
	add_child(predator)
	predator.global_position = area.player.global_position + Vector2(180, 80)
	predator.motor.global_position = predator.global_position
	predator.bind_field(area, hash(str(state.id)))
	var saved: Dictionary = state.get("locations", {}).get(area.map_location.get_display_id(), {})
	if not saved.is_empty(): predator.apply_persistent_state(saved)
	predator.persistent_state_changed.connect(func(_actor: LocalAreaInteractable, _state: Dictionary) -> void: sync_predator())
	area.queue_field_geometry_refresh()
	if zone != null: feedback_label.text = zone.presentation.predator_feedback

func sync_predator() -> void:
	if not is_instance_valid(predator) or not CampaignState.has_campaign() or SaveManager.is_restoring_campaign(): return
	var state: Dictionary = CampaignState.world_state.ecology_route.get("predator", {})
	if str(state.get("id", "")) != predator.persistent_ecology_actor_id or str(state.get("status", "")) != "ACTIVE": return
	var locations: Dictionary = state.get("locations", {})
	locations[area.map_location.get_display_id()] = predator.get_persistent_state()
	state["locations"] = locations

func _process(_delta: float) -> void:
	if overlay != null:
		overlay.visible = area.is_visible_in_tree() and (area._field_active or area.field_calls.presenting) and not CombatManager.is_encounter_active() and not DialogueManager.is_dialogue_active()
