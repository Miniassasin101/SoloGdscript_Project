@icon("res://addons/godot_gameplay_systems/inventory_system/assets/ItemIcon.png")
class_name Weapon extends Item


@export_group("Weapon Attributes")
@export var category: StringName = "sword"
@export_subgroup("Damage")
@export var die_type: int = 6
@export var die_number: int = 1
@export var flat_damage: int = 0
@export_subgroup("")
@export_enum("Small", "Medium", "Large", "Huge", "Enormous") var size: int = 1
@export_enum("Touch", "Short", "Medium", "Long", "Very Long") var reach: int = 0
@export var combat_effects: Array[StringName] = []
@export var encumberance: int = 1
@export var armor_points: int = 4
@export var hit_points: int = 8:
	set(val):
		if val < 0:
			hit_points = 0
		if val > max_hit_points:
			hit_points = max_hit_points
		hit_points = val

@export var max_hit_points: int = 8:
	set(val):
		if val < 0:
			max_hit_points = 0
		if val < hit_points:
			max_hit_points = hit_points
		max_hit_points = val

@export var traits: Array[StringName] = []
## How many hands needed to wield this weapon
@export var hands: int = 1

@export var is_broken: bool = false


func subtract_hitpoints(hitpoints_subtracted: int) -> void:
	hit_points -= hitpoints_subtracted
	hit_points = maxi(hit_points, 0)

func get_damage_after_armor(in_damage: int) -> int:
	return maxi(in_damage - armor_points, 0)


func roll_damage() -> int:
	var damage_total: int = 0
	damage_total += Utilities.roll(die_type, die_number)
	damage_total += flat_damage
	if is_broken:
		damage_total = ceili(damage_total/2.0)
	return damage_total
