class_name HealthSystem
extends Node

signal on_dead
@export var current_health: int = 10
@export var max_health: int = 10

func damage(damage_dealt: int) -> void:
	current_health -= damage_dealt
	if (current_health < 0):
		current_health = 0
	if current_health == 0:
		die()


func die() ->void:
	on_dead.emit()
	
