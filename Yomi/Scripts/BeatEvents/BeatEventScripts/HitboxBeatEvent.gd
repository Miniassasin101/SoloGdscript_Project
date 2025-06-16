class_name HitboxBeatEvent
extends DynamicBeatEvent

@export var hitbox_index: int = 0


var hitbox: CollisionBox = null

func setup_hitboxes_from_state() -> void:
	pass

func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	if !hitbox:
		hitbox = state.get_hitboxes().front()
	
	if !hitbox:
		push_error("State Hitboxes Not Set Up")
		return
	
	if !hitbox.is_active:
		hitbox.activate()
		hitbox.owning_char = state.unit
	
	var colliding_characters: Array[BaseChar] = hitbox.get_colliding_characters()
	
	if !colliding_characters.is_empty():
		var knockback_force: float = get_beat_value_by_name("knockback_force").value
		for cha in colliding_characters:
			var dir_to: Vector3 = state.unit.global_position.direction_to(cha.global_position)
			var p_req : GeneralImpulsePhysicsRequest = GeneralImpulsePhysicsRequest.new(dir_to, knockback_force)
			cha.queue_physics_request(p_req)
			pass
	
	
	
	if state.beat_counter == event_end_beat:
		hitbox.deactivate()
