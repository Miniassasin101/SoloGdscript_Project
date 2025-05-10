class_name CombatSystem
extends Node

# Signals for abilities to listen to
signal on_turn_started(unit: Unit)


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
@export var engagement_system: EngagementSystem
@export var special_effect_system: SpecialEffectSystem

@export_category("Conditions")
@export var facing_penalty_condition: FacingPenaltyCondition



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
			if unit == null:
				unit = UnitManager.instance.get_all_units()[0]
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
	if unit == null:
		unit = UnitManager.instance.get_all_units()[0]
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


# Similarly, if you need to add or update a single engagement:
func update_unit_engagements(changed_unit: Unit) -> void:
	engagement_system.update_engagements_for_unit(changed_unit)


# Pretty much only done by Interrupt Action
func interrupt_turn(_unit: Unit) -> void:
	SignalBus.continue_turn.emit()
	print_debug("Turn Interrupted")



func declare_action(action: Ability, event: ActivationEvent) -> void:
	current_event = event
	await check_declaration_reaction_queue(action, event)
	if not event.target_unit:
		return

	var attacker: Unit = event.unit
	var defender: Unit = event.target_unit
	# Make them look at each other...
	defender.animator.enable_head_look(attacker.body.get_part_marker("head"))
	attacker.animator.enable_head_look(defender.body.get_part_marker("head"))
	attacker.conditions_manager.apply_conditions_attack_declared_interval()

	# —— Weapon Reach Debuffs/Effects —— #
	var engagement: Engagement = engagement_system.get_engagement(attacker, defender)
	if engagement:
		var atk_w: Weapon = null #attacker.equipment.get_equipped_weapon()
		#var def_w: Weapon = defender.equipment.get_equipped_weapon()
		if action.has_method("get_weapon_from_ability"):
			atk_w = action.get_weapon_from_ability(attacker)
		else:
			atk_w = attacker.equipment.get_equipped_weapon()
		if not atk_w:
			atk_w = attacker.equipment.get_equipped_weapon()
		
		if not atk_w:
			push_error("No weapon in declare action on unit: " + attacker.ui_name + " " + attacker.name)
			return

		# 1) Is attacking with a too-short weapon at long reach (only attacks weapon)
		if engagement.is_fighting_at_shorter_range(atk_w):
			current_event.special_effects.append(
				special_effect_system.find_special_effect_by_name("Damage Weapon")
			)

		# 2) Is attacking with a too-long weapon at short reach (damage penalty)
		if engagement.is_fighting_at_longer_range(atk_w):
			event.attacker_long_reach_at_short = true

		# 3) Is defending with a long weapon at long reach (not possible)
		#if engagement.is_fighting_at_longer_range(def_w):
		#	event.defender_long_reach_at_short = true

	# —— end Weapon Reach logic —— #

	print_debug("Action Declared: ", action.ui_name)








func check_declaration_reaction_queue(_action: Ability, _event: ActivationEvent) -> void:
	# This is where you could prompt units who have "hold actions" or special abilities
	# triggered upon declarations. For now, we assume minimal logic.
	for unit: Unit in declaration_reaction_queue:
		if unit.is_holding:
			interrupt_turn(unit)
			await SignalBus.continue_turn
	# Additional logic can be added here per Mythras optional rules.



func reaction(reacting_unit: Unit, _attacking_unit: Unit, _ret_event: ActivationEvent):

	# Prompt UI or AI to choose a reaction ability (e.g., a parry, an evade).
	SignalBus.on_player_reaction.emit(reacting_unit)
	UnitActionSystem.instance.set_is_reacting()

	var ability: Ability = await SignalBus.move_complete#await SignalBus.reaction_selected

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
	for effect: SpecialEffect in special_effect_system.special_effects:
		if effect.can_activate(event):
			ret_effects.append(effect)
	SignalBus.on_player_special_effect.emit(event.winning_unit, ret_effects, abs_dif)
	var chosen_effects: Array[SpecialEffect] = await UIBus.effects_chosen
	event.special_effects.append_array(chosen_effects)
	for effect in event.special_effects:
		@warning_ignore("redundant_await")
		await effect.on_activated(event)
		if effect.activation_phase == effect.ActivationPhase.Initial and effect.can_apply(event):
			@warning_ignore("redundant_await")
			await effect.apply(event)
	return event



