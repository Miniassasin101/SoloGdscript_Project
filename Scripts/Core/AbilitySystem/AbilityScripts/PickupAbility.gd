@tool
class_name PickupAbility
extends Ability

################################################
#             EXPORTED PROPERTIES
################################################
@export var animation: Animation


@export_group("Attributes")
@export var ap_cost: int = 0


################################################
#             INTERNAL VARIABLES
################################################
## Stores the ActivationEvent passed in by the system.
var event: ActivationEvent = null
## The grid position of our chosen target to attack.
var target_position: GridPosition = null
## Reference to the Unit using this ability.
var unit: Unit

var target_item: Item = null



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
	unit = event.unit

	# Verify we have a valid Unit and a valid target position.
	if not unit or not target_position:
		return
	
	var gridobj: GridObject = LevelGrid.grid_system.get_grid_object(target_position)
	target_item = gridobj.get_first_item()
	if !target_item:
		if can_end(event):
			event.successful = true
			end_ability(event)
			return
	
	ObjectManager.instance.equip_item(unit, target_item)
	
	Utilities.spawn_text_line(unit, target_item.name + " Equipped")


	# Optionally end the ability if everything is done.
	if can_end(event):
		event.successful = true
		end_ability(event)




##
# Returns whether the pickup can be performed.
# We check if the target is within 1 tile of the user and meets any other conditions.
##
func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false

	# We get all valid target squares in range, then check if the event target is among them.
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			if item_at_pos_check(_event):
				return true

	return false


##
# Returns an Array of valid grid positions that can be targeted by this melee ability.
# In this example, we check adjacency (range = 1).
##
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []

	# We'll check squares in a small range around the user.
	valid_grid_position_list.append(_event.unit.get_grid_position())
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

func item_at_pos_check(_event: ActivationEvent) -> bool:
	var gridobj: GridObject = LevelGrid.grid_system.get_grid_object(_event.target_grid_position)
	if gridobj.has_any_item():
		return true
	return false
