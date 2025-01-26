class_name Testing
extends Node3D

@export var unit: Unit

@export var camerashake: CameraShake
@onready var unit_action_system: UnitActionSystem = $"../UnitActionSystem"
@onready var unit_ai: UnitAI = $"../UnitAI"
@onready var pathfinding: Pathfinding = $"../Pathfinding"
@onready var camera = unit_action_system.camera
@onready var mouse_world: MouseWorld = $"../MouseWorld"
@onready var unit_stats_ui: UnitStatsUI = $"../UILayer/UnitStatsUI"

@export var animlib: Array[Animation]

@export var special_effects: Array[SpecialEffect]


var testbool: bool = false
var timescalebool: bool = false


# Called every frame
func _process(_delta: float) -> void:
	test_pathfinding()
	handle_right_mouse_click()
	test_n()
	test_c()

# Testing function to visualize the path when a test key is pressed.
func test_pathfinding() -> void:
	if Input.is_action_just_pressed("testkey_b"):
		pathfinding.update_astar_walkable()
		# Get the grid position that the mouse is hovering over.
		var result = mouse_world.get_mouse_raycast_result("position")
		
		if result:
			var hovered_grid_position = pathfinding.pathfinding_grid_system.get_grid_position(result)
			
			if hovered_grid_position != null:
				# Find path from (0, 0) to the hovered grid position.
				var start_grid_position: GridPosition
				if unit_action_system.selected_unit:
					start_grid_position = unit_action_system.selected_unit.get_grid_position()
				elif start_grid_position == null:
					start_grid_position = pathfinding.pathfinding_grid_system.get_grid_position_from_coords(0, 0)
				var path = pathfinding.find_path(start_grid_position, hovered_grid_position)
				var cost = pathfinding.get_path_cost(start_grid_position, hovered_grid_position)
				# Print the path as a list of grid positions.
				for grid_position in path:
					pass
				print("Size: " + str(path.size()))
				print("Cost: " + str(cost))
				
				# Update the grid visual to show the path.
				GridSystemVisual.instance.update_grid_visual_pathfinding(path)

func handle_right_mouse_click() -> void:
	if Input.is_action_just_pressed("right_mouse"):
		#toggle_look_at_unit()
		#print_front_tiles()
		#toggle_anims_speed()
		#toggle_engine_speed()
		#make_tiles_red()
		#make_cone_tiles_red()
		#turn_unit_towards_facing()
		#set_facing()
		pass

func set_facing() -> void:
	unit.set_facing()

func turn_unit_towards_facing() -> void:
	unit.animator.rotate_unit_towards_facing(0)
	unit.facing = 0
	await get_tree().create_timer(2.5).timeout
	print_debug(unit.facing)



func toggle_engine_speed() -> void:
	if timescalebool:
		Engine.time_scale = 1.0
		timescalebool = false
		return
	Engine.time_scale = 0.1
	timescalebool = true


func toggle_anims_speed() -> void:
	for u: Unit in UnitManager.instance.units:
		unit.animator.toggle_slowdown()

func print_front_tiles() -> void:
	unit.set_facing()
	var grid_positions: Array[GridPosition] = Utilities.get_front_tiles(unit)
	for gridpos: GridPosition in grid_positions:
		print_debug(gridpos.to_str())


func make_tiles_red() -> void:
	unit.set_facing()
	var grid_positions: Array[GridPosition] = []
	grid_positions.append_array(Utilities.get_front_tiles(unit))
	grid_positions.append(Utilities.get_left_side_tile(unit))
	if testbool:
		GridSystemVisual.instance.unmark_red(grid_positions)
	GridSystemVisual.instance.mark_red(grid_positions)
	testbool = true

func make_cone_tiles_red() -> void:
	var grid_positions: Array[GridPosition] = []
	grid_positions.append_array(Utilities.get_front_cone(unit, 5))
	if testbool:
		GridSystemVisual.instance.unmark_red(grid_positions)
		testbool = false
		return
	GridSystemVisual.instance.mark_red(grid_positions)
	testbool = true


func toggle_look_at_unit() -> void:
	var result = mouse_world.get_mouse_raycast_result("position")
	var in_unit: Unit = LevelGrid.get_unit_at_grid_position(pathfinding.pathfinding_grid_system.get_grid_position(result))
	if unit.animator.is_looking:
		unit.animator.look_at_toggle()
	if in_unit and in_unit != unit:
		unit.animator.look_at_toggle(in_unit)


func trigger_camera_shake() -> void:
	var strength = 0.2 # the maximum shake strenght. The higher, the messier
	var shake_time = 0.2 # how much it will last
	var shake_frequency = 150 # will apply 250 shakes per `shake_time`

	CameraShake.instance.shake(strength, shake_time, shake_frequency)

func trigger_attack_anim() -> void:
	var root: AnimationNodeStateMachine = UnitActionSystem.instance.selected_unit.animator.animator_tree.tree_root
	var attack: AnimationNodeBlendTree = root.get_node("Attack")
	var attack_anim: AnimationNodeAnimation = attack.get_node("AttackAnimation")
	var animation: StringName = attack_anim.get_animation()
	print("Old Animation: ", animation)
	attack_anim.set_animation("GreatSwordTest1/Greatsword_Swing_001")
	#GreatSwordTest1/Greatsword_Swing_001
	UnitActionSystem.instance.selected_unit.animator.attack_anim()
	animation = attack_anim.get_animation()
	print("New Animation: ", animation)


