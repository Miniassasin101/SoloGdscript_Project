class_name ActionButtonUI
extends Button

@export var button_text: Label
@export var button: Button
var action: Action
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_base_action(inaction: Action) -> void:
	button_text.set_text(inaction.get_action_name().to_upper())# = action.get_action_name().to_upper()
	action = inaction

func _pressed() -> void:
	#print(action.get_action_name())
	SignalBus.selected_action_changed.emit(action)
