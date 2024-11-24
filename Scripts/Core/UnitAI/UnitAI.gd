class_name UnitAI
extends Node

enum State {
	WaitingForEnemyTurn,
	TakingTurn,
	Busy,
}

var state: State = State.WaitingForEnemyTurn
var timer: float = 0.0
var turn_finished: bool = true
var current_unit

const TIMEOUT_LIMIT: float = 5.0  # Maximum time allowed in a state before fallback
var state_timer: float = 0.0  # Timer to track time spent in a state

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.on_turn_changed.connect(on_turn_changed)
	SignalBus.action_complete.connect(on_action_complete)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if TurnSystem.instance.is_player_turn:
		return

	# Increment state timer
	state_timer += _delta

	# Check for timeout to prevent getting stuck in a state
	if state_timer > TIMEOUT_LIMIT:
		push_error("State timeout detected in state: ", state)
		set_state_waiting()
		return

	match state:
		State.WaitingForEnemyTurn:
			pass
		State.TakingTurn:
			if turn_finished:
				if try_take_enemy_ai_action():
					set_state_busy()
				else:
					# No more enemies have actions to take
					TurnSystem.instance.end_turn()
					set_state_waiting()
		State.Busy:
			pass  # State remains busy until we receive the action complete signal


func set_state_taking_turn() -> void:
	timer = 0.5
	state = State.TakingTurn
	state_timer = 0.0  # Reset state timer

func set_state_busy() -> void:
	state = State.Busy
	state_timer = 0.0  # Reset state timer
	turn_finished = false

func set_state_waiting() -> void:
	state = State.WaitingForEnemyTurn
	state_timer = 0.0  # Reset state timer


func on_action_complete() -> void:
	turn_finished = true
	state = State.TakingTurn  # After action completes, move to TakingTurn state
	state_timer = 0.0  # Reset state timer


func on_turn_changed() -> void:
	timer = 1.0
	if TurnSystem.instance.is_player_turn:
		set_state_waiting()
	if !TurnSystem.instance.is_player_turn:
		set_state_taking_turn()

func try_take_enemy_ai_action() -> bool:
	for enemy_unit: Unit in UnitManager.instance.get_enemy_units():
		current_unit = enemy_unit.name
		if try_take_enemy_action(enemy_unit):
			return true
	print_debug("No valid actions found for any enemy units.")
	return false

func try_take_enemy_action(enemy_unit: Unit) -> bool:
	var best_action: Action = null
	var best_enemy_ai_action: EnemyAIAction = null
	for action: Action in enemy_unit.get_action_array():
		if !enemy_unit.can_spend_action_points_to_take_action(action):
			# Enemy cannot afford this action
			continue
		var test_enemy_ai_action: EnemyAIAction = action.get_best_enemy_ai_action()
		if test_enemy_ai_action == null:
			continue
		if best_enemy_ai_action == null or test_enemy_ai_action.action_value > best_enemy_ai_action.action_value:
			best_enemy_ai_action = test_enemy_ai_action
			best_action = action
	
	# Execute the best action if available
	if best_enemy_ai_action != null and enemy_unit.try_spend_action_points_to_take_action(best_action):
		print_debug("Enemy unit ", enemy_unit, " takes action: ", best_action)
		best_action.take_action(best_enemy_ai_action.grid_position)
		return true
	else:
		print_debug("No valid action for enemy unit: ", enemy_unit)
		return false
