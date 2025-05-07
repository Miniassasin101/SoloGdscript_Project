class_name UnitActionSystem
extends Node

signal grid_position_selected(gridpos: GridPosition)

# Reference to the currently selected unit
@export var selected_unit: Unit

@onready var selected_action: Action
@onready var selected_ability: Ability

# Reference to the MouseWorld instance (set in the editor)
@export var mouse_world: MouseWorld


# Self-reference for signal emission
@onready var unit_action_system: UnitActionSystem = self

# Reference to the active Camera3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()


@export var combat_forecast: CombatForecastData = null


var is_busy: bool = false
# This is true to allow selection of a grid square during a sub ability choice
var sub_ability_choice: bool = false
var is_reacting: bool = false

var proactive_action_taken: bool = false

var gridpos_allowed: Array[GridPosition] = []

static var instance: UnitActionSystem = null


func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitActionSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	if selected_unit:
		set_selected_unit(selected_unit)
	
	#SignalBus.selected_ability_changed.connect(set_selected_ability)
	SignalBus.selected_ability_changed.connect(on_selected_ability_changed)
	SignalBus.ability_complete.connect(clear_busy)
	SignalBus.ability_complete_next.connect(on_ability_ended)
	SignalBus.new_grid_pos_hovered.connect(on_new_grid_pos_hovered)
	
	Console.add_command("create_combat_forecast", create_combat_forecast, [], 0, "Test Command in unit action system.")



func _process(_delta: float) -> void:

	# Check if the mouse is over a specific UI element
	var hovered_control = get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		return
	
	
	if is_busy and !sub_ability_choice and !is_reacting:
		return

	if Input.is_action_just_pressed("left_mouse"):
		
		
		if !TurnSystem.instance.is_player_turn or !TurnSystem.instance.combat_started:
			#return
			print_debug("Temporary Fix: is_action_just_pressed(left_mouse)")
		
		if sub_ability_choice:
			handle_sub_grid_selected()
			return
		
		if is_reacting:
			handle_selected_reaction()
			return
		
		handle_selected_ability()
		# Attempt to select a unit
		#if try_handle_unit_selection():
		#	return
		#else:
		#	handle_selected_ability()

func handle_selected_ability() -> void:
	if selected_unit and selected_ability:
		# Check if it's a proactive action (assuming selected_ability is always proactive if used during player's turn)
		if TurnSystem.instance.is_player_turn or LevelDebug.instance.control_enemy_debug:
			# Check if we've already taken a proactive action this cycle
			if TurnSystem.instance.has_taken_proactive_action_this_cycle(selected_unit) and check_ability_type_invalid(selected_ability):
				print_debug("You have already taken a proactive action this cycle!")
				return
			

			
		var mouse_grid_position = mouse_world.get_mouse_raycast_result("position")
		if mouse_grid_position:
			var grid_position: GridPosition = LevelGrid.get_grid_position(mouse_grid_position)
			if selected_unit.ability_container.can_activate_at_position(selected_ability, grid_position):
				# Attempt to spend AP
				if selected_unit.try_spend_ability_points_to_use_ability(selected_ability):
					# Activate ability
					set_busy()
					selected_unit.ability_container.activate_one(selected_ability, grid_position)
					SignalBus.emit_signal("ability_started")
					
					# Mark that we have taken a proactive action this cycle if the ability is of type "action"
					if selected_ability.tags_type.has("action"):
						TurnSystem.instance.mark_proactive_action_taken(selected_unit)

func use_ability(unit: Unit, ability: Ability, target_pos: GridPosition) -> void:
	if is_busy and !sub_ability_choice and !is_reacting:
		return
	if TurnSystem.instance.is_player_turn or LevelDebug.instance.control_enemy_debug:
		# Check if we've already taken a proactive action this cycle
		if TurnSystem.instance.has_taken_proactive_action_this_cycle(unit) and check_ability_type_invalid(selected_ability) and !is_reacting:
			print_debug("You have already taken a proactive action this cycle!")
			return
			
		if target_pos:
			if unit.ability_container.can_activate_at_position(ability, target_pos):
				# Attempt to spend AP
				if unit.try_spend_ability_points_to_use_ability(ability):
					# Activate ability
					set_busy()
					unit.ability_container.activate_one(ability, target_pos)
					SignalBus.emit_signal("ability_started")
					
					# Mark that we have taken a proactive action this cycle if the ability is of type "action"
					if ability.tags_type.has("action"):
						TurnSystem.instance.mark_proactive_action_taken(unit)

