@tool
class_name ParryAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

enum WeaponHand {None, Left, Right, Both}

@export_category("Animations")
@export var parry_animation_part_1: Animation
@export var parry_animation_idle: Animation
@export var parry_animation_reset: Animation
@export_category("Attributes")
@export var ap_cost: int = 1
@export_enum("None", "Left", "Right", "Both") var parry_side: int = WeaponHand.None
@export_group("")


var start_timer: float = 0.1
var event: ActivationEvent = null
var unit: Unit = null
var attacker: Unit = null

# NOTE: Logic for which parry animation to use will go here, depends on character and weapon.
# By default will use strike animation.


func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	unit = event.unit
	if not unit:
		if can_end(event):
			push_error("no unit: " + event.to_string())
			end_ability(event)
			return
	
	var animator: UnitAnimator = unit.animator
	
	var current_event: ActivationEvent = CombatSystem.instance.current_event
	
	var engagement_system: EngagementSystem = CombatSystem.instance.engagement_system
	
	var weapon: Weapon = get_weapon_from_ability(unit)
	
	var engagement: Engagement = engagement_system.get_engagement(current_event.unit, unit)
	
	# If defender’s weapon outranges the engagement by ≥2 steps, mark defender_long_reach_at_short
	if engagement.is_fighting_at_shorter_range(weapon):
			event.defender_long_reach_at_short = true
	
	
	if weapon != null:
		parry_animation_part_1 = weapon.parry_animation_part_1
		parry_animation_reset = weapon.parry_animation_part_2
		parry_animation_idle = weapon.parry_animation_idle
		
		current_event.defender_weapon = weapon
	
	Utilities.spawn_text_line(unit, "Parrying with: " + weapon.name)
	
	var animation_mask: int = -1

	if unit.get_equipped_weapons().size() >= 2:
		if weapon.tags.has("right"):
			animation_mask = animator.AnimationMask.LEFT
		elif weapon.tags.has("left"):
			animation_mask = animator.AnimationMask.RIGHT
	else:
		animation_mask = animator.AnimationMask.NONE

	await rotate_unit_towards_target_enemy(event)
	#animator.toggle_slowdown(1.3)

	
	#var mask: int = -1
	#if !unit.get_equipped_weapons().is_empty():
	#	if unit.get_equipped_weapon()
	
	await animator.play_animation_by_name(parry_animation_part_1.resource_name, 0.0, false, animation_mask, false) # Always be careful to wait for the animation to complete
	#animator.toggle_slowdown()
	animator.play_animation_by_name(parry_animation_idle.resource_name, 0.0, false, animation_mask, false)
	
	CombatSystem.instance.determine_defender_facing_penalty()
	var defend_skill_value: int = unit.get_attribute_after_sit_mod("combat_skill")
	var defending_roll: int = Utilities.roll(100)
	

	current_event.defender_roll = defending_roll
	print_debug("Defend Skill Value: ", defend_skill_value)
	print_debug("Defend Roll: ", defending_roll)

	var defender_success_level = Utilities.check_success_level(defend_skill_value, defending_roll)
	current_event.defender_success_level = defender_success_level
	print_debug("Parry Success Level: ", defender_success_level)
	
	if defender_success_level >= 1:
			current_event.parry_successful = true
	
	attacker = current_event.unit
	
	if can_end(event):
		end_ability(event)
	
	await animator.parry_reset
	

	

	
	animator.play_animation_by_name(parry_animation_reset.resource_name, 0.2, false, animation_mask)
	


func get_weapon_from_ability(in_unit: Unit) -> Weapon:
	var eq: Equipment = in_unit.equipment

	match parry_side:
		WeaponHand.Left:
			# try left, then 2-hand
			if eq.get_left_equipped_weapon():
				return eq.get_left_equipped_weapon()
			if eq.get_equipped_weapon() and eq.get_equipped_weapon().hands == 2:
				return eq.get_equipped_weapon()
			return null

		WeaponHand.Right:
			# try right, then 2-hand
			if eq.get_right_equipped_weapon():
				return eq.get_right_equipped_weapon()
			if eq.get_equipped_weapon() and eq.get_equipped_weapon().hands == 2:
				return eq.get_equipped_weapon()
			return null

		WeaponHand.Both:
			# here “Both” just means “any weapon”:
			# prefer a 2-hand, otherwise fall back to left or right
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




func rotate_unit_towards_target_enemy(_event: ActivationEvent) -> void:
	var animator: UnitAnimator = unit.animator
	animator.rotate_unit_towards_target_position(CombatSystem.instance.current_event.unit.get_grid_position())
	await animator.rotation_completed
	
	""" Test Timer
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = 0.5
	event.unit.add_child(timer)
	await timer.timeout
	"""








func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false
	#Add logic here to check to see if the user can parry the attack, given data like:
	#weapon has attacking trait. user is stunned. User is facing the wrong way, ect.
	
	if !can_activate_given_current_event():
		return false
	

	
	if !(_event.target_grid_position in get_valid_ability_target_grid_position_list(_event)):
		return false
	
		# **new**: make sure we actually have a weapon we can parry with
	var parry_weapon: Weapon = get_weapon_from_ability(_event.unit)
	if parry_weapon == null:
		return false

	return true


## Gets a list of valid grid positions for movement.
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	return [_event.unit.get_grid_position()]


func can_activate_given_current_event() -> bool:
	
	var current_event: ActivationEvent = CombatSystem.instance.current_event
	if not current_event:
		return false
	
	var parrying_unit: Unit = current_event.target_unit
	
	if not current_event:
		return false
	var parry_weapon: Weapon = get_weapon_from_ability(parrying_unit)
	if not parry_weapon:
		return false
	
	var engagement_system: EngagementSystem = CombatSystem.instance.engagement_system
	
	var weapon: Weapon = get_weapon_from_ability(parrying_unit)
	
	var engagement: Engagement = engagement_system.get_engagement(current_event.unit, parrying_unit)
	
	if engagement and engagement.is_fighting_at_longer_range(weapon):
		return false
	
	if !weapon.category == "shield" and current_event.weapon.tags.has("ranged"):
		return false
	
	return true


# Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 30
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
