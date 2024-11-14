class_name Action
extends Node

var is_active: bool
var unit: Unit
var on_action_complete: Callable = Callable()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit = get_parent()

func get_action_name() -> String:
	return ""
