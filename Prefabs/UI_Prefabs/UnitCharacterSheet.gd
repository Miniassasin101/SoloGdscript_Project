class_name UnitCharacterSheetUI
extends Control

@export_category("Scenes")
@export var character_sheet_part_panel_scene: PackedScene

@export_category("Labels")
@export var unit_name_label: Label
@export var action_points_label: Label
@export var unused_label_1: Label
@export var combat_skill_label: Label
@export var evade_skill_label: Label
@export var damage_modifier_label: Label
@export var initiative_bonus_label: Label
@export var experience_rolls_label: Label
@export var movement_rate_label: Label
@export var unused_label_2: Label
@export var size_label: Label
@export var power_label: Label
@export var dexterity_label: Label
@export var endurance_label: Label
@export var mind_label: Label
@export var will_label: Label
@export var presence_label: Label

@export_category("Containers")
@export var body_parts_container: VBoxContainer
# Will be cleared then populated with the data from the unit's body parts

@export_category("Buttons")
@export var close_button: Button

var is_open: bool = false
var last_unit: Unit = null

func _ready() -> void:
	visible = false
	SignalBus.open_character_sheet.connect(_on_open_character_sheet)
	close_button.pressed.connect(_on_close_button_pressed)

func _on_open_character_sheet(unit: Unit) -> void:
	if not is_instance_valid(unit):
		hide()
		is_open = false
		return

	if unit != last_unit:
		show()
		is_open = true
		last_unit = unit
		_populate_from_unit(unit)
		return

	if is_open:
		hide()
		is_open = false
		return

	show()
	is_open = true
	last_unit = unit
	_populate_from_unit(unit)

func _on_close_button_pressed():
	hide()
	is_open = false
	return

func _populate_from_unit(unit: Unit) -> void:
	assert(is_instance_valid(unit.attribute_map))

	# Basic Labels
	unit_name_label.text = unit.name if is_instance_valid(unit) else "n/a"
	action_points_label.text = _get_attribute_or_na(unit, "action_points")
	unused_label_1.text = ""
	combat_skill_label.text = _get_attribute_or_na(unit, "combat_skill")
	evade_skill_label.text = _get_attribute_or_na(unit, "evade_skill")
	damage_modifier_label.text = _get_attribute_or_na(unit, "damage_modifier")
	initiative_bonus_label.text = _get_attribute_or_na(unit, "initiative_bonus")
	experience_rolls_label.text = _get_attribute_or_na(unit, "experience_rolls")
	movement_rate_label.text = _get_attribute_or_na(unit, "movement_rate")
	unused_label_2.text = ""

	size_label.text = _get_attribute_or_na(unit, "size")
	power_label.text = _get_attribute_or_na(unit, "power")
	dexterity_label.text = _get_attribute_or_na(unit, "dexterity")
	endurance_label.text = _get_attribute_or_na(unit, "endurance")
	mind_label.text = _get_attribute_or_na(unit, "mind")
	will_label.text = _get_attribute_or_na(unit, "will")
	presence_label.text = _get_attribute_or_na(unit, "presence")

	# Clear old body-part panels
	for child in body_parts_container.get_children():
		child.queue_free()


	# Populate body-part panels if the unit's body is valid
	if is_instance_valid(unit.body):
		for part in unit.body.body_parts:
			var armor_val = unit.body.get_part_armor(part.part_name)
			var health_val = unit.body.get_part_health(part.part_name)
			var max_health_val = unit.body.get_part_health(part.part_name, true)

			# Instantiate the panel from the preloaded scene
			var panel = character_sheet_part_panel_scene.instantiate() as CharacterSheetPartPanel
			if panel == null:
				push_error("Failed to instantiate CharacterSheetPartPanel.")
				continue
			panel._testfunc()
			# Set part data
			panel.set_part_data(part.part_name, armor_val, health_val, max_health_val)

			# Add the panel to the body_parts_container
			body_parts_container.add_child(panel)


func _get_attribute_or_na(unit: Unit, attribute_name: String) -> String:
	if not is_instance_valid(unit) or not is_instance_valid(unit.attribute_map):
		return "n/a"

	var spec = unit.attribute_map.get_attribute_by_name(attribute_name)
	if spec == null:
		return "n/a"

	return str(spec.current_value)
