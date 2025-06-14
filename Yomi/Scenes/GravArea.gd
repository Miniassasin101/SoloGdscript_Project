class_name GravArea
extends Area3D

@export var gravity_scale: float = 1.0
@export var grav_force: float = 40.0
@export var characters_in_self: Array[BaseChar] = []

func apply_gravity(body: Node3D) -> void:
	if not body is BaseChar:
		return
	var cha: BaseChar = body as BaseChar
	if cha.physics_are_paused:
		return
	cha.apply_central_impulse(gravity_direction * gravity_scale)

func on_char_entered(body: Node3D) -> void:
	if not body is BaseChar:
		return
	var cha: BaseChar = body as BaseChar
	if !cha:
		return 
	
	if !(cha in characters_in_self):
		characters_in_self.append(cha)

func on_char_leave(body: Node3D) -> void:
	if not body is BaseChar:
		return
	var cha: BaseChar = body as BaseChar
	if !cha:
		return 
	
	if cha in characters_in_self:
		characters_in_self.erase(cha)


func _physics_process(delta: float) -> void:
	for cha in characters_in_self:
		cha.queue_physics_request(GeneralForcePhysicsRequest.new(Vector3.UP, grav_force))


func _on_body_entered(body: Node3D) -> void:
	on_char_entered(body)


func _on_body_exited(body: Node3D) -> void:
	on_char_leave(body)
