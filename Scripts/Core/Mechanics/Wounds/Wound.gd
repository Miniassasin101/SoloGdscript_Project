class_name Wound extends Resource

"""
RULE CLARIFICATIONS:
	
	- A wound is a specific injury on a body part that reduces the current health of that limb.
	
	- A wound itself does not have a severity, the entire hit location does. 
	For example, if a body part with 5 hit points recieved three wounds from three arrows for 2 damage each, then
	the first two arrows would bring the body part/hit location down to one hit point, making it a minor wound
	that can be healed from naturally. 
	The third arrow, however, would bring the hit points down to -1, making the body part Seriously Wounded.
	Now a first aid roll can only stabilize the injury or restore it to functionality, and either the healing skill
	or a spell, or natural healing can work on healing the wound.
	
	- Only one first aid can be done per wound, but many healing skill attempts can,
	making first aid sufficient for small damage wounds, but healing vital for large damage ones.
		
	- Healing rate applies once per day/week/month depending on the wound severity, and is applied to every 
	wound individually. If a unit is burned by dragon breath on three different hit locations resulting in minor wounds,
	each will heal at [healing_rate]/day 

"""

@export var stable: bool = false
## By how much the wound is reducing the unit's hit points.
@export var damage: int = 1

# added stuff for things like slashing wound, what to display, where to display it, ect.

func _init(in_damage: int = 1) -> void:
	damage = max(in_damage, 0)
