@tool
class_name ParryAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

@export_category("Animations")
@export var parry_animation_part_1: Animation
@export var parry_animation_idle: Animation
@export var parry_animation_reset: Animation
@export_category("Attributes")
@export var ap_cost: int = 1
@export_group("")



var start_timer: float = 0.1
var event: ActivationEvent = null
var unit: Unit = null

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
	var timer = Timer.new()
	
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = 1.0
	#event.unit.add_child(timer)
	#await timer.timeout
	#await unit.animator.movement_completed
	await rotate_unit_towards_target_enemy(event)
	await animator.play_animation_by_name(parry_animation_part_1.resource_name) # Always be careful to wait for the animation to complete
	animator.play_animation_by_name(parry_animation_idle.resource_name)
	
	if can_end(event):
		end_ability(event)
	await animator.parry_reset
	animator.play_animation_by_name(parry_animation_reset.resource_name)
	



func rotate_unit_towards_target_enemy(_event: ActivationEvent) -> void:
	var animator: UnitAnimator = unit.animator
	animator.rotate_unit_towards_target_position(event.target_grid_position)
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
	
	#var valid_grid_position_list = get_valid_ability_target_grid_position_list(_event)

	return true


## Gets a list of valid grid positions for movement.
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	return []



# Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 30
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
