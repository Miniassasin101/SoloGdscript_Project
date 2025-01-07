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
@export var hit_points: int = 8
@export var traits: Array[StringName] = []
## How many hands needed to wield this weapon
@export var hands: int = 1
