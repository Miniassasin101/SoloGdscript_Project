class_name CombatSystem
extends Node
"""
Manages and resolves combat interactions/reactions/disputes globally. 
Also deals with the combat flow in any individual turn.
"""
static var instance: CombatSystem = null



func _ready() -> void:
	if instance != null:
		push_error("There's more than one CombatSystem! - " + str(instance))
		queue_free()
		return
	instance = self

## Here things like poison, bleed, peristent effects, cost for energy draining abilities, ect. goes off.
func book_keeping() -> void:
	#placeholder
	SignalBus.on_book_keeping_ended.emit()


# NOTE: Later add functionality to take multiple units turns at once or in any order if same team
func start_turn(unit: Unit) -> void:
	print_debug("CombatSystem Turn Started: ", unit)
