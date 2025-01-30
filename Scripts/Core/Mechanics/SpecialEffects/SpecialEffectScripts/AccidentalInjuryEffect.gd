class_name AccidentalInjuryEffect extends SpecialEffect

"""
Description:
	The defender deflects or twists an opponent’s attack in such a way
that he fumbles, injuring himself. The attacker must roll damage
against himself in a random hit location using the weapon used to
strike. If unarmed he tears or breaks something internal, the damage roll ignoring any armour.

This only can be activated by a defending unit if the attacking unit fumbles their attack (-1 success level)
"""


func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	
	return true



# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	var target_unit: Unit = event.unit
	# Animation Stand In
	
	var hit_location: BodyPart = target_unit.get_random_hit_location()
	if hit_location == null:
		push_error("Error: null hit location on ", target_unit.name)
	
	var damage_total: int = roll_damage(event)
	
	damage_total -= int(hit_location.armor)
	print_debug("Damage after armor reduction: ", damage_total, "\nOn ", hit_location.part_name)

	# Ensure damage does not go negative
	damage_total = max(damage_total, 0)
	print_debug("Final damage dealt: ", damage_total)
	var effect_rolled_damage: int = damage_total
	
	apply_effect(event, effect_rolled_damage)
		
	#apply damage effect
	
	# Animation Stand-in
	
	# return


func roll_damage(event: ActivationEvent) -> int:
	# Roll base damage
	var weapon: Weapon = event.weapon
	var damage_total: int = 0
	if weapon:
		damage_total += Utilities.roll(weapon.die_type, weapon.die_number)
		damage_total += weapon.flat_damage
	else:
		# replace with unarmed later
		damage_total += Utilities.roll(4, 2)


	print_debug("Base damage rolled: ", damage_total)
	
	return damage_total

func apply_effect(event: ActivationEvent, effect_rolled_damage: int) -> void:

	# Create a new GameplayEffect resource
	var effect = GameplayEffect.new()
	var target_unit: Unit = event.unit
	# Prepare an AttributeEffect for health
	var health_effect = AttributeEffect.new()
	health_effect.attribute_name = "health"
	health_effect.minimum_value = -effect_rolled_damage
	health_effect.maximum_value = -effect_rolled_damage

	# Optionally, if you want to apply damage to a specific body part
	var part_effect = AttributeEffect.new()
	part_effect.attribute_name = event.body_part
	part_effect.minimum_value = -effect_rolled_damage
	part_effect.maximum_value = -effect_rolled_damage

	effect.attributes_affected.append(health_effect)
	effect.attributes_affected.append(part_effect)

	# Get the target unit from the grid and attach the effect

	if target_unit:
		target_unit.add_child(effect)
	Utilities.spawn_damage_label(target_unit, effect_rolled_damage)
	Utilities.spawn_text_line(event.target_unit, "Accidental Injury")