#region Attacker and Defender positional penalties
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
			if event.weapon.tags.has("left"):

				penalty_cond.situational_modifier = 3 # Hard
				event.unit.conditions_manager.add_condition(penalty_cond)
				Utilities.spawn_text_line(event.unit, "Side Attack", Color.YELLOW)
				return
			return

		elif (relative == Utilities.RelativePosition.LEFT_SIDE):
			if event.weapon.tags.has("right"):

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
			if event.weapon.tags.has("left"):
				penalty_cond.situational_modifier = 3 # Hard
				event.target_unit.conditions_manager.add_condition(penalty_cond)
				Utilities.spawn_text_line(event.target_unit, "Side Reaction", Color.YELLOW)
				return
			return

		elif (relative == Utilities.RelativePosition.LEFT_SIDE):
			if event.weapon.tags.has("right"):

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
#endregion

#region Compute positional penalties
func compute_attacker_facing_penalty(attacker: Unit, target: Unit, weapon: Weapon) -> FacingPenaltyCondition:
	if weapon == null:
		return null
	var penalty_cond: FacingPenaltyCondition = facing_penalty_condition.duplicate()
	var relative: int = Utilities.get_unit_relative_position(attacker, target)

	if weapon.hands == 2:
		if relative == Utilities.RelativePosition.FRONT:
			return null
		elif relative == Utilities.RelativePosition.RIGHT_SIDE or relative == Utilities.RelativePosition.LEFT_SIDE:
			penalty_cond.situational_modifier = 3  # Hard penalty
			return penalty_cond
		elif relative == Utilities.RelativePosition.BACK:
			penalty_cond.situational_modifier = 5  # Herculean penalty
			return penalty_cond
	elif weapon.hands == 1:
		if relative == Utilities.RelativePosition.FRONT:
			return null
		elif relative == Utilities.RelativePosition.RIGHT_SIDE:
			if weapon.tags.has("left"):
				penalty_cond.situational_modifier = 3
				return penalty_cond
			return null
		elif relative == Utilities.RelativePosition.LEFT_SIDE:
			if weapon.tags.has("right"):
				penalty_cond.situational_modifier = 3
				return penalty_cond
			return null
		elif relative == Utilities.RelativePosition.BACK:
			penalty_cond.situational_modifier = 5
			return penalty_cond
	return null

func compute_defender_facing_penalty(attacker: Unit, target: Unit, weapon: Weapon) -> FacingPenaltyCondition:
	if weapon == null:
		return null
	var penalty_cond: FacingPenaltyCondition = facing_penalty_condition.duplicate()
	# For the defender the relative position is determined with the target (defender) first
	var relative: int = Utilities.get_unit_relative_position(target, attacker)

	if weapon.hands == 2:
		if relative == Utilities.RelativePosition.FRONT:
			return null
		elif relative == Utilities.RelativePosition.RIGHT_SIDE or relative == Utilities.RelativePosition.LEFT_SIDE:
			penalty_cond.situational_modifier = 3  # Hard penalty
			return penalty_cond
		elif relative == Utilities.RelativePosition.BACK:
			penalty_cond.situational_modifier = 4  # Formidable penalty
			return penalty_cond
		else:
			#push_warning("No relative position on ", relative)
			return null

	elif weapon.hands == 1:
		if relative == Utilities.RelativePosition.FRONT:
			return null
		elif relative == Utilities.RelativePosition.RIGHT_SIDE:
			if weapon.tags.has("left"):
				penalty_cond.situational_modifier = 3
				return penalty_cond
			return null
		elif relative == Utilities.RelativePosition.LEFT_SIDE:
			if weapon.tags.has("right"):
				penalty_cond.situational_modifier = 3
				return penalty_cond
			return null
		elif relative == Utilities.RelativePosition.BACK:
			penalty_cond.situational_modifier = 4
			return penalty_cond
		else:
			#push_warning("No relative position on ", relative)
			return null
	return null
#endregion




# In CombatSystem.gd

