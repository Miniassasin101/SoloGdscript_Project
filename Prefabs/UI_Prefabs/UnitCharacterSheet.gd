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
# Will be cleared then populated with the data from the unit's body parts
@export var body_parts_container: VBoxContainer
@export var weapons_grid_container: WeaponsGridContainer 

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
	populate_weapons_from_unit(unit)

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

func populate_weapons_from_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(unit.equipment):
		weapons_grid_container.clear_weapons_display()
		return

	# Filter out only items that are Weapons.
	var all_equipped_items = unit.equipment.equipped_items
	var equipped_weapons: Array[Weapon] = []
	for item in all_equipped_items:
		if item is Weapon:
			equipped_weapons.append(item as Weapon)
	
	# Populate the WeaponsGridContainer with the found weapons.
	weapons_grid_container.populate_weapons(equipped_weapons, self)


##
# Optional: Called when a weapon name is clicked. You can pass
# the weapon to a custom popup or scene to show more details.
##
func show_weapon_details_popup_depreciated(weapon: Weapon) -> void:
	if weapon_details_popup_scene == null:
		# As a fallback, use a simple AcceptDialog
		var dialog = AcceptDialog.new()
		add_child(dialog)
		dialog.dialog_text = "Weapon: {0}\nDamage: {1}\nSize: {2}\nAP: {3}\nHP: {4}".format([
			weapon.name, 
			str(_compute_weapon_damage(weapon)),
			str(weapon.size), 
			str(weapon.armor_points),
			str(weapon.hit_points)
		])
		dialog.popup_centered()
		return

	# Otherwise, instantiate your custom popup scene
	var weapon_popup = weapon_details_popup_scene.instantiate()
	add_child(weapon_popup)
	# If your custom popup has a method like set_weapon(...)
	if weapon_popup.has_method("set_weapon"):
		weapon_popup.call("set_weapon", weapon)
	weapon_popup.popup_centered()

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
	var size_label = Label.new()
	size_label.text = "Size: %s" % _map_size_to_text(weapon.size)
	weapon_info_container.add_child(size_label)

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
# Maps the `size` integer to a readable text description.
##
func _map_size_to_text(size: int) -> String:
	match size:
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
# Maps the `reach` integer to a readable text description.
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

func _get_attribute_or_na(unit: Unit, attribute_name: String) -> String:
	if not is_instance_valid(unit) or not is_instance_valid(unit.attribute_map):
		return "n/a"

	var spec = unit.attribute_map.get_attribute_by_name(attribute_name)
	if spec == null:
		return "n/a"

	return str(spec.current_value)
