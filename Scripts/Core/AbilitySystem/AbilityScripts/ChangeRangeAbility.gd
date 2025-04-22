@tool
class_name ChangeRangeAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference


@export_group("Attributes")
@export var ap_cost: int = 1



var event: ActivationEvent = null
var unit: Unit = null
var target_unit: Unit = null

func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	unit = event.unit

	if not unit or not event.target_grid_position:
		push_error("ChangeRangeAbility: Missing unit or target grid position.")
		end_ability(event)
		return
	
	target_unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)
	
	if !target_unit:
		push_error("ChangeRangeAbility: Missing target unit.")
		end_ability(event)
		return

	# Validate the chosen target position.
	if not can_activate(event):
		push_error("ChangeRangeAbility: Target grid position is invalid.")
		end_ability(event)
		return

	# Fetch an existing DynamicButtonPicker in the scene tree.
	var dynamic_picker: DynamicButtonPicker = UILayer.instance.unit_action_system_ui.dynamic_button_picker
	if dynamic_picker == null:
		push_error("No DynamicButtonPicker in scene. Please instance or reference it properly.")
		return

	# Perform opposed rolls against each engaged opponent.
	var user_roll = Utilities.roll(100)
	var success = false

	# Loop through each engaged opponent.
	var opponent: Unit = target_unit

		# ----- NEW: Check if the opponent has 0 AP. Automatically fail if so.
	if opponent.get_ability_points() <= 0:

		Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
		
		on_block_fail()
		# Skip dynamic picker prompt if AP is insufficient.
		force_end()
		return

	# Prompt the opponent for block decision.
	dynamic_picker.pick_options(["Block", "Don't Block"])
	GridSystemVisual.instance.hide_all_grid_positions() 
	GridSystemVisual.instance.show_grid_positions([opponent.get_grid_position()])
	var choice: String = await dynamic_picker.option_selected

	if choice == "Block":
		# Opponent has opted to block; they must spend 1 AP.
		if opponent.can_spend_ability_points_to_use_ability(self):
			opponent.spend_ability_points(ap_cost)
			var opponent_roll = Utilities.roll(100)
			print_debug("Change Range: " + unit.ui_name + " rolled " + str(user_roll) + " vs. " + opponent.ui_name + " rolled " + str(opponent_roll))
			
			# If opponent’s roll is greater than or equal to the user’s roll, block succeeds.
			if opponent_roll <= user_roll:
				Utilities.spawn_text_line(opponent, "Block Successful", Color.AQUA)
				success = true

			else:
				Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
				
				on_block_fail()

		else:
			# Not enough AP to block; automatically fail the block.
			Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
			on_block_fail()

	else:  # Opponent chooses "Don't Block"
		# Automatically treat as block failure.
		on_block_fail()


	event.successful = true
	if can_end(event):
		end_ability(event)
		return



func force_end() -> void:
	event.successful = true
	if can_end(event):
		end_ability(event)


func on_block_fail() -> void:
	var engagement: Engagement = CombatSystem.instance.engagement_system.get_engagement(unit, target_unit)
	if engagement.reach_state == Engagement.ReachState.LONG:
		engagement.force_shorter_reach()
	elif engagement.reach_state == Engagement.ReachState.SHORT:
		engagement.force_longer_reach()
	else:
		push_error("Reach is neither long or short")





func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false
	
	var engagement_system: EngagementSystem = CombatSystem.instance.engagement_system
	
	if !engagement_system.is_unit_engaged(_event.unit):
		return false
	
	if !any_engagement_at_different_range(_event, engagement_system):
		return false
	

	
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			return true
	return false

func any_engagement_at_different_range(_event: ActivationEvent, engagement_system: EngagementSystem) -> bool:
	for engagement in engagement_system.get_engagements(_event.unit):
		if engagement.reach_state == engagement.ReachState.LONG or \
		engagement.reach_state == engagement.ReachState.SHORT:
			return true
	return false


func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []

	# We'll check squares in a small range around the user.
	for x in range(-1, 2):
		for z in range(-1, 2):

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
			



			valid_grid_position_list.append(candidate_position)

	return valid_grid_position_list
