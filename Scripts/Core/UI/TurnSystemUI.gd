class_name TurnSystemUI
extends Control


@export var turn_system: TurnSystem
@export var combat_system: CombatSystem

@export var end_turn_container: PanelContainer
@export var end_turn_button: Button
@export var end_phase_container: PanelContainer
@export var end_phase_button: Button

@export var turn_phase_label: Label
@export var round_counter_label: Label
@export var cycle_counter_label: Label
@export var movement_gait_label: Label

@export var enemy_turn_container: PanelContainer



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.on_turn_changed.connect(on_turn_changed)
	SignalBus.on_cycle_changed.connect(on_cycle_changed)
	SignalBus.on_phase_changed.connect(on_phase_changed)
	SignalBus.on_ui_update.connect(on_ui_update)
	

	on_ui_update()


func on_ui_update() -> void:
	update_enemy_turn_visual()
	update_turn_label()
	update_phase_label()
	update_cycle_label()
	update_gait_label()

func _on_end_turn_button_pressed() -> void:
	SignalBus.end_turn.emit()

func on_turn_changed() -> void:
	update_enemy_turn_visual()
	update_turn_label()

func on_phase_changed() -> void:
	update_phase_label()

func on_cycle_changed() -> void:
	update_cycle_label()

func update_turn_label() -> void:
	round_counter_label.text = "Round " + str(turn_system.round_number)

func update_cycle_label() -> void:
	cycle_counter_label.text = "Cycle " + str(turn_system.current_cycle)
	
func update_phase_label() -> void:
	turn_phase_label.text = combat_system.get_current_phase_name() + " Phase"
	
func update_gait_label() -> void:
	var cur_unit: Unit = TurnSystem.instance.current_unit_turn
	var move_gait: int = cur_unit.current_gait if cur_unit else 4
	match move_gait:
		0:
			movement_gait_label.set_text("Hold: " + str(move_gait))

		1:
			movement_gait_label.set_text("Walk: " + str(move_gait))

		2:
			movement_gait_label.set_text("Run: " + str(move_gait))

		3:
			movement_gait_label.set_text("Sprint: " + str(move_gait))
			
		4:
			movement_gait_label.set_text("None: " + str(move_gait))

func update_enemy_turn_visual() -> void:
	var is_player_turn: bool = TurnSystem.instance.is_player_turn
	# FIXME: Temporary debugging thing to allow me to control enemy units
	enemy_turn_container.visible = false#!is_player_turn
	if !LevelDebug.instance.end_turn_debug:
		end_turn_container.visible = is_player_turn
