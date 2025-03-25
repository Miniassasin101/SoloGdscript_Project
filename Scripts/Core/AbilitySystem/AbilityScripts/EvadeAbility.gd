@tool
class_name EvadeAbility extends Ability


@export_category("Animations")
@export var front_dodge_animation: Animation
@export var back_dodge_animation: Animation
@export var right_dodge_animation: Animation
@export var left_dodge_animation: Animation

@export_group("Attributes")
@export var ap_cost: int = 1

@export var evade_range: int = 1

@export var rotate_speed: float = 10.0  ## Speed for rotating the unit

var event: ActivationEvent = null
var unit: Unit = null



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	unit = event.unit
	if not unit or not event.target_grid_position:
		push_error("EvadeAbility: Missing unit or target grid position.")
		end_ability(event)
		return
	

	

	#push_error("Have not yet implemented evade roll check")
	determine_roll_result()



	var attacker_event: ActivationEvent = CombatSystem.instance.current_event
	
	if can_end(event):
		end_ability(event)
	
	

	
		
	
	await attacker_event.unit.animator.prompt_dodge# or attacker_event.unit.animator.attack_completed
	"""
	if attacker_event.miss:
		#unit.animator.toggle_slowdown(0.4)
		Engine.set_time_scale(0.01)
		unit.animator.flash_white(1.0)
		await unit.get_tree().create_timer(1.7, true, false, true).timeout
		Engine.set_time_scale(1.0)
		#unit.animator.toggle_slowdown(1.0)
	"""
	#await unit.animator.move_and_slide(event.target_grid_position)
	#await unit.animator.rotate_unit_towards_target_position(event.target_grid_position, rotate_speed)
	if attacker_event.miss:
		Utilities.spawn_text_line(unit, "Evaded", Color.AQUA, 1.2)
	await unit.animator.play_animation_by_name(determine_dodge_anim().resource_name, 0.2, true)
	unit.animator.move_and_slide(unit.get_grid_position())


func determine_dodge_anim() -> Animation:
	# Determine which adjacent tile was selected
	var target_tile: GridPosition = event.target_grid_position
	var dodge_animation: Animation
	
	if target_tile == Utilities.get_front_tile(unit):
		dodge_animation = front_dodge_animation
	elif target_tile == Utilities.get_back_tile(unit):
		dodge_animation = back_dodge_animation
	elif target_tile == Utilities.get_right_side_tile(unit):
		dodge_animation = right_dodge_animation
	elif target_tile == Utilities.get_left_side_tile(unit):
		dodge_animation = left_dodge_animation
	else:
		# If the selected tile doesn't match any expected adjacent position,
		# default to the front dodge animation (or handle as needed)
		push_error("EvadeAbility: Target tile does not match an expected adjacent position; defaulting to front dodge.")
		dodge_animation = front_dodge_animation
	
	return dodge_animation



func determine_roll_result() -> void:
	CombatSystem.instance.determine_defender_facing_penalty()
	var evade_skill_value: int = unit.get_attribute_after_sit_mod("evade_skill")
	var evading_roll: int = Utilities.roll(100)
	
	var current_event: ActivationEvent = CombatSystem.instance.current_event
	current_event.defender_roll = evading_roll
	print_debug("Evade Skill Value: ", evade_skill_value)
	print_debug("Evade Roll: ", evading_roll)

	var defender_success_level = Utilities.check_success_level(evade_skill_value, evading_roll)
	current_event.defender_success_level = defender_success_level
	print_debug("Evade Success Level: ", defender_success_level)
	if current_event.attacker_roll < evading_roll:
		current_event.miss = true






func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	if !valid_positions.is_empty():
		return true
	return false



func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []
	if _event.target_unit == null:
		_event.target_unit = _event.unit

	# We'll check squares in a small range around the user.
	for position in Utilities.get_adjacent_tiles_no_diagonal(_event.target_unit):

		# We only care if there's an enemy unit there (or some valid target).
		if LevelGrid.has_any_unit_on_grid_position(position):
			continue

		valid_grid_position_list.append(position)

	return valid_grid_position_list
