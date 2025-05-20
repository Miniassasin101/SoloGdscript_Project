class_name EvadeMove
extends Move



@export_category("Attributes") 
@export var dodge_animation: Animation



var event: ActivationEvent = null
var target_position: GridPosition = null
var unit: Unit = null





func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	target_position = event.target_grid_position
	unit = event.unit
	
	
	if not unit or not target_position:
		if can_end(event):
			push_error("EvadeMove: Missing unit or target grid position.")
			end_move(event)
			return


	unit.animator.rotate_unit_towards_facing(unit.facing)
	
	if can_end(event):
		event.successful = true
		unit.increase_initiative_score(action_speed)
		end_move(event)
	



func slowdown() -> void:
	Engine.set_time_scale(0.6)
	unit.animator.flash_white(1.0)
	await unit.get_tree().create_timer(1.7, true, false, true).timeout
	Engine.set_time_scale(1.0)




func determine_roll_result() -> void:
	
	var pool_1_name: String = accuracy[0]
	var pool_2_name: String = accuracy[1]
	
	var dexterity_dice_pool: int = unit.get_attribute_buffed_value_by_name(pool_1_name)
	var evasion_dice_pool: int = unit.get_attribute_buffed_value_by_name(pool_2_name)
	
	var total_dice: int = dexterity_dice_pool + evasion_dice_pool
	
	
	var current_event: ActivationEvent = CombatSystem.instance.current_event
	#current_event.defender_roll = evading_roll
	#print_debug("Evade Skill Value: ", evade_skill_value)
	#print_debug("Evade Roll: ", evading_roll)

	#var defender_success_level: int = Utilities.check_success_level(evade_skill_value, evading_roll)
	#current_event.defender_success_level = defender_success_level
	#print_debug("Evade Success Level: ", defender_success_level)
	if current_event.defender_success_level > current_event.attacker_success_level:
		current_event.miss = true
	elif current_event.attacker_roll > current_event.defender_roll and (current_event.defender_success_level == current_event.attacker_success_level):
		current_event.miss = true

func determine_dodge_anim() -> Animation:
	# Determine which adjacent tile was selected
	#var target_tile: GridPosition = event.target_grid_position
	var dodge_anim: Animation = dodge_animation
	
	
	return dodge_anim





func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false

	var valid_grid_position_list: Array[GridPosition] = get_valid_move_target_grid_position_list(_event)
	for x: GridPosition in valid_grid_position_list:
		if x._equals(_event.target_grid_position):
			return true
	return false



## Gets the tiles the character can move to, filtering out the ones that couldn't be reached.
func get_valid_move_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []
	
	
	valid_grid_position_list.append(_event.unit.get_grid_position())



	return valid_grid_position_list
