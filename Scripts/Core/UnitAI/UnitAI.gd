class_name UnitAI
extends Node

enum State {
	WaitingForEnemyTurn,
	TakingTurn,
	Busy,
}

var state: State = State.WaitingForEnemyTurn
var timer: float = 0.0
var turn_finished: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.on_turn_changed.connect(on_turn_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if TurnSystem.instance.is_player_turn:
		return
	
	match state:
		State.WaitingForEnemyTurn:
			pass
		State.TakingTurn:
			timer -= delta
			if timer <= 0.0:
				if try_take_enemy_ai_action():
					set_state_busy()
				else:
					# No more enemies have actions to take
					TurnSystem.instance.end_turn()
		State.Busy:
			timer -= delta
			if timer <= 0.0:
				state = State.TakingTurn  # Go back to TakingTurn to continue with the next unit

func set_state_taking_turn() -> void:
	timer = 0.5
	state = State.TakingTurn

func set_state_busy() -> void:
	timer = 1.0
	state = State.Busy

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
	var spin_action: SpinAction = enemy_unit.get_action("Spin")
	if enemy_unit and spin_action:
		var action_grid_position = enemy_unit.get_grid_position()
		if action_grid_position:
			if spin_action.is_valid_action_grid_position(action_grid_position):
				if enemy_unit.try_spend_action_points_to_take_action(spin_action): # also spends the action points
					spin_action.take_action(action_grid_position)
					return true
	return false
