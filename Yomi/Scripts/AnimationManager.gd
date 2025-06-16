class_name AnimationManager
extends Node

@export var unit: BaseChar
@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree

@export var skeleton: Node3D


var root: AnimationNodeStateMachine = null

var main: AnimationNodeBlendTree = null

var current_animation_a_node: AnimationNodeAnimation = null

var current_animation_b_node: AnimationNodeAnimation = null

var timeseek_a_node: AnimationNodeTimeSeek = null

var timeseek_b_node: AnimationNodeTimeSeek = null

var transition_node: AnimationNodeTransition = null


var time_scale: AnimationNodeTimeScale = null


# track which port was most recently active
var active_port: String = "AnimationA"
var active_anim_name: String = ""

var playback_time: float = 0.0
var anim_time: float = 0.0
var anim_playing: bool = false

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
	timeseek_a_node = main.get_node("TimeSeekA")
	timeseek_b_node = main.get_node("TimeSeekB")
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
	
	anim_time = 0.0
	
	
	
	active_anim_name = anim_name

func _process(delta):
	if anim_playing:
		anim_time += delta

func anim_pause() -> void:
	animator_tree.set("parameters/Main/TimeScale/scale", 0.0)
	
	anim_playing = false
	
	playback_time = animator_tree.get("parameters/Main/"+active_port+"/current_position")


	pass

func set_seek_playback(in_time: float) -> void:
	playback_time = in_time
	seek_anim_at()

func get_playback_time() -> float:
	return playback_time

func anim_unpause() -> void:
	animator_tree.set("parameters/Main/TimeScale/scale", 1.0)
	anim_playing = true

	if unit.ui_name == "Sapphire":
		if unit.is_ghost:
			pass

	

func seek_anim_at(seek_time: float = playback_time) -> void:
	var active_seek: String = "TimeSeekA" if active_port == "AnimationA" else "TimeSeekB"
	animator_tree.set("parameters/Main/" + active_seek + "/seek_request", seek_time)
	pass
