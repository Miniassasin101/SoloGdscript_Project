class_name SlashMove
extends Move


@export_group("Attributes")
@export var attack_animation: Animation
@export var clash_animation: Animation
@export var attack_range: int = 1
 ## Which hand is using the melee attack
@export_enum("None", "Left", "Right", "Both") var melee_side: int = WeaponHand.None

var rotation_speed: float = 5.0


var event: ActivationEvent = null
var target_position: GridPosition = null
var target_unit: Unit = null
var unit: Unit = null





func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	target_position = event.target_grid_position
	unit = event.unit
	
	
	if not unit or not target_position:
		end_sequence(false)
		return

	target_unit = LevelGrid.get_unit_at_grid_position(target_position)

	event.set_target_unit(target_unit)
	
	# First, declare the action with the CombatSystem.
	await FocusCombatSystem.instance.declare_move_event(event)
	
	# Ensure we can actually activate (check range, line-of-sight, etc.).
	if not await can_activate(event):
		print_debug("Melee attack action thwarted - out of range or invalid target.")
		end_sequence()
		return
	
	
	add_weapon_to_event()
	
	
	unit.animator.rotate_unit_towards_facing(unit.facing, rotation_speed)
	
	event = await FocusCombatSystem.instance.handle_single_target_move_event(event)
	
	
	if can_end(event):
		event.successful = true
		unit.increase_initiative_score(action_speed)
		end_move(event)
	


func add_weapon_to_event() -> void:
	# Automatically grab the same weapon we just validated
	event.weapon = get_weapon_from_ability(unit)


func get_weapon_from_ability(in_unit: Unit) -> Weapon:
	var eq = in_unit.equipment
	match melee_side:
		WeaponHand.Left:
			# First look for a true left-hand weapon,
			# otherwise accept a two-hander.
			if eq.get_left_equipped_weapon():
				return eq.get_left_equipped_weapon()
			if eq.get_equipped_weapon() and eq.get_equipped_weapon().hands == 2:
				return eq.get_equipped_weapon()
			return null

		WeaponHand.Right:
			if eq.get_right_equipped_weapon():
				return eq.get_right_equipped_weapon()
			if eq.get_equipped_weapon() and eq.get_equipped_weapon().hands == 2:
				return eq.get_equipped_weapon()
			return null

		WeaponHand.Both:
			# “Both” = any weapon: prefer 2H, then left, then right
			var two: Weapon = eq.get_equipped_weapon()
			if two and two.hands == 2:
				return two
			if eq.get_left_equipped_weapon():
				return eq.get_left_equipped_weapon()
			if eq.get_right_equipped_weapon():
				return eq.get_right_equipped_weapon()
			return null

		_:
			return null





func end_sequence(move_success: bool = true) -> void:
	if can_end(event):
		event.successful = move_success
		unit.increase_initiative_score(action_speed)
		end_move(event)


func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false

	var valid_grid_position_list: Array[GridPosition] = await get_valid_move_target_grid_position_list(_event)
	for x: GridPosition in valid_grid_position_list:
		if x._equals(_event.target_grid_position):
			return true
	return false



##
# Returns an Array of valid grid positions that can be targeted by this melee move.
# In this example, we check adjacency (range = 1).
##
func get_valid_move_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []

	# We'll check squares in a small range around the user.
	for x in range(-range, range + 1):
		for z in range(-range, range + 1):

			# Build a test position.
			var offset_position = GridPosition.new(x, z)
			var candidate_position = offset_position.add(_event.unit.get_grid_position())

			# Ensure the candidate position is valid in the LevelGrid.
			if not LevelGrid.is_valid_grid_position(candidate_position):
				continue

			# We only care if there's an enemy unit there (or some valid target).
			if not LevelGrid.has_any_unit_on_grid_position(candidate_position):
				continue

			var targ_unit: Unit = LevelGrid.get_unit_at_grid_position(candidate_position)

			# Check if the occupant is an enemy (or at least not on the same 'team').
			if targ_unit.is_enemy == _event.unit.is_enemy:
				# If they're on the same team, skip.
				continue

			_event.set_target_unit(targ_unit)

			#if is_blocked_by_condition(_event):
			#	continue


			valid_grid_position_list.append(candidate_position)

	return valid_grid_position_list
