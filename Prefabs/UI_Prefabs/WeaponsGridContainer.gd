@tool
class_name WeaponsGridContainer
extends GridContainer

## Holds references to any dynamically created rows,
## so we can remove/clear them if we call populate again.
var dynamic_rows: Array[Control] = []

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# If you need any setup, do it here.
	# Because this is a GridContainer, you can set "columns" = 1 or more in the Inspector.
	# Or you can switch to a VBoxContainer if you prefer.
	pass

##
# Removes (queue_free) all dynamically created rows from the last populate.
##
func clear_weapons_display() -> void:
	for row in dynamic_rows:
		row.queue_free()
	dynamic_rows.clear()

##
# Populates up to 7 weapons. Each weapon row:
#  [ Button: Name ] [Label: Damage] [Label: Size] [Label: AP] [Label: HP]
# Pressing the name button calls into the Character Sheet UI's "show_weapon_details_popup" method.
##
func populate_weapons(weapons: Array[Weapon], sheet_ui: UnitCharacterSheetUI) -> void:
	# First, clear old display.
	clear_weapons_display()

	if weapons.size() == 0:
		return  # No weapons to display, do nothing.

	# We only show up to 7.
	var max_weapons :int = mini(weapons.size(), 7)

	for i in range(max_weapons):
		var weapon: Weapon = weapons[i]
		
		# Create an HBoxContainer or any container you prefer for a "row".
		var row_container = HBoxContainer.new()
		row_container.name = "WeaponRow_%d".format(i)

		# 1) Create a button for the weapon name
		var name_button = Button.new()
		name_button.name = "WeaponNameBtn"
		name_button.text = weapon.name
		# We connect "pressed" to a helper in this script that calls sheet_ui
		name_button.pressed.connect(_on_weapon_name_pressed.bind(weapon, sheet_ui))
		
		# 2) A label for the damage
		var damage_label = Label.new()
		damage_label.name = "DamageLabel"
		damage_label.text = "%sd%s + %s" % [weapon.die_number, weapon.die_type, weapon.flat_damage]
		
		# 3) A label for size
		var size_label = Label.new()
		size_label.name = "SizeLabel"
		size_label.text = str(weapon.size)  # or a function that maps int -> "Small/Medium/etc."

		# 4) A label for AP
		var ap_label = Label.new()
		ap_label.name = "APLabel"
		ap_label.text = str(weapon.armor_points)

		# 5) A label for HP
		var hp_label = Label.new()
		hp_label.name = "HPLabel"
		hp_label.text = str(weapon.hit_points)

		# Add these controls to the row container
		row_container.add_child(name_button)
		row_container.add_child(damage_label)
		row_container.add_child(size_label)
		row_container.add_child(ap_label)
		row_container.add_child(hp_label)

		# Finally, add the row container to the GridContainer (this node)
		add_child(row_container)
		
		# Keep track of the row so we can remove it later
		dynamic_rows.append(row_container)


##
# Called when a weapon's name button is pressed.
# We pass the Weapon and the UI reference as extra arguments in the connect call.
##
func _on_weapon_name_pressed(weapon: Weapon, sheet_ui: UnitCharacterSheetUI) -> void:
	# The UnitCharacterSheetUI has a method like "show_weapon_details_popup(weapon)"
	if sheet_ui:
		sheet_ui.show_weapon_details_popup(weapon)
