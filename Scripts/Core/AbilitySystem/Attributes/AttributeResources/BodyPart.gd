
class_name BodyPart
extends Node

# Name of the body part, e.g. "head", "chest", "left_arm", "right_arm", "abdomen", "left_leg", "right_leg"
@export var part_name: String = ""       
@export var part_ui_name: String = ""

# A marker that shows where the body part is for use in stuff like being impaled with arrows or targeting
@export var body_part_marker: Marker3D

# For hit locations: For a d20 roll, these define the range of rolls that hit this part.
# Example: head = 19-20 means hit_range_start = 19, hit_range_end = 20
@export var hit_range_start: int = 1      
@export var hit_range_end: int = 1        


# Armor points on this body part (reduces damage)
@export var armor: int = 0           

# Array of adjacent body parts:
@export var adjacent_body_parts: Array[BodyPart] = []

# Array of conditions (Resources) that represent scars, injuries, etc. 
@export var wounds: Array[Wound] = []

var is_impaled: bool = false

var body: Body = null


func set_armor(val: int) -> void:
	armor = maxi(val, 0)

func get_adjacent_parts() -> Array[BodyPart]:
	return adjacent_body_parts

func get_body_part_marker_position() -> Vector3:
	return body_part_marker.global_position if body_part_marker else Vector3.ZERO

func get_body_part_marker() -> Marker3D:
	return body_part_marker

func get_armor() -> int:
	return armor

func get_damage_after_armor(in_damage: int) -> int:
	return max(in_damage - armor, 0)
