class_name TurnSystem
extends Node

var turn_number: int = 1

static var instance: TurnSystem = null

func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitActionSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	SignalBus.connect("next_turn", next_turn)

func next_turn() -> void:
	turn_number += 1
