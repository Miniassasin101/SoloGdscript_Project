class_name UnitActionSystemUI
extends Node

@export var action_button_prefab: PackedScene
@export var action_button_container: BoxContainer
@export var reaction_button_container: BoxContainer
@export var ability_points_text: Label
var selected_unit: Unit


func _ready() -> void:
	SignalBus.selected_unit_changed.connect(on_selected_unit_changed)
	SignalBus.action_points_changed.connect(_update_ability_points)
	SignalBus.on_turn_changed.connect(on_turn_changed)
	SignalBus.on_player_reaction.connect(on_player_reaction)
	selected_unit = UnitActionSystem.instance.get_selected_unit()
	create_unit_action_buttons()
	create_unit_reaction_buttons()
	_update_ability_points()
	reaction_button_container.visible = false


func create_unit_action_buttons() -> void:
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	
	for ability: Ability in selected_unit.ability_container.granted_abilities:
		var ability_button_ui = action_button_prefab.instantiate()
		ability_button_ui.set_base_ability(ability)
		action_button_container.add_child(ability_button_ui)

func create_unit_reaction_buttons() -> void:
	if !selected_unit:
		return
	for action_button in reaction_button_container.get_children():
		action_button.queue_free()
	
	for ability: Ability in selected_unit.ability_container.granted_abilities:
		if ability.tags_type.has("reaction"):
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
	selected_unit = unit
	print_debug("Selected Unit Ui Is: ", unit._to_string())
	create_unit_reaction_buttons()
	await SignalBus.reaction_selected
	print_debug("Reaction Selected")
	reaction_button_container.visible = false
	action_button_container.visible = true



func _update_ability_points() -> void:
	if selected_unit != null:
		ability_points_text.text = ("Ability Points: " + str(selected_unit.attribute_map.
		get_attribute_by_name("action_points").current_buffed_value))

func on_turn_changed() -> void:
	on_selected_unit_changed(UnitActionSystem.instance.get_selected_unit())
	self.visible = true #TurnSystem.instance.is_player_turn
	# FIXME: Revert back later
