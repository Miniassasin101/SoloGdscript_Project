## MoveContainer
## 
## This is the container for [Move] resources.
## [br][Move] resources can be activated, cancelled or finished under some circumstances and are used to apply 
## [GameplayEffect] resources to [GameplayAttributeMap] instances.

@icon("res://addons/godot_gameplay_systems/attributes_and_moves/assets/MoveContainer.svg")

class_name MoveContainer extends Node



#region Signals
## Emitted when an move is activated manually or automatically
signal move_activated(move: Move, activation_event: ActivationEvent)
## Emitted when an move blocked it's execution. This happen when the [method Move.can_block] returns [code]true[/code]. 
signal move_blocked(move: Move, activation_event: ActivationEvent)
## Emitted when an move is manually or automatically cancelled
signal move_cancelled(move: Move, activation_event: ActivationEvent)
## Emitted when an move has ended
signal move_ended(move: Move, activation_event: ActivationEvent)
## Emitted when an move is granted
signal move_granted(move: Move)
## Emitted when an move is revoked
signal move_revoked(move: Move)
## Emitted when the node is activated or disabled
signal activated(active: bool)
## Emitted when tags are updated
signal tags_updated(updated_tags: Array[String], previous_tags: Array[String])
#endregion


@export_category("Moves")
## It's the path to the [GameplayAttributeMap] which holds all character attributes
@export_node_path("GameplayAttributeMap") var gameplay_attribute_map_path = NodePath()
## It's a preset of [Move] resources. [Move] can be also granted at runtime using [method MoveContainer.grant]
@export var moves: Array[Move] = []
## If set to [code]false[/code], you will not be able to add/end/grant/revoke moves. 
## [br]Ideal to set a character to a dead state.
@export var active := true:
	get:
		return active
	set(value):
		active = value
		
		if not active:
			cancel_many()
		
		activated.emit(value)
## It's a preset of tags. Tags can be granted/removed at runtime and are usually referenced by [Move]
@export var tags: Array[String] = []


## It's the related [GameplayAttributeMap] as specified by [member MoveContainer.gameplay_attribute_map_path]
var gameplay_attribute_map: GameplayAttributeMap
## It's an array of granted Moves.
var granted_moves: Array[Move] = []




#region Move Handlers

## Handles the [signal Move.activated] signal
## [br]It's called internally by the current [MoveContainer], so you should not call it.
func _handle_move_activated(move: Move, activation_event: ActivationEvent) -> void:
	if not _is_eligible_for_operation(activation_event):
		return

	move_activated.emit(move, activation_event)

	if move.can_end(activation_event):
		#move.end_move(activation_event)
		pass


## Handles the [signal Move.blocked] signal.
## [br]It's called internally by the current [MoveContainer], so you should not call it.
func _handle_move_blocked(move: Move, activation_event: ActivationEvent) -> void:
	if not _is_eligible_for_operation(activation_event):
		return
		
	move_blocked.emit(move, activation_event)



## Handles the [signal Move.cancelled] signal
## [br]It's called internally by the current [MoveContainer], so you should not call it.
func _handle_move_cancelled(move: Move, activation_event: ActivationEvent) -> void:
	if not _is_eligible_for_operation(activation_event):
		return
	

	move_cancelled.emit(move, activation_event)


## Handles the [signal Move.ended] signal
## [br]It's called internally by the current [MoveContainer], so you should not call it.
func _handle_move_ended(move: Move, activation_event: ActivationEvent) -> void:
	if not _is_eligible_for_operation(activation_event):
		return
	
	move_ended.emit(move, activation_event)
#endregion





## Returns [code]true[/code] if the [MoveContainer] can process and [ActivationEvent], [code]false[/code] otherwise.
func _is_eligible_for_operation(activation_event: ActivationEvent) -> bool:
	return activation_event.move_container == self and active


## The [method Node._ready] override
func _ready() -> void:
	moves = moves.duplicate()
	gameplay_attribute_map = get_node(gameplay_attribute_map_path)
	grant_all_moves()


func can_activate_at_position(_move: Move, _target_grid_position: GridPosition) -> bool:
	if not active:
		return false
	elif granted_moves.has(_move):
		var event: ActivationEvent = ActivationEvent.new(self)
		event.target_grid_position = _target_grid_position
		return _move.can_activate(event)
	return false


