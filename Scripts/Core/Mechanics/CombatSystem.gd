class_name CombatSystem
extends Node

signal on_action_phase_start
signal on_movement_phase_start

# Enum for phases of a turn
enum TurnPhase { ACTION_PHASE, MOVEMENT_PHASE }

# Variables
static var instance: CombatSystem = null
var declaration_reaction_queue: Array[Unit] = []
var initiative_order: Array[Unit] = []
@export var marker_visibility_time: float = 1.5
@export_category("References")
@export var unit_action_system_ui: UnitActionSystemUI
@export var book_keeping_system: BookKeepingSystem
@export_category("Special Effects")
@export var special_effects: Array[SpecialEffect]
@export_category("Conditions")
@export var facing_penalty_condition: FacingPenaltyCondition


var engagements: Array[Engagement]

# NOTE: Maybe add a idle phase for before battle
var current_phase: TurnPhase:
	set(phase):
		current_phase = phase
		SignalBus.on_phase_changed.emit()

var current_event: ActivationEvent = null


func _ready() -> void:
	if instance != null:
		push_error("There's more than one CombatSystem! - " + str(instance))
		queue_free()
		return
	instance = self


# Tracks and handles any over time effects or spells
func book_keeping() -> void:
	# Apply poison, bleed, persistent effects, etc.
	book_keeping_system.run_book_keeping_check()
	

	SignalBus.on_book_keeping_ended.emit()



func start_turn(unit: Unit) -> void:
	print_debug("CombatSystem Turn Started: ", unit)
	current_phase = TurnPhase.ACTION_PHASE  # Start with the Action Phase
	
	unit.conditions_manager.apply_conditions_turn_interval()
	
	SignalBus.on_ui_update.emit()
	handle_phase(unit)

func handle_phase(unit: Unit) -> void:
	match current_phase:
		TurnPhase.ACTION_PHASE:
			print_debug("Action Phase for: ", unit)
			on_action_phase_start.emit()
			# Handle the logic for Action Phase
			await SignalBus.next_phase
			# Once complete, transition to Movement Phase
			transition_phase(TurnPhase.MOVEMENT_PHASE, unit)

		TurnPhase.MOVEMENT_PHASE:
			print_debug("Movement Phase for: ", unit)
			on_movement_phase_start.emit()
			await unit_action_system_ui.on_movement_phase_start()
			print_debug("Movement Gait determined")
			unit_action_system_ui.movement_handler() # make await later
			# Handle the logic for Movement Phase
			await SignalBus.end_turn
			# End turn after Movement Phase
			end_turn(unit)



func transition_phase(next_phase: TurnPhase, unit: Unit) -> void:
	current_phase = next_phase
	handle_phase(unit)
	SignalBus.on_ui_update.emit()

func end_turn(unit: Unit) -> void:
	print_debug("Turn Ended for: ", unit)
	unit.animator.rotate_unit_towards_facing()
	#transition_phase(TurnPhase.ACTION_PHASE, TurnSystem.instance.current_unit_turn)
	# Proceed to the next unit in the initiative order or other logic
	#SignalBus.on_turn_ended.emit()


func on_attack_ended(event: ActivationEvent) -> void:
	var units: Array[Unit] = [event.unit, event.target_unit]
	for unit in units:
		unit.conditions_manager.apply_conditions_attack_end_interval()


func generate_engagements() -> void:
	# Clear any previous engagements
	engagements.clear()

	# Retrieve all units from the UnitManager
	var all_units = UnitManager.instance.get_all_units()

	# Iterate through each unique pair of units
	for i in range(all_units.size()):
		for j in range(i + 1, all_units.size()):
			var unit_a = all_units[i]
			var unit_b = all_units[j]

			# Only engage if units are on opposing sides (enemy vs friendly)
			if unit_a.is_enemy == unit_b.is_enemy:
				continue

			# Check if unit_b is adjacent to unit_a using diagonal adjacency
			# (Assuming get_adjacent_tiles_with_diagonal(unit) returns an array of adjacent grid positions)
			var adjacent_tiles = Utilities.get_adjacent_tiles_with_diagonal(unit_a)
			if adjacent_tiles.has(unit_b.grid_position):
				# Create and initialize a new engagement between the two units
				# Only create a new engagement if one doesn't already exist.
				add_engagement(unit_a, unit_b)

# Checks whether an engagement already exists between two units.
func engagement_exists(unit_a: Unit, unit_b: Unit) -> bool:
	for engagement in engagements:
		# Order does not matter; both units must be present.
		if engagement.units.has(unit_a) and engagement.units.has(unit_b):
			return true
	return false

