@tool
class_name Body
extends Node


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
	

	body_parts = get_children() as Array[BodyPart]
	
	for part in body_parts:

		var spec: AttributeSpec = attribute_map.get_attribute_by_name(part.part_name + "_health")

		if spec == null:
			#add conditional stuff to set the body part health values
			
			add_health_attribute(part)
			if part.body == null:
				part.body = self




func apply_wound_from_event(event: ActivationEvent) -> void:
	if event.rolled_damage <= 0:
		return
	
	
	
	wound_effect_damage(event.body_part_health_name, event.rolled_damage)
	
	
	var wound: Wound = Wound.new()
	wound.damage = event.rolled_damage
	
	add_wound_to_part(event.body_part.part_name, wound)



func apply_wound_manual(body_part: BodyPart, rolled_damage: int) -> void:
	
	wound_effect_damage((body_part.part_name + "_health"), rolled_damage)
	
	var wound: Wound = Wound.new()
	wound.damage = rolled_damage
	
	add_wound_to_part(body_part.part_name, wound)



func wound_effect_damage(body_part_health_name: String, rolled_damage: int) -> void:
	# Create a new GameplayEffect resource
	var effect = GameplayEffect.new()


	# Optionally, if you want to apply damage to a specific body part
	var part_effect = AttributeEffect.new()
	part_effect.attribute_name = body_part_health_name
	part_effect.minimum_value = -rolled_damage
	part_effect.maximum_value = -rolled_damage

	effect.attributes_affected.append(part_effect)

	# Get the target unit from the grid and attach the effect

	unit.add_child(effect)






func add_health_attribute(part: BodyPart) -> void:
	var new_attr = AttributeResource.new()
	new_attr.attribute_name = part.part_name + "_health"
	new_attr.maximum_value = 10
	new_attr.minimum_value = -11
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
	var part: BodyPart = _find_part_by_name(part_name)
	if not part:
		push_warning("Body part '%s' not found." % part_name)
		return

	var spec = attribute_map.get_attribute_by_name(part.part_name + "_health")
	if spec:
		spec.current_value = value

func get_part_armor(part_name: String) -> int:
	var part: BodyPart = _find_part_by_name(part_name)

	return part.armor if part != null else 0

func get_if_any_part_has_armor() -> bool:
	var armor: int = 0
	for part in body_parts:
		armor += part.get_armor()
	if armor > 0:
		return true
	return false


func set_all_part_armor(armor_val: int) -> void:
	for part in body_parts:
		part.set_armor(armor_val)

func set_part_armor(part_name: String, armor_value: int) -> void:
	var part: BodyPart = _find_part_by_name(part_name)
	if part:
		part.armor = armor_value

func add_wound_to_part(part_name: String, wound: Wound) -> void:
	var part: BodyPart = _find_part_by_name(part_name)
	if part:
		part.wounds.append(wound)

func remove_wound_from_part(part_name: String, wound: Wound) -> void:
	var part: BodyPart = _find_part_by_name(part_name)
	if part and (wound in part.wounds):
		part.wounds.erase(wound)

func get_wounds_for_part(part_name: String) -> Array[Wound]:
	var part: BodyPart = _find_part_by_name(part_name)
	return part.wounds if part != null else []
	

func get_all_wounds() -> Array[Wound]:
	var ret_array: Array[Wound] = []
	for part: BodyPart in body_parts:
		ret_array.append_array(part.wounds)
	
	return ret_array


func roll_hit_location() -> BodyPart:
	var roll = Utilities.roll(20) 
	for part in body_parts:
		if roll >= part.hit_range_start and roll <= part.hit_range_end:
			return part
	return null

func _find_part_by_name(part_name: String) -> BodyPart:
	for part in body_parts:
		if part.part_name == part_name:
			return part
	return null
