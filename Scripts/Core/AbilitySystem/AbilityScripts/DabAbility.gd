@tool
class_name DabAbility extends Ability

## A test ability free action that can play any animation it's passed so long as it
## is in the proper library (Currently: "HumanoidAnimLib01")


## Example tooltip comment, put directly above the line(s) they reference
@export var animation: Animation
@export_group("Attributes")
@export var ap_cost: int = 0

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
	""" # Timer code
	# Animation stand-in
	var timer = Timer.new()
	
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = 0.5
	event.unit.add_child(timer)
	"""
	await perform_animation() # Always be careful to wait for the animation to complete


	if can_end(event):
		event.successful = true
		end_ability(event)


func perform_animation() -> void:
	await unit.animator.play_animation_by_name(animation.resource_name)
	return





func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false
	# Should always be able to dither
	var valid_grid_position_list = get_valid_ability_target_grid_position_list(_event)
	for x in valid_grid_position_list:
		if x._equals(_event.target_grid_position):
			return true
	return false



func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var ret: Array[GridPosition] = []
	ret.append(_event.unit.get_grid_position())
	return ret


# Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 0
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
