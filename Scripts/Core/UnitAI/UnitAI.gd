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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.on_turn_changed.connect(on_turn_changed)
	SignalBus.action_complete.connect(on_action_complete)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if TurnSystem.instance.is_player_turn:
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
		State.Busy:
			pass  # State remains busy until we receive the action complete signal


func set_state_taking_turn() -> void:
	timer = 0.5
	state = State.TakingTurn

func set_state_busy() -> void:
	state = State.Busy
	turn_finished = false

func set_state_waiting() -> void:
	state = State.WaitingForEnemyTurn


func on_action_complete() -> void:
	turn_finished = true
	state = State.TakingTurn  # After action completes, move to TakingTurn state


func on_turn_changed() -> void:
	timer = 1.0
	if !TurnSystem.instance.is_player_turn:
		set_state_taking_turn()

func try_take_enemy_ai_action() -> bool:
	for enemy_unit: Unit in UnitManager.instance.get_enemy_units():
		if try_take_enemy_action(enemy_unit):
			return true
	return false

func try_take_enemy_action(enemy_unit: Unit) -> bool:
	var best_action: Action = null
	var best_enemy_ai_action: EnemyAIAction = null
	for action: Action in enemy_unit.get_action_array():
		if !enemy_unit.can_spend_action_points_to_take_action(action):
			# Enemy cannot afford this action
			continue
		if best_enemy_ai_action == null:
			best_enemy_ai_action = action.get_best_enemy_ai_action()
			best_action = action
		else:
			var test_enemy_ai_action: EnemyAIAction = action.get_best_enemy_ai_action()
			if test_enemy_ai_action != null and test_enemy_ai_action.action_value > best_enemy_ai_action.action_value:
				best_enemy_ai_action = test_enemy_ai_action
				best_action = action
	if best_enemy_ai_action != null and enemy_unit.try_spend_action_points_to_take_action(best_action):
		best_action.take_action(best_enemy_ai_action.grid_position)
		return true
	else:
		return false
