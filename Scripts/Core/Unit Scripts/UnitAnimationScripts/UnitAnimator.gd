class_name UnitAnimator
extends Node

@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree
@export var fireball_projectile_prefab: PackedScene
@export var shoot_point: Node3D
@export var height_offset: float = 1.5  # Height offset to aim towards upper body

var fireball_instance: Projectile
var move_action: MoveAction
var shoot_action: ShootAction
@onready var unit: Unit = get_parent()
var target_unit: Unit
var stored_damage: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("connect_signals")


func on_start_moving() -> void:
	animator_tree.set("parameters/conditions/IsWalking", true)

func on_stop_moving() -> void:
	animator_tree.set("parameters/conditions/IsWalking", false)

func on_shoot(target_unit_in: Unit, _shooting_unit: Unit, damage: int) -> void:
	if fireball_projectile_prefab and shoot_point:
		# Instantiate the fireball
		fireball_instance = fireball_projectile_prefab.instantiate()

		var target_unit_shoot_at_position: Vector3 = target_unit_in.get_position()
		print(target_unit_shoot_at_position.y)
		target_unit_shoot_at_position.y = shoot_point.global_position.y
		print(target_unit_shoot_at_position.y)
		
		# Add the fireball to the root or the appropriate scene node
		get_tree().root.add_child(fireball_instance)
		# Set the fireball's initial position
		fireball_instance.global_transform.origin = shoot_point.global_transform.origin
		fireball_instance.target_hit.connect(trigger_damage)
		fireball_instance.setup(target_unit_shoot_at_position)
		target_unit = target_unit_in
		stored_damage = damage

func trigger_damage() -> void:
	target_unit.damage(stored_damage)


func connect_signals():
	move_action = unit.get_action("Move")
	shoot_action = unit.get_action("Shoot")
	if move_action:
		move_action.on_start_moving.connect(on_start_moving)
		move_action.on_stop_moving.connect(on_stop_moving)
	if shoot_action:
		shoot_action.on_shoot.connect(on_shoot)
