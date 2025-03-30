class_name UnitCharacterSheetUI
extends Control

@export_category("Scenes")
@export var character_sheet_part_panel_scene: PackedScene
@export var weapon_details_popup_scene: PackedScene = null

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
@export var weapons_container: WeaponsContainer
@export var conditions_container: VBoxContainer

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
		populate_weapons_from_unit(unit)
		return

	if is_open:
		hide()
		is_open = false
		return

	show()
	is_open = true
	last_unit = unit
	_populate_from_unit(unit)
	populate_weapons_from_unit(unit)


func _on_close_button_pressed():
	hide()
	is_open = false
	return


func _populate_from_unit(unit: Unit) -> void:
	# Basic attribute labels
	if is_instance_valid(unit):
		unit_name_label.text = unit.ui_name
	else:
		unit_name_label.text = "n/a"
	action_points_label.text = "AP: " + _get_attribute_or_na(unit, "action_points")
	combat_skill_label.text = "CB: " + _get_attribute_or_na(unit, "combat_skill")
	evade_skill_label.text = "EVD: " + _get_attribute_or_na(unit, "evade_skill")
	damage_modifier_label.text ="DMG: " + _get_attribute_or_na(unit, "damage_modifier")
	initiative_bonus_label.text = "INIT: " + _get_attribute_or_na(unit, "initiative_bonus")
	experience_rolls_label.text = "EXP: " + _get_attribute_or_na(unit, "experience_rolls")
	movement_rate_label.text = "MOV: " + _get_attribute_or_na(unit, "movement_rate")
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

			var panel = character_sheet_part_panel_scene.instantiate() as CharacterSheetPartPanel
			if panel == null:
				push_error("Failed to instantiate CharacterSheetPartPanel.")
				continue
			panel._testfunc()
			panel.set_part_data(part.part_name, armor_val, health_val, max_health_val)
			body_parts_container.add_child(panel)

	# Populate conditions list
	_populate_conditions(unit)


func populate_weapons_from_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(unit.equipment):
		weapons_container.clear_weapons_display()
		return

	var all_equipped_items = unit.equipment.equipped_items
	var equipped_weapons: Array[Weapon] = []
	for item in all_equipped_items:
		if item is Weapon:
			equipped_weapons.append(item as Weapon)
	
	weapons_container.populate_weapons(equipped_weapons, self)


func _get_attribute_or_na(unit: Unit, attribute_name: String) -> String:
	if not is_instance_valid(unit) or not is_instance_valid(unit.attribute_map):
		return "n/a"

	var spec = unit.attribute_map.get_attribute_by_name(attribute_name)
	if spec == null:
		return "n/a"

	return str(spec.current_value)


# ----------------------------------------------------------------------------
# CONDITIONS-RELATED UI
# ----------------------------------------------------------------------------

##
# Called from _populate_from_unit to fill out the "conditions_container"
##
func _populate_conditions(unit: Unit) -> void:
	# Clear any old children in conditions_container
	for child in conditions_container.get_children():
		child.queue_free()

	if not is_instance_valid(unit) or not is_instance_valid(unit.conditions_manager):
		return

	var all_conditions = unit.conditions_manager.get_all_conditions()
	
	for condition in all_conditions:
		var hbox = HBoxContainer.new()
		conditions_container.add_child(hbox)

		# This text is the base name of the condition
		var text = condition.ui_name
		
		# EXAMPLE: If "BlindCondition" or something has a property like turns_left, you can display it:
		if condition.has_method("get_remaining_rounds"):
			var rounds_left = condition.call("get_remaining_rounds")
			text += " (%d rounds left)" % int(rounds_left)

		# If it's a complicated condition like fatigue, make it clickable 
		if condition.has_method("get_details_text"):
			var detail_button = Button.new()
			detail_button.text = text
			detail_button.pressed.connect(_on_condition_details_pressed.bind(condition))
			hbox.add_child(detail_button)
		else:
			# For simpler conditions, just show them in a label
			var label = Label.new()
			label.text = text
			hbox.add_child(label)


##
# Fired when a user clicks on a "complicated" condition 
# (e.g. Fatigue) to see more details in a popup.
##
func _on_condition_details_pressed_dep(condition: Condition) -> void:
	var popup = AcceptDialog.new()
	popup.title = condition.ui_name

	var info_str = "Condition: %s" % condition.ui_name
	
	if condition is FatigueCondition:
		var fatigue_details = condition.get_fatigue_details()
		info_str += "\nFatigue Level: %s" % fatigue_details.get("name", "Unknown")

		# Example: show specific fields if they exist
		if "movement_penalty" in fatigue_details:
			info_str += "\nMovement Penalty: %s" % str(fatigue_details["movement_penalty"])
		if "initiative_penalty" in fatigue_details:
			info_str += "\nInitiative Penalty: %s" % str(fatigue_details["initiative_penalty"])
		if "action_points_penalty" in fatigue_details:
			info_str += "\nAP Penalty: %s" % str(fatigue_details["action_points_penalty"])
		if "recovery_period" in fatigue_details:
			info_str += "\nRecovery Period: %s" % str(fatigue_details["recovery_period"])
	else:
		info_str += "\n(No extra information available.)"

	popup.dialog_text = info_str
	UILayer.instance.add_child(popup)
	popup.popup_centered()