func handle_selected_reaction() -> void:
	var reacting_unit: Unit = CombatSystem.instance.current_event.target_unit
	if reacting_unit and selected_ability:
		
		if !selected_ability.tags_type.has("reaction"):
			return
		
		var mouse_grid_position = mouse_world.get_mouse_raycast_result("position")
		if mouse_grid_position:
			var grid_position: GridPosition = LevelGrid.get_grid_position(mouse_grid_position)
			if reacting_unit.ability_container.can_activate_at_position(selected_ability, grid_position):
				if reacting_unit.try_spend_ability_points_to_use_ability(selected_ability):
					reacting_unit.ability_container.activate_one(selected_ability, grid_position)
					SignalBus.emit_signal("reaction_started")


func check_ability_type_invalid(in_ability: Ability) -> bool:
	var tags: Array[String] = in_ability.tags_type
	if tags.has("reaction") or tags.has("action"):
		return true
	return false




## Is triggered when the ability completely resolves in order to move to the next phase.
## Main Phases are Action and Move phases in that order.
func on_ability_ended(ability: Ability) -> void:
	print_debug("Ability Ended Test")
	TurnSystem.instance.current_unit_turn.previous_ability = ability
	GridSystemVisual.instance.hide_all_grid_positions()
	SignalBus.next_phase.emit()
	#CombatSystem.instance.handle_phase()

## Function for handling managing sub choices in abilities, like choosing multiple targets in
## a successful ricochet ability or a secondary choice like in the turning part of Outmaneuver
func handle_ability_sub_gridpos_choice(in_gridpos_allowed: Array[GridPosition]) -> GridPosition:
	var action_container: Container = UILayer.instance.unit_action_system_ui.action_button_container
	var was_action_visible: bool = action_container.is_visible()
	action_container.set_visible(false)
	var gait_container: Container = UILayer.instance.unit_action_system_ui.gait_button_container
	var was_gait_visible: bool = gait_container.is_visible()
	UILayer.instance.unit_action_system_ui.gait_button_container.set_visible(false)
	sub_ability_choice = true
	var gridvis_ref: GridSystemVisual = GridSystemVisual.instance
	# First show the allowed grid positions on the grid
	gridvis_ref.hide_all_grid_positions()
	gridpos_allowed = in_gridpos_allowed
	gridvis_ref.show_grid_positions(gridpos_allowed)
	# Then wait for the position to be selected
	var ret_pos: GridPosition = await grid_position_selected
	# Then return the GridPosition and hide all the grid positions again
	gridvis_ref.hide_all_grid_positions()
	sub_ability_choice = false
	gridpos_allowed = []
	if was_action_visible:
		action_container.set_visible(true)
	if was_gait_visible:
		gait_container.set_visible(true)
	return ret_pos
	

# For when an ability has a sub grid choice
func handle_sub_grid_selected() -> void:
	
	var mouse_grid_position = mouse_world.get_mouse_raycast_result("position")
	if mouse_grid_position:
		var grid_position: GridPosition = LevelGrid.get_grid_position(mouse_grid_position)
		for gridpos in gridpos_allowed:
			if gridpos.equals(grid_position):
				grid_position_selected.emit(grid_position)

# Handles unit selection via mouse click
# Depreciated in current system
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
			if unit != TurnSystem.instance.current_unit_turn:
				return false
			# Select the unit
			set_selected_unit(unit)
			return true
		else:
			return false
	else:
		return false


func on_new_grid_pos_hovered() -> void:
	
	update_move_path()
	
	create_combat_forecast()

