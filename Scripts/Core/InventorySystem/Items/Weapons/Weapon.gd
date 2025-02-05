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
	if hit_points <= 0:
		is_broken = true

func get_damage_after_armor(in_damage: int) -> int:
	return maxi(in_damage - armor_points, 0)


func roll_damage_dep() -> int:
	var damage_total: int = 0
	damage_total += Utilities.roll(die_type, die_number)
	damage_total += flat_damage
	if is_broken:
		damage_total = ceili(damage_total/2.0)
	return damage_total


func roll_damage(maximize_count: int = 0) -> int:
	# Ensure that the number of dice to maximize does not exceed the weapon's dice.
	var dice_to_maximize: int = clampi(maximize_count, 0, die_number)
	var normal_dice: int = die_number - dice_to_maximize
	var damage_total: int = 0
	# Roll normally for the remaining dice.
	if normal_dice > 0:
		damage_total += Utilities.roll(die_type, normal_dice)
	# For each maximized die, add its maximum possible value.
	damage_total += dice_to_maximize * die_type
	# Add the flat damage bonus (which is not affected by maximisation).
	damage_total += flat_damage
	if is_broken:
		damage_total = ceili(damage_total / 2.0)
	return damage_total