func attack_unit(action: Ability, event: ActivationEvent) -> ActivationEvent:
	var _weapon: Weapon = event.weapon
	var attacking_unit: Unit = event.unit
	var target_unit: Unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)
	event.target_unit = target_unit
	current_event = event

	# Step 1: Calculate attacker's success outcome
	var attacker_success_level = _calculate_attacker_success(attacking_unit, event)
	if attacker_success_level <= 0:
		print_debug("Attacker missed.")
		event.miss = true
	show_success(attacking_unit, attacker_success_level)

	# Step 2: Handle defender reaction and capture reaction data
	var reaction_data = await _handle_defender_reaction(target_unit, attacking_unit, event)
	var defender_success_level: int = reaction_data["defender_success_level"]
	var parrying_weapon_size: int = reaction_data["parrying_weapon_size"]
	var attack_weapon_size: int = reaction_data["attack_weapon_size"]

	# Early exit if conditions require it (for example, if no reaction was triggered)
	if event.miss and event.parry_successful == false:
		hide_all_success_level()
		UILayer.instance.unit_action_system_ui.toggle_containers_visibility_off_except()
		current_event = null
		return event

	# Step 3: Resolve combat outcome based on success differential
	event = await _resolve_combat(action, event, attacker_success_level, defender_success_level,
								  attacking_unit, target_unit, parrying_weapon_size, attack_weapon_size)

	hide_all_success_level()
	UILayer.instance.unit_action_system_ui.toggle_containers_visibility_off_except()
	current_event = null
	return event


# Helper: Calculate attacker roll and success level, update event and show marker.
func _calculate_attacker_success(attacking_unit: Unit, event: ActivationEvent) -> int:
	determine_attacker_facing_penalty(event)

	var attacker_combat_skill: int = attacking_unit.get_attribute_after_sit_mod("combat_skill")
	var attacker_roll: int = Utilities.roll(100)
	print_debug("Attacker Combat Skill: ", attacker_combat_skill)
	print_debug("Attacker Roll: ", attacker_roll)
	event.attacker_roll = attacker_roll

	var success_level: int = Utilities.check_success_level(attacker_combat_skill, attacker_roll)
	print_debug("Attacker Success Level (pre-debug): ", success_level)

	# — Debug overrides — #
	if LevelDebug.instance.attacker_fail_debug:
		success_level = 0
	elif LevelDebug.instance.attacker_success_debug:
		success_level = 1

	print_debug("Attacker Success Level (post-debug): ", success_level)

	event.attacker_success_level = success_level
	if success_level == 2:
		event.attacker_critical = true
		Utilities.spawn_text_line(attacking_unit, "Critical!")
	elif success_level == -1:
		event.attacker_fumble = true
		Utilities.spawn_text_line(attacking_unit, "Fumble!", Color.FIREBRICK)

	show_success(attacking_unit, success_level)
	return success_level



# Helper: Handle the defender's reaction.
# Returns a Dictionary with:
# - defender_success_level (int)
# - parrying_weapon_size (int)
# - attack_weapon_size (int)
func _handle_defender_reaction(target_unit: Unit, attacking_unit: Unit, event: ActivationEvent) -> Dictionary:
	var defender_success_level: int = 0
	var parrying_weapon_size: int = 0
	var attack_weapon_size: int = event.weapon.size if event.weapon else 0

	# Normally prompt for a parry/evade...
	await reaction(target_unit, attacking_unit, event)
	defender_success_level = event.defender_success_level

	print_debug("Defender Success Level (pre-debug): ", defender_success_level)

	# — Debug overrides — #
	if LevelDebug.instance.parry_fail_debug:
		defender_success_level = 0
	elif LevelDebug.instance.parry_success_debug:
		defender_success_level = 1

	print_debug("Defender Success Level (post-debug): ", defender_success_level)

	# Mark whether a parry actually succeeded
	event.parry_successful = defender_success_level > 0

	# Show feedback
	show_success(target_unit, defender_success_level)
	if not target_unit.equipment.equipped_items.is_empty():
		var defender_weapon: Weapon = current_event.defender_weapon
		if !defender_weapon:
			current_event.defender_weapon = target_unit.get_equipped_weapon()
		parrying_weapon_size = current_event.defender_weapon.size



	event.defender_success_level = defender_success_level
	if defender_success_level == 2:
		event.defender_critical = true
		Utilities.spawn_text_line(target_unit, "Critical!")
	elif defender_success_level == -1:
		event.defender_fumble = true
		Utilities.spawn_text_line(target_unit, "Fumble!", Color.FIREBRICK)

	return {
		"defender_success_level": defender_success_level,
		"parrying_weapon_size": parrying_weapon_size,
		"attack_weapon_size": attack_weapon_size
	}



