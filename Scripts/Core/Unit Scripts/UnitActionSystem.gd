class_name UnitActionSystem
extends Node

# Reference to the currently selected unit
@export var selected_unit: Unit

@onready var selected_action: Action
@onready var selected_ability: Ability

# Reference to the MouseWorld instance (set in the editor)
@export var mouse_world: MouseWorld

# Reference to the RayCast3D node (set in the editor)
@export var raycast: RayCast3D

# Self-reference for signal emission
@onready var unit_action_system: UnitActionSystem = self



# Reference to the active Camera3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()

var is_busy: bool = false
var proactive_action_taken: bool = false


static var instance: UnitActionSystem = null


func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitActionSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	if selected_unit:
		set_selected_unit(selected_unit)
	
	SignalBus.selected_ability_changed.connect(set_selected_ability)
	SignalBus.ability_complete.connect(clear_busy)



func _process(_delta: float) -> void:
	if is_busy:
		return

	# Check if the mouse is over a specific UI element
	var hovered_control = get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		return

	if Input.is_action_just_pressed("left_mouse"):
		if !TurnSystem.instance.is_player_turn or !TurnSystem.instance.combat_started:
			#return
			print_debug("Temporary Fix")
		# Attempt to select a unit
		if try_handle_unit_selection():
			return
		else:
			handle_selected_ability()

func handle_selected_ability() -> void:
	if selected_unit and selected_ability:
		# Check if it's a proactive action (assuming selected_ability is always proactive if used during player's turn)
		if TurnSystem.instance.is_player_turn or LevelDebug.instance.control_enemy_debug:
			# Check if we've already taken a proactive action this cycle
			if TurnSystem.instance.has_taken_proactive_action_this_cycle(selected_unit):
				print_debug("You have already taken a proactive action this cycle!")
				return

			
		var mouse_grid_position = mouse_world.get_mouse_raycast_result("position")
		if mouse_grid_position:
			var grid_position: GridPosition = LevelGrid.get_grid_position(mouse_grid_position)
			if selected_unit.ability_container.can_activate_at_position(selected_ability, grid_position):
				# Attempt to spend AP
				if selected_unit.try_spend_ability_points_to_use_ability(selected_ability):
					# Activate ability
					selected_unit.ability_container.activate_one(selected_ability, grid_position)
					set_busy()
					SignalBus.emit_signal("ability_started")
					
					# Mark that we have taken a proactive action this cycle
					TurnSystem.instance.mark_proactive_action_taken(selected_unit)





# Handles unit selection via mouse click
func try_handle_unit_selection() -> bool:
	# Perform raycast to detect units
	var collider = mouse_world.get_mouse_raycast_result("collider")

	# Check if the raycast hit something
	if collider != null:
		var unit = collider.get_parent()
		if unit is Unit and unit != selected_unit:
			if unit.is_enemy:
				# Clicked on an enemy
				print_debug("Temporary debug fix to allow me to control enemy units")
				#return false
			elif unit != TurnSystem.instance.current_unit_turn:
				return false
			# Select the unit
			set_selected_unit(unit)
			return true
		else:
			return false
	else:
		return false

func reset_unit_cycle_actions(unit: Unit) -> void:
	if unit == selected_unit:
		proactive_action_taken = false


func set_busy() -> void:
	is_busy = true

func clear_busy() -> void:
	#print("clearbusy")
	SignalBus.update_grid_visual.emit()
	is_busy = false

func set_selected_unit(unit: Unit) -> void:
	selected_unit = unit
	#var aco = unit.ability_container.abilities
	if !unit.ability_container.abilities.is_empty():
		set_selected_ability(unit.ability_container.granted_abilities[0])
	SignalBus.selected_unit_changed.emit(unit)


func set_selected_ability(ability: Ability) -> void:
	selected_ability = ability
	SignalBus.update_grid_visual.emit()
	

func set_selected_action_by_name(action_name: String) -> void:
	if selected_unit:
		var action = selected_unit.get_action(action_name)
		if action != null:
			selected_action = action
			SignalBus.selected_action_changed.emit(action)
		else:
			print("Action not found: ", action_name)


# Retrieves the currently selected unit
func get_selected_unit() -> Unit:
	return selected_unit


func get_selected_ability() -> Ability:
	return selected_ability
