class_name Testing
extends Node3D

@export var unit_1: Unit
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

func _ready() -> void:
	Console.add_command("hello", console_hello, 0, 0, "Prints Hello")
	Console.add_command("trigger_camera_shake", trigger_camera_shake)
	Console.add_command("spawn_label", console_spawn_label, ["unit_identifier", "label_text"], 1, "Spawns a text label on a unit by its ui_name or name. Use one parameter for the identifier and optionally a second for the label text.")
	Console.add_command("move_unit", console_move_unit, ["unit_identifier", "x", "z"], 3, "Moves the unit with the given identifier to the specified grid position (x, z)")
	Console.add_command("reload_scene", console_reload_scene, 0, 0, "Reloads the currently active scene.")
	Console.add_command("play_anim", console_play_anim, ["unit_identifier", "animation_name"], 2, "Plays an animation on the specified unit by name.")
	Console.add_command("equip_weapon", console_equip_weapon, ["unit_name", "weapon_name"], 2, "Equips a weapon from WeaponResources to the unit.")
	Console.add_command("unequip_weapon", console_unequip_weapon, ["unit_name"], 1, "Unequips the currently equipped weapon of the unit.")
	Console.add_command("weapon_animation_update", console_weapon_animation_update, ["unit_name"], 1, "Updates the weapon specific animations on a unit.")
	Console.add_command("remove_all_dropped_items", console_remove_all_dropped_items, 0, 0, "Removes all dropped items from the world.")
	Console.add_command("open_character_sheet", console_open_character_sheet, ["unit_name"], 1, "Opens the character sheet for the specified unit.")
	Console.add_command("flash_color", console_flash_color, ["unit_name", "color_name", "duration"], 3, "Flashes a color on the specified unit. Example: flash_color Bob RED 2.5")
	Console.add_command("start_combat", console_start_combat, 0, 0, "Starts combat.")
	Console.add_command("end_round", console_end_round, 0, 0, "Ends the current round and starts a new one.")
	Console.add_command("next_turn", console_next_turn, 0, 0, "Advances to the next turn.")
	Console.add_command("print_turn_info", console_print_turn_info, 0, 0, "Prints current turn information.")
	Console.add_command("reset_cycle_actions", console_reset_cycle_actions, 0, 0, "Resets actions for the current cycle.")
	Console.add_command("set_round", console_set_round, ["round_number"], 1, "Manually sets the round number.")
	Console.add_command("set_turn", console_set_turn, ["turn_number"], 1, "Manually sets the turn number.")
	Console.add_command("set_cycle", console_set_cycle, ["cycle_number"], 1, "Manually sets the current cycle.")
	Console.add_command("simulate_unit_death", console_simulate_unit_death, ["unit_name"], 1, "Simulates death for the specified unit.")
	Console.add_command("update_initiative", console_update_initiative, 0, 0, "Updates the initiative order.")
	Console.add_command("set_attribute", console_set_attribute, ["unit_name", "attribute_name", "new_value"], 3, "Sets the specified attribute's current value on a unit.")
	Console.add_command("apply_attribute_effect", console_apply_attribute_effect, ["unit_name", "attribute_name", "effect_value"], 3, "Applies an attribute effect on a unit's attribute map.")
	Console.add_command("apply_damage", console_apply_damage, ["unit_name", "damage", "body_part_ui_name"], 3, "Applies a damage effect to a unit's health and spawns labels. Damage should be a positive number.")



	# Add unit name autocompletes for commands that use a unit identifier:
	Console.add_command_autocomplete_list("spawn_label", get_all_unit_names())
	Console.add_command_autocomplete_list("move_unit", get_all_unit_names())
	Console.add_command_autocomplete_list("play_anim", get_all_unit_names())
	Console.add_command_autocomplete_list("unequip_weapon", get_all_unit_names())
	# For equip_weapon, combine unit and weapon names so that both are suggested:
	Console.add_command_autocomplete_list("equip_weapon", get_all_unit_and_weapon_names())
	Console.add_command_autocomplete_list("open_character_sheet", get_all_unit_names())
	Console.add_command_autocomplete_list("flash_color", get_all_unit_names())
	
	
	# Already have weapon name autocomplete for other cases if needed:
	# Console.add_command_autocomplete_list("equip_weapon", get_all_weapon_names())





