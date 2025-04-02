class_name MarksmanEffect
extends SpecialEffect

# Allows the unit to choose an adjacent hit position to the actual hit location
#when using a ranged weapon

@export var location_prompt: String = "Choose a body location"



func apply(event: ActivationEvent) -> void:
	super.apply(event)

	var target_unit = event.target_unit
	if target_unit == null:
		push_warning("No target_unit to choose location from.")
		return
	
	var body_part: BodyPart = CombatSystem.instance.get_hit_location(target_unit)
	
	var part_list: Array = [body_part] + body_part.get_adjacent_parts()
	
	# Gather possible body-part names
	var part_names: Array[String] = []
	
	for part in part_list:
		part_names.append(part.part_ui_name)
	
	if part_names.is_empty():
		push_warning("No valid body parts to choose from.")
		return

	# Fetch an existing DynamicButtonPicker in the scene tree
	var dynamic_picker: DynamicButtonPicker = UILayer.instance.unit_action_system_ui.dynamic_button_picker
	if dynamic_picker == null:
		push_error("No DynamicButtonPicker in scene. Please instance or reference it properly.")
		return

	# Show the list of body parts
	dynamic_picker.pick_options(part_names)

	# Wait for user to pick one
	var chosen_part_name: String = await dynamic_picker.option_selected
	if chosen_part_name == "":
		push_warning("No location chosen or user cancelled.")
		return

	# Validate choice
	var chosen_part = target_unit.body._find_part_by_name(chosen_part_name)
	if chosen_part:
		Utilities.spawn_text_line(event.unit, "Chosen Location: %s" % chosen_part_name)
		# Store it on the event, or do some additional logic
		event.body_part = chosen_part
		event.body_part_health_name = event.body_part.part_name + "_health"
		event.body_part_ui_name = event.body_part.part_ui_name
	else:
		push_warning("Invalid part chosen: " + chosen_part_name)
