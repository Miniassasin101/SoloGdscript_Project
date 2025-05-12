class_name UnitActionSystemUI
extends Node


signal continue_turn

@export_category("References")
@export var turn_system_ui: TurnSystemUI

@export var action_button_prefab: PackedScene
@export var special_effect_button_prefab: PackedScene
@export var action_button_container: BoxContainer
@export var reaction_button_container: BoxContainer
@export var gait_button_container: BoxContainer
@export var dynamic_button_picker: DynamicButtonPicker
@export var dynamic_button_container: BoxContainer
@export var special_effect_container: MouseEventDroppableSlotContainer
@export var selected_special_effect_container: MouseEventDroppableSlotContainer
@export var mouse_event_droppable_controller: MouseEventDroppableSlotController
@export var move_points_text: Label

@export_category("")
var selected_unit: Unit
var reacting_unit: Unit = null

var special_effects: Array[SpecialEffect]
var slot_list: Array[MouseEventDroppableSlot] = []


func _ready() -> void:
	SignalBus.selected_unit_changed.connect(on_selected_unit_changed)
	SignalBus.action_points_changed.connect(_update_move_points)
	SignalBus.on_turn_changed.connect(on_turn_changed)
	SignalBus.on_player_reaction.connect(on_player_reaction)
	SignalBus.on_player_special_effect.connect(on_player_special_effect)
	SignalBus.gait_selected.connect(on_gait_selected)
	
	SignalBus.on_ui_update.connect(on_ui_update)
	
	#CombatSystem.instance.on_movement_phase_start.connect(on_movement_phase_start)
	selected_unit = UnitActionSystem.instance.get_selected_unit()
	create_unit_action_buttons()
	create_unit_reaction_buttons()
	_update_move_points()
	toggle_containers_visibility_off_except([action_button_container])


func on_ui_update() -> void:
	create_unit_action_buttons()
	_update_move_points()


func movement_handler() -> void:
	create_unit_action_buttons()


func create_unit_action_buttons() -> void:
	if CombatSystem.instance.current_phase == 1: # 1 is the movement phase
		create_unit_action_buttons_move_phase()
		return
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	
	var granted_moves = selected_unit.move_container.granted_moves
	
	for move: Move in granted_moves:
		if move.tags_type.has("reaction") or move.tags_type.has("move") or move.tags_type.has("free"):
			continue # FIXME: Replace with actual Tag logic later
		if !verify_gait_allowed(selected_unit.current_gait, move):
			continue
		if !selected_unit.conditions_manager.can_use_move_given_conditions(move):
			continue
		var move_button_ui = action_button_prefab.instantiate()
		move_button_ui.set_base_move(move)
		action_button_container.add_child(move_button_ui)
	
	# This is put at the end so free actions are placed in the back
	create_unit_free_action_buttons(granted_moves)
	
	# adds a next phase button at the very end 
	#create_next_phase_button()


func create_unit_action_buttons_move_phase() -> void:
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	var granted_moves = selected_unit.move_container.granted_moves
	
	for move: Move in granted_moves:
		if move.tags_type.has("reaction") or move.tags_type.has("action") or move.tags_type.has("free"):
			continue
		if selected_unit.current_gait == Utilities.MovementGait.HOLD_GROUND and move.tags_type.has("move"):
			continue
		if verify_gait_allowed(selected_unit.current_gait, move) == false:
			continue
		if FocusTurnSystem.instance.current_cycle >= 3 and move.tags_type.has("move"):
			continue
		if CombatSystem.instance.engagement_system.is_unit_engaged(selected_unit) and move.tags_type.has("move"):
			continue
		var move_button_ui: ActionButtonUI = action_button_prefab.instantiate()
		move_button_ui.set_base_move(move) # Always call a setup function on the button when adding.
		action_button_container.add_child(move_button_ui)
	
	# This is put at the end so free actions are placed in the back
	create_unit_free_action_buttons(granted_moves)
	
	# adds a next phase button at the very end 
	#create_next_phase_button()


func create_unit_free_action_buttons(granted_moves: Array[Move]) -> void:
	for move: Move in granted_moves:
		if move.tags_type.has("free"):
			var move_button_ui: ActionButtonUI = action_button_prefab.instantiate()
			move_button_ui.set_base_move(move)
			action_button_container.add_child(move_button_ui)


## Determines if a next_phase button needs to be made.
func create_next_phase_button() -> void:
	if FocusTurnSystem.instance.get_current_unit().attribute_map.get_attribute_by_name("action_points").current_modified_value <= 0:
		if FocusTurnSystem.instance.current_cycle >= 3:
			return
		
		var move_button_ui: ActionButtonUI = action_button_prefab.instantiate()
		move_button_ui.set_no_ap()
		action_button_container.add_child(move_button_ui)

func verify_gait_allowed(current_gait: int, in_move: Move) -> bool:
	if current_gait > in_move.movement_gait:
		return false
	return true


