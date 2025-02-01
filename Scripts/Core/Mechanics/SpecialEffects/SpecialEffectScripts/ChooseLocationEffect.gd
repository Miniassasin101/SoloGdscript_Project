class_name ChooseLocationEffect
extends SpecialEffect

@export var location_prompt: String = "Choose a body location"

func can_apply(event: ActivationEvent) -> bool:
	# E.g. some logic to check if the effect is valid
	return true

func apply(event: ActivationEvent) -> void:
	super.apply(event)

	var target_unit = event.target_unit
	if target_unit == null:
		push_warning("No target_unit to choose location from.")
		return

	# Gather possible body-part names
	var part_names = _get_valid_body_part_names(target_unit)
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

func _get_valid_body_part_names(target_unit: Unit) -> Array[String]:
	var ret: Array[String] = []
	for bp in target_unit.body.body_parts:
		ret.append(bp.part_name)
	return ret