func console_spawn_label(unit_identifier: String, label_text: String = "Hello from console") -> void:
	var found_unit: Unit = null
	# Loop through all units to find one with matching ui_name or node name.
	for u in UnitManager.instance.units:
		if u.ui_name == unit_identifier or u.name == unit_identifier:
			found_unit = u
			break
	if found_unit:
		# Spawn the text label on the found unit.
		Utilities.spawn_text_line(found_unit, label_text)
		Console.print_line("Spawned label on unit: " + unit_identifier)
	else:
		Console.print_error("No unit found with identifier: " + unit_identifier)

func console_move_unit(identifier: String, x_str: String, z_str: String) -> void:
	# Look up the unit by identifier (name or ui_name)
	var unit = UnitManager.instance.get_unit_by_name(identifier)
	if unit == null:
		Console.print_error("Unit not found: " + identifier)
		return

	# Convert coordinate parameters to integers
	var new_x = int(x_str)
	var new_z = int(z_str)

	# Create a new grid position (assumes a constructor GridPosition.new(x, z) exists)
	var new_grid_position: GridPosition = LevelGrid.get_grid_position_from_coords(new_x, new_z)
	
	# Optionally Update the unit's grid position (already handled in unit process
	#unit.grid_position = new_grid_position
	
	# Update the unit's world position.
	# This example assumes you have a LevelGrid helper function to convert grid positions to world coordinates.
	var new_world_pos: Vector3 = LevelGrid.get_world_position(new_grid_position)
	unit.set_global_position(new_world_pos)
	

	# Output a confirmation message to the console
	Console.print_line("Moved unit " + identifier + " to grid position (" + str(new_x) + ", " + str(new_z) + ")")

func console_reload_scene() -> void:
	var current_scene: Node = get_tree().get_current_scene()
	if current_scene == null:
		Console.print_error("No current scene is loaded.")
		return

	var scene_path: String = current_scene.get_scene_file_path()
	if scene_path.is_empty():
		Console.print_error("Could not get scene path.")
		return

	Console.print_info("Reloading current scene: " + scene_path)
	get_tree().change_scene_to_file(scene_path)

func console_play_anim(unit_identifier: String, animation_name: String) -> void:
	var unit := UnitManager.instance.get_unit_by_name(unit_identifier)
	if unit == null:
		Console.print_error("Unit not found: " + unit_identifier)
		return

	if unit.animator == null:
		Console.print_error("Unit has no animator: " + unit_identifier)
		return

	unit.animator.play_animation_by_name(animation_name)
	Console.print_info("Playing animation '" + animation_name + "' on unit '" + unit_identifier + "'")

func console_equip_weapon(unit_name: String, weapon_name: String) -> void:
	var unit := UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return

	var weapon_path := "res://Hero_Game/Scripts/Core/InventorySystem/Items/Weapons/WeaponResources/%s.tres" % weapon_name
	if not ResourceLoader.exists(weapon_path):
		Console.print_error("Weapon not found at path: " + weapon_path)
		return

	var weapon: Weapon = load(weapon_path).duplicate()
	if weapon == null:
		Console.print_error("Failed to load weapon: " + weapon_name)
		return

	unit.equipment.equip(weapon)


	Console.print_info("Equipped '%s' to unit '%s'" % [weapon.name, unit_name])

func console_unequip_weapon(unit_name: String) -> void:
	var unit := UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return

	unit.equipment.unequip_all(true)

	Console.print_info("Unequipped all weapons from unit '%s'" % unit_name)

func console_weapon_animation_update(unit_name: String) -> void:
	var unit := UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return
	
	unit.animator.weapon_setup(true, unit.get_equipped_weapon())

func console_remove_all_dropped_items() -> void:
	if ObjectManager.instance:
		ObjectManager.instance.remove_all_dropped_items()
		Console.print_info("All dropped items have been removed.")
	else:
		Console.print_error("ObjectManager instance not found.")

func console_open_character_sheet(unit_name: String) -> void:
	var unit := UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return
	SignalBus.emit_signal("open_character_sheet", unit)
	Console.print_info("Character sheet opened for unit: " + unit_name)