func create_unit_reaction_buttons() -> void:
	if !reacting_unit:
		return
	for action_button in reaction_button_container.get_children():
		action_button.queue_free()
	
	for move: Move in selected_unit.move_container.granted_moves:
		if move.tags_type.has("reaction"):
			if !verify_gait_allowed(reacting_unit.current_gait, move):
				continue
			
			var can_activate: bool = false
			for gridpos in reacting_unit.move_container.get_valid_move_target_grid_position_list(move):
				if reacting_unit.move_container.can_activate_at_position(move, gridpos):
					can_activate = true
					continue
			if !can_activate:
				continue
			
			var move_button_ui = action_button_prefab.instantiate()
			move_button_ui.set_base_move(move)
			reaction_button_container.add_child(move_button_ui)


func create_unit_special_effect_buttons(abs_dif: int) -> void:
	if !reacting_unit:
		return
	mouse_event_droppable_controller.setup_special_effect_slot_containers(special_effects, abs_dif)
	


func on_selected_unit_changed(unit: Unit) -> void:
	selected_unit = unit
	create_unit_action_buttons()
	create_unit_reaction_buttons()
	_update_move_points()



func on_player_reaction(unit: Unit) -> void:
	toggle_containers_visibility_off_except([reaction_button_container])
	reacting_unit = unit
	print_debug("Selected Unit Ui Is: ", unit._to_string())
	create_unit_reaction_buttons()
	await SignalBus.reaction_started
	print_debug("Reaction Selected")
	#toggle_containers_visibility_off_except()


## This function is passed a unit and a parsed list of special effects to choose from before emitting the chosen effect.
func on_player_special_effect(unit: Unit, in_special_effects: Array[SpecialEffect], abs_dif: int) -> void:
	reacting_unit = unit
	special_effects = in_special_effects
	print_debug("Selected Unit Ui Is: ", unit._to_string())
	create_unit_special_effect_buttons(abs_dif)
	toggle_containers_visibility_off_except([mouse_event_droppable_controller])
	var ret_effects: Array[SpecialEffect] = await UIBus.effects_confirmed# as Array[SpecialEffect]
	toggle_containers_visibility_off_except()
	UIBus.effects_chosen.emit(ret_effects)
	print_debug("finished")



func on_movement_phase_start() -> void:
	#await get_tree().create_timer(0.2).timeout
	toggle_containers_visibility_off_except([gait_button_container])
	var cycle_num: int = FocusTurnSystem.instance.current_cycle
	if cycle_num >= 3: 
		movement_phase_late_cycle() # NOTE: make await later.
	elif (cycle_num == 1) or ((FocusTurnSystem.instance.current_unit_turn.current_gait == Utilities.MovementGait.HOLD_GROUND) and cycle_num == 2):
		await movement_phase_first_two_cycles()
	toggle_containers_visibility_off_except([action_button_container])
	return


func toggle_containers_visibility_off_except(containers: Array[Control] = []) -> void:
	action_button_container.set_visible(false)
	gait_button_container.set_visible(false)
	reaction_button_container.set_visible(false)
	#special_effect_container.set_visible(false)
	#selected_special_effect_container.set_visible(false)
	mouse_event_droppable_controller.set_visible(false)
	
	if !containers.is_empty():
		for container: Control in containers:
			container.set_visible(true)


func movement_phase_late_cycle() -> void:
	print_debug("Cycle is 3 or more: Movement not allowed.")
	return

# FIXME: WRONGGGG
func movement_phase_first_two_cycles() -> void:
	#prompt gait based on previous action
	var allowed_gait: int = (
FocusTurnSystem.instance.current_unit_turn.previous_move.movement_gait if 
FocusTurnSystem.instance.current_unit_turn.previous_move else 0
)
	
	create_unit_gait_buttons(allowed_gait + 1)
	await continue_turn

	return


func create_unit_gait_buttons(gaits: int) -> void:
	for gait_button: Button in gait_button_container.get_children():
		gait_button.queue_free()
	
	for gait in range(gaits):
		var gait_button_ui: ActionButtonUI = action_button_prefab.instantiate()
		gait_button_ui.set_gait(gait)
		gait_button_container.add_child(gait_button_ui)


func on_gait_selected(in_gait: int) -> void:
	print_debug("Gait Selected: ", in_gait)
	FocusTurnSystem.instance.current_unit_turn.set_gait(in_gait)
	turn_system_ui.update_gait_label()
	continue_turn.emit()


func _update_move_points() -> void:
	if !move_points_text:
		return
	if selected_unit != null:
		move_points_text.set_text("Moves Left: " + str(5 - selected_unit.moves_made))


func on_turn_changed() -> void:
	var sel_unit: Unit = UnitActionSystem.instance.get_selected_unit()
	if sel_unit == null:
		return
	on_selected_unit_changed(sel_unit)
	#self.visible = FocusTurnSystem.instance.is_player_turn
	# FIXME: Revert back later


func get_dynamic_button_picker() -> DynamicButtonPicker:
	return dynamic_button_picker
