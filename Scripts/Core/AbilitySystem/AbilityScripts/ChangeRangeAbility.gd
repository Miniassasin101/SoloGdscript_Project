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
	
	if not target_unit:
		push_error("ChangeRangeAbility: Missing target unit.")
		end_ability(event)
		return

	var engagement = CombatSystem.instance.engagement_system.get_engagement(unit, target_unit)
	if not engagement:
		push_error("ChangeRangeAbility: No engagement found.")
		end_ability(event)
		return

	# Validate the chosen target position.
	if not can_activate(event):
		push_error("ChangeRangeAbility: Target grid position is invalid.")
		end_ability(event)
		return

	# 2) Build list of alternate reaches
	var alt_reaches: Array[int] = []
	for w in unit.get_equipped_weapons():
		if w and w.reach != engagement.reach:
			alt_reaches.append(w.reach)

	if alt_reaches.is_empty():
		# no weapon at a different reach → can't use
		Utilities.spawn_text_line(unit, "No alternate reach", Color.GRAY)
		end_ability(event)
		return

	# 3) Spend AP up front (you could alternatively charge after choice)
	if not unit.can_spend_ability_points_to_use_ability(self):
		Utilities.spawn_text_line(unit, "No AP", Color.GOLD)
		return end_ability(event)
	unit.spend_ability_points(ap_cost)

	# Fetch an existing DynamicButtonPicker in the scene tree.
	var dynamic_picker: DynamicButtonPicker = UILayer.instance.unit_action_system_ui.dynamic_button_picker
	if dynamic_picker == null:
		push_error("No DynamicButtonPicker in scene. Please instance or reference it properly.")
		return


	# 4) If more than one choice, pop up
	var chosen_reach: int
	if alt_reaches.size() > 1:
		var labels: Array[String] = []
		for r in alt_reaches:
			labels.append(_reach_label(r))
		var picker: DynamicButtonPicker = UILayer.instance.unit_action_system_ui.dynamic_button_picker
		picker.pick_options(labels)
		var picked: String = await picker.option_selected
		if picked == "":
			# canceled
			return end_ability(event)
		chosen_reach = alt_reaches[ labels.find(picked) ]
	else:
		chosen_reach = alt_reaches[0]


	# Perform an opposed evade roll against the opponent
	var user_roll = Utilities.roll(100)
	var success = false

	# Loop through each engaged opponent.
	var opponent: Unit = target_unit

		# ----- NEW: Check if the opponent has 0 AP. Automatically fail if so.
	if opponent.get_ability_points() <= 0: # Skip dynamic picker prompt if AP is insufficient.
		Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
		engagement.force_reach(chosen_reach)
		Utilities.spawn_text_line(unit, "Swapped to " + _reach_label(chosen_reach))
		Utilities.spawn_text_line(opponent, "Swapped to " + _reach_label(chosen_reach), Color.FIREBRICK)

		force_end()
		return
	# Small delay to prevent double clicks
	await unit.get_tree().create_timer(0.3).timeout
	
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
			
			# If opponent’s roll is less than than or equal to the user’s roll, block succeeds.
			if opponent_roll <= user_roll:
				Utilities.spawn_text_line(opponent, "Block Successful", Color.AQUA)
				success = true

			else:
				Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
				engagement.force_reach(chosen_reach)
				Utilities.spawn_text_line(unit, "Swapped to " + _reach_label(chosen_reach))
				Utilities.spawn_text_line(opponent, "Swapped to " + _reach_label(chosen_reach), Color.FIREBRICK)

		else:
			# Not enough AP to block; automatically fail the block.
			Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
			Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
			engagement.force_reach(chosen_reach)
			Utilities.spawn_text_line(unit, "Swapped to " + _reach_label(chosen_reach))
			Utilities.spawn_text_line(opponent, "Swapped to " + _reach_label(chosen_reach), Color.FIREBRICK)

	else:  # Opponent chooses "Don't Block"
		# Automatically treat as block failure.
		engagement.force_reach(chosen_reach)
		Utilities.spawn_text_line(unit, "Swapped to " + _reach_label(chosen_reach))
		Utilities.spawn_text_line(opponent, "Swapped to " + _reach_label(chosen_reach), Color.FIREBRICK)

	event.successful = true
	if can_end(event):
		end_ability(event)
		return



func force_end() -> void:
	event.successful = true
	if can_end(event):
		end_ability(event)



		

# Helper to map a Reach enum to display text
func _reach_label(r: int) -> String:
	match r:
		Engagement.Reach.TOUCH:     return "Touch"
		Engagement.Reach.SHORT:     return "Short"
		Engagement.Reach.MEDIUM:    return "Medium"
		Engagement.Reach.LONG:      return "Long"
		Engagement.Reach.VERY_LONG: return "Very Long"
	return "Unknown"



func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false
	# must be engaged
	var es = CombatSystem.instance.engagement_system
	if not es.is_unit_engaged(_event.unit):
		return false
	# must have at least one weapon whose reach differs
	for w in _event.unit.get_equipped_weapons():
		var eng = es.get_engagement(_event.unit, LevelGrid.get_unit_at_grid_position(_event.target_grid_position))
		if w and eng and w.reach != eng.reach:
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
