class_name ItemVisual extends Node3D

signal animation_finished

@export var animator: AnimationPlayer
@export var root: Node3D

var item: Item = null
var object: Node3D = null

func _ready() -> void:
	animator.animation_finished.connect(on_animation_finished)


func add_item(in_item: Item) -> void:
	item = in_item
	item.set_item_visual(self)
	object = item.get_object()
	root.add_child(object)



func play_animation(anim_name: StringName, speed_scale: float = 1.0) -> void:
	animator.set_speed_scale(speed_scale)
	animator.play(anim_name)

func pause_animation() -> void:
	animator.pause()



func set_trail_visibility(is_visible: bool) -> bool:
	var trail: GPUTrail3D = null
	for child in object.get_children():
		if child is GPUTrail3D:
			child.set_visibility(is_visible)
			return true
	return false




func on_animation_finished() -> void:
	animation_finished.emit()
	animator.set_speed_scale(1.0)
