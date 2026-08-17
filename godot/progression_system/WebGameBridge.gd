class_name WebGameBridge
extends Node

@export_node_path("CharacterBody2D") var player_path: NodePath
@export_node_path("Node2D") var enemy_pool_path: NodePath
@export_node_path("Node") var wave_manager_path: NodePath
@export_node_path("Control") var game_over_panel_path: NodePath
@export_node_path("Label") var game_over_stats_path: NodePath
@export_node_path("Button") var restart_button_path: NodePath

@onready var player: ModularRobotPlayer = get_node(player_path) as ModularRobotPlayer
@onready var enemy_pool: EnemyPool = get_node(enemy_pool_path) as EnemyPool
@onready var wave_manager: WaveManager = get_node(wave_manager_path) as WaveManager
@onready var game_over_panel: Control = get_node(game_over_panel_path) as Control
@onready var game_over_stats: Label = get_node(game_over_stats_path) as Label
@onready var restart_button: Button = get_node(restart_button_path) as Button

var web_bridge: Variant = null
var elapsed: float = 0.0
var sync_timer: float = 0.0
var kills: int = 0
var score: int = 0
var current_wave: int = 1
var finished: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		web_bridge = JavaScriptBridge.get_interface("NeonfallBridge")
	enemy_pool.enemy_defeated.connect(_on_enemy_defeated)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	player.died.connect(_on_player_died)
	restart_button.pressed.connect(_request_restart)
	game_over_panel.visible = false


func _process(delta: float) -> void:
	if finished or get_tree().paused:
		return
	elapsed += delta
	sync_timer += delta
	if sync_timer >= 10.0:
		sync_timer = 0.0
		_sync_progress(false)


func _on_enemy_defeated(_enemy_type: String, was_boss: bool, _position: Vector2, exp_value: int) -> void:
	if finished:
		return
	kills += 1
	score += 120 + exp_value * 14
	if was_boss:
		score += 5000


func _on_wave_started(wave_number: int, _kind: String, _enemy_count: int) -> void:
	current_wave = wave_number


func _on_wave_completed(wave_number: int) -> void:
	score += 400 + wave_number * 60


func _on_player_died() -> void:
	if finished:
		return
	finished = true
	_sync_progress(true)
	game_over_stats.text = "SKOR  %s\nWAVE  %02d   //   İMHA  %d\nSÜRE  %02d:%02d" % [
		_format_score(score), current_wave, kills,
		floori(elapsed / 60.0), floori(fmod(elapsed, 60.0)),
	]
	game_over_panel.visible = true
	restart_button.grab_focus()


func _sync_progress(is_finish: bool) -> void:
	if web_bridge == null:
		return
	if is_finish:
		web_bridge.finish(score, current_wave, kills, floori(elapsed))
	else:
		web_bridge.heartbeat(score, current_wave, kills, floori(elapsed))


func _request_restart() -> void:
	if web_bridge != null:
		web_bridge.restart()
	else:
		get_tree().reload_current_scene()


func _format_score(value: int) -> String:
	var raw: String = str(maxi(0, value))
	var output: String = ""
	for index: int in range(raw.length()):
		if index > 0 and (raw.length() - index) % 3 == 0:
			output += "."
		output += raw[index]
	return output
