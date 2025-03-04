@tool
class_name ProjectileAbility extends Ability


@export var animation: Animation
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
var target_unit: Unit = null
var rolled_damage: int = 0



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	target_position = event.target_grid_position
	unit = event.unit
	target_unit = LevelGrid.get_unit_at_grid_position(target_position)
	
	if not unit or not target_position:
		return
	
	await CombatSystem.instance.declare_action(self, event)
	if !can_activate(event):
		print_debug("Action has been thwarted")
		return
	

	await rotate_unit_towards_target_enemy(event)

	#Here is where the actual attack resolution comes in
	event = await CombatSystem.instance.attack_unit(self, event)

	await event.unit.get_tree().create_timer(0.5).timeout

	await shoot_projectile()
	
	@warning_ignore("redundant_await")
	await resolve_special_effects()
	
	
	@warning_ignore("redundant_await")
	await apply_effect()
	
	if can_end(event):
		event.successful = true
		CombatSystem.instance.on_attack_ended(event)
		end_ability(event)
	
	# Reset the positionings of the user and target
	await unit.get_tree().create_timer(2.0).timeout
	unit.animator.rotate_unit_towards_facing()
	call_deferred("target_unit_reset")

func target_unit_reset() -> void:
	if target_unit != null:
		target_unit.animator.parry_reset.emit()
		target_unit.animator.on_stop_being_targeted()
		await unit.get_tree().create_timer(1.0).timeout
		target_unit.animator.rotate_unit_towards_facing()


func rotate_unit_towards_target_enemy(_event: ActivationEvent) -> void:
	var animator: UnitAnimator = unit.animator
	animator.rotate_unit_towards_target_position(event.target_grid_position)
	await animator.rotation_completed

	# NOTE await doesnt do anything right now but later the coroutine will prompt user or ai decisions
	# on things like special effects.
	




func shoot_projectile_dep() -> void:
	assert(unit.shoot_point != null)
	await unit.animator.left_cast_anim(null, event.miss)
	var projectile_instance: Projectile = projectile.instantiate()
	# Will need to dynamically adjust shoot height later
	var target_shoot_at_position: Vector3 = LevelGrid.get_world_position(target_position) + Vector3(0.0, 1.2, 0.0)
	projectile_instance.setup(target_shoot_at_position, event.miss) #Add miss logic later
	event.unit.add_child(projectile_instance)
	projectile_instance.global_position = unit.shoot_point.global_position
	projectile_instance.global_transform.basis = unit.shoot_point.global_transform.basis
	projectile_instance.trigger_projectile()
	await projectile_instance.target_hit


func shoot_projectile() -> void:
	assert(unit.shoot_point != null)
	await unit.animator.attack_anim(animation, event.miss)#unit.animator.left_cast_anim(null, event.miss)
	var projectile_instance: Projectile = projectile.instantiate()
	# Will need to dynamically adjust shoot height later
	var target_shoot_at_position: Vector3 = LevelGrid.get_world_position(target_position) + Vector3(0.0, 1.2, 0.0)
	projectile_instance.setup(target_shoot_at_position, event.miss) #Add miss logic later
	event.unit.add_child(projectile_instance)
	projectile_instance.global_position = unit.shoot_point.global_position
	projectile_instance.global_transform.basis = unit.shoot_point.global_transform.basis
	projectile_instance.trigger_projectile()
	await projectile_instance.target_hit
	


	

func apply_effect() -> void:
	if event.miss or event.bypass_attack:
		return
	# Create a new GameplayEffect resource
	var effect = GameplayEffect.new()

	# Prepare an AttributeEffect for health
	var health_effect = AttributeEffect.new()
	health_effect.attribute_name = "health"
	health_effect.minimum_value = -event.rolled_damage
	health_effect.maximum_value = -event.rolled_damage
	effect.attributes_affected.append(health_effect)
	#effect.attributes_affected.append(part_effect)

	# Get the target unit from the grid and attach the effect
	if target_unit:
		target_unit.add_child(effect)
	
	target_unit.body.apply_wound_from_event(event)
	
	if event.rolled_damage == 0:
		Utilities.spawn_text_line(target_unit, "Blocked", Color.BLUE)
		Utilities.spawn_damage_label(target_unit, event.rolled_damage, Color.AQUA, 0.2)
	else:
		Utilities.spawn_text_line(target_unit,event.body_part_ui_name, Color.FIREBRICK)
		Utilities.spawn_damage_label(target_unit, event.rolled_damage) # Default color is crimson



func apply_effect_dep() -> void:
	var tar_unit: Unit = LevelGrid.get_unit_at_grid_position(event.target_grid_position)
	# creating a new [GameplayEffect] resource
	var effect: GameplayEffect = GameplayEffect.new()
	# creating a new [AttributeEffect] resource
	var health_effect: AttributeEffect = AttributeEffect.new()
	
	health_effect.attribute_name = "health"
	health_effect.minimum_value = -event.rolled_damage
	health_effect.maximum_value = -event.rolled_damage

	effect.attributes_affected.append(health_effect)
	
	tar_unit.add_child(effect)

	tar_unit.body.apply_wound_from_event(event)


	if !event.miss:
		if event.rolled_damage == 0:
			tar_unit.animator.flash_white()
		else:
			tar_unit.animator.flash_red()
	elif event.miss:
		tar_unit.animator.flash_white(0.4)
		Utilities.spawn_text_line(tar_unit, "Miss", Color.AQUA)
	
	



func resolve_special_effects() -> void:
	for effect in event.special_effects:
		if effect.can_apply(event) and (effect.activation_phase == effect.ActivationPhase.PostDamage):
			effect.apply(event)




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
			
			
			var temp_grid_position: GridPosition = _event.unit.get_grid_position().add(offset_grid_position)
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

			var tar_unit = LevelGrid.get_unit_at_grid_position(test_grid_position)

			#Replace later with actual teams functionality

			if tar_unit.is_enemy == _event.unit.is_enemy:
				# Both units are either player or enemy units
				continue
			
			var unit_world_position: Vector3 = LevelGrid.get_world_position(_event.unit.get_grid_position())
			if !MouseWorld.instance.has_line_of_sight(unit_world_position + Vector3.UP,
			 tar_unit.get_world_position() + Vector3.UP):
				#print_debug("No line of sight to target!" + tar_unit.to_string())
				continue

			# Add the valid grid position to the list.
			valid_grid_position_list.append(test_grid_position)
	return valid_grid_position_list


func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 1000
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
