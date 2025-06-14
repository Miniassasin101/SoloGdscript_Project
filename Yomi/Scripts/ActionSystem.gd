class_name ActionSystem
extends Node


signal locked_in(unit: BaseChar)


@export var unit: BaseChar = null

@export var action_system_ui: ActionSystemUI = null

@export var actionability_tracker: ActionabilityTracker = null

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
	#populate_action_bar()
	pass


func populate_action_bar():
	print_debug("working")
	EventBus.unit_actionable.emit(unit)
	pass

func on_action_locked_in(action: State) -> void:
	print_debug("State Locked In: " + action.state_name)
	action.on_action_unfocused()
	action.on_action_locked_in()
	unit.state_machine.queue_state(action)
	unit.state_machine._advance_state()
	unit.beat_physics_process()
	locked_in.emit(unit)
	#EventBus.resume.emit()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left_mouse"):
		if try_handle_unit_selection():
			return
	
	if Input.is_action_just_pressed("space_key"):
		action_system_ui._on_lock_in_button_pressed()




func try_handle_unit_selection() -> bool:
	var collider: CollisionObject3D = MouseController.instance.get_mouse_raycast_result("collider")
	if !collider:
		return false
	var in_unit: BaseChar = collider as BaseChar
	
	if !in_unit:
		return false
		
	if in_unit.is_ghost:
		return false
	
	if !actionability_tracker.is_unit_actionable(in_unit):
		return false
	
	if in_unit != action_system_ui.selected_unit:
		set_selected_unit(in_unit)
		
	
	return true

func set_selected_unit(in_unit: BaseChar) -> void:
	action_system_ui.on_selected_unit_changed(in_unit)
	unit = in_unit
