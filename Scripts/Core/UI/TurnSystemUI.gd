class_name TurnSystemUI
extends Control

@export var end_turn_button: Button
@export var turn_counter_label: Label
@export var turn_system: TurnSystem
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_turn_label()



func end_turn() -> void:
	SignalBus.emit_signal("next_turn")
	


func _on_end_turn_button_pressed() -> void:
	SignalBus.emit_signal("next_turn")
	update_turn_label()
	
func update_turn_label() -> void:
	turn_counter_label.text = "Turn " + str(turn_system.turn_number)
