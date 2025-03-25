class_name ItemVisual extends Node3D

signal animation_finished

@export var animator: AnimationPlayer
@export var root: Node3D

var item: Item = null
var object: Node3D = null

var object_animator: AnimationPlayer = null


var projectile_point: Node3D = null
var projectile: Node3D = null
var projectile_animator: AnimationPlayer = null

func _ready() -> void:
	animator.animation_finished.connect(on_animation_finished)


func add_item(in_item: Item) -> void:
	item = in_item
	item.set_item_visual(self)
	object = item.get_object()
	root.add_child(object)
	
	var object_children: Array[Node] = object.get_children()
	for child in object_children:
		if child.name == "ProjectilePoint" and child is Node3D:
			projectile_point = child
		elif child is AnimationPlayer:
			object_animator = child



func add_projectile(in_projectile: Node3D) -> void:
	var item_children: Array[Node] = object.get_children()
	if projectile_point:
		projectile_point.add_child(in_projectile)
		projectile = in_projectile
		for child in projectile.get_children():
			if child is AnimationPlayer:
				projectile_animator = child



func play_animation(anim_name: StringName, speed_scale: float = 1.0) -> void:
	animator.set_speed_scale(speed_scale)
	animator.play(anim_name)

func pause_animation() -> void:
	animator.pause()

func play_animation_on_weapon(anim_name: StringName, speed_scale: float = 1.0, _blend: float = -1.0) -> void:
	if !object_animator:
		return
	animator.set_speed_scale(speed_scale)
	object_animator.play(anim_name)#, blend, speed_scale)
	await object_animator.animation_finished

func play_animation_on_projectile(anim_name: StringName, speed_scale: float = 1.0, blend: float = -1.0) -> void:
	if !projectile_animator:
		return
	#animator.set_speed_scale(speed_scale)
	projectile_animator.play(anim_name, blend, speed_scale)
	await projectile_animator.animation_finished

func set_trail_visibility(is_vis: bool) -> bool:
	for child in object.get_children():
		if child is GPUTrail3D:
			child.set_visibility(is_vis)
			return true
	return false




func on_animation_finished() -> void:
	animation_finished.emit()
	animator.set_speed_scale(1.0)
