class_name DisarmOpponentEffect extends SpecialEffect

"""
Description:
	The character knocks, yanks or twists the opponent’s weapon out
of his hand. The opponent must make an opposed roll of his Combat Style
against the character’s original roll. If the recipient of
the disarm loses, his weapon is flung a distance equal to the roll of
the disarmer’s Damage Modifier in metres. If there is no Damage
Modifier then the weapon drops at the disarmed person’s feet. The
comparative size of the weapons affects the roll. Each step that the
disarming character’s weapon is larger increases the difficulty of the
opponent’s roll by one grade. Conversely each step the disarming
character’s weapon is smaller, makes the difficulty one grade easier. 

Disarming works only on creatures of up to twice the attacker’s POWER.
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







func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	# Opposed roll
	var winner_roll: int = event.get_winning_unit_roll()
	var winner_success_level: int = Utilities.check_success_level((event.winning_unit.get_attribute_after_sit_mod("combat_skill")), winner_roll)
	
	var loser_roll: int = Utilities.roll()
	var weapon_size_difference: int = event.winning_unit.get_equipped_weapon().size - event.losing_unit.get_equipped_weapon().size
	var loser_success_level: int = Utilities.check_success_level((event.winning_unit.get_attribute_after_sit_mod("combat_skill", weapon_size_difference)), loser_roll)
	
	if event.forced_sp_eff_fail:
		loser_success_level = -3
	
	# By how much the victim wins the opposed roll
	var success_level_difference: int = loser_success_level - winner_success_level
	
	if success_level_difference == 0:
		if loser_roll > winner_roll:
			Utilities.spawn_text_line(event.losing_unit, "Disarm Saved", Color.AQUA)
			return
	
	elif success_level_difference >= 1:
		Utilities.spawn_text_line(event.losing_unit, "Disarm Saved", Color.AQUA)
		return
		
	ObjectManager.instance.drop_item_in_world(event.losing_unit)

	
	Utilities.spawn_text_line(event.losing_unit, 
		"Disarmed",
		Color.AQUA
		)
