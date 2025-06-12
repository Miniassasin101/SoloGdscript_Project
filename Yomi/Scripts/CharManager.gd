class_name CharManager
extends Node


@export var actionability_tracker: ActionabilityTracker = null

@export var prediction_controller: PredictionController = null


var is_started: bool = false

var is_paused: bool = false

var units: Array[BaseChar] = []

static var instance: CharManager = null



func _ready() -> void:
	if instance != null:
		push_error("There's more than one CharManager! - " + str(instance))
		queue_free()
		return
	instance = self
	



func _process(delta: float) -> void:
	if is_started:
		return
		
	if Input.is_action_just_pressed("testkey_n"):
		initialize_units()
		is_started = true
		EventBus.combat_started.emit()

func _physics_process(delta: float) -> void:
	if not is_started:
		return
	
		# --- Begin Frame ---
	actionability_tracker.begin_frame()

	# --- Registration Phase ---
	for unit in units:
		unit.beat_physics_process(delta)
	
	prediction_controller.ghost_beat_process()
	
	
	#PredictionController.instance

	# --- Freeze Phase ---
	actionability_tracker.end_frame()
	


func initialize_units() -> void:
	# Iterate through all children and add those of type Unit to the units array
	for child in get_children():
		if child is BaseChar:
			if child in units:
				continue
			units.append(child)
			actionability_tracker.units_pool.append(child)
			child.state_machine.start_machine()
			child.resume_physics()
			
			BeatUtils.spawn_text_line(child, "Added")


func get_unit_by_index(index: int = 0) -> BaseChar:
	if units.is_empty():
		return null
	
	return units[index]


func get_all_units() -> Array[BaseChar]:
	return units