func get_engagement(unit_a: Unit, unit_b: Unit) -> Engagement:
	for engagement in engagements:
		# Order does not matter; both units must be present.
		if engagement.units.has(unit_a) and engagement.units.has(unit_b):
			return engagement
	return null

func get_engaged_opponents(unit: Unit) -> Array[Unit]:
	var ret_array: Array[Unit] = []
	for engagement in CombatSystem.instance.engagements:
		if engagement.units.has(unit):
			for other_unit in engagement.units:
				if other_unit != unit and not ret_array.has(other_unit):
					ret_array.append(other_unit)
	return ret_array

func add_engagement(unit_a: Unit, unit_b: Unit) -> void:
	if not engagement_exists(unit_a, unit_b):
		var new_engagement = Engagement.new(unit_a, unit_b)
		new_engagement.initialize_line(self)
		engagements.append(new_engagement)
	
		Utilities.spawn_text_line(unit_a, "Engaged")
		Utilities.spawn_text_line(unit_b, "Engaged")
		SignalBus.on_ui_update.emit()
		
		#unit_a.animator.look_at_toggle(unit_b.body.get_part_marker("head"))
		#unit_b.animator.look_at_toggle(unit_a.body.get_part_marker("head"))

func remove_engagement(unit_a: Unit, unit_b: Unit) -> void:
	var engagement: Engagement = get_engagement(unit_a, unit_b)
	if engagement:
		engagement.remove_engagement()
		engagements.erase(engagement)
		SignalBus.on_ui_update.emit()
		#unit_a.animator.look_at_toggle()
		#unit_b.animator.look_at_toggle()

func is_unit_engaged(unit: Unit) -> bool:
	for engagement in engagements:
		# Order does not matter; both units must be present.
		if engagement.units.has(unit):
			return true
	return false

# Only updates engagements for the unit that has changed grid position.
func update_engagements_for_unit(changed_unit: Unit) -> void:
	# Determine opposing units.
	var opposing_units: Array[Unit] = []
	if changed_unit.is_enemy:
		opposing_units = UnitManager.instance.get_player_units()
	else:
		opposing_units = UnitManager.instance.get_enemy_units()
	
	# Get all adjacent tiles (including diagonals) for the changed unit.
	var adjacent_tiles = Utilities.get_adjacent_tiles_with_diagonal(changed_unit)
	
	# For each opposing unit, check if they are adjacent.
	for other_unit in opposing_units:
		if adjacent_tiles.has(other_unit.grid_position):
			# Only create a new engagement if one doesn't already exist.
			add_engagement(changed_unit, other_unit)
		else:
			# Only removes an engagement if one already exists
			remove_engagement(changed_unit, other_unit)





# Pretty much only done by Interrupt Action
func interrupt_turn(_unit: Unit) -> void:
	SignalBus.continue_turn.emit()
	print_debug("Turn Interrupted")



func declare_action(action: Ability, event: ActivationEvent) -> void:
	# Possibly prompt others if they can react to the declaration itself.
	await check_declaration_reaction_queue(action, event)

	if event.target_unit:
		# Have the target unit look at the attacker’s head marker.
		event.target_unit.animator.enable_head_look(event.unit.body.get_part_marker("head"))
	print_debug("Action Declared: ", action.ui_name)




func check_declaration_reaction_queue(_action: Ability, _event: ActivationEvent) -> void:
	# This is where you could prompt units who have "hold actions" or special abilities 
	# triggered upon declarations. For now, we assume minimal logic.
	for unit: Unit in declaration_reaction_queue:
		if unit.is_holding:
			interrupt_turn(unit)
			await SignalBus.continue_turn
	# Additional logic can be added here per Mythras optional rules.



func reaction(reacting_unit: Unit, attacking_unit: Unit, ret_event: ActivationEvent):
	
	# Prompt UI or AI to choose a reaction ability (e.g., a parry, an evade).
	SignalBus.on_player_reaction.emit(reacting_unit)
	UnitActionSystem.instance.set_is_reacting()

	var ability: Ability = await SignalBus.ability_complete#await SignalBus.reaction_selected
	
	if ability == null:
		# No valid reaction chosen, treat as no reaction (auto fail)
		push_error("Invalid Reaction Ability on", reacting_unit.ui_name)
		return 
	


	# After activation, we assume reaction is a skill roll. In Mythras:
	# For example, if parry: skill = combat_skill
	# If evade: skill = evade skill
	UnitActionSystem.instance.set_is_reacting(false)
	return


