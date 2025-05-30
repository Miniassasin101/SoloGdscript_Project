class_name ActionSystem
extends Node


@export var unit: BaseChar = null



static var instance: ActionSystem = null



func _ready() -> void:
	if instance != null:
		push_error("There's more than one ActionSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	
	EventBus.combat_started.connect(on_combat_started)
	EventBus.selection_locked_in.connect(on_action_locked_in)


func on_combat_started():
	populate_action_bar()


func populate_action_bar():
	print_debug("working")
	EventBus.unit_actionable.emit()
	pass

func on_action_locked_in(action: State) -> void:
	print_debug("State Locked In: " + action.state_name)
	action.on_action_unfocused()
	action.on_action_locked_in()
	unit.state_machine.queue_state(action)
	unit.state_machine._advance_state()
	EventBus.resume.emit()
