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
@export_category("Special Effects")
@export var special_effects: Array[SpecialEffect]


# NOTE: Maybe add a idle phase for before battle
var current_phase: TurnPhase:
	set(phase):
		current_phase = phase
		SignalBus.on_phase_changed.emit()


func _ready() -> void:
	if instance != null:
		push_error("There's more than one CombatSystem! - " + str(instance))
		queue_free()
		return
	instance = self


# Tracks and handles any over time effects or spells
func book_keeping() -> void:
	# Apply poison, bleed, persistent effects, etc.
	SignalBus.on_book_keeping_ended.emit()



func start_turn(unit: Unit) -> void:
	print_debug("CombatSystem Turn Started: ", unit)
	current_phase = TurnPhase.ACTION_PHASE  # Start with the Action Phase
	#unit_action_system_ui.create_unit_action_buttons()
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



# Pretty much only done by Interrupt Action
func interrupt_turn(_unit: Unit) -> void:
	SignalBus.continue_turn.emit()
	print_debug("Turn Interrupted")



func declare_action(action: Ability, event: ActivationEvent) -> void:
	# Possibly prompt others if they can react to the declaration itself.
	await check_declaration_reaction_queue(action, event)
	print_debug("Action Declared: ", action.ui_name)



func check_declaration_reaction_queue(_action: Ability, _event: ActivationEvent) -> void:
	# This is where you could prompt units who have "hold actions" or special abilities 
	# triggered upon declarations. For now, we assume minimal logic.
	for unit: Unit in declaration_reaction_queue:
		if unit.is_holding:
			interrupt_turn(unit)
			await SignalBus.continue_turn
	# Additional logic can be added here per Mythras optional rules.



func reaction(reacting_unit: Unit, attacking_unit: Unit) -> int:
	# Prompt UI or AI to choose a reaction ability (e.g., a parry, an evade).
	SignalBus.on_player_reaction.emit(reacting_unit)
	var ability: Ability = await SignalBus.reaction_selected
	if ability == null:
		# No valid reaction chosen, treat as no reaction (auto fail)
		return 0

	# Check if the ability can be activated and the unit can spend AP.
	if !ability.can_activate(ActivationEvent.new(reacting_unit.ability_container)):
		push_error("Reaction Could Not Be Activated: " + ability.to_string())
		return 0

	if !reacting_unit.try_spend_ability_points_to_use_ability(ability):
		return 0

	reacting_unit.ability_container.activate_one(ability, attacking_unit.get_grid_position())
	var reacted_ability: Ability = await SignalBus.ability_complete
	if reacted_ability.ui_name == "Dither":
		print_debug(reacting_unit._to_string(), " Dithered")
		return 0


	# After activation, we assume reaction is a skill roll. In Mythras:
	# For example, if parry: skill = combat_skill
	# If evade: skill = evade skill
	var defend_skill_value = reacting_unit.attribute_map.get_attribute_by_name("combat_skill").current_buffed_value
	var defending_roll = Utilities.roll(100)
	print_debug("Defend Skill Value: ", defend_skill_value)
	print_debug("Defend Roll: ", defending_roll)

	var defender_success_level = Utilities.check_success_level(defend_skill_value, defending_roll)
	print_debug("Defender Success Level: ", defender_success_level)
	return defender_success_level


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
	return event
	


