class_name SpecialEffectButtonUI
extends Button

@export var button_text: Label
@export var button: Button
var special_effect: SpecialEffect = null


func _ready() -> void:
	pass # Replace with function body.


func set_special_effect(in_effect: SpecialEffect) -> void:
	button_text.set_text(in_effect.ui_name.to_upper())
