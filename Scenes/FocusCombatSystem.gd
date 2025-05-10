class_name FocusCombatSystem 
extends Node



@export var book_keeping_system: BookKeepingSystem


static var instance: FocusCombatSystem = null


func _ready() -> void:
	if instance != null:
		push_error("There's more than one FocusCombatSystem! - " + str(instance))
		queue_free()
		return
	instance = self


# Tracks and handles any over time effects or spells
func book_keeping() -> void:
	# Apply poison, bleed, persistent effects, etc.
	book_keeping_system.run_book_keeping_check()


	SignalBus.on_book_keeping_ended.emit()


func start_turn(unit: Unit) -> void:
	print_debug("FocusCombatSystem Turn Started: ", unit)

	unit.conditions_manager.apply_conditions_turn_interval()
	
	SignalBus.on_ui_update.emit()
	

func handle_unit_turn(unit: Unit) -> void:
	