## Prompts the ui for the user to choose their special effects.
## The abs_def is the number of success levels difference there were, determining how many special effects can be chosen.
func prompt_special_effect_choice(event: ActivationEvent, abs_dif: int) -> ActivationEvent:
	#here the ui will be prompted for the user to choose a number of special effects equal to the degree of level of success
	var ret_effects: Array[SpecialEffect] = []
	for effect: SpecialEffect in special_effects:
		if effect.can_activate(event):
			ret_effects.append(effect)
	SignalBus.on_player_special_effect.emit(event.winning_unit, ret_effects, abs_dif)
	var chosen_effects: Array[SpecialEffect] = await UIBus.effects_chosen
	event.special_effects.append_array(chosen_effects)
	for effect in chosen_effects:
		@warning_ignore("redundant_await")
		await effect.on_activated(event)
		if effect.activation_phase == effect.ActivationPhase.Initial and effect.can_apply(event):
			@warning_ignore("redundant_await")
			await effect.apply(event)
	return event
	


func determine_attacker_facing_penalty(event: ActivationEvent) -> void:
	if !event.weapon:
		return
	var penalty_cond: FacingPenaltyCondition = facing_penalty_condition.duplicate()
	if event.weapon.hands == 2: # Logic for all two handed weapons
		var relative: int = Utilities.get_unit_relative_position(event.unit, event.target_unit)
		if relative == Utilities.RelativePosition.FRONT:
			return
		elif (relative == Utilities.RelativePosition.RIGHT_SIDE) or\
		(relative == Utilities.RelativePosition.LEFT_SIDE):
			penalty_cond.situational_modifier = 3 # Hard
			event.unit.conditions_manager.add_condition(penalty_cond) 
			Utilities.spawn_text_line(event.unit, "Side Attack", Color.YELLOW)
			return
		elif relative == Utilities.RelativePosition.BACK:
			# FIXME: Make it change based off if attacker or defender
			penalty_cond.situational_modifier = 5 # Herculean
			event.unit.conditions_manager.add_condition(penalty_cond) 
			Utilities.spawn_text_line(event.unit, "Back Attack", Color.CRIMSON)
			return
	

	elif event.weapon.hands == 1: # Logic for all one handed weapons

		var relative: int = Utilities.get_unit_relative_position(event.unit, event.target_unit)
		if relative == Utilities.RelativePosition.FRONT:
			return
		elif (relative == Utilities.RelativePosition.RIGHT_SIDE):
			if event.weapon.tags.has("left_hand"):
				
				penalty_cond.situational_modifier = 3 # Hard
				event.unit.conditions_manager.add_condition(penalty_cond) 
				Utilities.spawn_text_line(event.unit, "Side Attack", Color.YELLOW)
				return
			return
		
		elif (relative == Utilities.RelativePosition.LEFT_SIDE):
			if event.weapon.tags.has("right_hand"):
				
				penalty_cond.situational_modifier = 3 # Hard
				event.unit.conditions_manager.add_condition(penalty_cond) 
				Utilities.spawn_text_line(event.unit, "Side Attack", Color.YELLOW)
				return
			return
		
		elif relative == Utilities.RelativePosition.BACK:
			# FIXME: Make it change based off if attacker or defender
			penalty_cond.situational_modifier = 5 # Herculean
			event.unit.conditions_manager.add_condition(penalty_cond) 
			Utilities.spawn_text_line(event.unit, "Back Attack", Color.CRIMSON)
			return


