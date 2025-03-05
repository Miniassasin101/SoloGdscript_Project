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


func can_activate(event: ActivationEvent) -> bool:

	if !super.can_activate(event):
		return false
	
	if !event.winning_unit.equipment.has_equipped_weapon():
		return false
	if !event.weapon:
		return false
	return true


func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	# Rerolls damage and chooses the greater one
	# NOTE: Maybe add ability to choose which damage roll later, but idk why someone would.
	var new_rolled_damage = event.weapon.roll_damage(event.maximize_count)
	if new_rolled_damage > event.weapon_damage_before_armor:
		event.rolled_damage = event.body_part.get_damage_after_armor(new_rolled_damage)
		print_debug("Old Damage: ", event.weapon_damage_before_armor)
		print_debug("New Impale Damage: ", new_rolled_damage)
	
	if event.rolled_damage <= 0:
		Utilities.spawn_text_line(event.unit, "Impale Failed: No Injury")
		return false
	
	return true




# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	var impaling_weapon: Weapon = event.weapon
	
	var target_marker: Marker3D = event.body_part.get_body_part_marker()
	
	var weapon_visual: ItemVisual = impaling_weapon.get_item_visual()
	

	
	if weapon_visual.projectile != null:
		var impaling_visual: Node3D = weapon_visual.projectile
		impaling_visual.reparent(target_marker, true)
		#var root_pos: Vector3 = impaling_visual.root.get_position()
		#root_pos += Vector3(0, 0, 0.45)
		#weapon_visual.root.set_position(root_pos)
		impaling_visual.set_global_position(target_marker.global_position)
		#impaling_visual.global_rotate(Vector3.UP, 180.0)
		event.body_part.is_impaled = true
		apply_effect(event)
		return
		
	
	weapon_visual.reparent(target_marker, false)
	var root_pos: Vector3 = weapon_visual.root.get_position()
	root_pos += Vector3(0, 0, 0.45)
	weapon_visual.root.set_position(root_pos)
	event.winning_unit.equipment.unequip(impaling_weapon)
	weapon_visual.set_trail_visibility(false)
	event.body_part.is_impaled = true
	
	
	#apply impaled condition if the save fails
	apply_effect(event)
	
	# Animation Stand-in


func apply_effect(event: ActivationEvent) -> void:

	var target_unit: Unit = event.target_unit
	

	if target_unit and impaled_condition:
		# Make sure to duplicate the resources always to avoid effects applying on every instance
		var new_impaled_condition: ImpaledCondition = impaled_condition.duplicate()
		new_impaled_condition.impaled_weapon = event.weapon
		new_impaled_condition.impaled_projectile_visual = event.weapon.get_item_visual().projectile
		new_impaled_condition.body_part = event.body_part
		target_unit.conditions_manager.add_condition(new_impaled_condition) 

		Utilities.spawn_text_line(target_unit, "Impaled", Color.FIREBRICK)
	
	else: 
		push_error("No target unit or impaled condition")
		Utilities.spawn_text_line(event.unit, "ERROR ON " + ui_name, Color.FIREBRICK)
