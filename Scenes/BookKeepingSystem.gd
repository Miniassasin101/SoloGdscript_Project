class_name BookKeepingSystem extends Node




@export var combat_system: CombatSystem



func run_book_keeping_check() -> void:
	
	combat_fatigue_check()


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
				unit.attribute_map.get_attribute_by_name("endurance").current_buffed_value * 2.0), roll)
			if success_level >= 1:
				Utilities.spawn_text_line(unit, "Passed Endurance Roll: " + str(roll) + "/" + 
				str(unit.attribute_map.get_attribute_by_name("endurance").current_buffed_value * 2))
				continue
			
			var fatigue: FatigueCondition = unit.conditions_manager.get_condition_by_name("fatigue")
			var new_fatigue_level_ui_name: String = fatigue.get_fatigue_level_name()
			#var fatigue_details: Dictionary = fatigue.get_fatigue_details()
			
			unit.conditions_manager.increase_fatigue()
			
			Utilities.spawn_text_line(unit, new_fatigue_level_ui_name)
			unit.setup_fatigue_left()
			
