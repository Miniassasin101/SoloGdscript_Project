class_name PredictionController
extends Node



@export var simulation_duration_in_beats: int = 180
@export var pause_between_actions_in_beats: int = 15



var ghost_templates: Array[GhostTemplate] = []
var ghost_units: Array[BaseChar] = []

var is_running: bool = false
var is_paused: bool = true

var beats_elapsed_in_loop: int = 0

var reset_requested: bool = false

static var instance: PredictionController = null


func _ready() -> void:
	if instance != null:
		push_error("There's more than one PredictionController! - " + str(instance))
		queue_free()
		return
	instance = self
	
	EventBus.prediction_reset.connect(restart_prediction_loop)
	


func ghost_beat_process() -> void:
	if is_paused or !is_running:
		return
	
	
	ghost_begin_beat()
	
	
	for unit in ghost_units:
		unit.beat_physics_process()
	
	
	ghost_end_beat()
	
	

func ghost_begin_beat() -> void:
	if beats_elapsed_in_loop > simulation_duration_in_beats or reset_requested:
		if reset_requested:
			reset_requested = false
		stop_prediction()
		reset_ghosts()
		start_first_prediction()
		pass
	pass


func ghost_end_beat() -> void:
	beats_elapsed_in_loop += 1
	pass
	



func begin_prediction_setup() -> void:
	var real_units: Array[BaseChar] = ActionabilityTracker.instance.units_pool
	
	for unit in ghost_units:
		unit.queue_free()
	ghost_units.clear()
	#ghost_templates.clear()
	
	create_ghost_templates(real_units)
	create_ghosts_from_templates()
	
	start_first_prediction()
	


func create_ghost_templates(real_units: Array[BaseChar]) -> void:
	var new_templates: Array[GhostTemplate] = []
	
	for unit in real_units:
		var new_temp: GhostTemplate = GhostTemplate.create_from_unit(unit)
		
		if !new_temp:
			continue
		
		new_templates.append(new_temp)
	
	ghost_templates = new_templates


func create_ghosts_from_templates() -> void:
	var new_ghosts: Array[BaseChar] = []
	
	for template in ghost_templates:
		var original_unit: BaseChar = template.original_unit
		if !original_unit:
			pass
		var new_ghost: BaseChar = template.original_unit.duplicate() as BaseChar if original_unit else null
		self.add_child(new_ghost)
		var original_sm: StateMachine = original_unit.state_machine
		var ghost_sm: StateMachine = new_ghost.state_machine
		new_ghost.setup_from_ghost_template(template)
		
		new_ghosts.append(new_ghost)
		pass
	
	ghost_units = new_ghosts
	pass



func start_first_prediction() -> void:
	is_running = true
	is_paused = false
	beats_elapsed_in_loop = 0
	

	
	for unit in ghost_units:
		unit.state_machine.unpause_animation()
		unit.resume_physics()
	


func resume_prediction() -> void:
	if is_paused:
		for unit in ghost_units:
			unit.state_machine.unpause_animation()
			unit.resume_physics()
		is_paused = false
	pass


func stop_prediction() -> void:
	is_paused = true
	for unit in ghost_units:
		unit.state_machine.pause_animation()
		unit.pause_physics()
	pass


func reset_ghosts() -> void:
	var iter_num: int = 0
	for unit in ghost_units:
		unit.setup_from_ghost_template(ghost_templates[iter_num])
		iter_num += 1
	pass


func clear_prediction() -> void:
	is_running = false
	is_paused = true
	for unit in ghost_units:
		unit.queue_free()
	ghost_units.clear()
	ghost_templates.clear()
	pass


func restart_prediction_loop() -> void:
	if !is_running:
		return
	#stop_prediction()
	#reset_ghosts()
	#start_first_prediction()
	reset_requested = true


func update_template_for_unit(unit: BaseChar, new_action: State) -> void:
	for tmpl in ghost_templates:
		if tmpl.original_unit == unit:
			tmpl.action_override = new_action
			## Also immediately update the spawned ghost, if it already exists:
			#var ghost: BaseChar = ghost_units[i] as BaseChar
			## clear their future queue and insert the override action first
			#ghost.state_machine.state_stack.clear()
			#if new_action:
			#	ghost.state_machine.queue_state(new_action)
			## then re‐queue whatever the template had in its original queue
			#for s in tmpl.action_queue:
			#	ghost.state_machine.queue_state(s)
			return
