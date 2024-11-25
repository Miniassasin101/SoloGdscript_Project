class_name ShootAction
extends Action

signal on_shoot(target_unit: Unit, shooting_unit: Unit, damage: int)

var total_spin_amount: float = 0.0
var max_shoot_distance: int = 5

var state: State
var state_timer: float
var to_turn_timer: float
var can_shoot_bullet: bool
var target_unit: Unit

enum State {
	Aiming,
	Shooting,
	Cooling
}


func _ready() -> void:
	super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	state_timer -= delta
	match state:
		State.Aiming:
			to_turn_timer -= delta
			if to_turn_timer <= 0.0:
				var aim_direction: Vector3 = (target_unit.get_world_position() - unit.get_world_position()).normalized()
				# Smoothly rotate the unit towards the movement direction.
				var target_rotation = Basis.looking_at(aim_direction, Vector3.UP, true)
				var rotate_speed: float = 3.0
				unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)
				unit.global_transform.basis = unit.global_transform.basis.orthonormalized()
		State.Shooting:
			if can_shoot_bullet:
				shoot()
				can_shoot_bullet = false
		State.Cooling:
			pass

	if state_timer <= 0.0:
		next_state()

func next_state() -> void:
	match state:
		State.Aiming:
			if state_timer <= 0.0:
				state = State.Shooting
				var shooting_state_time: float = 0.2
				state_timer = shooting_state_time
		State.Shooting:
			if state_timer <= 0.0:
				state = State.Cooling
				var cooling_state_time: float = 0.3
				state_timer = cooling_state_time

		State.Cooling:
			if state_timer <= 0.0:
				super.action_complete()
				state_timer = 0.2
				to_turn_timer = 1.0

# Later replace below logic with logic to pass along a damage dealing effect package
func shoot() -> void:
	on_shoot.emit(target_unit, get_parent(), 4)
	
	#target_unit.damage(4)

func get_action_name():
	return "Shoot"


func get_valid_action_grid_position_list() -> Array:
	var unit_grid_position: GridPosition = unit.get_grid_position()
	return get_valid_action_grid_position_list_input(unit_grid_position)

# Gets a list of valid grid positions for movement.
func get_valid_action_grid_position_list_input(unit_grid_position: GridPosition) -> Array:
	var valid_grid_position_list: Array[GridPosition] = []  # Initialize an empty array for valid grid positions.

	# Loop through the x and z ranges based on max_shoot_distance.
	for x in range(-max_shoot_distance, max_shoot_distance + 1):
		for z in range(-max_shoot_distance, max_shoot_distance + 1):
			# Create an offset grid position.
			var offset_grid_position = GridPosition.new(x, z)
			# Calculate the test grid position.
			
			
			var temp_grid_position: GridPosition = unit_grid_position.add(offset_grid_position)
			var test_grid_object: GridObject = LevelGrid.grid_system.get_grid_object(temp_grid_position)
			if test_grid_object == null:
				continue
			var test_grid_position: GridPosition = test_grid_object.get_grid_position()
			# Calculate the Euclidean distance and use that to limit the distance.
			var euclidean_distance: float = sqrt(pow(x, 2) + pow(z, 2))
			if euclidean_distance > float(max_shoot_distance):
				continue

			# Skip invalid grid positions.
			if !LevelGrid.is_valid_grid_position(test_grid_position):
				continue
			


			# Skip grid positions that are unoccupied.
			if !LevelGrid.has_any_unit_on_grid_position(test_grid_position):
				continue

			target_unit = LevelGrid.get_unit_at_grid_position(test_grid_position)

			#Replace later with actual teams functionality

			if target_unit.is_enemy == unit.is_enemy:
				# Both units are either player or enemy units
				continue
			
			var unit_world_position: Vector3 = LevelGrid.get_world_position(unit_grid_position)
			if !MouseWorld.instance.has_line_of_sight(unit_world_position + Vector3.UP,
			 target_unit.get_world_position() + Vector3.UP):
				#print_debug("No line of sight to target!" + target_unit.to_string())
				continue

			# Add the valid grid position to the list.
			valid_grid_position_list.append(test_grid_position)
	return valid_grid_position_list

func take_action(grid_position: GridPosition) -> void:
	action_start()
	target_unit = LevelGrid.get_unit_at_grid_position(grid_position)
	if target_unit.is_enemy == unit.is_enemy:
		action_complete()
		return
		
	state = State.Aiming
	var aiming_state_time: float = 1.0
	state_timer = aiming_state_time
	to_turn_timer = 0.2
	
	can_shoot_bullet = true


func get_enemy_ai_action(grid_position: GridPosition):
	var enemy_ai_action: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_action.action_value = 1000
	enemy_ai_action.grid_position = grid_position
	return enemy_ai_action

func get_target_count_at_position(grid_position: GridPosition) -> int:
	return get_valid_action_grid_position_list_input(grid_position).size()
