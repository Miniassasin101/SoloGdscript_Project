extends SpecialEffect
class_name SunderEffect

# Called when checking if the effect can be activated.
# Here we ensure that the hit location exists and actually has armor or natural protection.
func can_activate(event: ActivationEvent) -> bool:
	# First, let any conditions defined in the base SpecialEffect pass.
	if not super.can_activate(event):
		return false

	var has_part_with_armor: bool = false
	# Ensure we have a valid hit location.
	for part: BodyPart in event.losing_unit.body.body_parts:
		if part.get_armor() >= 1:
			has_part_with_armor = true
			break
	
	if !has_part_with_armor:
		return false
	
	
	# Optionally, you could add more conditions (for example,
	# checking that the attacker’s weapon is of a type that can sunder).
	return true


# Applies the sunder effect. It uses the rolled damage and first tries to reduce the armor
# value of the hit location. Any surplus damage beyond the armor’s current value is then
# applied to the hit points (via a wound).
func apply(event: ActivationEvent) -> void:
	# Call the base method in case it does any global handling.
	super.apply(event)
	
	# Get the total damage that was rolled for this attack.
	var damage: int = event.rolled_damage
	if damage <= 0:
		print_debug("SunderEffect: No damage to apply.")
		return
	
	# Make sure we have a hit location.
	if not event.body_part:
		push_error("SunderEffect: Missing hit location on target_unit.")
		return
	
	# Get the current Armor Points from the hit location.
	var armor_points: int = event.body_part.armor
	print_debug("SunderEffect: Rolled damage =", damage, "Armor Points =", armor_points)
	
	# Determine how the damage applies:
	# 1. If the rolled damage after armor reduction 
	#    is less than or equal to the armor points,
	#    all damage goes toward reducing the armor.
	# 2. If the damage exceeds the armor points, first reduce the armor to zero,
	#    then carry the remaining damage over to the hit points.
	if armor_points > 0:
		var surplus_damage: int = damage - armor_points
		
		# Reduce the armor value
		event.body_part.armor = max(armor_points - damage, 0)
		print_debug("SunderEffect: Armor reduced to", event.body_part.armor)
		
		# Show a message indicating the sunder effect.
		Utilities.spawn_text_line(event.target_unit, "Sunder!", Color.ORANGE)
		
		# If there is damage remaining after the armor is reduced to zero,
		# that surplus is applied to the target's hit points.
		if surplus_damage > 0:
			print_debug("SunderEffect: Surplus damage =", surplus_damage)
			# Update the event's damage to the surplus and call the existing wound application.
			event.rolled_damage = surplus_damage

		else:
			# If no surplus remains, then no hit point damage is taken.
			print_debug("SunderEffect: All damage absorbed by armor.")

	