func determine_defender_facing_penalty(event: ActivationEvent = current_event) -> void:
	if !event.weapon:
		return
	
	var penalty_cond: FacingPenaltyCondition = facing_penalty_condition.duplicate()
	if event.weapon.hands == 2: # Logic for all two handed weapons
		var relative: int = Utilities.get_unit_relative_position(event.target_unit, event.unit)
		if relative == Utilities.RelativePosition.FRONT:
			return
		
		elif (relative == Utilities.RelativePosition.RIGHT_SIDE) or\
		(relative == Utilities.RelativePosition.LEFT_SIDE):
			penalty_cond.situational_modifier = 3 # Hard
			event.target_unit.conditions_manager.add_condition(penalty_cond) 
			Utilities.spawn_text_line(event.target_unit, "Side Reaction", Color.YELLOW)
			return
		
		elif relative == Utilities.RelativePosition.BACK:
			# FIXME: Make it change based off if attacker or defender
			penalty_cond.situational_modifier = 4 # Formidable
			event.target_unit.conditions_manager.add_condition(penalty_cond)
			Utilities.spawn_text_line(event.unit, "Back Reaction", Color.ORANGE)
			return
	
	# FIXME: Make it so that it checks to see which hand the weapon is equipped in
	elif event.weapon.hands == 1: # Logic for all one handed weapons
		var relative: int = Utilities.get_unit_relative_position(event.target_unit, event.unit)
		if relative == Utilities.RelativePosition.FRONT:
			return
		
		elif relative == Utilities.RelativePosition.RIGHT_SIDE:
			if event.weapon.tags.has("left_hand"):
				penalty_cond.situational_modifier = 3 # Hard
				event.target_unit.conditions_manager.add_condition(penalty_cond) 
				Utilities.spawn_text_line(event.target_unit, "Side Reaction", Color.YELLOW)
				return
			return
		
		elif (relative == Utilities.RelativePosition.LEFT_SIDE):
			if event.weapon.tags.has("right_hand"):
				
				penalty_cond.situational_modifier = 3 # Hard
				event.target_unit.conditions_manager.add_condition(penalty_cond) 
				Utilities.spawn_text_line(event.target_unit, "Side Reaction", Color.YELLOW)
				return
			return
			
		elif relative == Utilities.RelativePosition.BACK:
			penalty_cond.situational_modifier = 4 # Formidable
			event.target_unit.conditions_manager.add_condition(penalty_cond) 
			Utilities.spawn_text_line(event.target_unit, "Back Reaction", Color.ORANGE)
			return
		
		else:
			push_warning("No relative position on ", relative)




func attack_unit(action: Ability, event: ActivationEvent) -> ActivationEvent:
	var weapon: Weapon = event.weapon
	var attacking_unit: Unit = event.unit
	var target_unit: Unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)
	event.target_unit = target_unit
	var ret_event: ActivationEvent = event
	current_event = ret_event


	determine_attacker_facing_penalty(event)
	var attacker_combat_skill = attacking_unit.get_attribute_after_sit_mod("combat_skill")
	var attacker_roll: int = Utilities.roll(100)
	print_debug("Attacker Combat Skill: ", attacker_combat_skill)
	print_debug("Attacker Roll: ", attacker_roll)
	ret_event.attacker_roll = attacker_roll

	var attacker_success_level: int = Utilities.check_success_level(attacker_combat_skill, attacker_roll)
	print_debug("Attacker Success Level: ", attacker_success_level)
	if LevelDebug.instance.attacker_success_debug:
		attacker_success_level = 1
	if LevelDebug.instance.attacker_fail_debug:
		attacker_success_level = 0
	# If attacker fails outright:
	if attacker_success_level <= 0:
		print_debug("Attacker missed.")
		ret_event.miss = true
	ret_event.attacker_success_level = attacker_success_level
	if attacker_success_level == 2:
		ret_event.attacker_critical = true
		Utilities.spawn_text_line(attacking_unit, "Critical!")
		
	elif attacker_success_level == -1:
		ret_event.attacker_fumble = true
		Utilities.spawn_text_line(attacking_unit, "Fumble!", Color.FIREBRICK)
	# Show Attacker's marker
	show_success(attacking_unit, attacker_success_level)

	# If Attacker succeeded, prompt defender for a reaction
	var defender_success_level: int = 0
	var defender_wants_reaction: bool = true  # Example prompt
	var parrying_weapon_size: int = 0
	var attack_weapon_size = weapon.size if weapon else 0

	if defender_wants_reaction:
		await reaction(target_unit, attacking_unit, ret_event)
		defender_success_level = ret_event.defender_success_level
		#defender_success_level = 2
		
		if LevelDebug.instance.parry_fail_debug:
			defender_success_level = 0
	
		if LevelDebug.instance.parry_success_debug:
			defender_success_level = 1
		
		
		show_success(target_unit, defender_success_level)

		# If defender wins, determine parry effectiveness
		#if defender_success_level >= 1:
		#	ret_event.parry_successful = true
		if !target_unit.equipment.equipped_items.is_empty():
			parrying_weapon_size = target_unit.equipment.get_equipped_weapon().size
	
	ret_event.defender_success_level = defender_success_level
	if defender_success_level == 2:
		ret_event.defender_critical = true
		Utilities.spawn_text_line(target_unit, "Critical!")
	elif defender_success_level == -1:
		ret_event.defender_fumble = true
		Utilities.spawn_text_line(target_unit, "Fumble!", Color.FIREBRICK)
	


	if !defender_wants_reaction:
		current_event = null
		return ret_event

	if LevelDebug.instance.parry_fail_debug:
		ret_event.parry_successful = false
	
	if LevelDebug.instance.parry_success_debug:
		ret_event.parry_successful = true
	
	
	
	if ret_event.miss and ret_event.parry_successful == false:
		hide_all_success_level()
		current_event = null
		return ret_event


	# FIXME: rn on a fail and crit fail a special effect is gotten
	# Determine success differential
	var differential: int = attacker_success_level - defender_success_level
	var abs_dif: int = abs(differential) # shows by how much the success was
	if differential > 0:
		print_debug("Attacker wins. Applying damage. Also prompt special effects")
		ret_event.set_winning_unit(attacking_unit)
		ret_event.set_losing_unit(target_unit)
		ret_event = await prompt_special_effect_choice(ret_event, abs_dif)
		
		for effect in ret_event.special_effects:
			print(effect.ui_name)
		
		if !event.bypass_attack:
			setup_hit_location(ret_event)
			
			ret_event.rolled_damage = roll_damage(action, ret_event, target_unit, parrying_weapon_size, attack_weapon_size)

	elif differential == 0:
		print_debug("It's a tie - no special effects.")
		
		if !event.bypass_attack:
			setup_hit_location(ret_event)
			
			ret_event.rolled_damage = roll_damage(action, ret_event, target_unit, parrying_weapon_size, attack_weapon_size)

	else:
		print_debug("Defender wins. Prompt Special Effects")
		
		ret_event.set_winning_unit(target_unit)
		ret_event.set_losing_unit(attacking_unit)
		ret_event = await prompt_special_effect_choice(ret_event, abs_dif)
		
		if !event.bypass_attack:
			setup_hit_location(ret_event)
			
			ret_event.rolled_damage = roll_damage(action, ret_event, target_unit, parrying_weapon_size, attack_weapon_size)

	hide_all_success_level()
	current_event = null
	return ret_event