func create_combat_forecast() -> void:
	if !selected_ability:
		var combat_forecast_ui: CombatForecastUI = CombatForecastUI.instance
		combat_forecast_ui.set_visible(false)
		return
	
	if !selected_ability.tags_type.has("attack") and !selected_ability.tags_type.has("parry"):
		var combat_forecast_ui: CombatForecastUI = CombatForecastUI.instance
		combat_forecast_ui.set_visible(false)
		return
	
	var attacker: Unit = selected_unit
	
	if !MouseWorld.instance.current_hovered_grid:
		var combat_forecast_ui: CombatForecastUI = CombatForecastUI.instance
		combat_forecast_ui.set_visible(false)
		return
	
	var target_unit: Unit = LevelGrid.get_unit_at_grid_position(MouseWorld.instance.current_hovered_grid)
	if target_unit == null:
		var combat_forecast_ui: CombatForecastUI = CombatForecastUI.instance
		combat_forecast_ui.set_visible(false)
		# clear any current forecast
		return
	
	if target_unit == attacker:
		var combat_forecast_ui: CombatForecastUI = CombatForecastUI.instance
		combat_forecast_ui.set_visible(false)
		return
	
	
	
	var forecast_data: CombatForecastData = CombatForecastData.new(attacker, target_unit)
	
	combat_forecast = forecast_data
	
	var combat_forecast_ui: CombatForecastUI = CombatForecastUI.instance
	
	combat_forecast_ui.set_combat_forcast_data(forecast_data)
	
	combat_forecast_ui.set_visible(true)
	return
	


func on_selected_ability_changed(ability: Ability) -> void:
	if ability != selected_ability:
		set_selected_ability(ability)
	else:
		var unit: Unit
		if UnitActionSystem.instance.is_reacting:
			unit = CombatSystem.instance.current_event.target_unit
		else:
			unit = UnitActionSystem.instance.selected_unit
			#return

		if unit != null:
			var gridpositions: Array[GridPosition] = unit.ability_container.get_valid_ability_target_grid_position_list(ability)
			if gridpositions.size() == 1:
				use_ability(unit, ability, gridpositions[0])
				


func update_move_path() -> void:
	# Only proceed if a move ability is selected.
	if selected_ability and selected_ability is MoveAbility:
		# Get the current hovered grid cell from MouseWorld.
		var hovered_grid: GridPosition = mouse_world.current_hovered_grid
		if hovered_grid:
			# Return if the grid cell isnt currently visible.
			if !GridSystemVisual.instance.cell_at_pos_is_visible(hovered_grid):
				GridSystemVisual.instance.clear_highlights()
				return
			var start_grid: GridPosition = selected_unit.get_grid_position()
			if start_grid:
				# Compute the path from start to hovered grid cell.
				var path: Array[GridPosition] = Pathfinding.instance.find_path(start_grid, hovered_grid)
				if path.size() > 0:
					# Highlight the path cells: they will rise and be light blue.
					GridSystemVisual.instance.highlight_path(path)
				else:
					pass
					#GridSystemVisual.instance.hide_all_grid_positions()
			else:
				pass
				#GridSystemVisual.instance.hide_all_grid_positions()
		else:
			pass
			# No cell is hovered; clear any previous highlights.
			#GridSystemVisual.instance.hide_all_grid_positions()
	else:
		# Not a move ability; update grid visuals normally.
		GridSystemVisual.instance.clear_highlights()
	#	GridSystemVisual.instance.update_grid_visual()






func reset_unit_cycle_actions(unit: Unit) -> void:
	if unit == selected_unit:
		proactive_action_taken = false


func set_busy() -> void:
	is_busy = true

func set_is_reacting(val: bool = true) -> void:
	is_reacting = val
	GridSystemVisual.instance.hide_all_grid_positions()

func clear_busy(_ability: Ability = null) -> void:
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
	


# Retrieves the currently selected unit
func get_selected_unit() -> Unit:
	return selected_unit


func get_selected_ability() -> Ability:
	return selected_ability
