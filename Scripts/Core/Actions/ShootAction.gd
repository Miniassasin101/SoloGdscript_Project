class_name ShootAction
extends Action


var total_spin_amount: float = 0.0
var max_shoot_distance: int = 3

var state: State
var state_timer: float
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
func _process(delta: float) -> void:
	if not is_active:
		return
	
	state_timer -= delta
	match state:
		State.Aiming:
			var aim_direction: Vector3 = (target_unit.get_world_position() - unit.get_world_position()).normalized()
			# Smoothly rotate the unit towards the movement direction.
			var target_rotation = Basis.looking_at(aim_direction, Vector3.UP, true)
			var rotate_speed: float = 10.0
			unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)
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
				var shooting_state_time: float = 0.1
				state_timer = shooting_state_time
		State.Shooting:
			if state_timer <= 0.0:
				state = State.Cooling
				var cooling_state_time: float = 0.5
				state_timer = cooling_state_time

		State.Cooling:
			if state_timer <= 0.0:
				super.action_complete()

# Later replace below logic with logic to pass along a damage dealing effect package
func shoot() -> void:
	target_unit.damage()

func get_action_name():
	return "Shoot"

# Gets a list of valid grid positions for movement.
func get_valid_action_grid_position_list() -> Array:
	var valid_grid_position_list: Array[GridPosition] = []  # Initialize an empty array for valid grid positions.
	var unit_grid_position: GridPosition = unit.get_grid_position()

	# Loop through the x and z ranges based on max_shoot_distance.
	for x in range(-max_shoot_distance, max_shoot_distance + 1):
		for z in range(-max_shoot_distance, max_shoot_distance + 1):
			# Create an offset grid position.
			var offset_grid_position = GridPosition.new(x, z)
			# Calculate the test grid position.
			var test_grid_position: GridPosition = unit_grid_position.add(offset_grid_position)
			
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

			var target_unit: Unit = LevelGrid.get_unit_at_grid_position(test_grid_position)

			#Replace later with actual teams functionality

			if target_unit.is_enemy == unit.is_enemy:
				# Both units are either player or enemy units
				continue

			# Add the valid grid position to the list.
			valid_grid_position_list.append(test_grid_position)
	return valid_grid_position_list

func take_action(grid_position: GridPosition) -> void:
	action_start()
	target_unit = LevelGrid.get_unit_at_grid_position(grid_position)
	state = State.Aiming
	var aiming_state_time: float = 1.0
	state_timer = aiming_state_time
	
	can_shoot_bullet = true
