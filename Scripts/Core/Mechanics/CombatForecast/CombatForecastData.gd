extends Resource
class_name CombatForecastData

#------------------------------------------------------------------
# Data members for Attacker (offense)
#------------------------------------------------------------------
# References to the unit and the selected weapon.
var attacker : Unit = null
var attacker_weapon : Weapon = null

# The base and modified combat skill values
var base_skill_value : int = 0
var modified_skill_value : int = 0

# The string representing the modifier
var attacker_modifier_name: String = "STANDARD"

# Chance of a successful hit and critical hit (values assumed to be percent)
var hit_chance : int = 0
var crit_chance : int = 0

# Minimum and Maximum possible damage before armor reduction
var min_damage: int = 0
var max_damage: int = 0

#------------------------------------------------------------------
# Data members for Defender (reaction)
#------------------------------------------------------------------
# References to the defender unit and their selected weapon.
var defender : Unit = null
var defender_weapon : Weapon = null

# Chance of parry (or, if use_evade is true, chance of evade) and its critical chance.
var parry_base_chance: int = 0
var parry_chance : int = 0
var parry_crit_chance : int = 0
var evade_chance : int = 0
var evade_crit_chance : int = 0

# The string representing the modifier
var defender_modifier_name: String = "STANDARD"

# Toggle to use evade chance instead of parry
var use_evade : bool = false

var damaging_weapon: bool = false

var attacker_long_reach_at_short: bool = false

var defender_long_reach_at_short: bool = false



#------------------------------------------------------------------
# Damage Forecast
#------------------------------------------------------------------
# A dictionary storing damage values "row by row" (for example: head, torso, arms, legs)
var damage_by_location : Dictionary = {}

#------------------------------------------------------------------
# Initialization
#------------------------------------------------------------------
func _init(_attacker: Unit, _defender: Unit) -> void:
	construct_forecast(_attacker, _defender)



func construct_forecast(_attacker: Unit, _defender: Unit) -> void:
	# Set attacker/defender and their weapons.
	attacker = _attacker
	defender = _defender
	
	var selected_ability: Ability = UnitActionSystem.instance.selected_ability
	
	#var attacker_weapon: Weapon
	
	if selected_ability is MeleeAbility:
		attacker_weapon = selected_ability.get_weapon_from_ability(attacker)
	
	else:
		if CombatSystem.instance.current_event:
			attacker_weapon = CombatSystem.instance.current_event.weapon
		
		else:
			attacker_weapon = _attacker.equipment.get_equipped_weapon()
	
	
	var left_weapon: bool = CombatForecastUI.instance.showing_left_parry
	
	#attacker_weapon = _attacker.equipment.get_equipped_weapon()
	if left_weapon:
		defender_weapon = _defender.equipment.get_left_equipped_weapon()
	else:
		defender_weapon = _defender.equipment.get_right_equipped_weapon()
	
	if !defender_weapon:
		defender_weapon = defender.get_equipped_weapon()
	
	if !attacker_weapon:
		attacker_weapon = attacker.get_equipped_weapon()
	
	var atk_reach: int = attacker_weapon.reach
	var def_reach: int = defender_weapon.reach
	
	
	var engagement_system: EngagementSystem = CombatSystem.instance.engagement_system
	var engagement: Engagement = engagement_system.get_engagement(attacker, defender)

	if engagement:
		# 1) Is trying to attack with a too-short weapon at a longer reach?
		if engagement.is_fighting_at_shorter_range(attacker_weapon):
			# attacker is inside defender's reach → can only damage the weapon
			damaging_weapon = true

		# 2) is truing to attack with a too-long weapon at a short reach?
		if engagement.is_fighting_at_longer_range(attacker_weapon):
			attacker_long_reach_at_short = true

		# 3) is trying to defend with a too-long weapon at a short reach?
		if engagement.is_fighting_at_longer_range(defender_weapon):
			defender_long_reach_at_short = true
		
	
	
	

	#------------------------------------------------------------------
	# Attacker Data
	#------------------------------------------------------------------
	# Store the base (buffed) combat skill value.
	base_skill_value = int(attacker.get_attribute_buffed_value_by_name("combat_skill"))
	
	# Temporarily add the facing penalty condition to get the modified skill value.
	var attacker_facing_condition: FacingPenaltyCondition = CombatSystem.instance.compute_attacker_facing_penalty(attacker, defender, attacker_weapon)
	if attacker_facing_condition != null:
		attacker.conditions_manager.add_condition(attacker_facing_condition)
	
	# Retrieve the modified combat skill value (after conditions).
	modified_skill_value = attacker.get_attribute_after_sit_mod("combat_skill")
	# For this example, we assume the hit chance is equal to the modified combat skill.
	hit_chance = modified_skill_value
	# And calculate the critical chance from that modified value.
	crit_chance = Utilities.get_crit_value_of_skill(modified_skill_value)
	
	attacker_modifier_name = attacker.get_situational_modifier_grade_name()
	
	
	# Remove the temporary facing penalty condition.
	if attacker_facing_condition != null:
		attacker.conditions_manager.remove_condition(attacker_facing_condition)
	
	#------------------------------------------------------------------
	# Defender Data
	#------------------------------------------------------------------
	# Temporarily add the defender's facing penalty condition.
	var defender_facing_condition: FacingPenaltyCondition = CombatSystem.instance.compute_defender_facing_penalty(attacker, defender, defender_weapon)
	if defender_facing_condition != null:
		defender.conditions_manager.add_condition(defender_facing_condition)
	
	# Retrieve the defender's modified combat skill for reaction.
	var defender_mod_skill: int = defender.get_attribute_after_sit_mod("combat_skill")
	# Use that value as the parry chance.
	parry_chance = defender_mod_skill
	# And calculate the parry critical chance.
	parry_crit_chance = Utilities.get_crit_value_of_skill(defender_mod_skill)
	
	defender_modifier_name = defender.get_situational_modifier_grade_name()
	
	# Remove the temporary facing penalty condition.
	if defender_facing_condition != null:
		defender.conditions_manager.remove_condition(defender_facing_condition)
	
	# Compute the defender's original (buffed) combat skill (without temporary modifiers).
	var defender_original_skill: int = int(defender.get_attribute_buffed_value_by_name("combat_skill"))
	parry_base_chance = defender_original_skill
	
	if defender_long_reach_at_short:
		parry_chance = 0
	
	# Compute the defender's original evade skill.
	# If the defender has an "evade" attribute, use that; otherwise fall back to the combat skill.
	var defender_evade_skill: int = 0
	if defender.get_attribute_by_name("evade_skill") != null:
		defender_evade_skill = int(defender.get_attribute_buffed_value_by_name("evade_skill"))
	else:
		defender_evade_skill = defender_original_skill
	
	#------------------------------------------------------------------
	# Evade Chance and Critical Chance
	#------------------------------------------------------------------
	# Default to not using the evade system; you can toggle use_evade externally.
	# If use_evade is true, compute the evade chance based on the modified evade value.

	# Here we assume an evade attribute works similar to combat_skill.
	evade_chance = int(defender.get_attribute_after_sit_mod("evade_skill"))
	evade_crit_chance = Utilities.get_crit_value_of_skill(evade_chance)

	
	
	#------------------------------------------------------------------
	# Damage Forecast
	#------------------------------------------------------------------
	# Initialize the damage-by-location dictionary.
	damage_by_location = {}