func toggle_sword_hold():
	var units: Array[Unit] = UnitManager.instance.units
	for in_unit: Unit in units:
		in_unit.holding_weapon = !in_unit.holding_weapon
		in_unit.animator.weapon_setup(in_unit.holding_weapon)

func toggle_difficult_terrain() -> void:
	# Get the grid position under the mouse
	var result = mouse_world.get_mouse_raycast_result("position")
	if result:
		var hovered_grid_position = pathfinding.pathfinding_grid_system.get_grid_position(result)
		if hovered_grid_position != null:
			# Get the grid object
			var grid_object = pathfinding.pathfinding_grid_system.get_grid_object(hovered_grid_position)
			if grid_object:
				# Toggle difficult terrain
				grid_object.is_difficult_terrain = not grid_object.is_difficult_terrain

				# Update visuals
				var grid_visual = GridSystemVisual.instance.grid_visuals[hovered_grid_position.x][hovered_grid_position.z]
				if grid_visual:
					grid_visual.set_difficult_terrain(grid_object.is_difficult_terrain)

				# Recalculate AStar cost based on terrain type
				pathfinding.update_astar_costs()

				# Print confirmation
				if grid_object.is_difficult_terrain:
					print("Grid position " + hovered_grid_position.to_str() + " marked as difficult terrain.")
				else:
					print("Grid position " + hovered_grid_position.to_str() + " is now normal terrain.")


# Prints out all of the stats of the unit under the mouse
func print_statblock() -> void:
	var result = mouse_world.get_mouse_raycast_result("position")
	var in_unit: Unit = LevelGrid.get_unit_at_grid_position(pathfinding.pathfinding_grid_system.get_grid_position(result))
	var attributes_dict = in_unit.attribute_map.get_attributes_dict()
	print(in_unit.name)
	for attribute_name in attributes_dict.keys():
		var attribute_value = attributes_dict[attribute_name]
		print(attribute_name, ": ", attribute_value)

# Disables grid object walkability and update pathfinding.
func turn_unwalkable() -> void:
	# Get the grid position that the mouse is hovering over.
	var result = mouse_world.get_mouse_raycast_result("position")
	
	if result:
		var hovered_grid_position = pathfinding.pathfinding_grid_system.get_grid_position(result)
		
		if hovered_grid_position != null:
			# Get the grid object at the hovered position.
			var grid_object = pathfinding.pathfinding_grid_system.get_grid_object(hovered_grid_position)
			if grid_object:
				# Set the grid object to not walkable.
				grid_object.is_walkable = false
				
				# Update the AStar points in the pathfinding system.
				pathfinding.update_astar_walkable()
				print("Grid object at " + hovered_grid_position.to_str() + " is now not walkable.")

func test_n() -> void:
	if Input.is_action_just_pressed("testkey_n"):
		TurnSystem.instance.start_combat()

func test_c() -> void:
	if Input.is_action_just_pressed("testkey_c"):
		open_character_sheet()
		#equip_weapon()
		#open_special_effect_buttons()
		pass



func test_shift_c() -> void:
	if Input.is_action_just_pressed("testkey_shift_c"):
		#open_character_sheet()
		pass

func open_special_effect_buttons() -> void:
	SignalBus.on_player_special_effect.emit(unit, special_effects)

func equip_weapon() -> void:
	# Grab the unit under the mouse or whichever unit you want
	var result = mouse_world.get_mouse_raycast_result("position")
	if !result:
		return
	var test_unit: Unit = LevelGrid.get_unit_at_grid_position(
		pathfinding.pathfinding_grid_system.get_grid_position(result)
	)
	if test_unit == null:
		return
	var testitem_original: Item = preload("res://Hero_Game/Scripts/Core/InventorySystem/Items/Weapons/SwordTest.tres")
	var testitem: Item = testitem_original.duplicate()
	if !testbool:
		print(test_unit.name)
		test_unit.inventory.add_item(testitem)
		for item: Item in test_unit.inventory.items:
			print("Item: ", item.name)
		testbool = true
		return
	test_unit.equipment.equip(testitem)
	#var slot: EquipmentSlot = test_unit.equipment.find_slot_by_item(testitem)
	testbool = false
	test_unit.holding_weapon = true
	test_unit.update_weapon_anims()





func open_character_sheet() -> void:
	# Grab the unit under the mouse or whichever unit you want
	var result = mouse_world.get_mouse_raycast_result("position")
	if !result:
		return
	var hovered_unit: Unit = LevelGrid.get_unit_at_grid_position(
		pathfinding.pathfinding_grid_system.get_grid_position(result)
	)
	if hovered_unit:
		# Emit your signal passing in the unit reference
		SignalBus.emit_signal("open_character_sheet", hovered_unit)

func apply_effect(att_name: String) -> void:
	# creating a new [GameplayEffect] resource
	var effect = GameplayEffect.new()
	# creating a new [AttributeEffect] resource
	var health_effect = AttributeEffect.new()
	
	health_effect.attribute_name = att_name
	health_effect.minimum_value = -2
	health_effect.maximum_value = -2

	
	effect.attributes_affected.append(health_effect)
	
	unit_action_system.selected_unit.add_child(effect)
