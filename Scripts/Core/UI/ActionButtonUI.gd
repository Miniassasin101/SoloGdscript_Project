class_name ActionButtonUI
extends Button

@export var button_text: Label
@export var button: Button
var action: Action
var ability: Ability
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_base_action(inaction: Action) -> void:
	button_text.set_text(inaction.get_action_name().to_upper())
	action = inaction

func set_base_ability(_ability: Ability) -> void:
	button_text.set_text(_ability.ui_name.to_upper())
	ability = _ability

func _pressed() -> void:
	if ability:
		print(ability.ui_name)
	SignalBus.selected_action_changed.emit(action)
	SignalBus.selected_ability_changed.emit(ability)
