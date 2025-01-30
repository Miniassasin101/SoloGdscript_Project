# Save this as BodyPart.gd (as a resource script)
# Make sure this file is placed in your project (e.g., "res://scripts/BodyPart.gd")

class_name BodyPart
extends Resource

# Name of the body part, e.g. "head", "chest", "left_arm", "right_arm", "abdomen", "left_leg", "right_leg"
@export var part_name: String = ""       
@export var part_ui_name: String = ""
# Armor points on this body part (reduces damage)
@export var armor: float = 0.0            


# For hit locations: For a d20 roll, these define the range of rolls that hit this part.
# Example: head = 19-20 means hit_range_start = 19, hit_range_end = 20
@export var hit_range_start: int = 1      
@export var hit_range_end: int = 1        

# Array of conditions (Resources) that represent scars, injuries, etc. 
@export var conditions: Array[Resource] = []
