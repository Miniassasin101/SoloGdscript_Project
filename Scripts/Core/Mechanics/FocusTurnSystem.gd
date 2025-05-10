class_name FocusTurnSystem
extends Node


@export var unit_manager: UnitManager



var turn_number: int = 1:
	set(value):
		turn_number = value
		SignalBus.on_ui_update.emit()

# our map of Unit→initiative value (int)
var initiative_scores: Dictionary = {}


# fully sorted list of all Units
var initiative_queue: Array[Unit] = []



# the slice of Units who all go on this tick
var current_group: Array[Unit] = []:
	get:
		return current_group
	set(value):
		current_group = value
		SignalBus.on_ui_update.emit()

# Whichever unit is currently selected/actionable
var current_unit_turn: Unit = null:
	get:
		return current_unit_turn
	set(value):
		current_unit_turn = value
		SignalBus.on_ui_update.emit()


var combat_started: bool = false


var is_player_turn: bool = true:
	get:
		return is_player_turn
	set(value):
		is_player_turn = value
		SignalBus.is_player_turn.emit()




static var instance: FocusTurnSystem = null



func _ready() -> void:
	if instance != null:
		push_error("There's more than one FocusTurnSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	
	SignalBus.end_turn.connect(next_turn)


## This is the first function that is called when combat begins. Will return with an error if initiative hasnt been rolled
## Likely it should also probably trigger initiative at the same time.
func start_combat() -> void:
	if combat_started == true:
		return
	
	var init: int = 0
	# Reset all unit initiative scores
	for unit in unit_manager.get_all_units():
		initiative_scores[unit] = init
		init += 1

	# Sort queue initially
	_resort_initiative_queue()

	
	if initiative_queue.is_empty():
		push_error("No units in initiative_queue")
		return
	

	
	_prepare_next_group()
	
	#unit_manager.setup_units_for_combat()
	combat_started = true
	#CombatSystem.instance.engagement_system.generate_engagements()
	#start_round()
	current_unit_turn = current_group[0]
	
	is_player_turn = !current_unit_turn.is_enemy
	
	if is_player_turn or LevelDebug.instance.control_enemy_debug:
		UnitActionSystem.instance.set_selected_unit(current_unit_turn)
	
	start_turn()



func start_turn(unit: Unit = current_unit_turn) -> void:
	FocusCombatSystem.instance.start_turn(current_unit_turn)


func next_turn() -> void:
	pass



## Initiative Functions
func _resort_initiative_queue():
	initiative_queue.assign(initiative_scores.keys())
	initiative_queue.sort_custom(_compare_initiative)

func _compare_initiative(a: Unit, b: Unit) -> bool:
	return initiative_scores[b] > initiative_scores[a]


## Build the next group of simultaneously‐acting units.
## This can also just be one unit sandwiched in-between enemies
func _prepare_next_group() -> void:
	current_group.clear()
	
	var first_unit: Unit = initiative_queue[0]
	var first_unit_is_enemy: bool = first_unit.is_enemy
	var first_score: int = initiative_scores[first_unit]
	
	# Gather all units with the same score and team

	for unit in initiative_queue:
		if unit.is_enemy != first_unit_is_enemy:
			break
		current_group.append(unit)
	
	# Now these units can act in any order
	#SignalBus.start_simultaneous_turn.emit(current_group)


func set_current_unit(unit) -> void:
	current_unit_turn = unit

func get_current_unit() -> Unit:
	return current_unit_turn