func get_valid_move_target_grid_position_list(_move: Move) -> Array[GridPosition]:
	if not active:
		return []
	elif granted_moves.has(_move):
		var event = ActivationEvent.new(self)
		event.target_grid_position = get_parent().get_grid_position()
		if _move.has_method("get_valid_move_target_grid_position_list"):
			return _move.get_valid_move_target_grid_position_list(event)
	return[]


# Gets the best AI action for a specified grid position.
func get_enemy_ai_move(_move: Move, grid_position: GridPosition) -> EnemyAIAction:
	if not active:
		return null
	elif granted_moves.has(_move):
		var event = ActivationEvent.new(self)
		event.target_grid_position = grid_position
		if _move.has_method("get_enemy_ai_move"):
			return _move.get_enemy_ai_move(event)
	return null

## Activates a single [Move] calling [method Move.try_activate].
func activate_one(move: Move, grid_position: GridPosition = null, in_event: ActivationEvent = null) -> void:
	if not active:
		return
	var target_pos: GridPosition = grid_position
	if target_pos == null:
		target_pos = get_parent().get_grid_position()
	if granted_moves.has(move):
		if in_event != null:
			move.try_activate(in_event)
			return
		var event = ActivationEvent.new(self)
		event.target_grid_position = target_pos
		move.try_activate(event)


## Activates many [Move] resources by tags calling [method Move.try_activate]
## [br]If parallel_execution is [code]true[/code], then the event passed is generated once for all moves
## otherwise the event will be regenerated for each iteration
func activate_many(parallel_execution: bool = false) -> void:
	if not active:
		return
		
	if parallel_execution:
		var activation_event = ActivationEvent.new(self)

		for x in granted_moves:
			x.try_activate(activation_event)
	else:
		for x in granted_moves:
			x.try_activate(ActivationEvent.new(self))


## Adds a tag to an [MoveContainer] avoiding duplicates
func add_tag(tag: String, skip_emitting = false) -> void:
	if not tags.has(tag):
		var previous_tags: Array[String] = tags.duplicate()
		tags.append(tag)
		tags_updated.emit(tags, previous_tags)


## Adds many tags to an [MoveContainer]
func add_tags(tags: Array[String]) -> void:
	var previous_tags: Array[String]

	for t in tags:
		if not self.tags.has(t):
			if previous_tags == null:
				previous_tags = tags.duplicate()
			
			add_tag(t)
		
	tags_updated.emit(tags, previous_tags)


## Checks if the [Move] can be granted
func can_grant(move: Move) -> bool:
	if not active:
		return false
	
	if move.grant_tags_required.size() > 0:
		if move.has_all_tags(move.grant_tags_required, self.tags):
			return !granted_moves.has(move)
		else:
			return false
	
	return !granted_moves.has(move)


## Checks if the [Move] can be revoked
func can_revoke(move: Move) -> bool:
	if not active:
		return false
	
	return granted_moves.has(move) and move.can_end(ActivationEvent.new(self))


## Cancels one [Move] using [method Move.can_cancel]
func cancel_one(move: Move) -> void:
	if not active:
		return
	
	var activation_event = ActivationEvent.new(self)

	if move.can_cancel(activation_event):
		move.cancel(activation_event)


## Cancels many [Move].
func cancel_many() -> void:
	if not active:
		return
	
	var activation_event = ActivationEvent.new(self)

	for a in granted_moves:
		if a.can_cancel(activation_event):
			a.cancel(activation_event)


## Ends an move if possible.
func end_one(move: Move) -> void:
	if not active:
		return
	
	var activation_event = ActivationEvent.new(self)

	if granted_moves.has(move):
		if move.can_end(activation_event):
			move.end_move(activation_event)
		

## Ends many moves if possible.
func end_many() -> void:
	if not active:
		return
	
	var activation_event = ActivationEvent.new(self)
	
	for a in granted_moves:
		if a.can_end(activation_event):
			a.end_move(activation_event)


