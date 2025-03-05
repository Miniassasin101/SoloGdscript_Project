@tool
class_name ReloadAbility extends Ability


@export var animation: Animation
@export_group("Attributes")
@export var ap_cost: int = 1

var event: ActivationEvent = null
var unit: Unit = null



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	unit = event.unit
	if not unit or not event.target_grid_position:
		push_error("BraceAbility: Missing unit or target grid position.")
		end_ability(event)
		return
	
	# Validate the chosen target position.
	if not can_activate(event):
		push_error("BraceAbility: Target grid position is invalid.")
		end_ability(event)
		return
	
	# NOTE: Add an animation here to show that the unit is bracing
	
	await reload()
	
	

	
	if can_end(event):
		event.successful = true
		end_ability(event)



func reload() -> void:
	var target_unit: Unit = event.unit
	
	unit.animator.play_animation_by_name(animation.resource_name)
	
	await unit.animator.event_occured
	#Engine.set_time_scale(0.1)
	var unit_weapon: Weapon = unit.get_equipped_weapon()
	
	var reload_projectile: Node3D = unit_weapon.projectile.instantiate()
	
	unit.right_hand_socket.add_child(reload_projectile)
	reload_projectile.rotate_object_local(Vector3.UP, 90.0)
	
	await unit.animator.event_occured
	
	reload_projectile.reparent(unit)
	
	var projectile_point: Node3D = unit_weapon.item_visual.projectile_point
	
	var tween: Tween = unit.get_tree().create_tween()
	# Move this projectile from its current position to final_pos in travel_time seconds
	tween.tween_property(reload_projectile, "global_position", projectile_point.global_position, 0.3)
	tween.parallel().tween_property(reload_projectile, "global_rotation", projectile_point.global_rotation, 0.3)
	await tween.finished
	reload_projectile.queue_free()
	
	unit_weapon.load_projectile()
	
	#Engine.set_time_scale(1.0)







func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false
	
	var equipped_weapon: Weapon = _event.unit.get_equipped_weapon()
	if !equipped_weapon.tags.has("ranged") or equipped_weapon.is_loaded:
		return false
	
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			return true
	return false



func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var in_unit: Unit = _event.unit
	var valid_positions: Array[GridPosition] = []
	
	valid_positions.append(in_unit.get_grid_position())
	
	return valid_positions

# --- Utility Functions --- 
