class_name UnitActionSystemUI
extends Node

@export var action_button_prefab: PackedScene
@export var action_button_container: BoxContainer
@export var action_points_text: Label
@export var selected_unit: Unit


func _ready() -> void:
	SignalBus.selected_unit_changed.connect(on_selected_unit_changed)
	SignalBus.action_points_changed.connect(_update_action_points)
	SignalBus.on_turn_changed.connect(on_turn_changed)
	selected_unit = UnitActionSystem.instance.get_selected_unit()
	create_unit_action_buttons()
	_update_action_points()


func create_unit_action_buttons() -> void:
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	
	for action: Action in  selected_unit.get_action_array():
		var action_button_ui = action_button_prefab.instantiate()
		action_button_ui.set_base_action(action)
		action_button_container.add_child(action_button_ui)
		
func on_selected_unit_changed(unit: Unit) -> void:
	selected_unit = unit
	create_unit_action_buttons()
	_update_action_points()


func _update_action_points() -> void:
	if selected_unit:
		action_points_text.text = "Action Points: " + str(selected_unit.get_action_points())

func on_turn_changed() -> void:
	self.visible = TurnSystem.instance.is_player_turn