func attack_unit(action: Ability, event: ActivationEvent) -> ActivationEvent:
	var weapon: Weapon = event.weapon
	var attacking_unit: Unit = event.character
	var target_unit: Unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)
	event.target_unit = target_unit

	var attacker_combat_skill = event.attribute_map.get_attribute_by_name("combat_skill").current_buffed_value
	var attacker_roll: int = Utilities.roll(100)
	print_debug("Attacker Combat Skill: ", attacker_combat_skill)
	print_debug("Attacker Roll: ", attacker_roll)

	var attacker_success_level: int = Utilities.check_success_level(attacker_combat_skill, attacker_roll)
	print_debug("Attacker Success Level: ", attacker_success_level)
	var ret_event: ActivationEvent = event
	if LevelDebug.instance.attacker_success_debug == true:
		attacker_success_level = 1
	# If attacker fails outright:
	if attacker_success_level <= 0:
		print_debug("Attacker missed.")
		ret_event.miss = true
	ret_event.attacker_success_level = attacker_success_level
	if attacker_success_level == 2:
		ret_event.attacker_critical = true
	elif attacker_success_level == -1:
		ret_event.attacker_fumble = true
	# Show Attacker's marker
	show_success(attacking_unit, attacker_success_level)

	# Attacker succeeded, prompt defender for a reaction
	var defender_success_level: int = 0
	var defender_wants_reaction: bool = true  # Example prompt
	var parry_success: bool = false
	var parrying_weapon_size: int = 0
	var attack_weapon_size = weapon.size if weapon else 0#0 #event.attribute_map.get_attribute_by_name("weapon_size").current_buffed_value

	if defender_wants_reaction:
		defender_success_level = await reaction(target_unit, attacking_unit)
		show_success(target_unit, defender_success_level)

		# If defender wins, determine parry effectiveness
		if defender_success_level >= 1:
			parry_success = true
		if !target_unit.equipment.equipped_items.is_empty():
			parrying_weapon_size = target_unit.equipment.equipped_items.front().size
	
	ret_event.defender_success_level = defender_success_level
	if defender_success_level == 2:
		ret_event.defender_critical = true
	elif defender_success_level == -1:
		ret_event.defender_fumble = true
	
	hide_all_success_level()

	if !defender_wants_reaction:
		return ret_event

	if LevelDebug.instance.parry_fail_debug:
		parry_success = false
	var hit_location: BodyPart = get_hit_location(target_unit)
	if hit_location == null:
		push_error("Error: null hit location on ", target_unit.name)
	ret_event.body_part = hit_location.part_name + "_health"
	if ret_event.miss and parry_success == false:
		return ret_event


	# FIXME: rn on a fail and crit fail a special effect is gotten
	# Determine success differential
	var differential: int = attacker_success_level - defender_success_level
	var abs_dif: int = abs(differential) # shows by how much the success was
	if differential > 0:
		print_debug("Attacker wins. Applying damage. Also prompt special effects")
		ret_event.set_winning_unit(attacking_unit)

		ret_event = await prompt_special_effect_choice(ret_event, abs_dif)
		
		for effect in ret_event.special_effects:
			print(effect.ui_name)
			
		ret_event.rolled_damage = roll_damage(action, ret_event, target_unit, hit_location, parry_success, parrying_weapon_size, attack_weapon_size)

	elif differential == 0:
		print_debug("It's a tie - no special effects.")
		ret_event.rolled_damage = roll_damage(action, ret_event, target_unit, hit_location, parry_success, parrying_weapon_size, attack_weapon_size)

	else:
		print_debug("Defender wins. Prompt Special Effects")
		
		ret_event.set_winning_unit(target_unit)
		ret_event = await prompt_special_effect_choice(ret_event, abs_dif)
		
		ret_event.rolled_damage = roll_damage(action, ret_event, target_unit, hit_location, parry_success, parrying_weapon_size, attack_weapon_size)

	
	return ret_event

func get_parry_level() -> void:
	pass

func get_hit_location(target_unit: Unit) -> BodyPart:
	var ret = target_unit.body.roll_hit_location()
	return ret



# FIXME: 
func roll_damage(ability: Ability, _event: ActivationEvent, _target_unit: Unit, hit_location: BodyPart,  
parry_success: bool, parrying_weapon_size: int, attack_weapon_size: int) -> int:
	# Roll base damage
	var weapon: Weapon = _event.weapon
	var damage_total: int = 0
	if weapon:
		damage_total += Utilities.roll(weapon.die_type, weapon.die_number)
		damage_total += weapon.flat_damage
	else:
		damage_total += Utilities.roll(ability.damage, ability.die_number)
		damage_total += ability.flat_damage

	print_debug("Base damage rolled: ", damage_total)

	# Apply parry reduction based on weapon size comparison
	if parry_success:
		if parrying_weapon_size >= attack_weapon_size:
			print_debug("Parry successful - Full damage blocked by equal or larger weapon.")
			return 0  # Fully blocked
		elif parrying_weapon_size == attack_weapon_size - 1:
			damage_total = ceili(float(damage_total) / 2.0)  # Half damage
			print_debug("Parry successful - Half damage taken (smaller parrying weapon).")
		else:
			print_debug("Parry unsuccessful - Weapon too small to reduce damage.")

	# Apply armor reduction after parry
	#var armor_value = target_unit.attribute_map.get_attribute_by_name("armor").current_buffed_value
	var armor_value = hit_location.armor
	damage_total -= int(armor_value)
	print_debug("Damage after armor reduction: ", damage_total, "\nOn ", hit_location.part_name)

	# Ensure damage does not go negative
	damage_total = max(damage_total, 0)
	print_debug("Final damage dealt: ", damage_total)

	return damage_total


# Helper Functions

# Show the attacker's success level marker
func show_success(in_unit: Unit, success_level: int) -> void:
	var marker_color = get_color_for_success_level(success_level)
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
