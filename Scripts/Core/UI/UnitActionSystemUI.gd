class_name UnitActionSystemUI
extends Node

@export var action_button_prefab: PackedScene
@export var action_button_container: BoxContainer
@export var ability_points_text: Label
var selected_unit: Unit


func _ready() -> void:
	SignalBus.selected_unit_changed.connect(on_selected_unit_changed)
	SignalBus.action_points_changed.connect(_update_ability_points)
	SignalBus.on_turn_changed.connect(on_turn_changed)
	selected_unit = UnitActionSystem.instance.get_selected_unit()
	create_unit_action_buttons()
	_update_ability_points()


func create_unit_action_buttons() -> void:
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	
	for ability: Ability in selected_unit.ability_container.granted_abilities:
		var ability_button_ui = action_button_prefab.instantiate()
		ability_button_ui.set_base_ability(ability)
		action_button_container.add_child(ability_button_ui)
		
func on_selected_unit_changed(unit: Unit) -> void:
	selected_unit = unit
	create_unit_action_buttons()
	_update_ability_points()


func _update_ability_points() -> void:
	if selected_unit != null:
		ability_points_text.text = ("Ability Points: " + str(selected_unit.attribute_map.
		get_attribute_by_name("action_points").current_buffed_value))

func on_turn_changed() -> void:
	self.visible = TurnSystem.instance.is_player_turn
