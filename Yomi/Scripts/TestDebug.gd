class_name TestDebug
extends Node



@export var current_character: BaseChar = null


func _ready() -> void:
	Console.add_command("hello", console_hello, 0, 0, "Prints Hello")
	Console.add_command("get_unit_by_index", console_get_unit_by_index, ["index"], 1, "Sets Debug character to one at index if found.")
	Console.add_command("set_color", console_set_color, ["color"], 1, "Sets current character color. Options: white, green, red, blue.")





func console_hello() -> void:
	Console.print_line("Hello!", true)


func console_get_unit_by_index(index: String = "") -> void:
	var cha: BaseChar = CharManager.instance.get_unit_by_index(index.to_int())
	if cha:
		current_character = cha
		Console.print_line("New Character: " + cha.ui_name)


func console_set_color(color_name: String = "") -> void:
	if current_character == null:
		Console.print_line("No character selected.")
		return

	var color_map = {
		"white": Color.WHITE,
		"green": Color(0, 1, 0),
		"red": Color(1, 0, 0),
		"blue": Color(0, 0, 1),
	}

	if !color_map.has(color_name.to_lower()):
		Console.print_line("Invalid color. Use: white, green, red, blue.")
		return

	current_character.set_self_color(color_map[color_name.to_lower()])
	Console.print_line("Color set to " + color_name)
