class_name LevelDebug
extends Node

# Manages a lot of the debug settings and variables
static var instance: LevelDebug = null

@export var end_turn_debug: bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if instance != null:
		push_error("There's more than one Level! - " + str(instance))
		queue_free()
		return
	instance = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
