class_name Testing
extends Node3D

@export var unit: Unit
@export var unit_2: Unit
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
	test_v()

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
	grid_positions.append_array(Utilities.get_left_cone(unit, 20))
	GridSystemVisual.instance.show_grid_positions(grid_positions)
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
	attack_anim.set_animation("HumanoidAnimLib01/Greatsword_Swing_001")
	#HumanoidAnimLib01/Greatsword_Swing_001
	#UnitActionSystem.instance.selected_unit.danimator.attack_anim()
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



func test_v() -> void:
	if Input.is_action_just_pressed("testkey_v"):
		#remove_all_ap()
		#add_armor()
		#play_weapon_spin_anim()
		#drop_equipped_weapon()
		#create_engagement()
		#apply_knockback()
		#print_relative_position()
		set_unit_part_color()
		#print_pascal()
		pass



func test_c() -> void:
	if Input.is_action_just_pressed("testkey_c"):
		open_character_sheet()
		#equip_weapon()
		#open_special_effect_buttons()
		#print_active_special_effects()
		#spawn_text_label()
		#flash()
		#flash_on_equipped_weapon()
		#print_conditions()
		#print_situational_modifier_attribute()
		#equip_weapon_on_ground()
		#spawn_text_at_bodypart()
		#apply_condition()
		pass


func print_pascal() -> void:
	var pasc: String = "Left Leg".to_pascal_case()
	print_debug(pasc)

func set_unit_part_color() -> void:
	#UnitUIManager3D.instance.set_unit_part_red(unit, "LeftArm")
	UnitUIManager3D.instance.set_unit_part_blue(unit, "RightLeg")


func select_unit() -> Unit:
	var pos: GridPosition = await UnitActionSystem.instance.handle_ability_sub_gridpos_choice(UnitManager.instance.get_all_unit_positions())
	return LevelGrid.get_unit_at_grid_position(pos)

func print_relative_position() -> void:
	var u_1: Unit = await select_unit()
	var u_2: Unit = await select_unit()
	
	var relative_pos = Utilities.get_cone_relative_position(u_1, u_2)
	
	match relative_pos:
		Utilities.RelativePosition.FRONT:
			print_debug(u_2.ui_name, " is in front of ", u_1.ui_name)
		Utilities.RelativePosition.BACK:
			print_debug(u_2.ui_name, " is behind ", u_1.ui_name)
		Utilities.RelativePosition.LEFT_SIDE:
			print_debug(u_2.ui_name, " is to the left of ", u_1.ui_name)
		Utilities.RelativePosition.RIGHT_SIDE:
			print_debug(u_2.ui_name, " is to the right of ", u_1.ui_name)
		Utilities.RelativePosition.UNKNOWN:
			print_debug(u_2.ui_name, " is in an unknown position relative to ", u_1.ui_name)

	


func apply_knockback() -> void:
	var knock_cond: KnockbackCondition = preload("res://Hero_Game/Scripts/Core/Mechanics/Conditions/ConditionResources/KnockbackConditionResource.tres")
	unit.conditions_manager.add_condition(knock_cond) 
		
	knock_cond.apply(unit)

func create_engagement() -> void:
	if unit and unit_2:
		var engagement: Engagement = Engagement.new(unit, unit_2)
		engagement.initialize_line(self)

func apply_condition() -> void:
	unit.conditions_manager.apply_condition_by_name("impaled")


func spawn_text_at_bodypart() -> void:
	var body_part: BodyPart = unit.body._find_part_by_name("leg_left")
	var body_part_pos: Vector3 = body_part.get_body_part_marker_position()
	Utilities.spawn_text_line(unit, body_part.part_ui_name, Color.ALICE_BLUE, 1.0, body_part_pos)

func drop_equipped_weapon() -> void:
	ObjectManager.instance.drop_item_in_world(unit)

func equip_weapon_on_ground() -> void:
	var gridobj: GridObject = LevelGrid.grid_system.get_grid_object(unit.get_grid_position())

	for item in gridobj.item_list:
		if item is Weapon:
			ObjectManager.instance.equip_item(unit, item)
			return




func play_weapon_spin_anim() -> void:
	var weapon: Weapon = unit.equipment.get_equipped_weapon()
	var weapon_visual: ItemVisual = weapon.get_item_visual()
	weapon_visual.play_animation("ItemSpin", 3.0)



func print_situational_modifier_attribute() -> void:
	print(unit.get_attribute_after_sit_mod("evade_skill"))

func add_armor() -> void:
	var units: Array[Unit] = UnitManager.instance.get_all_units()
	for u in units:
		u.body.set_all_part_armor(100)

func remove_all_ap() -> void:
	var units: Array[Unit] = UnitManager.instance.get_all_units()
	for u in units:
		u.spend_all_ability_points()

func print_conditions() -> void:
	for condition in unit.conditions_manager.get_all_conditions():
		print("Condition: ", condition.ui_name)

func flash_on_equipped_weapon() -> void:
	Utilities.flash_color_on_mesh(unit.get_equipped_weapon().get_object() as MeshInstance3D, Color.CRIMSON)

func flash() -> void:
	unit.animator.flash_color(Color.YELLOW, 5.0)
	await get_tree().create_timer(3.0).timeout
	unit.animator.flash_color(Color.REBECCA_PURPLE)
	await get_tree().create_timer(0.6).timeout
	unit.animator.flash_color(Color.BLACK)
	await get_tree().create_timer(0.6).timeout
	unit.animator.flash_color(Color.MAGENTA)
	

#	unit.animator.flash_red()
#	unit.animator.trigger_camera_shake_large()


func spawn_text_label() -> void:
	Utilities.spawn_text_line(unit, "Testing, Testing, 123", Color.FOREST_GREEN)
	await get_tree().create_timer(1.0).timeout
	Utilities.spawn_text_line(unit, "Testing, Testing, 123", Color.CRIMSON)
	await get_tree().create_timer(1.0).timeout
	Utilities.spawn_text_line(unit, "Testing, Testing, 123")

func test_shift_c() -> void:
	if Input.is_action_just_pressed("testkey_shift_c"):
		#open_character_sheet()
		pass

func print_active_special_effects() -> void:
	var effects: Array[SpecialEffect] = MouseEventDroppableSlotController.instance.get_active_special_effects()
	for eff in effects:
		print(eff.ui_name)


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
