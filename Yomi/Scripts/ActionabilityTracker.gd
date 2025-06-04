class_name ActionabilityTracker
extends Node

@export var action_system: ActionSystem = null

@export var char_manager: CharManager = null

var units_pool: Array[BaseChar]

var actionable_pool: Array[BaseChar]

var locked_in_pool: Array[BaseChar]

var is_paused: bool = false

static var instance: ActionabilityTracker = null

func _ready() -> void:
	if instance != null:
		push_error("There's more than one ActionabilityTracker! - " + str(instance))
		queue_free()
		return
	instance = self
	EventBus.unit_actionable.connect(on_unit_actionable)
	action_system.locked_in.connect(on_unit_locked_in)
	
	#units_pool.append_array(char_manager.units)


func on_unit_actionable(unit: BaseChar) -> void:
	for u in units_pool:
		if u.state_machine.current_state.beats_left == 1:
			u.state_machine.current_state.play_beats(1)
	if unit in units_pool:
		if unit in actionable_pool:
			return
		actionable_pool.append(unit)
		if !is_paused:
			action_system.set_selected_unit(unit)
			is_paused = true
			
			EventBus.pause.emit()


func is_unit_actionable(unit: BaseChar) -> bool:
	if unit in actionable_pool:
		return true
	return false

func on_unit_locked_in(unit: BaseChar) -> void:
	if unit in actionable_pool:
		locked_in_pool.append(unit)
		actionable_pool.erase(unit)
		unit.state_machine.is_actionable = false
	
	if actionable_pool.is_empty():
		EventBus.resume.emit()
		is_paused = false
		return
	action_system.set_selected_unit(actionable_pool[0])
