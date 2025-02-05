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
	var target_unit = LevelGrid.get_unit_at_grid_position(target_position)
	# Verify we have a valid Unit and a valid target position.
	if not unit or not target_position:
		return
	var impaled_condition: ImpaledCondition

	# If the target position is another tile we assume that we are ripping free an impaled weapon
	if !target_position.equals(unit.get_grid_position()):
		if target_unit:
			if target_unit.conditions_manager.has_condition("impaled"):
				impaled_condition = target_unit.conditions_manager.get_condition_by_name("impaled") as ImpaledCondition
				
				# If the target unit is allied then rip, else safely remove.
				if target_unit.is_enemy != unit.is_enemy:
					impaled_condition.rip_free(event.unit, target_unit)
				else:
					impaled_condition.apply(target_unit)


	# If the target position is the user's tile then we check to see if we're removing an
	# impaled weapon from themsleves or picking an item up off of the ground, then doing it.
	else:
		var item_on_ground: bool = LevelGrid.grid_system.get_grid_object(target_position).has_any_item()
		var unit_has_impaled: bool = unit.conditions_manager.has_condition("impaled")
		
		if unit_has_impaled and item_on_ground:
			var result: String = await dynamic_pick_impale_pickup()
			match result:
				"Remove Impale": # Safely removes the impaled weapon
					impaled_condition = target_unit.conditions_manager.get_condition_by_name("impaled") as ImpaledCondition
					impaled_condition.apply(target_unit)

				"Pickup": # Picks up an item from the ground.
					var gridobj: GridObject = LevelGrid.grid_system.get_grid_object(target_position)
					target_item = gridobj.get_first_item()
					ObjectManager.instance.equip_item(unit, target_item)
					Utilities.spawn_text_line(unit, target_item.name + " Equipped")

		# If the unit just wants to remove impaled weapon from themselves
		elif unit_has_impaled and !item_on_ground:
			impaled_condition = target_unit.conditions_manager.get_condition_by_name("impaled") as ImpaledCondition
			impaled_condition.apply(target_unit)

		# If the unit just wants to pick an item off of the ground
		# FIXME: Add a choice of the item to pickup later
		elif !unit_has_impaled and item_on_ground:
			var gridobj: GridObject = LevelGrid.grid_system.get_grid_object(target_position)
			target_item = gridobj.get_first_item()
			ObjectManager.instance.equip_item(unit, target_item)
			Utilities.spawn_text_line(unit, target_item.name + " Equipped")



	if can_end(event):
		event.successful = true
		end_ability(event)





func dynamic_pick_impale_pickup() -> String:
	# Gather possible body-part names
	var impale_pickup: Array[String] = ["Remove Impale", "Pickup"]

	# Fetch an existing DynamicButtonPicker in the scene tree
	var dynamic_picker: DynamicButtonPicker = UILayer.instance.unit_action_system_ui.dynamic_button_picker
	if dynamic_picker == null:
		push_error("No DynamicButtonPicker in scene. Please instance or reference it properly.")
		return ""

	# Show the list of body parts
	dynamic_picker.pick_options(impale_pickup)

	# Wait for user to pick one
	var chosen_name: String = await dynamic_picker.option_selected
	if chosen_name == "":
		push_warning("No location chosen or user cancelled.")
		return ""
	return chosen_name



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
			return true

	return false


##
# Returns an Array of valid grid positions that can be targeted by this melee ability.
# In this example, we check adjacency (range = 1).
##
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []

	# We'll check squares in a small range around the user.
	var unit_pos: GridPosition = _event.unit.get_grid_position()
	if item_at_pos_check_by_pos(unit_pos) or _event.unit.conditions_manager.has_condition("impaled"):
		valid_grid_position_list.append(_event.unit.get_grid_position())
	
	for gridpos in Utilities.get_adjacent_tiles_no_diagonal(_event.unit):
		var in_unit: Unit = LevelGrid.get_unit_at_grid_position(gridpos)
		if in_unit:
			if in_unit.conditions_manager.has_condition("impaled"):
				valid_grid_position_list.append(gridpos)
				
	
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

func item_at_pos_check_by_pos(gridpos: GridPosition) -> bool:
	var gridobj: GridObject = LevelGrid.grid_system.get_grid_object(gridpos)
	if gridobj.has_any_item():
		return true
	return false
