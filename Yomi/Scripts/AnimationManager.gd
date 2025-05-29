class_name AnimationManager
extends Node


@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree

@export var skeleton: Node3D


var root: AnimationNodeStateMachine = null

var main: AnimationNodeBlendTree = null

var current_animation_a_node: AnimationNodeAnimation = null

var current_animation_b_node: AnimationNodeAnimation = null

var transition_node: AnimationNodeTransition = null


var time_scale: AnimationNodeTimeScale = null


# track which port was most recently active
var active_port: String = "AnimationA"
var active_anim_name: String = ""


func _ready() -> void:
	animator_tree_setup()




func animator_tree_setup() -> void:
	make_tree_root_unique()

	set_animator_tree_properties()


# This prevents any animation changes like weapon equips duplicating across instances
func make_tree_root_unique() -> void:
	animator_tree.set_tree_root(animator_tree.tree_root.duplicate(true))


# ------------------------------------------------------------
# Cache all the AnimationTree nodes we need for blending
# ------------------------------------------------------------
func set_animator_tree_properties() -> void:
	# Root of the state machine
	root = animator_tree.tree_root as AnimationNodeStateMachine
	if root == null:
		push_error("AnimationTree does not have a valid StateMachine root.")
		return

	# Main sub–state machine
	main = root.get_node("Main")
	current_animation_a_node = main.get_node("AnimationA")
	current_animation_b_node = main.get_node("AnimationB")
	transition_node = main.get_node("Transition")
	time_scale = main.get_node("TimeScale")
	return





func get_character_mesh() -> Array[MeshInstance3D]:
	var ret_array: Array[MeshInstance3D] = []
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			ret_array.append(child as MeshInstance3D)

	return ret_array



# ------------------------------------------------------------
# Cross-fade from “A” → “B” whenever you call play_animation()
# ------------------------------------------------------------
func play_animation(anim_name: String, fade_time: float = 0.2) -> void:
	# decide which port to write the new clip into
	var target_port = "AnimationB" if active_port == "AnimationA" else "AnimationA"

	# set the animation on that node
	if target_port == "AnimationA":
		current_animation_a_node.animation = anim_name
	else:
		current_animation_b_node.animation = anim_name

	# configure the cross-fade
	transition_node.set_xfade_time(fade_time)

	# tell the AnimationTree to transition into the new port
	animator_tree["parameters/Main/Transition/transition_request"] = target_port

	# update which port is now active
	active_port = target_port
	
	active_anim_name = anim_name

func anim_pause() -> void:

	animator_tree.set("parameters/Main/TimeScale/scale", 0.0)
	
func anim_unpause() -> void:
	animator_tree.set("parameters/Main/TimeScale/scale", 1.0)
