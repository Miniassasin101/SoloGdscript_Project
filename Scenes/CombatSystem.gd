class_name CombatSystem
extends Node

static var instance: CombatSystem = null
var declaration_reaction_queue: Array[Unit] = []
var initiative_order: Array[Unit] = []
@export var marker_visibility_time: float = 1.5



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
	var defending_roll = AbilityUtils.roll(100)
	print_debug("Defend Skill Value: ", defend_skill_value)
	print_debug("Defend Roll: ", defending_roll)

	var defender_success_level = AbilityUtils.check_success_level(defend_skill_value, defending_roll)
	print_debug("Defender Success Level: ", defender_success_level)
	return defender_success_level



func attack_unit(action: Ability, event: ActivationEvent) -> ActivationEvent:
	var weapon: Weapon = event.weapon
	var attacking_unit: Unit = event.character
	var target_unit: Unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)

	var attacker_combat_skill = event.attribute_map.get_attribute_by_name("combat_skill").current_buffed_value
	var attacker_roll: int = AbilityUtils.roll(100)
	print_debug("Attacker Combat Skill: ", attacker_combat_skill)
	print_debug("Attacker Roll: ", attacker_roll)

	var attacker_success_level: int = AbilityUtils.check_success_level(attacker_combat_skill, attacker_roll)
	print_debug("Attacker Success Level: ", attacker_success_level)
	var ret_event: ActivationEvent = event
	if LevelDebug.instance.attacker_success_debug == true:
		attacker_success_level = 1
	# If attacker fails outright:
	if attacker_success_level <= 0:
		print_debug("Attacker missed.")
		ret_event.miss = true

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
	hide_all_success_level()

	if !defender_wants_reaction:
		return ret_event
	if LevelDebug.instance.parry_fail_debug:
		parry_success = false
	var hit_location: BodyPart = get_hit_location(target_unit)
	if hit_location == null:
		push_error("Error: null hit location on ", target_unit.name)
	ret_event.body_part = hit_location.part_name + "_health"
	if ret_event.miss:
		return ret_event

	# FIXME: rn on a fail and crit fail a special effect is gotten
	# Determine success differential
	var differential: int = attacker_success_level - defender_success_level
	
	if differential > 0:
		print_debug("Attacker wins. Applying damage. Also prompt special effects")

		ret_event.rolled_damage = roll_damage(action, event, target_unit, hit_location, parry_success, parrying_weapon_size, attack_weapon_size)

	elif differential == 0:
		print_debug("It's a tie - no special effects.")
		ret_event.rolled_damage = roll_damage(action, event, target_unit, hit_location, parry_success, parrying_weapon_size, attack_weapon_size)

	else:
		print_debug("Defender wins. Prompt Special Effects")
		ret_event.rolled_damage = roll_damage(action, event, target_unit, hit_location, parry_success, parrying_weapon_size, attack_weapon_size)

	
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
		damage_total += AbilityUtils.roll(weapon.die_type, weapon.die_number)
		damage_total += weapon.flat_damage
	else:
		damage_total += AbilityUtils.roll(ability.damage, ability.die_number)
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