func console_flash_color(unit_name: String, color_name: String, duration_str: String) -> void:
	var unit: Unit = UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return

	var color: Color = Color(color_name.to_upper())
	if color == null:
		Console.print_error("Invalid color name: " + color_name)
		return

	var duration: float = float(duration_str)
	unit.animator.flash_color(color, duration)
	Console.print_info("Flashed " + color_name + " on " + unit_name + " for " + duration_str + " seconds.")

func console_start_combat() -> void:
	if TurnSystem.instance:
		TurnSystem.instance.start_combat()
		Console.print_info("Combat started.")
	else:
		Console.print_error("No TurnSystem instance found.")

func console_end_round() -> void:
	if TurnSystem.instance:
		TurnSystem.instance.end_round()
		Console.print_info("Round ended.")
	else:
		Console.print_error("No TurnSystem instance found.")

func console_next_turn() -> void:
	if TurnSystem.instance:
		TurnSystem.instance.next_turn()
		Console.print_info("Advanced to next turn.")
	else:
		Console.print_error("No TurnSystem instance found.")

func console_print_turn_info() -> void:
	if TurnSystem.instance:
		var ts: TurnSystem = TurnSystem.instance
		var current_unit_name: String =  ts.current_unit_turn.ui_name if ts.current_unit_turn else "None"
		Console.print_line("Round: " + str(ts.round_number) +
						   " | Cycle: " + str(ts.current_cycle) +
						   " | Turn: " + str(ts.turn_number) +
						   " | Current Unit: " + current_unit_name)
	else:
		Console.print_error("No TurnSystem instance found.")

func console_reset_cycle_actions() -> void:
	if TurnSystem.instance:
		TurnSystem.instance.reset_cycle_actions()
		Console.print_info("Cycle actions have been reset.")
	else:
		Console.print_error("No TurnSystem instance found.")

func console_set_round(round_str: String) -> void:
	if TurnSystem.instance:
		TurnSystem.instance.round_number = int(round_str)
		Console.print_info("Round number set to " + round_str)
	else:
		Console.print_error("No TurnSystem instance found.")

func console_set_turn(turn_str: String) -> void:
	if TurnSystem.instance:
		TurnSystem.instance.turn_number = int(turn_str)
		Console.print_info("Turn number set to " + turn_str)
	else:
		Console.print_error("No TurnSystem instance found.")

func console_set_cycle(cycle_str: String) -> void:
	if TurnSystem.instance:
		TurnSystem.instance.current_cycle = int(cycle_str)
		Console.print_info("Cycle set to " + cycle_str)
	else:
		Console.print_error("No TurnSystem instance found.")

func console_simulate_unit_death(unit_name: String) -> void:
	if TurnSystem.instance and UnitManager.instance:
		var unit = UnitManager.instance.get_unit_by_name(unit_name)
		if unit:
			TurnSystem.instance.on_unit_died(unit)
			Console.print_info("Simulated death for unit " + unit_name)
		else:
			Console.print_error("Unit " + unit_name + " not found.")
	else:
		Console.print_error("TurnSystem or UnitManager instance not found.")

func console_update_initiative() -> void:
	if TurnSystem.instance:
		TurnSystem.instance.setup_initiative()
		Console.print_info("Initiative order updated.")
	else:
		Console.print_error("No TurnSystem instance found.")

func console_set_attribute(unit_name: String, attribute_name: String, new_value_str: String) -> void:
	var unit = UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return
	if not unit.attribute_map:
		Console.print_error("No attribute map found for unit: " + unit_name)
		return
	var spec = unit.attribute_map.get_attribute_by_name(attribute_name)
	if spec == null:
		Console.print_error("Attribute '" + attribute_name + "' not found for unit: " + unit_name)
		return
	var new_value = float(new_value_str)
	spec.current_value = new_value
	Console.print_info("Set attribute '" + attribute_name + "' to " + new_value_str + " for unit " + unit_name)

func console_apply_attribute_effect(unit_name: String, attribute_name: String, effect_value_str: String) -> void:
	var unit = UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return
	if not unit.attribute_map:
		Console.print_error("No attribute map found for unit: " + unit_name)
		return
	var effect = AttributeEffect.new()
	effect.attribute_name = attribute_name
	var effect_value = float(effect_value_str)
	effect.minimum_value = effect_value
	effect.maximum_value = effect_value
	unit.attribute_map.apply_effect(effect)
	Console.print_info("Applied effect on attribute '" + attribute_name + "' with value " + effect_value_str + " on unit " + unit_name)

