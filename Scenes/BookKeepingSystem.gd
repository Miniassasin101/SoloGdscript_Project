class_name BookKeepingSystem extends Node




@export var combat_system: CombatSystem



func run_book_keeping_check() -> void:
	
	combat_fatigue_check()
	
	applicable_conditions_check()


## Checks to see if any units need to roll to resist fatigue
func combat_fatigue_check() -> void:
	var units: Array[Unit] = UnitManager.instance.get_all_units()
	var current_round_number: int = TurnSystem.instance.get_current_round()
	
	if current_round_number <= 1:
		return


	for unit in units:
		if !unit.try_reduce_fatigue_left():
			var roll: int = Utilities.roll(100)
			var success_level: int = Utilities.check_success_level((
				roundi(unit.get_attribute_buffed_value_by_name("fortitude_skill"))), roll)
			if success_level >= 1:
				Utilities.spawn_text_line(unit, "Passed Fortitude Roll: " + str(roll) + "/" + 
				str(unit.get_attribute_buffed_value_by_name("fortitude")))
				continue
			
			
			unit.conditions_manager.increase_fatigue() # Will also spawn the text line
			
			unit.setup_fatigue_left()
			

func applicable_conditions_check() -> void:
	var units: Array[Unit] = UnitManager.instance.get_all_units()
	for unit in units:
		unit.conditions_manager.apply_conditions_round_interval()
