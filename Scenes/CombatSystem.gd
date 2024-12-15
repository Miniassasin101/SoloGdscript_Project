class_name CombatSystem
extends Node
"""
Manages and resolves combat interactions/reactions/disputes globally. 
Also deals with the combat flow in any individual turn.
"""
static var instance: CombatSystem = null

var declaration_reaction_queue: Array[Unit] = []

func _ready() -> void:
	if instance != null:
		push_error("There's more than one CombatSystem! - " + str(instance))
		queue_free()
		return
	instance = self

## Here things like poison, bleed, peristent effects, cost for energy draining abilities, ect. goes off.
func book_keeping() -> void:
	#placeholder
	SignalBus.on_book_keeping_ended.emit()


# NOTE: Later add functionality to take multiple units turns at once or in any order if same team
func start_turn(unit: Unit) -> void:
	print_debug("CombatSystem Turn Started: ", unit)

func interrupt_turn(unit: Unit) -> void:
	# Call interrupt turn on turn_system
	SignalBus.continue_turn.emit()
	print_debug("Turn Interrupted")

func declare_action(action: Ability, event: ActivationEvent) -> void:
	await check_declaration_reaction_queue(action, event)
	
	print("Action Declared")
	

func check_declaration_reaction_queue(action: Ability, event: ActivationEvent) -> void:
	# Sort reaction queue
	for unit: Unit in declaration_reaction_queue:
		#Prompt if the unit wants to use their reaction
		if unit.is_holding:
			interrupt_turn(unit)
			await SignalBus.continue_turn
		pass
	# NOTE: Add functionality here to check to see if the defending unit's combat skill is over 100%.
	#trigger a reaction prompt if so.
	# Store variable of the current unit's turn?
	#if action.has_some_tags(action.tags_type, ["attack"]):

func attack_unit(action: Ability, event: ActivationEvent) -> int:
	# NOTE: Check for any modifiers to difficulty grade like fog or injured limbs here.
	var attacking_unit: Unit = event.character
	var target_unit: Unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)

	# NOTE: Later change static combat skill check with magic check.
	var attacking_unit_roll: int = AbilityUtils.roll(100)
	print_debug("Attacking unit Roll: ", attacking_unit_roll)
	var defending_unit_roll: int = AbilityUtils.roll(100)
	var attacker_combat_skill = event.attribute_map.get_attribute_by_name("combat_skill").current_buffed_value
	var defender_combat_skill = target_unit.attribute_map.get_attribute_by_name("combat_skill").current_buffed_value

	# NOTE: Should probably move some of this logic into an opposed roll method in ability utilities
	var attacker_success_level: int = AbilityUtils.check_success_level(attacker_combat_skill, attacking_unit_roll)
	var defender_success_level: int = AbilityUtils.check_success_level(defender_combat_skill, defending_unit_roll)
	var winning_unit: Unit = null
	var differential: int = attacker_success_level - defender_success_level
	if differential >= 1:
		winning_unit = attacking_unit
	elif differential == 0:
		print_debug("Its a tie")
	else:
		winning_unit = target_unit
	
	# FIXME: Prompt winning unit for special effects here
	if winning_unit != null:
		print_debug("Winner is: ", winning_unit, "With a success level of: ", absi(differential))
	var damage: int = roll_damage(action, event, target_unit)
	#Maybe move the following logic onto the abilities?:
	#also add hit location logic here later possibly
	return damage


# var damage is the damage die: Ex: 6 is a d6
# var die_number is the number of those die: Ex: 2d6 or 4d8
# var flat_damage is the bonus damage added: Ex: 1d6 + 1 or 3d8 + 5
#also pass in any special effects chosen to determine damage
func roll_damage(ability: Ability, event: ActivationEvent, target_unit: Unit) -> int:
	#Check Damage type for resistances
	#Check any modifications from special effects, buffs, ect.
	#Check any hidden biases in player's favor for game feel
	var damage_total: int = 0
	damage_total += AbilityUtils.roll(ability.damage, ability.die_number)
	damage_total += ability.flat_damage
	damage_total -= target_unit.attribute_map.get_attribute_by_name("armor").current_buffed_value
	return damage_total
	
	
	