func console_apply_damage(unit_name: String, damage_str: String, body_part_ui_name: String) -> void:
	# Look up the unit by its name (or ui_name)
	var unit = UnitManager.instance.get_unit_by_name(unit_name)
	if unit == null:
		Console.print_error("Unit not found: " + unit_name)
		return

	# Convert the damage value from string to float.
	var damage = float(damage_str)
	
	# Create a new GameplayEffect resource.
	var effect = GameplayEffect.new()

	# Prepare an AttributeEffect for health.
	var health_effect = AttributeEffect.new()
	health_effect.attribute_name = "health"
	# Damage is negative.
	health_effect.minimum_value = -damage
	health_effect.maximum_value = -damage
	effect.attributes_affected.append(health_effect)
	
	unit.body.apply_wound_manual(unit.body._find_part_by_name(body_part_ui_name), damage)
	
	# Apply the effect using the unit's attribute map.
	if unit.attribute_map:
		unit.attribute_map.apply_effect(effect)
	else:
		Console.print_error("No attribute map found for unit: " + unit_name)
		return

	# (Optional) If you have a method to apply wounds, you could call it here.
	# unit.body.apply_wound_from_event(simulated_event) -- skipped in this console command.

	# Spawn text/damage labels to give visual feedback.
	if damage == 0:
		Utilities.spawn_text_line(unit, "Blocked", Color.BLUE)
		Utilities.spawn_damage_label(unit, damage, Color.AQUA, 0.2)
	else:
		Utilities.spawn_text_line(unit, body_part_ui_name, Color.FIREBRICK)
		Utilities.spawn_damage_label(unit, damage)  # Default color assumed crimson

	Console.print_info("Applied damage effect of " + damage_str + " to unit '" + unit_name + "' on part '" + body_part_ui_name + "'.")





# Called every frame
func _process(_delta: float) -> void:
	#test_pathfinding()
	handle_right_mouse_click()
	test_n()
	test_c()
	test_v()
"""
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
"""

func get_all_weapon_names() -> PackedStringArray:
	var dir := DirAccess.open("res://Hero_Game/Scripts/Core/InventorySystem/Items/Weapons/WeaponResources")
	var weapons := PackedStringArray()
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				weapons.append(file_name.get_basename()) # Strips .tres
			file_name = dir.get_next()
	return weapons

func get_all_unit_names() -> PackedStringArray:
	var names := PackedStringArray()
	if !UnitManager.instance:
		return []
	for unit in UnitManager.instance.units:
		# You can choose one or both (here we add the node name)
		names.append(unit.name)
		# Uncomment the next line if you want to also include the ui_name:
		names.append(unit.ui_name)
	return names

func get_all_unit_and_weapon_names() -> PackedStringArray:
	var combined: PackedStringArray = get_all_unit_names()
	combined.append_array(get_all_weapon_names())
	return combined


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

func console_hello() -> void:
	print_debug("Hello!")

func set_facing() -> void:
	unit_1.set_facing()

func turn_unit_towards_facing() -> void:
	unit_1.animator.rotate_unit_towards_facing(0)
	unit_1.facing = 0
	await get_tree().create_timer(2.5).timeout
	print_debug(unit_1.facing)



func toggle_engine_speed() -> void:
	if timescalebool:
		Engine.time_scale = 1.0
		timescalebool = false
		return
	Engine.time_scale = 0.1
	timescalebool = true


func toggle_anims_speed() -> void:
	for u: Unit in UnitManager.instance.units:
		unit_1.animator.toggle_slowdown()

func print_front_tiles() -> void:
	unit_1.set_facing()
	var grid_positions: Array[GridPosition] = Utilities.get_front_tiles(unit_1)
	for gridpos: GridPosition in grid_positions:
		print_debug(gridpos.to_str())


func make_tiles_red() -> void:
	unit_1.set_facing()
	var grid_positions: Array[GridPosition] = []
	grid_positions.append_array(Utilities.get_front_tiles(unit_1))
	grid_positions.append(Utilities.get_left_side_tile(unit_1))
	if testbool:
		GridSystemVisual.instance.unmark_red(grid_positions)
	GridSystemVisual.instance.mark_red(grid_positions)
	testbool = true