func _on_condition_details_pressed(condition: Condition) -> void:
	var popup = AcceptDialog.new()
	popup.title = condition.ui_name
	
	var info_str = "Condition: %s" % condition.ui_name
	
	# Ask the condition itself for its details text, if available.
	if condition.has_method("get_details_text"):
		info_str += "\n" + condition.get_details_text()
	else:
		info_str += "\n(No extra information available.)"
		
	popup.dialog_text = info_str
	UILayer.instance.add_child(popup)
	popup.popup_centered()



##
# Shows a popup containing detailed weapon information.
##
func show_weapon_details_popup(weapon: Weapon) -> void:
	assert(weapon is Weapon)  # Ensure the input is a valid Weapon instance.

	var popup = ConfirmationDialog.new()
	popup.name = "WeaponDetailsPopup"
	popup.title = weapon.name
	popup.min_size = Vector2(400, 300)

	# Add weapon details to the popup dynamically
	var weapon_info_container = VBoxContainer.new()

	# Weapon category
	var category_label = Label.new()
	category_label.text = "Category: %s" % weapon.category
	weapon_info_container.add_child(category_label)

	# Damage info
	var damage_label = Label.new()
	damage_label.text = "Damage: %sd%s + %s" % [weapon.die_number, weapon.die_type, weapon.flat_damage]
	weapon_info_container.add_child(damage_label)

	# Weapon size
	var weapon_size_label = Label.new()
	weapon_size_label.text = "Size: %s" % _map_size_to_text(weapon.size)
	weapon_info_container.add_child(weapon_size_label)

	# Weapon reach
	var reach_label = Label.new()
	reach_label.text = "Reach: %s" % _map_reach_to_text(weapon.reach)
	weapon_info_container.add_child(reach_label)

	# Encumbrance
	var encumbrance_label = Label.new()
	encumbrance_label.text = "Encumbrance: %s" % weapon.encumberance
	weapon_info_container.add_child(encumbrance_label)

	# Armor points
	var armor_points_label = Label.new()
	armor_points_label.text = "Armor Points (AP): %s" % weapon.armor_points
	weapon_info_container.add_child(armor_points_label)

	# Hit points
	var hit_points_label = Label.new()
	hit_points_label.text = "Hit Points (HP): %s" % weapon.hit_points
	weapon_info_container.add_child(hit_points_label)

	# Traits
	if weapon.traits.size() > 0:
		var traits_label = Label.new()
		traits_label.text = "Traits: %s" % ", ".join(weapon.traits)
		weapon_info_container.add_child(traits_label)

	# Combat effects
	if weapon.combat_effects.size() > 0:
		var effects_label = Label.new()
		effects_label.text = "Combat Effects: %s" % ", ".join(weapon.combat_effects)
		weapon_info_container.add_child(effects_label)

	# Hands required
	var hands_label = Label.new()
	hands_label.text = "Hands Required: %s" % weapon.hands
	weapon_info_container.add_child(hands_label)

	# Add all information to the popup
	popup.add_child(weapon_info_container)

	# Add popup to the current scene and display it
	get_tree().root.add_child(popup)
	popup.popup_centered()
	
	
	
	##
# Maps the size integer to a readable text description.
##
func _map_size_to_text(map_size: int) -> String:
	match map_size:
		0:
			return "Small"
		1:
			return "Medium"
		2:
			return "Large"
		3:
			return "Huge"
		4:
			return "Enormous"
		_:
			return "Unknown"

##
# Maps the reach integer to a readable text description.
##
func _map_reach_to_text(reach: int) -> String:
	match reach:
		0:
			return "Touch"
		1:
			return "Short"
		2:
			return "Medium"
		3:
			return "Long"
		4:
			return "Very Long"
		_:
			return "Unknown"


##
# Example of a simple function to compute a final damage string,
# e.g. "1d6+2" or "2d8+0", etc.
##
func _compute_weapon_damage(weapon: Weapon) -> String:
	var ret: String = "{0}d{1}+{2}"

	return ret.format([weapon.die_number, weapon.die_type, weapon.flat_damage])
