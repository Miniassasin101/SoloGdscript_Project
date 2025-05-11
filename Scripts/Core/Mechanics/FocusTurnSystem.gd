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
var current_unit: Unit = null:
	get:
		return current_unit
	set(value):
		current_unit = value
		SignalBus.on_ui_update.emit()


var combat_started: bool = false


var is_player_turn: bool = true:
	get:
		return is_player_turn
	set(value):
		is_player_turn = value
		SignalBus.is_player_turn.emit()


var lowest_initiative_score: int = 0


static var instance: FocusTurnSystem = null



func _ready() -> void:
	if instance != null:
		push_error("There's more than one FocusTurnSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	
	
	SignalBus.selected_unit_changed.connect(_on_selected_unit_changed)
	SignalBus.end_turn.connect(_on_end_turn)


## This is the first function that is called when combat begins. Will return with an error if initiative hasnt been rolled
## Likely it should also probably trigger initiative at the same time.
func start_combat() -> void:
	if combat_started == true:
		return
	
	# 1) Reset every unit’s initiative and put them into the queue
	_initialize_initiative()

	
	combat_started = true
	
	#is_player_turn = !current_unit.is_enemy
	
	if is_player_turn or LevelDebug.instance.control_enemy_debug:
		UnitActionSystem.instance.set_selected_unit(current_unit)
	
	advance_to_next_group()
	
	UIBus.instantiate_stats_bars.emit()
	UIBus.update_stat_bars.emit()

func _initialize_initiative():
	initiative_scores.clear()
	var count = 0
	for unit in unit_manager.get_all_units():
		initiative_scores[unit] = count
		unit.turn_state = Unit.TurnState.IN_QUEUE
		count += 1
	sort_queue()


func sort_queue():
	initiative_queue.assign(initiative_scores.keys())
	initiative_queue.sort_custom(_compare_initiative)

func _compare_initiative(a:Unit, b:Unit) -> bool:
	return initiative_scores[b] > initiative_scores[a]

func advance_to_next_group():
	for u in current_group:
		u.turn_state = Unit.TurnState.IN_QUEUE
		
	current_group.clear()
	if initiative_queue.is_empty():
		return
  
	var lead = initiative_queue[0]
	var leadScore = initiative_scores[lead]
	var leadIsEnemy = lead.is_enemy

  # gather all same‐score, same‐side into group
	for u in initiative_queue:
		if u.is_enemy != leadIsEnemy:
			break
		u.turn_state = Unit.TurnState.TURN_STARTED
		current_group.append(u)
	
	lowest_initiative_score = leadScore

	begin_group_turn()

func begin_group_turn():
	if current_group.is_empty():
		return
  # pick the index of the first who’s still queued
	var next: int = current_group.find_custom(func(u): return u.turn_state == Unit.TurnState.TURN_STARTED)
	if next < 0:
	# everyone in this group already acted → rotate initiative
		_on_group_exhausted()
		return

	var unit = current_group[next]
	unit.turn_state = Unit.TurnState.TURN_STARTED
	current_unit = unit
	is_player_turn = not unit.is_enemy

  # give control back to the ActionSystem
	if is_player_turn or LevelDebug.instance.control_enemy_debug:
		UnitActionSystem.instance.set_selected_unit(unit)

	FocusCombatSystem.instance.start_turn(unit)

func _on_group_exhausted():
  # everyone in this group has gone; sort & refill for next tick
	sort_queue()
	advance_to_next_group()
	UIBus.instantiate_stats_bars.emit()
	UIBus.update_stat_bars.emit()


func _on_end_turn():
	if not current_unit:
		return
	current_unit.turn_state = Unit.TurnState.TURN_ENDED
	begin_group_turn()
	UIBus.update_stat_bars.emit()


func _on_selected_unit_changed(to_unit: Unit):
	if current_group.has(to_unit) and to_unit != current_unit:
		# Let the player swap within the same group
		current_unit = to_unit
		FocusCombatSystem.instance.start_turn(to_unit)







func can_select_unit(to_unit: Unit) -> bool:
	return current_group.has(to_unit) and to_unit != current_unit



func current_group_has_active_members() -> bool:
	for unit in current_group:
		if unit.turn_state == Unit.TurnState.TURN_STARTED:
			return true
	return false

func get_first_active_group_member() -> Unit:
	for unit in current_group:
		if unit.turn_state == Unit.TurnState.TURN_STARTED:
			return unit
	return null



func set_current_unit(unit) -> void:
	current_unit = unit

func get_current_unit() -> Unit:
	return current_unit

func add_initiative_score(unit: Unit, amount: int) -> void:
	if not initiative_scores.has(unit):
		push_error("Tried to add initiative score to unit not in initiative_scores")
		return
	
	initiative_scores[unit] += amount
	
	UIBus.update_stat_bars.emit()