## Finds the first [Move] which matches the [Callable] predicate. Returns [code]null[/code] otherwise.
func find_by(predicate: Callable, includes_ungranted = false) -> Move:
	if includes_ungranted:
		for a in moves:
			if predicate.call(a):
				return a
	for a in granted_moves:
		if predicate.call(a):
			return a
	return null
	

## Returns a filtered array of [Move] which satisfy the [Callable] predicate.
func filter_moves(predicate: Callable, includes_ungranted = false) -> Array[Move]:
	var out: Array[Move] = []
	
	if includes_ungranted:
		for a in moves:
			if predicate.call(a):
				out.append(a)
	for a in granted_moves:
		if predicate.call(a):
			out.append(a)
	
	return out



## Gives an [Move] at runtime
## If the [Move] has already been granted, it will be ignored silently
## [br]Returns [code]true[/code] if the move has been granted, [code]false[/code] otherwise
func grant(move: Move) -> bool:
	# It's not active, maybe the owner is dead or on holiday
	if not active:
		return false
	
	# Obviously skip granting if move is null
	if move == null:
		return false
	
	# Skips if cannot be granted
	if not can_grant(move):
		return false

	# Removes from moves array if it's there. This avoids duplication which could lead to bugs.
	var move_index = moves.find(move)

	if move_index >= 0:
		moves.remove_at(move_index)

	# Appends to moves array
	granted_moves.append(move)

	# Connecting signals (unless they are already connected)
	if not move.activated.is_connected(_handle_move_activated):
		move.activated.connect(_handle_move_activated)
	if not move.blocked.is_connected(_handle_move_blocked):
		move.blocked.connect(_handle_move_blocked)
	if not move.cancelled.is_connected(_handle_move_cancelled):
		move.cancelled.connect(_handle_move_cancelled)
	if not move.ended.is_connected(_handle_move_ended):
		move.ended.connect(_handle_move_ended)


	# Granting tags if any
	if move.grant_tags:
		add_tags(move.grant_tags)

	# Emits grant signal, so UI/parent nodes can do stuff with it
	move_granted.emit(move)

	# Returns true, so the caller knows the move has been granted
	return true


## Grants many [Move] at runtime
## If an [Move] is granted, it is removed from the [member MoveContainer.moves] array and added to the [member MoveContainer.granted_moves] array.
## If an [Move] has already been granted, it will be ignored silently
## [br]Returns [code]int[/code] the number of moves granted
func grant_all_moves() -> int:
	var granted = 0
	var cursor = -1

	for i in moves.size():
		var move = moves[cursor]

		if grant(move):
			granted += 1
		else:
			cursor -= 1

	return granted


## Returns [code]true[/code] if has an [Move] which satisfies the [Callable] predicate, [code]false[/code] otherwise
func has_move(predicate: Callable, includes_ungranted = false) -> bool:
	return find_by(predicate, includes_ungranted) != null


## Returns [code]true[/code] if the tag is contained in the tags of the specified [Move] in the [MoveContainer], [code]false[/code] otherwise.
func has_tag(tag: String) -> bool:
	return tags.has(tag)


## Removes a single tag
func remove_tag(tag: String) -> void:
	var index = tags.find(tag)
	
	if index >= 0:
		var previous_tags = tags.duplicate()
		tags.remove_at(index)
		tags_updated.emit(tags, previous_tags)


## Removes many tags
func remove_tags(tags_to_remove: Array[String]) -> void:
	if tags_to_remove.size() == 0:
		return

	var previous_tags = tags.duplicate()
	
	for t in tags_to_remove:
		var index = tags.find(t)
		
		if index >= 0:
			tags.remove_at(index)

	tags_updated.emit(tags, previous_tags)


## End an [Move] and then removes from the [member MoveContainer.granted_moves] array and emits [signal MoveContainer.move_revoked].
func revoke(move: Move, removes_completely: bool = false) -> void:
	if not active:
		return
	
	if not can_revoke(move):
		return
	
	var index = granted_moves.find(move)
	var activation_event = ActivationEvent.new(self)

	if move.can_end(activation_event):
		move.end_move(activation_event)


		if index >= 0:
			granted_moves.remove_at(index)
			move_revoked.emit(move)

			if not removes_completely and not moves.has(move):
				moves.append(move)
