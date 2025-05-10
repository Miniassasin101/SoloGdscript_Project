@icon("res://addons/godot_gameplay_systems/attributes_and_abilities/assets/Ability.svg")
class_name Move extends Resource

## Represents an action or move

## Emitted the the move has been activated.
signal activated(Move, ActivationEvent)
## Emitted the the move has been blocked in [method Move.try_activate].
signal blocked(Move, ActivationEvent)
## Emitted the the move has been cancelled.
signal cancelled(Move, ActivationEvent)
## Emitted the the move has been ended.
signal ended(Move, ActivationEvent)
## Emitted upon move completion for phase handling.
signal move_complete(Move, ActivationEvent)

@export_group("User interface", "ui_")
## Is the icon shown in your user interface.
@export var ui_icon: Texture2D = null
## Is the name of the move shown in your user interface.
@export var ui_name: String = ""


@export_group("Move Data", "move_data_")

## What type of action this move is. Affects how far back unit is pushed in initiative.
@export_enum("Slow", "Standard", "Swift", "Free")\
var action_type: int = 1

## Damage type of the ability. Determines critical extra effects, as well as is affected by weakness/resistance.
@export_enum("Blunt", "Spike", "Keen", "Hewing", "Toxin", "Volt", "Frost", "Flame", "Acid")\
var damage_type: int = 0

## Number of dice added to the damage roll.
@export var base_power: int = 1

## How far out can this move hit a target.
@export var range: int = 1

## The attribute + skill or skill + skill used to successfully perform this move.
@export var accuracy: Array[String] = ["attribute", "skill"]


## Damage attribute is added with power and modifiers for damage pool.
@export var attribute: String = ""


## Array of added effects like "Ranged" or "Roll three chance dice to poison the foe"
@export var effects: Array[String] = ["attribute", "skill"]


## Ability Description
@export var description: String = ""








#region Tags
@export_group("Move Granting")
## Automatically grants an move when added to a [MoveContainer].
@export var grant_automatic: bool = true

## Adds these tags to the owning [MoveContainer] when the move is granted.
## [br]Useful for skill trees or skill progression systems.
@export var grant_tags: Array[String] = []

## Tags required for granting an move
## [br]These tags will be checked to ensure that the [Move] can be granted or not.
@export var grant_tags_required: Array[String] = []


@export_group("Tags", "tags_")
## Tags to determine what type of move this is
## Ex: attack, reaction, defensive, ect.
@export var tags_type: Array[String] = []


@export_group("Other Tags", "other_tags_")
## Tags added once move has been activated.
## [br]Use [member Move.tags_to_remove_on_activation] to remove some of these tags after the activation.
@export var tags_activation: Array[String] = []

## Tags required for activation. 
## [br]The move cannot be activated if the [MoveContainer] does not have all the tags provided here.
@export var tags_activation_required: Array[String] = []

## Blocks execution if ore or more tags are contained by [MoveContainer]
## [br]Use these tags to block the activation of a move.
@export var tags_block: Array[String] = []

## Tags required for cancellation.
## [br]Use these tags to determine if a move can be cancelled or not.
@export var tags_cancellation_required: Array[String] = []


## Tags which will block the end of an [Move].
@export var tags_end_blocking: Array[String] = []

## Tags which will be removed on activation.
@export var tags_to_remove_on_activation: Array[String] = []

## Tags which will be removed on block.
@export var tags_to_remove_on_block: Array[String] = []

## Tags which will be removed on cancellation.
@export var tags_to_remove_on_cancellation: Array[String] = []


## Tags which will be removed when a move ends.
@export var tags_to_remove_on_end: Array[String] = []
#endregion





## Activates the effect. This will forcefully activate it even if some criteria do not match.
## You should use [method Move.try_activate] instead for a proper (and safer) flow.
func activate(activation_event: ActivationEvent) -> void:
	activated.emit(self, activation_event)


