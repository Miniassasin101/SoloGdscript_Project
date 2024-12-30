@tool
class_name Body
extends Node

signal setup_body

@export var body_parts: Array[BodyPart] = []


var attribute_map: GameplayAttributeMap = null
@onready var unit: Unit = get_parent()
func _ready() -> void:
	SignalBus.connect("form_body", _on_setup_body)

func _on_setup_body() -> void:
	if unit != null:
		attribute_map = unit.attribute_map
	else:
		push_warning("No unit set for Body node.")
		return
	
	if attribute_map == null:
		push_warning("AttributeMap not found for Body node.")
		return

	for part in body_parts:

		var spec = attribute_map.get_attribute_by_name(part.part_name + "_health")

		if spec == null:
			#add conditional stuff to set the body part health values
			add_health_attribute(part)
			



func add_health_attribute(part: BodyPart) -> void:
	var new_attr = AttributeResource.new()
	new_attr.attribute_name = part.part_name + "_health"
	new_attr.minimum_value = -11
	new_attr.maximum_value = 10
	new_attr.current_value = new_attr.maximum_value
	attribute_map.add_single_attribute(new_attr)


func get_part_health(part_name: String, get_max: bool = false) -> float:
	var part = _find_part_by_name(part_name)
	if not part:
		push_warning("Body part '%s' not found." % part_name)
		return 0.0
		
	var spec = attribute_map.get_attribute_by_name(part.part_name + "_health")
	if spec:
		if get_max:
			return spec.maximum_value
		return spec.current_value
	return 0.0

func set_part_health(part_name: String, value: float) -> void:
	var part = _find_part_by_name(part_name)
	if not part:
		push_warning("Body part '%s' not found." % part_name)
		return

	var spec = attribute_map.get_attribute_by_name(part.part_name + "_health")
	if spec:
		spec.current_value = value

func get_part_armor(part_name: String) -> float:
	var part = _find_part_by_name(part_name)

	return part.armor if part != null else 0.0

func set_part_armor(part_name: String, armor_value: float) -> void:
	var part = _find_part_by_name(part_name)
	if part:
		part.armor = armor_value

func add_condition_to_part(part_name: String, condition: Resource) -> void:
	var part = _find_part_by_name(part_name)
	if part:
		part.conditions.append(condition)

func remove_condition_from_part(part_name: String, condition: Resource) -> void:
	var part = _find_part_by_name(part_name)
	if part and condition in part.conditions:
		part.conditions.erase(condition)

func get_conditions_for_part(part_name: String) -> Array:
	var part = _find_part_by_name(part_name)
	return part.conditions if part != null else []

func roll_hit_location() -> BodyPart:
	var roll = AbilityUtils.roll(20) 
	for part in body_parts:
		if roll >= part.hit_range_start and roll <= part.hit_range_end:
			return part
	return null

func _find_part_by_name(part_name: String) -> BodyPart:
	for part in body_parts:
		if part.part_name == part_name:
			return part
	return null
