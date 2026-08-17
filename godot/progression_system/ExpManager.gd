class_name ExpManager
extends Node

signal exp_changed(level: int, current_exp: int, required_exp: int)
signal level_up_requested(level: int)
signal level_cap_reached(level: int)

@export_range(2, 200, 1) var level_cap: int = 60
@export_node_path("Node2D") var player_path: NodePath
@export_node_path("Node2D") var enemy_pool_path: NodePath
@export_node_path("Node2D") var orb_pool_path: NodePath

@onready var player: ModularRobotPlayer = get_node(player_path) as ModularRobotPlayer
@onready var enemy_pool: EnemyPool = get_node(enemy_pool_path) as EnemyPool
@onready var orb_pool: ExpOrbPool = get_node(orb_pool_path) as ExpOrbPool

var level: int = 1
var current_exp: int = 0
var required_exp: int = 8
var magnet_radius: float = 120.0


func _ready() -> void:
	enemy_pool.enemy_defeated.connect(_on_enemy_defeated)
	orb_pool.orb_collected.connect(add_exp)
	reset_run()


func reset_run() -> void:
	level = 1
	current_exp = 0
	required_exp = get_required_exp(level)
	magnet_radius = 120.0
	if is_instance_valid(orb_pool):
		orb_pool.release_all()
	exp_changed.emit(level, current_exp, required_exp)


func add_exp(amount: int) -> void:
	if amount <= 0 or level >= level_cap:
		return
	current_exp += amount
	while current_exp >= required_exp and level < level_cap:
		current_exp -= required_exp
		level += 1
		required_exp = get_required_exp(level)
		level_up_requested.emit(level)
	if level >= level_cap:
		current_exp = 0
		required_exp = 0
		level_cap_reached.emit(level)
	exp_changed.emit(level, current_exp, required_exp)


func get_required_exp(for_level: int) -> int:
	# İlk beş seviye oyuncuya sistemi hızla tanıtır; sonrasında eğri kontrollü
	# biçimde yükselir ve uzun koşularda ilerlemeyi tamamen durdurmaz.
	const EARLY_LEVEL_REQUIREMENTS: Array[int] = [8, 14, 22, 32, 45]
	if for_level <= EARLY_LEVEL_REQUIREMENTS.size():
		return EARLY_LEVEL_REQUIREMENTS[maxi(0, for_level - 1)]
	return 45 + roundi(13.0 * pow(float(for_level - 5), 1.22))


func set_magnet_radius(radius: float) -> void:
	magnet_radius = clampf(radius, 24.0, 720.0)
	orb_pool.set_magnet_radius(magnet_radius)


func _on_enemy_defeated(_enemy_type: String, _was_boss: bool, death_position: Vector2, exp_value: int) -> void:
	orb_pool.acquire(death_position, exp_value, player, magnet_radius)
