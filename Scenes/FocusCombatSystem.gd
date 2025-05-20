class_name FocusCombatSystem 
extends Node



@export var book_keeping_system: BookKeepingSystem


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
func handle_single_target_move_event(event: ActivationEvent) -> void:
	# NOTE: Conditions modifiers go here
	var user: Unit = event.unit
	var target: Unit = event.target_unit
	
	current_event = event
	
	
	# Step 1: Calculate user's success outcome
	var user_success_level: int = _calculate_attacker_success(user, event).success_level
	if user_success_level <= 0:
		print_debug("User failed.")
		event.miss = true
	
	



# Helper: Calculate attacker roll and success level, update event and show marker.
func _calculate_attacker_success(attacking_unit: Unit, event: ActivationEvent) -> DicePool:
	var move: Move = event.move
	
	# NOTE: get required successes here
	var successes_needed: int = 1
	
	# Gather Accuracy dice pool, either attribute + skill or skill + skill
	var pool_1: int = 0
	var pool_2: int = 0
	
	var pool_1_name: String = event.move.accuracy[0]
	var pool_2_name: String = event.move.accuracy[1]
	
	pool_1 = attacking_unit.get_attribute_buffed_value_by_name(pool_1_name)
	pool_2 = attacking_unit.get_attribute_buffed_value_by_name(pool_2_name)
	
	print_debug("Accuracy Pool 1 - {}: {}".format([pool_1_name, pool_1], "{}"))
	print_debug("Accuracy Pool 2 - {}: {}".format([pool_2_name, pool_2], "{}"))
	
	var total_pool: int = pool_1 + pool_2 + 4
	
	var dice_pool: DicePool = DicePool.new(total_pool)
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