func get_parry_level() -> void:
	pass

func get_hit_location(target_unit: Unit) -> BodyPart:
	var ret = target_unit.body.roll_hit_location()
	return ret




func roll_damage(ability: Ability, event: ActivationEvent, _target_unit: Unit, 
			parrying_weapon_size: int, attack_weapon_size: int) -> int:
	# Roll base damage
	var weapon: Weapon = event.weapon
	var damage_total: int = 0
	if weapon:
		damage_total = weapon.roll_damage(event.maximize_count)
		event.weapon_damage_before_armor = damage_total
	else:
		damage_total += Utilities.roll(ability.damage, ability.die_number)
		damage_total += ability.flat_damage

	print_debug("Base damage rolled: ", damage_total)

	# Apply parry reduction based on weapon size comparison
	if event.parry_successful:
		if parrying_weapon_size >= attack_weapon_size or (event.enhance_parry):
			print_debug("Parry successful - Full damage blocked by equal or larger weapon.")
			return 0  # Fully blocked
		
		elif parrying_weapon_size == attack_weapon_size - 1:
			damage_total = ceili(damage_total / 2.0)  # Half damage
			print_debug("Parry successful - Half damage taken (smaller parrying weapon).")
		
		else:
			print_debug("Parry unsuccessful - Weapon too small to reduce damage.")

	# Apply armor reduction after parry
	if !event.bypass_armor:
		damage_total = event.body_part.get_damage_after_armor(damage_total)

	print_debug("Damage after armor reduction: ", damage_total, "\nOn ", event.body_part.part_name)

	return damage_total


## Sets the hit location / body part variables on the event.
func setup_hit_location(ret_event: ActivationEvent) -> void:
	if ret_event.body_part:
		return
	var hit_location: BodyPart = get_hit_location(ret_event.target_unit)
	if hit_location == null:
		push_error("Error: null hit location on ", ret_event.target_unit.name)
	ret_event.body_part = hit_location
	ret_event.body_part_health_name = hit_location.part_name + "_health"
	ret_event.body_part_ui_name = hit_location.part_ui_name


# Helper Functions

# Show the attacker's success level marker
func show_success(in_unit: Unit, success_level: int) -> void:
	var marker_color: StringName = get_color_for_success_level(success_level)
	in_unit.set_color_marker(marker_color)  # Emit a signal to show the marker
	in_unit.set_color_marker_visible(true)

func hide_all_success_level() -> void:
	await get_tree().create_timer(marker_visibility_time).timeout
	SignalBus.hide_success.emit()

# Utility to map success levels to colors
func get_color_for_success_level(success_level: int) -> StringName:
	match success_level:
		2: return "blue"   # Critical Success
		1: return "green"  # Success
		0: return "yellow" # Failure/Miss
		-1: return "red"    # Critical Failure
		_: return "white"  # Default color (unexpected value)


func get_current_phase_name() -> String:
	if current_phase == TurnPhase.ACTION_PHASE:
		return "Action"
	else:
		return "Move"
