class_name ForceFailureEffect extends SpecialEffect

"""
Description:
	Used when an opponent fumbles, the character can combine Force
Failure with any other Special Effect which requires an opposed roll
to work. Force Failure causes the opponent to fail his resistance roll
by default – thereby automatically be disarmed, tripped, etc.

This only can be activated if the losing unit 
rolls a fumble (-1 success level)
"""


func on_activated(event: ActivationEvent) -> void:
	event.forced_sp_eff_fail = true
	Utilities.spawn_text_line(event.losing_unit, "Forced Failure", Color.FIREBRICK)
