class_name BashEffect extends SpecialEffect

"""
Description:
	The attacker deliberately bashes the opponent off balance. How far
the defender totters back or sideward depends on the weapon being
used. Shields knock an opponent back one metre per for every two
points of damage rolled (prior to any subtractions due to armour,
parries, and so forth), whereas bludgeoning weapons knock back one
metre per for every three points. Bashing works only on creatures up
to twice the attacker’s SIZ. If the recipient is forced backwards into
an obstacle, then they must make a Hard Athletics or Acrobatics skill
roll to avoid falling or tripping over.

"""

## This condition is immidiately applied, and will also handle what happens when the unit crashes into a wall.
## This solves several potential issues with the movement negatively affecting other special effect resolutions
@export var knockback_condition: KnockbackCondition

func can_activate(event: ActivationEvent) -> bool:
	# Basic checks from the SpecialEffect base class:
	if not super.can_activate(event):
		return false
	
	if event.target_unit.get_attribute_buffed_value_by_name("size") > \
	event.unit.get_attribute_buffed_value_by_name("size"):
		return false
	
	return true

func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false

	
	return true




# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	apply_effect(event)
	
	# Animation Stand-in



func apply_effect(event: ActivationEvent) -> void:
	var target_unit: Unit = event.target_unit

	if target_unit:
		var knock_cond: Condition = knockback_condition.duplicate()
		# get grid position of direction based off of origin.
		# The condition will handle moving the unit with tweens and stopping them
		# if they are going to move into an impassable square.
		# Knockback condition will use a dummy function for now to represent falling prone upon hitting a wall
		target_unit.conditions_manager.add_condition(knock_cond) 
		knock_cond.apply(target_unit)

	Utilities.spawn_text_line(target_unit, "Knocked Back", Color.FIREBRICK)
