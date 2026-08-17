class_name RunProgression
extends Node

@export var run_seed: int = 0
@export_node_path("CharacterBody2D") var player_path: NodePath
@export_node_path("Node") var exp_manager_path: NodePath
@export_node_path("Node") var buff_system_path: NodePath
@export_node_path("CanvasLayer") var level_up_ui_path: NodePath
@export_node_path("Node") var wave_manager_path: NodePath

@onready var player: ModularRobotPlayer = get_node(player_path) as ModularRobotPlayer
@onready var exp_manager: ExpManager = get_node(exp_manager_path) as ExpManager
@onready var buff_system: BuffSystem = get_node(buff_system_path) as BuffSystem
@onready var level_up_ui: LevelUpUI = get_node(level_up_ui_path) as LevelUpUI
@onready var wave_manager: WaveManager = get_node_or_null(wave_manager_path) as WaveManager

var pending_levels: Array[int] = []


func _ready() -> void:
	exp_manager.level_up_requested.connect(_on_level_up_requested)
	level_up_ui.choice_selected.connect(_on_choice_selected)
	level_up_ui.choice_skipped.connect(_on_choice_skipped)
	player.died.connect(_on_player_died)
	start_run(run_seed)


func start_run(seed_value: int = 0) -> void:
	pending_levels.clear()
	level_up_ui.force_close()
	exp_manager.reset_run()
	buff_system.reset_run(seed_value)
	player.weapon_manager.configure_selection_seed(buff_system.run_seed)
	player.weapon_manager.reset_run_modifiers()
	player.weapon_manager.reset_to_starter_loadout()
	if wave_manager != null:
		wave_manager.configure_run_seed(buff_system.run_seed)
	_apply_modifiers(buff_system.get_modifiers())


func _on_level_up_requested(new_level: int) -> void:
	pending_levels.append(new_level)
	_show_next_level_if_ready()


func _show_next_level_if_ready() -> void:
	if level_up_ui.active or pending_levels.is_empty():
		return
	var level: int = pending_levels.pop_front()
	var weapon_card_count: int = 3 if level <= 4 else (2 if level <= 8 else 1)
	var choices: Array[Dictionary] = player.weapon_manager.roll_weapon_choices(weapon_card_count, level)
	var buff_choices: Array[Dictionary] = buff_system.roll_choices(4 - choices.size(), level)
	choices.append_array(buff_choices)
	_shuffle_choices(choices)
	level_up_ui.show_choices(level, choices)


func _on_choice_selected(choice: Dictionary) -> void:
	if String(choice.get("choice_kind", "buff")) == "weapon":
		var weapon_id: String = String(choice.get("weapon_id", ""))
		var slot: int = int(choice.get("slot", 0))
		if player.equip_weapon(slot, weapon_id) == null:
			push_error("Silah kartı uygulanamadı: %s" % weapon_id)
			return
	else:
		if not buff_system.apply_choice(choice):
			push_error("Sunulmayan veya tekrar oynatılmış buff seçimi reddedildi.")
			return
	_apply_modifiers(buff_system.get_modifiers())
	call_deferred("_show_next_level_if_ready")


func _on_choice_skipped() -> void:
	call_deferred("_show_next_level_if_ready")


func _shuffle_choices(choices: Array[Dictionary]) -> void:
	for index: int in range(choices.size() - 1, 0, -1):
		var swap_index: int = buff_system.rng.randi_range(0, index)
		var temporary: Dictionary = choices[index]
		choices[index] = choices[swap_index]
		choices[swap_index] = temporary


func _apply_modifiers(modifiers: Dictionary) -> void:
	player.set_run_speed_multiplier(float(modifiers.get("speed_multiplier", 1.0)))
	player.set_run_survivability(
		int(modifiers.get("max_health_bonus", 0)),
		float(modifiers.get("damage_reduction", 0.0)),
		float(modifiers.get("dash_cooldown_multiplier", 1.0)),
		int(modifiers.get("wave_repair", 8))
	)
	player.weapon_manager.apply_run_modifiers(modifiers)
	exp_manager.set_magnet_radius(float(modifiers.get("magnet_radius", 120.0)))


func _on_player_died() -> void:
	# Leaderboard'a gidecek koşu özeti bundan önce alınmalıdır. Bundan sonra
	# istemci belleğinde hiçbir koşu buff'ı kalmaz.
	pending_levels.clear()
	level_up_ui.force_close()
	exp_manager.reset_run()
	buff_system.reset_run(run_seed)
	player.weapon_manager.reset_run_modifiers()
	_apply_modifiers(buff_system.get_modifiers())
