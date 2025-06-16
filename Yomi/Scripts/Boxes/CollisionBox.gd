@tool
class_name CollisionBox
extends Area3D

enum BoxType {Hitbox, Hurtbox}

@export var collision_shape: CollisionShape3D = null

@export var box_shape: BoxShape3D = null


@export_enum("Hitbox", "Hurtbox") var box_type: int = BoxType.Hitbox

var owning_char: BaseChar = null

var is_active: bool = false

var is_ghost: bool = false

func _enter_tree() -> void:
	box_shape = box_shape.duplicate(true)
	collision_shape.shape = box_shape
	print_debug("CBOX INIT2")


func activate() -> void:
	is_active = true
	collision_shape.debug_color = Color.PURPLE
	monitoring = true
	pass

func deactivate() -> void:
	is_active = false
	collision_shape.debug_color = Color.RED
	monitoring = false
	pass


func get_colliding_characters() -> Array[BaseChar]:

	var collisions: Array[Area3D] = get_overlapping_areas()
	var units: Array[BaseChar] = []
	for col in collisions:
		var par = col.get_parent()
		if par is BaseChar:
			if par.is_ghost != owning_char.is_ghost or par == owning_char:
				continue
			units.append(par)
	if !units.is_empty():
		pass
	return units
	
