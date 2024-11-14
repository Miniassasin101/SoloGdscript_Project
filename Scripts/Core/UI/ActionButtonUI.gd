class_name ActionButtonUI
extends Node

@export var text: Label
@export var button: Button
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_base_action(action: Action) -> void:
	text.text = action.get_action_name().to_upper()
	
