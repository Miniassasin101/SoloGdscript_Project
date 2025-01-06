@tool
class_name ProjectileAbility extends Ability

@export_group("Attributes")
@export var damage: int = 6
@export var die_number: int = 1
@export var flat_damage: int = 0
@export var attack_range: int = 5
@export var ap_cost: int = 1

@export_group("Prefabs")
@export var projectile: PackedScene


var total_spin_amount: float = 0.0
var event: ActivationEvent = null
var target_position: GridPosition = null
var unit: Unit
var rolled_damage: int = 0



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	target_position = event.target_grid_position
	unit = event.character
	
	if not unit or not target_position:
		return
	
	await CombatSystem.instance.declare_action(self, event)
	if !can_activate(event):
		print_debug("Action has been thwarted")
		return
	

	rotate_unit_towards_target_enemy(event)
	# creating a new [GameplayEffect] node

	


func rotate_unit_towards_target_enemy(_event: ActivationEvent) -> void:
	var animator: UnitAnimator = unit.animator
	animator.rotate_unit_towards_target_position(event.target_grid_position)
	await animator.rotation_completed
	var timer = Timer.new()
	
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = 0.5
	timer.timeout.connect(shoot_projectile)
	# NOTE await doesnt do anything right now but later the coroutine will prompt user or ai decisions
	# on things like special effects.
	
	#Here is where the actual attack resolution comes in
	event = await CombatSystem.instance.attack_unit(self, event)
	event.character.add_child(timer)
	
	

func shoot_projectile() -> void:
	assert(unit.shoot_point != null)
	
	var projectile_instance: Projectile = projectile.instantiate()
	# Will need to dynamically adjust shoot height later
	var target_shoot_at_position: Vector3 = LevelGrid.get_world_position(target_position) + Vector3(0.0, 1.2, 0.0)
	projectile_instance.setup(target_shoot_at_position, false) #Add miss logic later
	
	event.character.add_child(projectile_instance)
	projectile_instance.global_transform.origin = unit.shoot_point.global_transform.origin
	projectile_instance.global_transform.basis = unit.shoot_point.global_transform.basis
	projectile_instance.target_hit.connect(apply_effect)
	

func apply_effect() -> void:
	# creating a new [GameplayEffect] resource
	var effect = GameplayEffect.new()
	# creating a new [AttributeEffect] resource
	var health_effect = AttributeEffect.new()
	
	health_effect.attribute_name = "health"
	health_effect.minimum_value = -event.rolled_damage
	health_effect.maximum_value = -event.rolled_damage

	var part_effect = AttributeEffect.new()
	
	part_effect.attribute_name = event.body_part
	part_effect.minimum_value = -event.rolled_damage
	part_effect.maximum_value = -event.rolled_damage
	
	
	
	effect.attributes_affected.append(health_effect)
	effect.attributes_affected.append(part_effect)
	
	LevelGrid.get_unit_at_grid_position(event.target_grid_position).add_child(effect)
	
	if can_end(event):
		end_ability(event)




func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false

	var valid_grid_position_list = get_valid_ability_target_grid_position_list(_event)
	for x in valid_grid_position_list:
		if x._equals(_event.target_grid_position):
			return true
	return false


# Gets a list of valid grid positions for shooting.
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []  # Initialize an empty array for valid grid positions.

	# Loop through the x and z ranges based on max_shoot_distance.
	for x in range(-attack_range, attack_range + 1):
		for z in range(-attack_range, attack_range + 1):
			# Create an offset grid position.
			var offset_grid_position = GridPosition.new(x, z)
			# Calculate the test grid position.
			
			
			var temp_grid_position: GridPosition = _event.character.get_grid_position().add(offset_grid_position)
			var test_grid_object: GridObject = LevelGrid.grid_system.get_grid_object(temp_grid_position)
			if test_grid_object == null:
				continue
			var test_grid_position: GridPosition = test_grid_object.get_grid_position()
			# Calculate the Euclidean distance and use that to limit the distance.
			var euclidean_distance: float = sqrt(pow(x, 2) + pow(z, 2))
			if euclidean_distance > float(attack_range):
				continue

			# Skip invalid grid positions.
			if !LevelGrid.is_valid_grid_position(test_grid_position):
				continue
			


			# Skip grid positions that are unoccupied.
			if !LevelGrid.has_any_unit_on_grid_position(test_grid_position):
				continue

			var target_unit = LevelGrid.get_unit_at_grid_position(test_grid_position)

			#Replace later with actual teams functionality

			if target_unit.is_enemy == _event.character.is_enemy:
				# Both units are either player or enemy units
				continue
			
			var unit_world_position: Vector3 = LevelGrid.get_world_position(_event.character.get_grid_position())
			if !MouseWorld.instance.has_line_of_sight(unit_world_position + Vector3.UP,
			 target_unit.get_world_position() + Vector3.UP):
				#print_debug("No line of sight to target!" + target_unit.to_string())
				continue

			# Add the valid grid position to the list.
			valid_grid_position_list.append(test_grid_position)
	return valid_grid_position_list


func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 1000
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
