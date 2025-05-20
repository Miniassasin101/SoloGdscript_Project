class_name FocusCombatSystem 
extends Node


@export_category("References")
@export var book_keeping_system: BookKeepingSystem

@export_category("Attributes")
@export var marker_visibility_time: float = 1.5


var current_event: ActivationEvent = null




static var instance: FocusCombatSystem = null


func _ready() -> void:
	if instance != null:
		push_error("There's more than one FocusCombatSystem! - " + str(instance))
		queue_free()
		return
	instance = self


# Tracks and handles any over time effects or spells
func book_keeping() -> void:
	# Apply poison, bleed, persistent effects, etc.
	book_keeping_system.run_book_keeping_check()


	SignalBus.on_book_keeping_ended.emit()


func start_turn(unit: Unit) -> void:
	print_debug("FocusCombatSystem Turn Started: ", unit)

	unit.conditions_manager.apply_conditions_turn_interval()
	
	SignalBus.on_ui_update.emit()
	

func handle_unit_turn(unit: Unit) -> void:
	pass



func declare_move_event(event: ActivationEvent) -> void:
	
	if event.target_unit:
		handle_head_looks(event.unit, event.target_unit)
	
	pass

func handle_head_looks(defender: Unit, attacker: Unit) -> void:
	defender.animator.enable_head_look(attacker.body.get_part_marker("head"))
	attacker.animator.enable_head_look(defender.body.get_part_marker("head"))


# right now only handles offensive effects.
func handle_single_target_move_event(event: ActivationEvent) -> ActivationEvent:
	# NOTE: Conditions modifiers go here
	var user: Unit = event.unit
	var target: Unit = event.target_unit
	
	current_event = event
	
	
	# Step 1: Calculate user's success outcome
	var user_success_pool: DicePool = _calculate_attacker_pool(user, event)
	if user_success_pool.success_level <= 0:
		print_debug("User failed.")
		event.miss = true
	
	show_success(user, user_success_pool)
	
		# Early exit if conditions require it (for example, if no reaction was triggered)
	if event.miss:
		hide_all_success_level()
		#UILayer.instance.unit_action_system_ui.toggle_containers_visibility_off_except()
		current_event = null
		return event
	
	
	# Step 2: Handle defender reaction and capture reaction data
	#var reaction_data = await _handle_defender_reaction(target_unit, attacking_unit, event)
	
	return current_event




# Helper: Calculate attacker roll and success level, update event and show marker.
func _calculate_attacker_pool(attacking_unit: Unit, event: ActivationEvent) -> DicePool:
	var move: Move = event.move
	
	# NOTE: get required successes here
	var successes_needed: int = 3
	
	# Gather Accuracy dice pool, either attribute + skill or skill + skill
	var pool_1: int = 0
	var pool_2: int = 0
	
	var pool_1_name: String = event.move.accuracy[0]
	var pool_2_name: String = event.move.accuracy[1]
	
	pool_1 = floori(attacking_unit.get_attribute_buffed_value_by_name(pool_1_name))
	pool_2 = floori(attacking_unit.get_attribute_buffed_value_by_name(pool_2_name))
	
	print_debug("Accuracy Pool 1 - {}: {}".format([pool_1_name, pool_1], "{}"))
	print_debug("Accuracy Pool 2 - {}: {}".format([pool_2_name, pool_2], "{}"))
	
	var total_pool: int = pool_1 + pool_2 + 4
	
	var dice_pool: DicePool = DicePool.new(total_pool, successes_needed)
	dice_pool.roll()
	
	var success_count: int = dice_pool.get_success_count()
	var min: int = dice_pool.get_min()
	var max: int = dice_pool.get_max()
	var result_counts: Dictionary = dice_pool.get_result_counts()
	
	print_debug(dice_pool.to_str())
	

	event.attacker_pool = dice_pool

	var success_level: int = dice_pool.success_level
	print_debug("Attacker Success Level (pre-debug): ", success_level)

	# — Debug overrides — #
	if LevelDebug.instance.attacker_fail_debug:
		success_level = 0
	elif LevelDebug.instance.attacker_success_debug:
		success_level = 1

	print_debug("Attacker Success Level (post-debug): ", success_level)

	event.attacker_success_level = success_level
	if success_level == 2:
		event.attacker_critical = true
		Utilities.spawn_text_line(attacking_unit, "Critical!")
	elif success_level == -1:
		event.attacker_fumble = true
		Utilities.spawn_text_line(attacking_unit, "Fumble!", Color.FIREBRICK)

	#show_success(attacking_unit, success_level)
	return dice_pool


func _handle_defender_reaction(target_unit: Unit, attacking_unit: Unit, event: ActivationEvent) -> DicePool:
	var defender_success_level: int = 0


	# Normally prompt for a parry/evade...
	await reaction(target_unit, event)
	defender_success_level = event.defender_success_level

	print_debug("Defender Success Level (pre-debug): ", defender_success_level)

	# — Debug overrides — #
	if LevelDebug.instance.parry_fail_debug:
		defender_success_level = 0
	elif LevelDebug.instance.parry_success_debug:
		defender_success_level = 1

	print_debug("Defender Success Level (post-debug): ", defender_success_level)

	# Mark whether a parry actually succeeded
	event.parry_successful = defender_success_level > 0

	# Show feedback
	#show_success(target_unit, defender_success_level)




	event.defender_success_level = defender_success_level
	if defender_success_level == 2:
		event.defender_critical = true
		Utilities.spawn_text_line(target_unit, "Critical!")
	elif defender_success_level == -1:
		event.defender_fumble = true
		Utilities.spawn_text_line(target_unit, "Fumble!", Color.FIREBRICK)
		

	return DicePool.new()



func reaction(reacting_unit: Unit, _ret_event: ActivationEvent):

	# Prompt UI or AI to choose a reaction ability (e.g., a parry, an evade).
	SignalBus.on_player_reaction.emit(reacting_unit)
	
	UnitActionSystem.instance.set_is_reacting()

	var move: Move = await SignalBus.move_complete

	if move == null:
		# No valid reaction chosen, treat as no reaction (auto fail)
		push_error("Invalid Reaction Ability on", reacting_unit.ui_name)
		return



	# After activation, we assume reaction is a skill roll. In Mythras:
	# For example, if parry: skill = combat_skill
	# If evade: skill = evade skill
	UnitActionSystem.instance.set_is_reacting(false)
	return


# Helper Functions

# Show the attacker's success level marker
func show_success(in_unit: Unit, user_pool: DicePool) -> void:
	var marker_color: StringName = get_color_for_success_level(user_pool.success_level)
	in_unit.set_color_marker(marker_color)  # Emit a signal to show the marker
	in_unit.color_marker.set_number(user_pool.get_success_count())
	in_unit.set_color_marker_visible(true)

func hide_all_success_level() -> void:
	await get_tree().create_timer(marker_visibility_time).timeout
	SignalBus.hide_success.emit()

# Utility to map success levels to colors
func get_color_for_success_level(success_level: int) -> StringName:
	match success_level:
		2: return "blue"   # Critical Success
		1: return "green"  # Success
		0: return "yellow" # Failure/Miss
		-1: return "red"    # Critical Failure
		_: return "white"  # Default color (unexpected value)
