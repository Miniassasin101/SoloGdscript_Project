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
	SignalBus.ability_complete.connect(on_ability_complete)

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
				if try_take_enemy_ai_ability():
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


func on_ability_complete() -> void:
	turn_finished = true
	state = State.TakingTurn  # After ability completes, move to TakingTurn state
	state_timer = 0.0  # Reset state timer

func on_turn_changed() -> void:
	timer = 1.0
	if TurnSystem.instance.is_player_turn:
		set_state_waiting()
	if !TurnSystem.instance.is_player_turn:
		set_state_taking_turn()


func try_take_enemy_ai_ability() -> bool:
	for enemy_unit: Unit in UnitManager.instance.get_enemy_units():
		current_unit = enemy_unit.name
		if try_use_enemy_ability(enemy_unit):
			return true
	print_debug("No valid abilities found for any enemy units.")
	return false


func try_use_enemy_ability(enemy_unit: Unit) -> bool:
	var best_ability: Ability = null
	var best_enemy_ai_ability: EnemyAIAction = null
	for ability: Ability in enemy_unit.ability_container.granted_abilities:
		if !enemy_unit.can_spend_ability_points_to_use_ability(ability):
			# Enemy cannot afford this ability
			continue
		var test_enemy_ai_ability: EnemyAIAction = get_best_enemy_ai_ability(enemy_unit.ability_container, ability)
		if test_enemy_ai_ability == null:
			continue
		if best_enemy_ai_ability == null or test_enemy_ai_ability.action_value > best_enemy_ai_ability.action_value:
			best_enemy_ai_ability = test_enemy_ai_ability
			best_ability = ability
	
	# Execute the best action if available
	if best_enemy_ai_ability != null and enemy_unit.try_spend_ability_points_to_use_ability(best_ability):
		var testname = best_ability.ui_name
		best_ability.ended.connect(on_ability_complete)
		enemy_unit.ability_container.activate_one(best_ability, best_enemy_ai_ability.grid_position)
		return true
	else:
		print_debug("No valid ability for enemy unit: ", enemy_unit)
		return false

func get_best_enemy_ai_ability(ability_container: AbilityContainer, ability: Ability):
	var enemy_ai_ability_list: Array[EnemyAIAction] = []
	var valid_ability_grid_position_list: Array[GridPosition] = ability_container.get_valid_ability_target_grid_position_list(ability)
	
	for grid_position: GridPosition in valid_ability_grid_position_list:
		var enemy_ai_ability: EnemyAIAction = ability_container.get_enemy_ai_ability(ability, grid_position)
		if enemy_ai_ability != null:
			enemy_ai_ability_list.append(enemy_ai_ability)

	if !enemy_ai_ability_list.is_empty():
		# Sort using a callable function to compare ability values
		enemy_ai_ability_list.sort_custom(_compare_enemy_ai_abilities)
		return enemy_ai_ability_list[0]
	else:
		# No possible Enemy AI Abilities
		print(ability.ui_name + " is not possible")
		return null

# Comparison function for sorting the enemy AI actions based on action value
func _compare_enemy_ai_abilities(a: EnemyAIAction, b: EnemyAIAction) -> bool:
	if a.action_value > b.action_value:
		return true
	else:
		return false
