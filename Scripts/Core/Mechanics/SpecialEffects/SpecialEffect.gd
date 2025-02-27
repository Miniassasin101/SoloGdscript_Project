class_name SpecialEffect extends Resource

signal effect_finished

# Postresolution occurs right before the end of the 
enum ActivationPhase {Initial, PostDamage, Postresolution}

@export var ui_name: StringName

@export var activation_phase: ActivationPhase = ActivationPhase.Initial
@export_enum("Offensive", "Defensive", "Both") var activation_allowed: int = 2
@export var weapon_types_allowed: Array[String] = []
@export var stackable: bool = false
@export_category("Specific Roll")
@export_enum("None", "Self Criticals", "Opponent Fumbles") var roll_required: int = 0



func apply(_event: ActivationEvent) -> void:
	
	pass

func can_activate(event: ActivationEvent) -> bool:

	if !check_offensive_defensive(event):
		return false
	
	if !check_weapon_types(event):
		return false
	
	if !check_specific_roll(event):
		return false
	
	
	return true


func on_activated(_event: ActivationEvent) -> void:
	pass


func check_specific_roll(event: ActivationEvent) -> bool:
	# If we don't require a specific roll (roll_required == 0 => "None"), just return true.
	if roll_required == 0:
		return true

	# Figure out if the winning unit is the attacker or the defender:
	var user_is_attacker: bool = (event.winning_unit == event.unit)
	var user_is_defender: bool = (event.winning_unit == event.target_unit)
	
	# If the winning unit is neither the attacker nor the defender,
	# something is off. Return false, or handle as needed:
	if !(user_is_attacker or user_is_defender):
		return false
	
	match roll_required:
		# "Self Criticals"
		1:
			if user_is_attacker:
				# The "self" in question is the attacker
				return event.attacker_critical
			elif user_is_defender:
				# The "self" in question is the defender
				return event.defender_critical
			return false
		
		# "Opponent Fumbles"
		2:
			if user_is_attacker:
				# Opponent = defender
				return event.defender_fumble
			elif user_is_defender:
				# Opponent = attacker
				return event.attacker_fumble
			return false
		
		_:
			# Fallback if there's any unexpected enum value
			return false



func check_offensive_defensive(event: ActivationEvent) -> bool:
	if event.target_unit == event.winning_unit:
		if activation_allowed == 0:
			return false
	elif event.unit == event.winning_unit:
		if activation_allowed == 1:
			return false
	return true


func check_weapon_types(event: ActivationEvent) -> bool:
	if !weapon_types_allowed.is_empty():
		for weapon_type: String in weapon_types_allowed:
			if event.weapon.category != weapon_type:
				return false
	return true




func can_apply(_event: ActivationEvent) -> bool:
	return true
