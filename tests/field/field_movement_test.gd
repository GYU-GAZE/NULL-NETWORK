extends NavigatorTestHarness

func run() -> void:
	prepare_campaign("field_physics")
	var location := ContentRegistry.get_location("akihabara")
	var area := location.local_area.area_scene.instantiate() as NavigatorLocalAreaScene
	add_child(area)
	area.setup_local_area(location.local_area, "", Vector2.ZERO, false, {}, location)
	check(await until(func() -> bool: return area.field_navigation.ready), "Field navigation geometry did not become ready")
	var actors := area.get_field_exes()
	check(actors.size() >= 2 and actors.size() <= 5, "Akiba is not populated by individual ecological field units")
	var actor := actors[0]
	for other: LocalAreaExeActor in actors:
		other.set_available(other == actor)
	var profile := actor.behavior_profile.duplicate() as FieldBehaviorProfileData
	profile.speed = 170
	profile.acceleration = 800
	profile.minimum_pause = 0.05
	profile.maximum_pause = 0.05
	profile.patrol_offsets = PackedVector2Array([Vector2(240, 0), Vector2.ZERO])
	profile.behavior = FieldBehaviorProfileData.Behavior.PASSIVE
	actor.behavior_profile = profile
	actor.refresh_field_context()
	_place(area, actor, Vector2(860, 540))
	area.player.global_position = area.to_global(Vector2(650, 350))
	area.set_area_active(true)
	var crossed := false
	for frame: int in range(180):
		await get_tree().physics_frame
		var position := area.to_local(actor.global_position)
		check(not Rect2(906, 502, 108, 76).has_point(position), "Field body crossed the actual kiosk collision")
		crossed = crossed or position.x > 1050
	check(crossed, "Patrol never navigated around the production obstacle")
	check(actor.motor is CharacterBody2D and actor.get_node_or_null("PhysicalBody") == null, "Field movement still displaces a StaticBody2D")
	# Physical chase and contact are distinct. Detection alone cannot call combat.
	profile.behavior = FieldBehaviorProfileData.Behavior.AGGRESSIVE
	profile.perception_radius = 220
	profile.maximum_pursuit = 280
	actor.refresh_field_context()
	_place(area, actor, Vector2(650, 700))
	area.player.global_position = area.to_global(Vector2(810, 700))
	var contacts: Array[String] = []
	area.field_contact_requested.connect(func(target: LocalAreaExeActor) -> void: contacts.append(target.field_unit_id))
	await _frames(24)
	check(actor.motor.state == FieldEXEMotor.State.CHASING and actor.global_position.x > 680, "Aggressive EXE did not physically pursue the Player")
	check(contacts.is_empty(), "Perception opened combat before contact")
	await capture("field_chasing")
	await _frames(60)
	check(contacts.size() == 1, "Physical contact did not emit exactly one intent")
	actor.release_call(true)
	await _frames(12)
	check(contacts.size() == 1, "Escape grace immediately reentered aggro")
	# Territorial units return rather than pursuing beyond their authored territory.
	profile.behavior = FieldBehaviorProfileData.Behavior.TERRITORIAL
	profile.territory_radius = 100
	actor.refresh_field_context()
	_place(area, actor, Vector2(650, 700))
	area.player.global_position = area.to_global(Vector2(720, 700))
	await _frames(12)
	check(actor.motor.state == FieldEXEMotor.State.CHASING, "Territorial EXE did not guard its territory")
	area.player.global_position = area.to_global(Vector2(850, 700))
	await _frames(30)
	check(actor.motor.state != FieldEXEMotor.State.CHASING and actor.global_position.distance_to(area.to_global(actor.motor.home)) < 110, "Territorial EXE chased outside its territory")
	# Cautious/cowardly are real retreat, not a sprite-only animation.
	for behavior: int in [FieldBehaviorProfileData.Behavior.CAUTIOUS, FieldBehaviorProfileData.Behavior.COWARDLY]:
		profile.behavior = behavior as FieldBehaviorProfileData.Behavior
		actor.refresh_field_context()
		_place(area, actor, Vector2(650, 700))
		area.player.global_position = area.to_global(Vector2(700, 700))
		await _frames(28)
		check(actor.motor.state == FieldEXEMotor.State.FLEEING and actor.global_position.x < 640, "Cautious/cowardly EXE did not retreat physically")
	await capture("field_fleeing")
	# Return home after exceeding leash.
	profile.behavior = FieldBehaviorProfileData.Behavior.AGGRESSIVE
	profile.maximum_pursuit = 90
	actor.refresh_field_context()
	_place(area, actor, Vector2(650, 700))
	actor.motor.global_position = area.to_global(Vector2(820, 700))
	actor.global_position = actor.motor.global_position
	area.player.global_position = area.to_global(Vector2(1000, 700))
	await _frames(55)
	check(actor.global_position.distance_to(area.to_global(actor.motor.home)) < 80, "EXE did not physically return within its leash")
	var position := actor.global_position
	area.set_area_active(false)
	await _frames(15)
	check(actor.global_position == position, "Inactive Navigator did not pause field physics")
	# Real DialogueManager also pauses an otherwise active field.
	area.set_area_active(true)
	DialogueManager.start_dialogue("npc.ganbarekun.field_meeting")
	await _frames(15)
	check(actor.global_position == position, "Dialogue did not pause field movement")
	DialogueManager.reset_save_data()
	var state := actor.get_persistent_state()
	area.set_area_active(false)
	actor.motor.global_position += Vector2(100, 0)
	actor.apply_persistent_state(state)
	check(actor.global_position.is_equal_approx(position), "Field position was not restored from the population descriptor")
	check(actor.motor.to_data().rng == state.field_motion.rng, "Restoring field motion changed its deterministic RNG")
	area.queue_free()
	await get_tree().process_frame
	finish("FIELD_MOVEMENT_TEST")

func _frames(amount: int) -> void:
	for _frame: int in range(amount):
		await get_tree().physics_frame

func _place(area: NavigatorLocalAreaScene, actor: LocalAreaExeActor, point: Vector2) -> void:
	actor.global_position = area.to_global(point)
	actor.motor.global_position = actor.global_position
	actor.motor.home = point
	actor.motor.destination = point
	actor.motor.state = FieldEXEMotor.State.IDLE
	actor.motor.grace_seconds = 0
	actor.motor.needs_separation = false
	actor.motor._returning = false
	actor.motor._perception_left = 0
	actor.motor._path_left = 0
	actor.motor._pause_left = 0
	actor.motor.velocity = Vector2.ZERO
	actor._contact_queued = false
