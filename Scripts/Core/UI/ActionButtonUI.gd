class_name ActionButtonUI
extends Button

@export var button_text: Label
@export var button: Button
var ability: Ability


func _ready() -> void:
	pass # Replace with function body.


func set_base_ability(_ability: Ability) -> void:
	button_text.set_text(_ability.ui_name.to_upper())
	#print_debug(_ability.ui_name.to_upper())
	ability = _ability

func _pressed() -> void:
	if ability.tags_type.has("reaction"):
		SignalBus.reaction_selected.emit(ability)
		
	SignalBus.selected_ability_changed.emit(ability)
