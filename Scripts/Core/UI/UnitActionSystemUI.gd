class_name UnitActionSystemUI
extends Node


signal continue_turn

@export_category("Refrerences")
@export var turn_system_ui: TurnSystemUI


@export_category("")
@export var action_button_prefab: PackedScene
@export var action_button_container: BoxContainer
@export var reaction_button_container: BoxContainer
@export var gait_button_container: BoxContainer
@export var ability_points_text: Label
var selected_unit: Unit
var reacting_unit: Unit = null



func _ready() -> void:
	SignalBus.selected_unit_changed.connect(on_selected_unit_changed)
	SignalBus.action_points_changed.connect(_update_ability_points)
	SignalBus.on_turn_changed.connect(on_turn_changed)
	SignalBus.on_player_reaction.connect(on_player_reaction)
	SignalBus.gait_selected.connect(on_gait_selected)
	
	SignalBus.on_ui_update.connect(on_ui_update)
	
	#CombatSystem.instance.on_movement_phase_start.connect(on_movement_phase_start)
	selected_unit = UnitActionSystem.instance.get_selected_unit()
	create_unit_action_buttons()
	create_unit_reaction_buttons()
	_update_ability_points()
	reaction_button_container.visible = false
	gait_button_container.visible = false


func on_ui_update() -> void:
	create_unit_action_buttons()
	_update_ability_points()


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
	
	var granted_abilities = selected_unit.ability_container.granted_abilities
	
	for ability: Ability in granted_abilities:
		if ability.tags_type.has("reaction") or ability.tags_type.has("move") or ability.tags_type.has("free"):
			continue # FIXME: Replace with actual Tag logic later
		if !verify_gait_allowed(selected_unit.current_gait, ability):
			continue
		var ability_button_ui = action_button_prefab.instantiate()
		ability_button_ui.set_base_ability(ability)
		action_button_container.add_child(ability_button_ui)
	
	# This is put at the end so free actions are placed in the back
	create_unit_free_action_buttons(granted_abilities)
	
	# adds a next phase button at the very end 
	create_next_phase_button()


func create_unit_action_buttons_move_phase() -> void:
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	var granted_abilities = selected_unit.ability_container.granted_abilities
	
	for ability: Ability in granted_abilities:
		if ability.tags_type.has("reaction") or ability.tags_type.has("action") or ability.tags_type.has("free"):
			continue
		if selected_unit.current_gait == Utilities.MovementGait.HOLD_GROUND and ability.tags_type.has("move"):
			continue
		if verify_gait_allowed(selected_unit.current_gait, ability) == false:
			continue
		var ability_button_ui: ActionButtonUI = action_button_prefab.instantiate()
		ability_button_ui.set_base_ability(ability) # Always call a setup function on the button when adding.
		action_button_container.add_child(ability_button_ui)
	
	# This is put at the end so free actions are placed in the back
	create_unit_free_action_buttons(granted_abilities)
	
	# adds a next phase button at the very end 
	#create_next_phase_button()


func create_unit_free_action_buttons(granted_abilities: Array[Ability]) -> void:
	for ability: Ability in granted_abilities:
		if ability.tags_type.has("free"):
			var ability_button_ui: ActionButtonUI = action_button_prefab.instantiate()
			ability_button_ui.set_base_ability(ability)
			action_button_container.add_child(ability_button_ui)


## Determines if a next_phase button needs to be made.
func create_next_phase_button() -> void:
	if TurnSystem.instance.current_unit_turn.attribute_map.get_attribute_by_name("action_points").current_buffed_value == 0:
		var ability_button_ui: ActionButtonUI = action_button_prefab.instantiate()
		ability_button_ui.set_no_ap()
		action_button_container.add_child(ability_button_ui)

func verify_gait_allowed(current_gait: int, in_ability: Ability) -> bool:
	if current_gait > in_ability.movement_gait:
		return false
	return true


func create_unit_reaction_buttons() -> void:
	if !reacting_unit:
		return
	for action_button in reaction_button_container.get_children():
		action_button.queue_free()
	
	for ability: Ability in selected_unit.ability_container.granted_abilities:
		if ability.tags_type.has("reaction"):
			if !verify_gait_allowed(reacting_unit.current_gait, ability):
				continue
			var ability_button_ui = action_button_prefab.instantiate()
			ability_button_ui.set_base_ability(ability)
			reaction_button_container.add_child(ability_button_ui)



func on_selected_unit_changed(unit: Unit) -> void:
	selected_unit = unit
	create_unit_action_buttons()
	create_unit_reaction_buttons()
	_update_ability_points()


func on_player_reaction(unit: Unit) -> void:
	reaction_button_container.visible = true
	action_button_container.visible = false
	reacting_unit = unit
	print_debug("Selected Unit Ui Is: ", unit._to_string())
	create_unit_reaction_buttons()
	await SignalBus.reaction_selected
	print_debug("Reaction Selected")
	reaction_button_container.visible = false
	#action_button_container.visible = true


func on_movement_phase_start() -> void:
	#await get_tree().create_timer(0.2).timeout
	action_button_container.set_visible(false)
	gait_button_container.set_visible(true)
	var cycle_num: int = TurnSystem.instance.current_cycle
	if cycle_num >= 3: 
		movement_phase_late_cycle() # NOTE: make await later.
	elif (cycle_num == 1) or ((TurnSystem.instance.current_unit_turn.current_gait == Utilities.MovementGait.HOLD_GROUND) and cycle_num == 2):
		await movement_phase_first_two_cycles()
	action_button_container.set_visible(true)
	gait_button_container.set_visible(false)
	return





func movement_phase_late_cycle() -> void:
	print_debug("Cycle is 3 or more: Movement not allowed.")
	return

# FIXME: WRONGGGG
func movement_phase_first_two_cycles() -> void:
	#prompt gait based on previous action
	var allowed_gait: int = (
TurnSystem.instance.current_unit_turn.previous_ability.movement_gait if 
TurnSystem.instance.current_unit_turn.previous_ability else 0
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
	TurnSystem.instance.current_unit_turn.set_gait(in_gait)
	turn_system_ui.update_gait_label()
	continue_turn.emit()


func _update_ability_points() -> void:
	if selected_unit != null:
		ability_points_text.text = ("Ability Points: " + str(selected_unit.attribute_map.
		get_attribute_by_name("action_points").current_buffed_value))


func on_turn_changed() -> void:
	on_selected_unit_changed(UnitActionSystem.instance.get_selected_unit())
	#self.visible = TurnSystem.instance.is_player_turn
	# FIXME: Revert back later
