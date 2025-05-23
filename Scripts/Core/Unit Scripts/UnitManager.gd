class_name UnitManager
extends Node

@export var unit_action_system: UnitActionSystem
# Arrays to store references to child units.
var units: Array[Unit] = []
var friendly_units: Array[Unit] = []
var enemy_units: Array[Unit] = []



static var instance: UnitManager = null

@export var sword_test: Weapon = null

func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitManager! - " + str(instance))
		queue_free()
		return
	instance = self

	initialize_units()
	

	
	#if LevelDebug.instance.auto_equip_debug:
		#get_tree().process_frame.connect(test_equip_units, CONNECT_ONE_SHOT)

	connect_global_signals()

func trigger_unit_ui_setup() -> void:
	UnitUIManager3D.instance.setup_unit_ui(units)

func test_equip_units() -> void:

	#var iteration_num: int = 1
	for unit: Unit in units:
		var new_weapon: Weapon = null
		if unit.weapons_equip_combat_start.is_empty():
			if sword_test:
				new_weapon = sword_test.duplicate()
				unit.equipment.equip(new_weapon)
		else:
			for weapon in unit.weapons_equip_combat_start:
				new_weapon = weapon.duplicate()
				unit.equipment.equip(new_weapon)

		#new_weapon.name = new_weapon.name + " " + str(iteration_num)
		#iteration_num += 1
		#unit.equipment.equip(new_weapon)
# Initializes the units by storing references to all child units.
func initialize_units() -> void:
	# Iterate through all children and add those of type Unit to the units array
	for child in get_children():
		if child is Unit:
			units.append(child)
			child.unit_manager = self  # Set this manager reference in the unit
			_update_unit_lists(child)
	SignalBus.form_body.emit()
	print(units)

func setup_units_for_combat() -> void:
	for unit in get_all_units():
		unit.setup_fatigue_left()
	
	trigger_unit_ui_setup()
	
	test_equip_units()


# Connects the UnitManager to global signals
func connect_global_signals() -> void:
	SignalBus.add_unit.connect(_on_add_unit)
	SignalBus.remove_unit.connect(_on_remove_unit)





# React to the global "add_unit" signal
func _on_add_unit(unit: Unit) -> void:
	add_unit(unit)

# React to the global "remove_unit" signal
func _on_remove_unit(unit: Unit) -> void:
	remove_unit(unit)
	TurnSystem.instance.on_unit_died(unit)

# Adds a new unit to the manager (e.g., during runtime).
func add_unit(unit: Unit) -> void:
	if unit not in units:
		units.append(unit)
		unit.unit_manager = self  # Set reference back to this manager
		_update_unit_lists(unit)
		unit.body._on_setup_body()
		call_deferred("unit_setup", unit)
		SignalBus.on_unit_added.emit(unit)




func unit_setup(unit: Unit) -> void:
		TurnSystem.instance.setup_initiative()
		
		SignalBus.on_unit_added.emit(unit)
		
		
		unit.body.update_body_ui()


# Removes a unit from the manager (e.g., when it is destroyed).
func remove_unit(unit: Unit) -> void:
	if unit in units:
		units.erase(unit)
		_update_unit_lists(unit, true)

		# If combat is underway, update the initiative order.

		unit_setup(unit)
		
		SignalBus.on_unit_removed.emit(unit)
		# Finally, remove the unit node from the scene.
		unit.remove_self()
		


# Updates the friendly and enemy unit lists based on a unit's type.
func _update_unit_lists(unit: Unit, remove: bool = false) -> void:
	if unit.is_enemy:
		if remove:
			enemy_units.erase(unit)
		elif unit not in enemy_units:
			enemy_units.append(unit)
	else:
		if remove:
			friendly_units.erase(unit)
		elif unit not in friendly_units:
			friendly_units.append(unit)

# Get a reference to all units managed by this manager.
func get_all_units() -> Array[Unit]:
	return units

# Get all enemy units.
func get_enemy_units() -> Array[Unit]:
	return enemy_units

# Get all player units.
func get_player_units() -> Array[Unit]:
	return friendly_units

# Retrieves a specific unit by its name.
func get_unit_by_name(unitname: String) -> Unit:
	for unit in units:
		if unit.name == unitname or unit.ui_name == unitname:
			return unit
	return null


## returns an array of every grid position adjacent to an enemy.
## Used for engagement mostly.
func get_enemy_adjacent_positions(in_unit: Unit) -> Array[GridPosition]:
	var u: Array[Unit] = enemy_units if in_unit.is_enemy == false else friendly_units
	var ret_array: Array[GridPosition] = []
	for unit in u:
		ret_array.append_array(Utilities.get_adjacent_tiles_with_diagonal(unit))
	return ret_array

func get_enemy_positions(in_unit: Unit) -> Array[GridPosition]:
	var u: Array[Unit] = enemy_units if in_unit.is_enemy == false else friendly_units
	var ret_array: Array[GridPosition] = []
	for unit in u:
		ret_array.append(unit.get_grid_position())
	return ret_array
	

func get_all_unit_positions() -> Array[GridPosition]:
	var ret_array: Array[GridPosition] = []
	for unit in units:
		ret_array.append(unit.get_grid_position())
	return ret_array


# Sets the action system reference for all units.
func set_action_system_for_units(action_system: UnitActionSystem) -> void:
	unit_action_system = action_system
	for unit in units:
		unit.action_system = unit_action_system

# Debug print to list all units in the manager.
func print_all_units() -> void:
	for unit in units:
		print(unit.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Optional: Process logic related to all units can be placed here if needed
	pass
