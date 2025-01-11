@tool
class_name MeleeAbility
extends Ability

################################################
#             EXPORTED PROPERTIES
################################################
@export var animation: Animation

@export var hit_vfx: PackedScene

@export_group("Attributes")
## The damage die used. Example: 6 means a six sided die or a "d6".
@export var damage: int = 6
## The number of dice to roll, e.g. 1 for 1d6 or 2 for 2d6 (if you implement dice).
@export var die_number: int = 1
## Any flat damage bonus. For instance, +2 to total damage.
@export var flat_damage: int = 0
## Melee range set to 1, so the target must be adjacent (including diagonals).
@export var attack_range: int = 1
## Action Points cost. 1 means it costs 1 AP to use this ability.
@export var ap_cost: int = 1


################################################
#             INTERNAL VARIABLES
################################################
## Stores the ActivationEvent passed in by the system.
var event: ActivationEvent = null
## The grid position of our chosen target to attack.
var target_position: GridPosition = null
## Reference to the Unit using this melee ability.
var unit: Unit
## Cached damage roll result, if you do dice logic. 
var rolled_damage: int = 0


################################################
#             OVERRIDDEN METHODS
################################################

##
# Called when we try to use/activate this ability.
# This method sets up the action, checks validity, rotates
# the Unit to face the target, and finally triggers the melee attack.
##
func try_activate(_event: ActivationEvent) -> void:
	# Call base logic (handles AP cost checks, etc.).
	super.try_activate(_event)
	
	# Store relevant data from the event.
	event = _event
	target_position = event.target_grid_position
	unit = event.character

	# Verify we have a valid Unit and a valid target position.
	if not unit or not target_position:
		return

	# First, declare the action with the CombatSystem.
	await CombatSystem.instance.declare_action(self, event)

	# Ensure we can actually activate (check range, line-of-sight, etc.).
	if not can_activate(event):
		print_debug("Melee attack action thwarted - out of range or invalid target.")
		return

	
	add_weapon_to_event()
	
	# Rotate the Unit to face the target, then continue the action (attack).
	rotate_unit_towards_target_enemy(event)


##
# Returns whether the melee attack can be performed.
# We check if the target is within 1 tile of the user and meets any other conditions.
##
func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false

	# We get all valid target squares in range, then check if the event target is among them.
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			return true
	return false


##
# Returns an Array of valid grid positions that can be targeted by this melee ability.
# In this example, we check adjacency (range = 1).
##
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []

	# We'll check squares in a small range around the user.
	for x in range(-attack_range, attack_range + 1):
		for z in range(-attack_range, attack_range + 1):

			# Build a test position.
			var offset_position = GridPosition.new(x, z)
			var candidate_position = _event.character.get_grid_position().add(offset_position)

			# Ensure the candidate position is valid in the LevelGrid.
			if not LevelGrid.is_valid_grid_position(candidate_position):
				continue

			# We only care if there's an enemy unit there (or some valid target).
			if not LevelGrid.has_any_unit_on_grid_position(candidate_position):
				continue

			# Check if the occupant is an enemy (or at least not on the same 'team').
			var target_unit = LevelGrid.get_unit_at_grid_position(candidate_position)
			if target_unit.is_enemy == _event.character.is_enemy:
				# If they're on the same team, skip.
				continue

			valid_grid_position_list.append(candidate_position)

	return valid_grid_position_list


##
# Called by the system once the ability has completed all logic
# and the ability can be cleaned up. Here, we just call the base method.
##
func end_ability(_event: ActivationEvent) -> void:
	super.end_ability(_event)


##
# Optionally used by the AI to rank this ability. You can keep or modify.
##
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 1000
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability


################################################
#             HELPER METHODS
################################################

# FIXME: Add a prompt if there is more than one weapon equipped
func add_weapon_to_event() -> void:
	
	for item: Item in unit.equipment.equipped_items:
		event.weapon = item
		return
	


##
# Rotates the user to face the target.
# After rotation, we call melee_attack_anim() to perform the strike.
##
func rotate_unit_towards_target_enemy(_event: ActivationEvent) -> void:
	var animator: UnitAnimator = unit.animator
	# Rotate the unit to face the target's grid position.
	animator.rotate_unit_towards_target_position(_event.target_grid_position)

	# Wait for rotation to complete, then proceed with the melee animation.
	await animator.rotation_completed
	
	
	event = await CombatSystem.instance.attack_unit(self, event)


	# Perform the actual swing animation.
	melee_attack_anim()


##
# Triggers the melee attack animation on UnitAnimator.
# Once the animation "hits," we apply effect/damage. 
# This function is the heart of the melee sequence.
##
func melee_attack_anim() -> void:


	# 1) If your animator signals when the attack hits or finishes,
	#    you can "await" that signal here. For example:
	await unit.animator.melee_attack_anim(animation, event.miss)

	# 2) Here you can trigger any hit fx on the ability by passing it to the target unit's animator:
	var target_unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)
	if !event.miss:
		target_unit.animator.trigger_hit_fx(hit_vfx, unit.get_global_rotation())

	# 3) Now that the animation is presumably done or at the hit frame, apply damage.
	apply_effect()
	# 4) Optionally end the ability if everything is done.
	if can_end(event):
		event.successful = true
		end_ability(event)


##
# Applies the damage effect to the target unit at target_position.
# This is the "on-hit" portion of the melee attack.
##
func apply_effect() -> void:
	if event.miss:
		return
	# Create a new GameplayEffect resource
	var effect = GameplayEffect.new()

	# Prepare an AttributeEffect for health
	var health_effect = AttributeEffect.new()
	health_effect.attribute_name = "health"
	health_effect.minimum_value = -event.rolled_damage
	health_effect.maximum_value = -event.rolled_damage

	# Optionally, if you want to apply damage to a specific body part
	var part_effect = AttributeEffect.new()
	part_effect.attribute_name = event.body_part
	part_effect.minimum_value = -event.rolled_damage
	part_effect.maximum_value = -event.rolled_damage

	effect.attributes_affected.append(health_effect)
	effect.attributes_affected.append(part_effect)

	# Get the target unit from the grid and attach the effect
	var target_unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)
	if target_unit:
		target_unit.add_child(effect)
