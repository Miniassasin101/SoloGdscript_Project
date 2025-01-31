class_name TurnSystem
extends Node

@export var unit_manager: UnitManager
var round_number: int = 1
var turn_number: int = 1
var current_cycle: int = 1
## Tracks who has taken a proactive action this cycle.
var actions_per_cycle: Dictionary = {}
var initiative_order: Array[Unit] = []
var current_unit_turn: Unit = null:
	get:
		return current_unit_turn
	set(value):
		current_unit_turn = value
		SignalBus.on_ui_update.emit()
		
var is_player_turn: bool = true:
	get:
		return is_player_turn
	set(value):
		is_player_turn = value
		SignalBus.is_player_turn.emit()

var combat_started: bool = false

static var instance: TurnSystem = null



func _ready() -> void:
	if instance != null:
		push_error("There's more than one TurnSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	SignalBus.end_turn.connect(next_turn)
	SignalBus.on_book_keeping_ended.connect(on_book_keeping_ended)
	setup_initiative()


## Initiative Functions
# FIXME: Make happen on combat start rather than ready later.
func setup_initiative() -> void:
	initiative_order = []
	var units: Array[Unit] = unit_manager.get_all_units()
	
	# Create an array of dictionaries holding the unit and its calculated initiative
	var initiatives = []
	if !units:
		print("ERROR")
		return
	for u in units:
		var roll_value = Utilities.roll(10)
		var bonus = u.attribute_map.get_attribute_by_name("initiative_bonus").current_buffed_value
		var initiative_penalty = u.conditions_manager.get_total_initiative_penalty()  # Get penalty from conditions


		var total_initiative = roll_value + bonus + initiative_penalty

		# Stores dictionaries in the array
		initiatives.append({"unit": u, "initiative": total_initiative})
	
	# Sort the initiatives by their initiative value descending
	initiatives.sort_custom(_compare_initiative)
	
	# Extract just the units in sorted order
	for entry in initiatives:
		initiative_order.append(entry["unit"])
	prints("Unit Initiative", initiatives)
	


## Custom compare function for sorting initiatives descending by initiative value.
func _compare_initiative(a, b) -> int:
	return b["initiative"] < a["initiative"]


## This is the first function that is called when combat begins. Will return with an error if initiative hasnt been rolled
## Likely it should also probably trigger initiative at the same time.
func start_combat() -> void:
	if initiative_order.is_empty():
		push_error("No units in initiative")
		return
	unit_manager.setup_units_for_combat()
	combat_started = true
	start_round()


## Is called immediately after combat starts, as well as at the start of every round.\n
## Sets [code]current_cycle[/code] and [code]turn_number[/code] to 1 at the start of a new round.\n
## Then the [code]current_unit_turn[/code] is set to the first unit in the initiative order.
## Also sets player turn, calls book_keeping, and updates ui to reflect cycle and turn number changes.
## If it's the player's turn, then the selected unit is also set.
func start_round() -> void:
	current_cycle = 1
	turn_number = 1
	reset_cycle_actions()
	current_unit_turn = initiative_order[0]
	is_player_turn = !current_unit_turn.is_enemy
	CombatSystem.instance.book_keeping()
	SignalBus.on_ui_update.emit()
	if is_player_turn or LevelDebug.instance.control_enemy_debug:
		UnitActionSystem.instance.set_selected_unit(current_unit_turn)

	
func on_book_keeping_ended() -> void:
	print_debug("on book keeping ended")
	start_turn()


func start_turn() -> void:
	CombatSystem.instance.start_turn(current_unit_turn)

func next_turn() -> void:
	turn_number += 1
	if turn_number > initiative_order.size():
		# End of cycle
		if any_unit_has_ap_left():
			# Start new cycle
			turn_number = 1
			current_cycle += 1
			print_debug("Current Cycle: ", current_cycle)
			SignalBus.emit_signal("on_cycle_changed")
			reset_cycle_actions()
		else:
			# End of round
			end_round()
			return
	
	current_unit_turn = initiative_order[turn_number - 1]
	is_player_turn = !current_unit_turn.is_enemy
	SignalBus.on_turn_changed.emit()

	# Set the selected unit if it's a player turn
	if is_player_turn or LevelDebug.instance.control_enemy_debug:
		UnitActionSystem.instance.set_selected_unit(current_unit_turn)
		
	start_turn()


func end_turn() -> void:
	if turn_number >= initiative_order.size():
		# End of cycle: check if a new cycle is needed
		if any_unit_has_ap_left():
			turn_number = 1
			current_cycle += 1
			print_debug("Current Cycle: ", current_cycle)

			reset_cycle_actions()
			start_turn()
			return
		else:
			end_round()
			return
	next_turn()


func any_unit_has_ap_left() -> bool:
	for u in initiative_order:
		if u.attribute_map.get_attribute_by_name("action_points").current_buffed_value > 0:
			return true
	return false

func has_taken_proactive_action_this_cycle(unit: Unit) -> bool:
	return actions_per_cycle.has(unit) and actions_per_cycle[unit] == true

func mark_proactive_action_taken(unit: Unit) -> void:
	actions_per_cycle[unit] = true



func reset_cycle_actions():
	actions_per_cycle.clear()
	UnitActionSystem.instance.reset_unit_cycle_actions(current_unit_turn)





func end_round() -> void:
	round_number += 1
	turn_number = 1

	print_debug("Round Ended. New Round Number: ", round_number)
	SignalBus.on_round_changed.emit()
	start_round()



func on_unit_died(in_unit: Unit) -> void:
	# Check if the unit exists in the initiative order
	if in_unit in initiative_order:
		var index: int = initiative_order.find(in_unit)
		
		# Remove the unit from the initiative order
		initiative_order.remove_at(index)
		print_debug("Unit removed from initiative: ", in_unit)

		# Handle if the current unit is the one that died
		if current_unit_turn == in_unit:
			print_debug("Current unit died: ", in_unit)
			# Move to the next turn if it was the current unit's turn
			if initiative_order.size() > 0:
				# Ensure the turn index stays within bounds
				turn_number = min(turn_number, initiative_order.size())
				current_unit_turn = initiative_order[turn_number - 1]
				is_player_turn = !current_unit_turn.is_enemy
				SignalBus.on_turn_changed.emit()
				start_turn()
			else:
				# If no units remain, end the combat
				print_debug("Combat ended as no units remain.")
				combat_started = false
				SignalBus.combat_ended.emit()



# Getters and setters
func get_current_unit() -> Unit:
	return current_unit_turn


func get_current_round() -> int:
	return round_number
