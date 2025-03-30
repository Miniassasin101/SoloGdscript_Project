class_name ImpaledCondition extends Condition

# If the Bleeding Condition is patched up, it doesnt apply the effect, but check to see if the
# Unit does strenuous physical activity like make an attack. If so, patched up becomes false, and
# the visual effect of the wound reopening begins


var impaled_weapon: Weapon = null

var impaled_projectile_visual: Node3D = null

var body_part: BodyPart = null

@export_category("Camera Shake")
@export var strength = 0.15 # the maximum shake strength. The higher, the messier
@export var shake_time = 0.4 # how much it will last
@export var shake_frequency = 50 # will apply 250 shakes per `shake_time`


## Removes the impaled weapon, dealing damage in the process
func apply(unit: Unit) -> void:


	Utilities.spawn_text_line(unit, "-Impaled", Color.AQUA)
	
	#apply_effect(unit)
	if impaled_projectile_visual:
		impaled_projectile_visual.queue_free()
	else:
		ObjectManager.instance.drop_item_in_world(unit, impaled_weapon)

	
	super.remove_self(unit)


func rip_free(ripping_free_unit: Unit, target_unit: Unit) -> void:
	Utilities.spawn_text_line(target_unit, "-Impaled", Color.AQUA)
	Utilities.spawn_text_line(target_unit, impaled_weapon.name + " Ripped Free", Color.FIREBRICK)
	
	
	
	if impaled_projectile_visual:
		impaled_projectile_visual.queue_free()
	else:
		ripping_free_unit.equipment.equip(impaled_weapon)
	
	apply_effect(target_unit)
	super.remove_self(target_unit)


func apply_effect(unit: Unit) -> void:
	var effect_rolled_damage = ceili(impaled_weapon.roll_damage()/2.0)
	# Create a new GameplayEffect resource
	var effect = GameplayEffect.new()
	var target_unit: Unit = unit
	# Prepare an AttributeEffect for health
	var health_effect = AttributeEffect.new()
	health_effect.attribute_name = "health"
	health_effect.minimum_value = -effect_rolled_damage
	health_effect.maximum_value = -effect_rolled_damage

	effect.attributes_affected.append(health_effect)

	# Applies damage to a specific body part
	target_unit.body.apply_wound_manual(body_part, effect_rolled_damage)

	# Make the screen shake:



	CameraShake.instance.shake(strength, shake_time, shake_frequency)


	# Get the target unit from the grid and attach the effect
	if target_unit:
		target_unit.add_child(effect)
	Utilities.spawn_damage_label(target_unit, effect_rolled_damage)
	#Utilities.spawn_text_line(target_unit, "Impale Remove", Color.FIREBRICK)



func get_details_text() -> String:
	var details := "This unit is impaled by a weapon."

	if impaled_weapon:
		details += "\nImpaled Weapon: %s" % impaled_weapon.name
	else:
		details += "\nImpaled Weapon: Unknown"

	if body_part:
		details += "\nImpacted Body Part: %s" % body_part.part_name
	else:
		details += "\nImpacted Body Part: Unknown"

	# Estimate damage on removal: half of weapon's average damage
	if impaled_weapon:
		var average_damage = (impaled_weapon.die_number * ((impaled_weapon.die_type + 1) / 2.0)) + impaled_weapon.flat_damage
		var estimated_removal_damage = ceili(average_damage / 2.0)
		details += "\nEstimated Damage on Removal: %d" % estimated_removal_damage
	else:
		details += "\nEstimated Damage on Removal: Unknown"

	details += "\nRemoving the weapon will cause immediate damage to the body part."

	var base := super.get_details_text()
	if base != "":
		details += "\n" + base

	return details
