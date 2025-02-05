class_name DamageWeaponEffect extends SpecialEffect

"""
Description:
	Permits the character to damage the opponent’s weapon (attacking or
parrying weapon). The targeted weapon uses its own Armour Points
(AP) to resist damage. If reduced to zero HP, the weapon breaks.
"""


func can_activate(event: ActivationEvent) -> bool:
	# Basic checks from the SpecialEffect base class:
	if not super.can_activate(event):
		return false

	# Check if the 'opponent' even has a weapon to damage.
	# For instance, if we need to ensure they parried with a weapon,
	# or if the attacker used a weapon, etc.

	if !event.losing_unit.equipment.has_equipped_weapon():
		return false

	return true


func on_activated(event: ActivationEvent) -> void:
	event.bypass_attack = true



func apply(event: ActivationEvent) -> void:
	super.apply(event)

	var opponent_weapon: Weapon = _get_opponents_weapon(event)
	if opponent_weapon == null:
		# No valid weapon found (they might have parried unarmed, or are disarmed).
		Utilities.spawn_text_line(event.winning_unit, "No Weapon to Damage", Color.YELLOW)
		return

	# We'll use the final rolled_damage from event (the same damage you’d apply to a body part).
	# Or you could roll a separate damage if your rules say so.
	var damage = roll_damage_on_weapon(event)
	if damage <= 0:
		# No effect if zero or negative damage
		Utilities.spawn_text_line(event.losing_unit, "Deflect", Color.AQUA)
		Utilities.spawn_damage_label(event.losing_unit, 0.0, Color.AQUA, 0.5)
		return


	# Apply leftover damage to weapon's HP
	opponent_weapon.subtract_hitpoints(damage)
	if opponent_weapon.hit_points <= 0:
		# The weapon breaks!
		Utilities.spawn_text_line(event.losing_unit, "Break!", Color.ORANGE)

	else:
		Utilities.spawn_text_line(event.losing_unit, 
			opponent_weapon.name + " Damaged",
			Color.FIREBRICK
		)
		Utilities.spawn_damage_label(event.losing_unit, float(damage), Color.FIREBRICK)



func roll_damage_on_weapon(event: ActivationEvent) -> int:
	# Roll base damage
	var attacking_weapon: Weapon = event.winning_unit.equipment.get_equipped_weapon()
	var defending_weapon: Weapon = event.losing_unit.equipment.get_equipped_weapon()
	var damage_total: int = 0

	damage_total = attacking_weapon.roll_damage()

	# Apply armor reduction after parry
	damage_total = defending_weapon.get_damage_after_armor(damage_total)


	return damage_total


#
# Identify the *opponent’s* weapon to be damaged. 
#   - If the effect user is the attacker, we might target the defender’s parrying weapon.
#   - If the effect user is the defender (winning_unit == target_unit), 
#     we might damage the attacker’s weapon, etc.
#
func _get_opponents_weapon(event: ActivationEvent) -> Weapon:
	# Determine which side is using this effect
	var user_is_attacker: bool = (event.winning_unit == event.unit)
	var user_is_defender: bool = (event.winning_unit == event.target_unit)

	# If attacker is the "user," the opponent is the defender:
	if user_is_attacker:
		var opponent_unit = event.target_unit
		if !opponent_unit or !opponent_unit.equipment:
			return null

		# In Mythras, the “parrying weapon” might be the front() item or 
		# you might store it in the event. This is just an example:
		if opponent_unit.equipment.equipped_items.size() > 0:
			return opponent_unit.equipment.get_equipped_weapon()

	# If defender is the "user," the opponent is the attacker:
	if user_is_defender:
		var opponent_unit = event.unit
		if !opponent_unit or !opponent_unit.equipment:
			return null

		if opponent_unit.equipment.equipped_items.size() > 0:
			return opponent_unit.equipment.get_equipped_weapon()

	return null
