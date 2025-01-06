@tool
class_name HeldItem3D
extends Node3D

##
#  HeldItem3D
#
#  This node will listen to an Equipment node's signals and instantiate/hide
#  an Item's 3D scene whenever the item is equipped or unequipped.
##

## Emitted when an Item is displayed.
signal item_displayed(item: Item)

## Emitted when an Item is hidden.
signal item_hidden(item: Item)

@export_category("Unit")
@export var unit: Unit = null

@export_category("Equipment")
## A direct reference to an Equipment instance.
## If null, no items will be displayed.
@export var equipment_path: Equipment = null:
	get:
		return equipment_path
	set(value):
		equipment_path = value
		update_configuration_warnings()

@export_group("Tagging", "tags_")
## Only displays an equipped Item if it has all of these tags.
@export var tags_to_display: Array[String] = []


## Holds the current spawned Item scene, if any.
var current: Node3D = null

var equipment: Equipment = null

func _init() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()


func _ready() -> void:
	# If equipment_path is assigned in the editor, we can connect signals.
	if equipment_path != null:
		equipment_path.equipped.connect(_on_item_equipped)
		equipment_path.unequipped.connect(_on_item_unequipped)
	if unit == null:
		var testunit = get_parent().get_parent().get_parent().get_parent().get_parent()
		if testunit is Unit:
			unit = testunit
		else:
			push_error("HeldItemPathERR at: ", self.scene_file_path)
	equipment = unit.equipment


## Called whenever the equipment node emits its "equipped" signal.
func _on_item_equipped(item: Item, slot: EquipmentSlot) -> void:
	# If we have no tags_to_display, or the item has them all, instantiate the item.
	if tags_to_display.size() > 0:
		for tag in tags_to_display:
			if not item.tags.has(tag):
				return  # If missing any required tag, do nothing.

	# Instantiate only if the item has a valid scene.
	if item.scene and item.scene.can_instantiate():
		# Clean up any previously displayed item
		if current:
			current.queue_free()
			current = null

		current = item.scene.instantiate()
		add_child(current)
		item_displayed.emit(item)


## Called whenever the equipment node emits its "unequipped" signal.
func _on_item_unequipped(item: Item, slot: EquipmentSlot) -> void:
	# If we currently have an item displayed, remove it.
	if current:
		current.queue_free()
		current = null
		item_hidden.emit(item)


func _get_configuration_warnings() -> PackedStringArray:
	var errors = PackedStringArray()

	if equipment_path == null:
		errors.push_back("equipment_path is null. Please assign an Equipment node.")

	return errors