func make_cone_tiles_red() -> void:
	var grid_positions: Array[GridPosition] = []
	grid_positions.append_array(Utilities.get_left_cone(unit_1, 20))
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
	if unit_1.animator.is_looking:
		unit_1.animator.look_at_toggle()
	if in_unit and in_unit != unit_1:
		unit_1.animator.look_at_toggle(in_unit)


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
	UnitUIManager3D.instance.set_unit_part_blue(unit_1, "RightLeg")


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
	unit_1.conditions_manager.add_condition(knock_cond) 
		
	knock_cond.apply(unit_1)

func create_engagement() -> void:
	if unit_1 and unit_2:
		var engagement: Engagement = Engagement.new(unit_1, unit_2)
		engagement.initialize_line(self)

func apply_condition() -> void:
	unit_1.conditions_manager.apply_condition_by_name("impaled")


func spawn_text_at_bodypart() -> void:
	var body_part: BodyPart = unit_1.body._find_part_by_name("leg_left")
	var body_part_pos: Vector3 = body_part.get_body_part_marker_position()
	Utilities.spawn_text_line(unit_1, body_part.part_ui_name, Color.ALICE_BLUE, 1.0, body_part_pos)

func drop_equipped_weapon() -> void:
	ObjectManager.instance.drop_item_in_world(unit_1)

func equip_weapon_on_ground() -> void:
	var gridobj: GridObject = LevelGrid.grid_system.get_grid_object(unit_1.get_grid_position())

	for item in gridobj.item_list:
		if item is Weapon:
			ObjectManager.instance.equip_item(unit_1, item)
			return




func play_weapon_spin_anim() -> void:
	var weapon: Weapon = unit_1.equipment.get_equipped_weapon()
	var weapon_visual: ItemVisual = weapon.get_item_visual()
	weapon_visual.play_animation("ItemSpin", 3.0)



func print_situational_modifier_attribute() -> void:
	print(unit_1.get_attribute_after_sit_mod("evade_skill"))

func add_armor() -> void:
	var units: Array[Unit] = UnitManager.instance.get_all_units()
	for u in units:
		u.body.set_all_part_armor(100)

func remove_all_ap() -> void:
	var units: Array[Unit] = UnitManager.instance.get_all_units()
	for u in units:
		u.spend_all_ability_points()

func print_conditions() -> void:
	for condition in unit_1.conditions_manager.get_all_conditions():
		print("Condition: ", condition.ui_name)

func flash_on_equipped_weapon() -> void:
	Utilities.flash_color_on_mesh(unit_1.get_equipped_weapon().get_object() as MeshInstance3D, Color.CRIMSON)

func flash() -> void:
	unit_1.animator.flash_color(Color.YELLOW, 5.0)
	await get_tree().create_timer(3.0).timeout
	unit_1.animator.flash_color(Color.REBECCA_PURPLE)
	await get_tree().create_timer(0.6).timeout
	unit_1.animator.flash_color(Color.BLACK)
	await get_tree().create_timer(0.6).timeout
	unit_1.animator.flash_color(Color.MAGENTA)
	

#	unit.animator.flash_red()
#	unit.animator.trigger_camera_shake_large()


func spawn_text_label() -> void:
	Utilities.spawn_text_line(unit_1, "Testing, Testing, 123", Color.FOREST_GREEN)
	await get_tree().create_timer(1.0).timeout
	Utilities.spawn_text_line(unit_1, "Testing, Testing, 123", Color.CRIMSON)
	await get_tree().create_timer(1.0).timeout
	Utilities.spawn_text_line(unit_1, "Testing, Testing, 123")

func test_shift_c() -> void:
	if Input.is_action_just_pressed("testkey_shift_c"):
		#open_character_sheet()
		pass

func print_active_special_effects() -> void:
	var effects: Array[SpecialEffect] = MouseEventDroppableSlotController.instance.get_active_special_effects()
	for eff in effects:
		print(eff.ui_name)


func open_special_effect_buttons() -> void:
	SignalBus.on_player_special_effect.emit(unit_1, special_effects)







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
