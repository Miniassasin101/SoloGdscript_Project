extends SpecialEffect
class_name MaximiseDamageEffect



func can_apply(event: ActivationEvent) -> bool:
	# Only allow this effect if the attacker scored a critical hit.
	if not super.can_apply(event):
		return false
	return true



func apply(event: ActivationEvent) -> void:
	# For Maximise Damage, simply log that the effect has been applied.
	event.maximize_count += 1
