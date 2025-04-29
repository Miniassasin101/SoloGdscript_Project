extends HBoxContainer
class_name BodyPartsContainer

# Exported VBoxContainers for each column
@export var part_name_container: VBoxContainer
@export var part_armor_container: VBoxContainer
@export var part_health_container: VBoxContainer

# Holds references to the column containers for easy clearing.
var containers: Array[VBoxContainer] = []

func _ready() -> void:
	# Initialize the containers list. This mirrors the setup in your weapons container.
	containers = [part_name_container, part_armor_container, part_health_container]


##
# Clears any dynamically created rows in each container.
##
func clear_body_parts_display() -> void:
	for container in containers:
		for child in container.get_children():
			child.queue_free()


##
# Populates the display with the current unit’s body parts.
#
# For each body part, we display:
#   - The part name.
#   - The current armor value.
#   - The current and maximum health (formatted as “current / max”).
#
# @param unit The unit whose body parts we want to display.
##
func populate_body_parts(unit: Unit) -> void:
	# Clear any previous display.
	clear_body_parts_display()

	# Exit if there is no valid unit body.
	if not is_instance_valid(unit) or not is_instance_valid(unit.body):
		return

	# Iterate over each body part in the unit’s body
	for part in unit.body.body_parts:
		# Retrieve current stats for the body part.
		var current_armor: int = int(unit.body.get_part_armor(part.part_name))
		var current_health: int = int(unit.body.get_part_health(part.part_name))
		var max_health: int = int(unit.body.get_part_health(part.part_name, true))

		# 1) Create a label for the body part name.
		var name_label = Label.new()
		name_label.name = "PartNameLabel"
		name_label.text = part.part_ui_name
		name_label.add_theme_font_size_override("font_size", 15)
		# Left-align the part name.
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# 2) Create a label for the armor value.
		var armor_label = Label.new()
		armor_label.name = "ArmorLabel"
		armor_label.text = str(current_armor)
		armor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# 3) Create a label for the health values.
		var health_label = Label.new()
		health_label.name = "HealthLabel"
		health_label.text = str(current_health) + " / " + str(max_health)
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Add the labels to their respective containers (columns).
		part_name_container.add_child(name_label)
		part_armor_container.add_child(armor_label)
		part_health_container.add_child(health_label)
