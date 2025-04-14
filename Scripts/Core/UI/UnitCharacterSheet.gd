class_name UnitCharacterSheetUI
extends Control

@export_category("Scenes")
@export var character_sheet_part_panel_scene: PackedScene  # (Not used for body parts anymore)
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
# Note: body_parts_container is now an instance of BodyPartsContainer.
@export var body_parts_container: BodyPartsContainer
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

func _on_close_button_pressed() -> void:
	hide()
	is_open = false
	return

func _populate_from_unit(unit: Unit) -> void:
	# Update basic attribute labels.
	if is_instance_valid(unit):
		unit_name_label.text = unit.ui_name
	else:
		unit_name_label.text = "n/a"
	action_points_label.text = "AP: " + _get_attribute_or_na(unit, "action_points")
	combat_skill_label.text = "CB: " + _get_attribute_or_na(unit, "combat_skill")
	evade_skill_label.text = "EVD: " + _get_attribute_or_na(unit, "evade_skill")
	damage_modifier_label.text = "DMG: " + _get_attribute_or_na(unit, "damage_modifier")
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

	# Update body parts display using the refactored container.
	# If the unit has a valid body, let BodyPartsContainer handle population;
	# otherwise, clear any existing data.
	if is_instance_valid(unit.body):
		body_parts_container.populate_body_parts(unit)
	else:
		body_parts_container.clear_body_parts_display()

	# Update conditions list.
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

	return str(int(spec.current_value))

func _populate_conditions(unit: Unit) -> void:
	# Clear the conditions container first.
	for child in conditions_container.get_children():
		child.queue_free()

	if not is_instance_valid(unit) or not is_instance_valid(unit.conditions_manager):
		return

	var all_conditions: Array[Condition] = unit.conditions_manager.get_all_conditions()
	
	for condition in all_conditions:
		var hbox = HBoxContainer.new()
		conditions_container.add_child(hbox)

		# Base text is the condition's name.
		var text = condition.ui_name
		
		# Optionally display extra details such as rounds left.
		if condition.has_method("get_remaining_rounds"):
			var rounds_left = condition.call("get_remaining_rounds")
			text += " (%d rounds left)" % int(rounds_left)

		# If the condition offers details, make it clickable.
		if condition.has_method("get_details_text"):
			var detail_button = Button.new()
			detail_button.text = text
			detail_button.pressed.connect(_on_condition_details_pressed.bind(condition))
			hbox.add_child(detail_button)
		else:
			var label = Label.new()
			label.text = text
			hbox.add_child(label)

func _on_condition_details_pressed(condition: Condition) -> void:
	var popup = AcceptDialog.new()
	popup.title = condition.ui_name
	
	var info_str = "Condition: %s" % condition.ui_name
	if condition.has_method("get_details_text"):
		info_str += "\n" + condition.get_details_text()
	else:
		info_str += "\n(No extra information available.)"
		
	popup.dialog_text = info_str
	UILayer.instance.add_child(popup)
	popup.popup_centered()

func show_weapon_details_popup(weapon: Weapon) -> void:
	# Shows a popup with detailed weapon information.
	assert(weapon is Weapon)
	var popup = ConfirmationDialog.new()
	popup.name = "WeaponDetailsPopup"
	popup.title = weapon.name
	popup.min_size = Vector2(400, 300)

	var weapon_info_container = VBoxContainer.new()

	var category_label = Label.new()
	category_label.text = "Category: %s" % weapon.category
	weapon_info_container.add_child(category_label)

	var damage_label = Label.new()
	damage_label.text = "Damage: %sd%s + %s" % [weapon.die_number, weapon.die_type, weapon.flat_damage]
	weapon_info_container.add_child(damage_label)

	var weapon_size_label = Label.new()
	weapon_size_label.text = "Size: %s" % _map_size_to_text(weapon.size)
	weapon_info_container.add_child(weapon_size_label)

	var reach_label = Label.new()
	reach_label.text = "Reach: %s" % _map_reach_to_text(weapon.reach)
	weapon_info_container.add_child(reach_label)

	var encumbrance_label = Label.new()
	encumbrance_label.text = "Encumbrance: %s" % weapon.encumberance
	weapon_info_container.add_child(encumbrance_label)

	var armor_points_label = Label.new()
	armor_points_label.text = "Armor Points (AP): %s" % weapon.armor_points
	weapon_info_container.add_child(armor_points_label)

	var hit_points_label = Label.new()
	hit_points_label.text = "Hit Points (HP): %s" % weapon.hit_points
	weapon_info_container.add_child(hit_points_label)

	if weapon.traits.size() > 0:
		var traits_label = Label.new()
		traits_label.text = "Traits: %s" % ", ".join(weapon.traits)
		weapon_info_container.add_child(traits_label)

	if weapon.combat_effects.size() > 0:
		var effects_label = Label.new()
		effects_label.text = "Combat Effects: %s" % ", ".join(weapon.combat_effects)
		weapon_info_container.add_child(effects_label)

	var hands_label = Label.new()
	hands_label.text = "Hands Required: %s" % weapon.hands
	weapon_info_container.add_child(hands_label)

	popup.add_child(weapon_info_container)
	get_tree().root.add_child(popup)
	popup.popup_centered()

func _map_size_to_text(map_size: int) -> String:
	match map_size:
		0: return "Small"
		1: return "Medium"
		2: return "Large"
		3: return "Huge"
		4: return "Enormous"
		_: return "Unknown"

func _map_reach_to_text(reach: int) -> String:
	match reach:
		0: return "Touch"
		1: return "Short"
		2: return "Medium"
		3: return "Long"
		4: return "Very Long"
		_: return "Unknown"

func _compute_weapon_damage(weapon: Weapon) -> String:
	return "{0}d{1}+{2}".format([weapon.die_number, weapon.die_type, weapon.flat_damage])
