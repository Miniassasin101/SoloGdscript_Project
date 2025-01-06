@tool
class_name DitherAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

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
	unit = event.character
	if not unit:
		if can_end(event):
			push_error("no unit: " + event.to_string())
			end_ability(event)
			return

	# Animation stand-in
	var timer = Timer.new()
	
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = 0.5
	event.character.add_child(timer)
	await timer.timeout
	# FIXME: add an (await unit.animator.dither flourish animation)

	if can_end(event):
		end_ability(event)







func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false
	# Should always be able to dither

	return true





# Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 0
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
