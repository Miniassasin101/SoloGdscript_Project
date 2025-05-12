# SpecialEffectSystem.gd
extends Node
class_name SpecialEffectSystem

signal special_effect_applied(effect: SpecialEffect, event: ActivationEvent)
signal special_effect_finished(effect: SpecialEffect, event: ActivationEvent)

@export var special_effects: Array[SpecialEffect] = []


func find_special_effect_by_name(name: StringName) -> SpecialEffect:
		for effect in special_effects:
			if (effect.ui_name == name) or (effect.ui_name.to_snake_case() == name):
				return effect
		return null


func get_activatable_effects(event: ActivationEvent) -> Array:
		var avail: Array = []
		for effect in special_effects:
			if effect.can_activate(event):
				avail.append(effect)
		return avail


func apply_special_effect_by_name(name: StringName, event: ActivationEvent) -> bool:
		var template: SpecialEffect = find_special_effect_by_name(name)
		if not template:
			return false
		if not template.can_activate(event) or not template.can_apply(event):
			return false

		var inst: SpecialEffect = template.duplicate(true) as SpecialEffect
		inst.effect_finished.connect(_on_special_effect_finished.bind(inst, event))


		event.special_effects.append(inst)
		special_effect_applied.emit(inst, event)

		@warning_ignore("redundant_await")
		await inst.apply(event)
		return true


func remove_special_effect_by_name(name: StringName, event: ActivationEvent) -> bool:
		for i in range(event.special_effects.size()):
			if event.special_effects[i].ui_name == name:
				event.special_effects.remove_at(i)
				return true
		return false


func _on_special_effect_finished(inst: SpecialEffect, event: ActivationEvent) -> void:
		special_effect_applied.emit(inst, event)
