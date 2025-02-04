class_name ImpaleEffect extends SpecialEffect

""" Description
Description:
	The attacker can attempt to drive an impaling weapon deep into the
defender. Roll weapon damage twice, with the attacker choosing
which of the two results to use for the attack. If armour is penetrated
and causes a wound, then the attacker has the option of leaving the
weapon in the wound, or yanking it free on their next turn. Leaving
the weapon in the wound inflicts a difficulty grade on the victim’s
future skill attempts. The severity of the penalty depends on the size
of both the creature and the weapon impaling it, as listed on the
Impale Effects Table above. For simplicity’s sake, further impalements 
with the same sized weapon inflict no additional penalties.
To withdraw an impaled weapon during melee requires use of the
Ready Weapon combat action. The wielder must pass an unopposed
Brawn roll (or win an opposed Brawn roll if the opponent resists).
Success pulls the weapon free, causing further injury to the same
location equal to half the normal damage roll for that weapon,
but without any damage modifier. Failure implies that the weapon
remained stuck in the wound with no further effect, although the
wielder may try again on their next turn. Specifically barbed weapons 
(such as harpoons) inflict normal damage. Armour does not reduce 
withdrawal damage. Whilst it remains impaled, the attacker cannot 
use his impaling weapon for parrying.


"""

@export var impaled_condition: Condition


func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	# Rerolls damage and chooses the greater one
	# NOTE: Maybe add ability to choose which damage roll later, but idk why someone would.
	var new_rolled_damage = event.weapon.roll_damage()
	if new_rolled_damage > event.weapon_damage_before_armor:
		event.rolled_damage = event.body_part.get_damage_after_armor(new_rolled_damage)
	
	if event.rolled_damage <= 0:
		Utilities.spawn_text_line(event.unit, "Impale Failed: No Injury")
		return false
	
	return true




# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	var target_unit: Unit = event.target_unit
	var impaling_weapon: Weapon = event.weapon
	
	var roll: int = Utilities.roll(100)
	var success_level: int = Utilities.check_success_level((target_unit.get_attribute_after_sit_mod("fortitude_skill")), roll)
	
	if event.forced_sp_eff_fail:
		success_level = -3
	
	if success_level >= 1:
		Utilities.spawn_text_line(target_unit, "Bleed Saved", Color.AQUA)
		return
	
	#apply damage effect if the save fails
	apply_effect(event)
	
	# Animation Stand-in


func apply_effect(event: ActivationEvent) -> void:

	var target_unit: Unit = event.target_unit
	

	if target_unit:
		# Make sure to duplicate the resources always to avoid effects applying on every instance
		target_unit.conditions_manager.add_condition(impaled_condition.duplicate()) 

	Utilities.spawn_text_line(target_unit, "Impaled", Color.FIREBRICK)
