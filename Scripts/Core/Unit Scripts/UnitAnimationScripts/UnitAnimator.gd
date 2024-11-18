class_name UnitAnimator
extends Node

@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree
var move_action: MoveAction
@onready var unit: Unit = get_parent()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("connect_signals")


func on_start_moving() -> void:
	if unit.get_action("Move"):
		print("hello")
	if move_action == null:
		connect_signals()
	animator_tree.set("parameters/conditions/IsWalking", true)

func on_stop_moving() -> void:
	animator_tree.set("parameters/conditions/IsWalking", false)

func connect_signals():
	move_action = unit.get_action("Move")
	if move_action:
		move_action.on_start_moving.connect(on_start_moving)
		move_action.on_stop_moving.connect(on_stop_moving)