# Helper: Resolve the combat based on success differential,
# prompt special effects if needed, and roll damage.
func _resolve_combat(action: Ability, event: ActivationEvent, attacker_success_level: int, defender_success_level: int,
					   attacking_unit: Unit, target_unit: Unit, parrying_weapon_size: int, attack_weapon_size: int) -> ActivationEvent:
	var differential: int = attacker_success_level - defender_success_level
	var abs_dif: int = abs(differential)

	if differential > 0:
		print_debug("Attacker wins. Applying damage. Also prompt special effects")
		event.set_winning_unit(attacking_unit)
		event.set_losing_unit(target_unit)
		event = await prompt_special_effect_choice(event, abs_dif)
		if not event.bypass_attack:
			setup_hit_location(event)
			event.rolled_damage = roll_damage(action, event, target_unit, parrying_weapon_size, attack_weapon_size)

	elif differential == 0:
		print_debug("It's a tie - no special effects.")
		if not event.bypass_attack:
			setup_hit_location(event)
			event.rolled_damage = roll_damage(action, event, target_unit, parrying_weapon_size, attack_weapon_size)

	else:
		print_debug("Defender wins. Prompt Special Effects")
		event.set_winning_unit(target_unit)
		event.set_losing_unit(attacking_unit)
		event.special_effects.clear()
		event = await prompt_special_effect_choice(event, abs_dif)
		if not event.bypass_attack:
			setup_hit_location(event)
			event.rolled_damage = roll_damage(action, event, target_unit, parrying_weapon_size, attack_weapon_size)

	return event







func get_hit_location(target_unit: Unit) -> BodyPart:
	var ret = target_unit.body.roll_hit_location()
	return ret


func roll_damage(ability: Ability, event: ActivationEvent, _target_unit: Unit,
	parrying_weapon_size: int, attack_weapon_size: int) -> int:
	# 1. Roll base damage
	var weapon: Weapon = event.weapon
	var damage_total: int = 0
	if weapon:
		damage_total = weapon.roll_damage(event.maximize_count)
		event.weapon_damage_before_armor = damage_total
	else:
		damage_total += Utilities.roll(ability.damage, ability.die_number)
		damage_total += ability.flat_damage
	print_debug("Base damage rolled: ", damage_total)

	# 2. Compute effective sizes with reach penalties
	var effective_parry_size: int = parrying_weapon_size
	var effective_attack_size: int = attack_weapon_size

	# Penalty when attacker has long weapon at short range
	if event.attacker_long_reach_at_short:
		var atk_weapon: Weapon = event.weapon
		var def_weapon: Weapon = event.defender_weapon
		if atk_weapon and def_weapon:
			var reach_diff = absi(atk_weapon.reach - def_weapon.reach)
			effective_parry_size = maxi(parrying_weapon_size - reach_diff, 0)
		print_debug("Effective parry size after attacker-reach penalty: ", effective_parry_size)

	# Penalty when defender has long weapon at short range
	if event.defender_long_reach_at_short:
		var atk_weapon: Weapon = event.weapon
		var def_weapon: Weapon = event.defender_weapon
		if atk_weapon and def_weapon:
			var reach_diff: int = absi(def_weapon.reach - atk_weapon.reach)
			effective_attack_size = maxi(attack_weapon_size - reach_diff, 0)
		print_debug("Effective attack size after defender-reach penalty: ", effective_attack_size)

	# 3. Apply parry reduction using effective sizes
	if event.parry_successful:
		if effective_parry_size >= effective_attack_size or event.enhance_parry:
			print_debug("Parry successful - Full damage blocked (effective sizes).")
			damage_total = 0
		elif effective_parry_size == effective_attack_size - 1:
			damage_total = ceili(damage_total / 2.0)
			print_debug("Parry successful - Half damage taken (effective sizes).")
		else:
			print_debug("Parry unsuccessful - Effective parry too small.")

	# 4. Apply armor reduction
	if not event.bypass_armor:
		damage_total = event.body_part.get_damage_after_armor(damage_total)

	print_debug("Damage after armor reduction: ", damage_total, " on ", event.body_part.part_name)
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