## Return [code]true[/code] if the move can be activated, [code]false[/code] otherwise.
## [br]Always return: [code]true[/code] if [member Move.tags_activation_required] is empty.
func can_activate(activation_event: ActivationEvent) -> bool:
	if tags_activation_required.size() > 0:
		return has_all_tags(tags_activation_required, activation_event.tags)
	
	return true


## Returns [code]true[/code] if the move can be blocked, [code]false[/code] otherwise.
## [br]Always return: [code]true[/code] if [member Move.tags_block] is empty.
func can_block(activation_event: ActivationEvent) -> bool:
	if tags_block.size() > 0:
		return has_some_tags(tags_block, activation_event.tags)

	return false


## Return [code]true[/code] if the move can be cancelled, [code]false[/code] otherwise.
## [br]Always return: [code]true[/code] if [member Move.tags_cancellation_required] is empty.
func can_cancel(activation_event: ActivationEvent) -> bool:
	if tags_cancellation_required.size() > 0:
		return has_some_tags(tags_cancellation_required, activation_event.tags)
	
	return false


## Return [code]true[/code] if the move can be ended, [code]false[/code] otherwise.
## [br]Always return: [code]true[/code] if [member Move.tags_end_blocking] is empty.
func can_end(activation_event: ActivationEvent) -> bool:
	if tags_end_blocking.size() > 0:
		return !has_some_tags(tags_end_blocking, activation_event.tags)

	return true


## Cancels an move forcefully. Remember to call [method Move.can_cancel] first.
## [br]This will forcefully activate it even if some criteria do not match.
## [br]You should use [method Move.try_activate] instead for a proper (and safer) flow.
func cancel(activation_event: ActivationEvent) -> void:
	if can_cancel(activation_event):
		cancelled.emit(self, activation_event)


## Ends the move forcefully. Remember to call [method Move.can_end] first.
func end_move(activation_event: ActivationEvent) -> void:
	if can_end(activation_event):
		ended.emit(self, activation_event)


		# Might be an issue with passive or persistent abilities

		
		SignalBus.move_complete.emit(self)
		
		# If the action is successfully completed, then the next phase is triggered indirectly through this signal
		# The move phase has to be manually ended by the player as it does not end after a move is used.
		if activation_event.successful and is_type("action"): # Tags are: action, reaction, free, and move
			SignalBus.move_complete_next.emit(self)



## Checks if the parameter [code]tags[/code] has all tags included in [code]tags_to_check[/code].
## [br]It checks if [code]tags[/code] has all [code]tags_to_check[/code].
func has_all_tags(tags: Array[String], tags_to_check: Array[String]) -> bool:
	for t in tags:
		if not tags_to_check.has(t):
			return false

	return true

## Checks if the parameter [code]tags[/code] has some tags included in [code]tags_to_check[/code].
## [br]It checks if [code]tags[/code] has all [code]tags_to_check[/code].
func has_some_tags(tags: Array[String], tags_to_check: Array[String]) -> bool:
	for t in tags:
		if tags_to_check.has(t):
			return true

	return false

func is_type(tag: String) -> bool:
	for t: String in tags_type:
		if t.to_lower() == tag.to_lower():
			return true
	return false

## Tries to activate an move, then tries to cancel it and then tries to end it.
func try_activate(activation_event: ActivationEvent) -> void:
	if can_block(activation_event):
		blocked.emit(self, activation_event)
		return

	if can_activate(activation_event):
		activate(activation_event)

func get_enemy_ai_move(_event: ActivationEvent) -> EnemyAIAction:
	push_error(" Method get_enemy_ai_move() was called on base Move ")
	return null

func get_valid_move_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	#push_warning(" Method get_valid_move_target_grid_position_list() was called on base move ")
	return []


func spawn_damage_label(in_unit: Unit, damage_val: float, color: Color) -> void:
	Utilities.spawn_damage_label(in_unit, damage_val, color)
	
