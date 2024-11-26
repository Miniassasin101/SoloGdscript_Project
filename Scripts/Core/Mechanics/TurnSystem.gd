class_name TurnSystem
extends Node

var turn_number: int = 1
var is_player_turn: bool = true
static var instance: TurnSystem = null

func _ready() -> void:
	if instance != null:
		push_error("There's more than one TurnSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	SignalBus.connect("end_turn", end_turn)

func end_turn() -> void:
	turn_number += 1
	is_player_turn = !is_player_turn
	SignalBus.emit_signal("on_turn_changed")
