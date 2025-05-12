class_name AttributeResource extends Resource


enum SkillType {Combat, Survival, Social, Knowledge, Other}


@export_category("Attribute")
## Is the attribute name
@export var attribute_name: String = ""
## Is the attribute minimum value
@export var minimum_value: int = 0
## Is the attribute maximum value
@export var maximum_value: int = 0
## Is the attribute maximum potential (determined by rank)
@export var maximum_potential: int = 0
## Is the attribute initial value
@export var current_value: int = 0
## Is the attribute base value
@export var base_value: int = 0
## Is how much the attribute is buffed/reduced by
@export var modifier: int = 0

@export_category("Derived")
## Array of the attributes that will be used in the calculation method. Uses "Word" notation for derived and "word" notation for base.
@export var derived_from: Array[String]

## Determines which calculation will be used for an attribute
@export_enum("Base", "Derived", "Table") var calculation_type: int


@export_category("Skill")
## Marks an attribute as a skill
@export var is_skill: bool = false

## Determines what category of skill this is
@export_enum("Combat", "Survival", "Social", "Knowledge", "Other") var skill_type: int = SkillType.Combat





func _init(p_attribute_name: String = "", p_minimum_value: int = 0, p_maximum_value: int = 0, p_current_value: int = 0) -> void:
	attribute_name = p_attribute_name
	minimum_value = p_minimum_value
	maximum_value = p_maximum_value
	current_value = p_current_value
