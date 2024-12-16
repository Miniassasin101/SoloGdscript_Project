class_name CombatSystem
extends Node

static var instance: CombatSystem = null
var declaration_reaction_queue: Array[Unit] = []
var initiative_order: Array[Unit] = []

func _ready() -> void:
	if instance != null:
		push_error("There's more than one CombatSystem! - " + str(instance))
		queue_free()
		return
	instance = self

func book_keeping() -> void:
	# Apply poison, bleed, persistent effects, etc.
	SignalBus.on_book_keeping_ended.emit()

func start_turn(unit: Unit) -> void:
	print_debug("CombatSystem Turn Started: ", unit)

func interrupt_turn(unit: Unit) -> void:
	SignalBus.continue_turn.emit()
	print_debug("Turn Interrupted")

func declare_action(action: Ability, event: ActivationEvent) -> void:
	# Possibly prompt others if they can react to the declaration itself.
	await check_declaration_reaction_queue(action, event)
	print("Action Declared")

func check_declaration_reaction_queue(action: Ability, event: ActivationEvent) -> void:
	# This is where you could prompt units who have "hold actions" or special abilities 
	# triggered upon declarations. For now, we assume minimal logic.
	for unit: Unit in declaration_reaction_queue:
		if unit.is_holding:
			interrupt_turn(unit)
			await SignalBus.continue_turn
	# Additional logic can be added here per Mythras optional rules.

func reaction(reacting_unit: Unit) -> int:
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

	reacting_unit.ability_container.activate_one(ability)
	await SignalBus.ability_complete

	# After activation, we assume reaction is a skill roll. In Mythras:
	# For example, if parry: skill = combat_skill
	# If evade: skill = evade skill
	var defend_skill_value = reacting_unit.attribute_map.get_attribute_by_name("combat_skill").current_buffed_value
	var defending_roll = AbilityUtils.roll(100)

	var defender_success_level = AbilityUtils.check_success_level(defend_skill_value, defending_roll)
	return defender_success_level

func attack_unit(action: Ability, event: ActivationEvent) -> int:
	var attacking_unit: Unit = event.character
	var target_unit: Unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)

	var attacker_combat_skill = event.attribute_map.get_attribute_by_name("combat_skill").current_buffed_value
	var attacker_roll: int = AbilityUtils.roll(100)
	print_debug("Attacker Roll: ", attacker_roll)

	var attacker_success_level: int = AbilityUtils.check_success_level(attacker_combat_skill, attacker_roll)
	if LevelDebug.instance.attacker_success_debug == true:
		attacker_success_level = 1

	# If attacker fails outright:
	if attacker_success_level <= 0:
		print_debug("Attacker failed, no reaction needed.")
		return 0

	# Attacker succeeded, prompt defender for a reaction
	var defender_success_level: int = 0
	var defender_wants_reaction = true  # Example prompt
	var parry_success = false
	var parrying_weapon_size = 0
	var attack_weapon_size = 0 #event.attribute_map.get_attribute_by_name("weapon_size").current_buffed_value

	if defender_wants_reaction:
		defender_success_level = await reaction(target_unit)

		# If defender wins, determine parry effectiveness
		if defender_success_level >= attacker_success_level:
			parry_success = true
			parrying_weapon_size = 0#target_unit.attribute_map.get_attribute_by_name("weapon_size").current_buffed_value

	# Determine success differential
	var differential: int = attacker_success_level - defender_success_level
	if differential > 0:
		print_debug("Attacker wins. Applying damage. Also prompt special effects")
		var damage: int = roll_damage(action, event, target_unit, parry_success, parrying_weapon_size, attack_weapon_size)
		return damage
	elif differential == 0:
		print_debug("It's a tie - no special effects.")
		var damage: int = roll_damage(action, event, target_unit, parry_success, parrying_weapon_size, attack_weapon_size)
		return damage
	else:
		print_debug("Defender wins. Prompt Special Effects")
		var damage: int = roll_damage(action, event, target_unit, parry_success, parrying_weapon_size, attack_weapon_size)
		return damage


# FIXME: 
func roll_damage(ability: Ability, event: ActivationEvent, target_unit: Unit, parry_success: bool, parrying_weapon_size: int, attack_weapon_size: int) -> int:
	# Roll base damage
	var damage_total: int = 0
	damage_total += AbilityUtils.roll(ability.damage, ability.die_number)
	damage_total += ability.flat_damage

	print_debug("Base damage rolled: ", damage_total)

	# Apply parry reduction based on weapon size comparison
	if parry_success:
		if parrying_weapon_size >= attack_weapon_size:
			print_debug("Parry successful - Full damage blocked by equal or larger weapon.")
			return 0  # Fully blocked
		elif parrying_weapon_size == attack_weapon_size - 1:
			damage_total = ceili(damage_total / 2)  # Half damage
			print_debug("Parry successful - Half damage taken (smaller parrying weapon).")
		else:
			print_debug("Parry unsuccessful - Weapon too small to reduce damage.")

	# Apply armor reduction after parry
	var armor_value = target_unit.attribute_map.get_attribute_by_name("armor").current_buffed_value
	damage_total -= armor_value
	print_debug("Damage after armor reduction: ", damage_total)

	# Ensure damage does not go negative
	damage_total = max(damage_total, 0)
	print_debug("Final damage dealt: ", damage_total)

	return damage_total
