@icon("res://addons/godot_gameplay_systems/attributes_and_abilities/assets/AttributeTable.svg")
@tool
class_name AttributesTable
extends Resource

@export_category("Attributes")
@export var attributes : Array[AttributeResource] = []

@export_category("Hit Locations")
@export var hit_locations : Array[HitLocationsAttribute] = []

func _init(p_attributes: Array[AttributeResource] = [], p_hit_locations : Array[HitLocationsAttribute] = []) -> void:
	attributes = p_attributes
	hit_locations = p_hit_locations

func _notification(what):
	# Runs inside the editor
	if Engine.is_editor_hint():
		# After the resource is loaded or changes in the editor
		# ensure each attribute is unique
		if what == NOTIFICATION_POSTINITIALIZE:
			_make_attributes_unique()

func _make_attributes_unique():
	if attributes.size() == 0:
		return

	for i in range(attributes.size()):
		var attr = attributes[i]
		if attr and attr.resource_path != "":
			# Duplicate the attribute resource to make it unique
			var unique_attr = attr.duplicate()
			# Clear the resource path so it's no longer tied to an external file
			unique_attr.resource_path = ""
			attributes[i] = unique_attr
