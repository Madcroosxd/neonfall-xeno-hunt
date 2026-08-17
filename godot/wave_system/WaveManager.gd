class_name WaveManager
extends Node

signal wave_started(wave_number: int, wave_kind: String, total_enemies: int)
signal wave_progress(queued_remaining: int, active_enemies: int)
signal wave_completed(wave_number: int)
signal boss_spawned(boss_name: String, max_health: float)
signal boss_health_changed(current_health: float, max_health: float)
signal boss_defeated(boss_name: String)

const MAX_SPAWNS_PER_PHYSICS_FRAME: int = 3

const ENEMY_DATABASE: Dictionary = {
	"blobby": {
		"enemy_type": "blobby", "display_name": "Kristal Kovan Böceği",
		"health": 20.0, "speed": 160.0, "contact_damage": 10, "exp_value": 3,
		"radius": 18.0, "visual_scale": 0.9, "color": "5cc9ff", "face": "•ᴗ•",
	},
	"ufo_head": {
		"enemy_type": "ufo_head", "display_name": "Gözcü Disk",
		"health": 15.0, "speed": 220.0, "contact_damage": 6, "ranged_damage": 0, "exp_value": 4,
		"radius": 16.0, "visual_scale": 0.82, "color": "59e8ff", "face": "◉‿◉",
	},
	"laser_lemon": {
		"enemy_type": "laser_lemon", "display_name": "Zehir Karınca",
		"health": 30.0, "speed": 190.0, "contact_damage": 15, "exp_value": 5,
		"radius": 20.0, "visual_scale": 1.0, "color": "7dff8a", "face": "⊙",
	},
	"space_donkey": {
		"enemy_type": "space_donkey", "display_name": "Zırhlı Avcı",
		"health": 60.0, "speed": 100.0, "contact_damage": 25, "knockback": 540.0, "exp_value": 8,
		"radius": 28.0, "visual_scale": 1.35, "color": "a8b0bd", "face": "ಠ益ಠ",
	},
}

const BOSS_DATABASE: Dictionary = {
	"mega_monitor": {
		"enemy_type": "mega_monitor", "display_name": "ÇEKİRDEK MUHAFIZ",
		"health": 800.0, "speed": 68.0, "contact_damage": 22, "exp_value": 60,
		"radius": 62.0, "visual_scale": 2.7, "color": "ff536f", "face": "ERROR",
		"is_boss": true,
	},
	"mixtape_mech": {
		"enemy_type": "mixtape_mech", "display_name": "SİNYAL AVCISI",
		"health": 1000.0, "speed": 74.0, "contact_damage": 24, "knockback": 440.0, "exp_value": 80,
		"radius": 66.0, "visual_scale": 2.9, "color": "ffad45", "face": "▶ REC",
		"is_boss": true,
	},
	"mother_disk": {
		"enemy_type": "mother_disk", "display_name": "ANA GEMİ VOID",
		"health": 1200.0, "speed": 58.0, "contact_damage": 28, "exp_value": 100,
		"radius": 72.0, "visual_scale": 3.2, "color": "8a72ff", "face": "MOTHERSHIP",
		"is_boss": true,
	},
}

const BOSS_ORDER: Array[String] = ["mega_monitor", "mixtape_mech", "mother_disk"]

@export_group("Scene References")
@export_node_path("CharacterBody2D") var player_path: NodePath
@export_node_path("Node2D") var enemy_pool_path: NodePath
@export_node_path("Node2D") var spawn_points_path: NodePath
@export_node_path("Marker2D") var arena_center_path: NodePath

@export_group("Wave Tuning")
@export var run_seed: int = 0
@export var auto_start: bool = true
@export var auto_advance: bool = true
@export_range(20, 140, 1) var max_active_enemies: int = 72
@export_range(1, 30, 1) var prewarm_per_enemy_type: int = 18
@export_range(0.02, 1.0, 0.01) var normal_spawn_interval: float = 0.12
@export_range(0.02, 1.0, 0.01) var swarm_spawn_interval: float = 0.045
@export_range(0.0, 10.0, 0.1) var intermission_duration: float = 2.5

@onready var player: ModularRobotPlayer = get_node(player_path) as ModularRobotPlayer
@onready var enemy_pool: EnemyPool = get_node(enemy_pool_path) as EnemyPool
@onready var spawn_points: Node2D = get_node(spawn_points_path) as Node2D
@onready var arena_center: Marker2D = get_node(arena_center_path) as Marker2D

var current_wave: int = 0
var wave_active: bool = false
var waiting_for_next_wave: bool = false
var intermission_remaining: float = 0.0
var spawn_queue: Array[String] = []
var spawn_cursor: int = 0
var spawn_cooldown: float = 0.0
var current_spawn_interval: float = 0.12
var current_health_multiplier: float = 1.0
var current_speed_multiplier: float = 1.0
var current_damage_multiplier: float = 1.0
var boss_alive: bool = false
var active_boss_name: String = ""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var boss_bag: Array[String] = []
var last_boss_id: String = ""


func _ready() -> void:
	configure_run_seed(run_seed)
	enemy_pool.enemy_defeated.connect(_on_enemy_defeated)
	enemy_pool.boss_health_changed.connect(_on_boss_health_changed)
	enemy_pool.summon_requested.connect(_on_summon_requested)
	enemy_pool.prepare(ENEMY_DATABASE.keys(), prewarm_per_enemy_type)
	enemy_pool.prepare(BOSS_DATABASE.keys(), 1)
	if auto_start:
		call_deferred("start_next_wave")


func configure_run_seed(seed_value: int) -> void:
	run_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_msec()
	rng.seed = run_seed ^ 0x57415645
	boss_bag.clear()
	last_boss_id = ""


func _physics_process(delta: float) -> void:
	if waiting_for_next_wave:
		if not auto_advance:
			return
		intermission_remaining -= delta
		if intermission_remaining <= 0.0:
			start_next_wave()
		return
	if not wave_active or boss_alive:
		return

	_spawn_from_budget(delta)
	var queued_remaining: int = maxi(0, spawn_queue.size() - spawn_cursor)
	wave_progress.emit(queued_remaining, enemy_pool.get_active_count())
	if queued_remaining == 0 and enemy_pool.get_active_count() == 0:
		_finish_wave()


func start_next_wave() -> void:
	start_wave(current_wave + 1)


func start_wave(wave_number: int) -> void:
	if wave_number <= 0:
		return
	enemy_pool.release_all()
	current_wave = wave_number
	wave_active = true
	waiting_for_next_wave = false
	boss_alive = false
	active_boss_name = ""
	spawn_queue.clear()
	spawn_cursor = 0
	spawn_cooldown = 0.0

	# 90 gibi hem 9'a hem 10'a bölünen dalgalarda Boss kuralı önceliklidir.
	if current_wave % 10 == 0:
		_start_boss_wave()
		return

	var swarm_wave: bool = current_wave % 9 == 0
	var normal_count: int = 8 + current_wave * 3
	var total_count: int = normal_count * 2 if swarm_wave else normal_count
	current_spawn_interval = swarm_spawn_interval if swarm_wave else normal_spawn_interval
	current_health_multiplier = (0.55 if swarm_wave else 1.0) * (1.0 + float(current_wave - 1) * 0.115)
	current_speed_multiplier = (1.16 if swarm_wave else 1.0) * minf(1.34, 1.0 + float(current_wave - 1) * 0.012)
	current_damage_multiplier = (0.78 if swarm_wave else 1.0) * (1.0 + float(current_wave - 1) * 0.045)
	for _index: int in range(total_count):
		spawn_queue.append(_pick_enemy_type())
	wave_started.emit(current_wave, "SWARM" if swarm_wave else "NORMAL", total_count)


func _start_boss_wave() -> void:
	var boss_round: int = maxi(0, int(float(current_wave) / 10.0) - 1)
	var boss_cycle: int = floori(float(boss_round) / float(BOSS_ORDER.size()))
	var boss_id: String = _pick_boss_id()
	var definition: Dictionary = (BOSS_DATABASE[boss_id] as Dictionary).duplicate(true)
	# Üç Boss da ilk karşılaşmada veritabanındaki temel canıyla gelir. Zorluk
	# artışı ancak tam Boss rotasyonu tamamlandıktan sonra uygulanır.
	var boss_health_scale: float = 1.0 + float(boss_cycle) * 0.38
	definition["health"] = float(definition["health"]) * boss_health_scale
	definition["speed"] = float(definition["speed"]) * minf(1.28, 1.0 + float(boss_cycle) * 0.055)
	definition["contact_damage"] = int(round(float(definition["contact_damage"]) * (1.0 + float(boss_cycle) * 0.16)))
	var boss: PooledEnemy = enemy_pool.acquire(definition, player, arena_center.global_position)
	boss_alive = true
	active_boss_name = String(definition["display_name"])
	wave_started.emit(current_wave, "BOSS", 1)
	boss_spawned.emit(active_boss_name, boss.max_health)


func _spawn_from_budget(delta: float) -> void:
	if spawn_cursor >= spawn_queue.size():
		return
	spawn_cooldown -= delta
	var frame_budget: int = MAX_SPAWNS_PER_PHYSICS_FRAME
	while spawn_cursor < spawn_queue.size() and spawn_cooldown <= 0.0 and frame_budget > 0:
		if enemy_pool.get_active_count() >= max_active_enemies:
			return
		_spawn_normal_enemy(spawn_queue[spawn_cursor], _random_spawn_position())
		spawn_cursor += 1
		frame_budget -= 1
		spawn_cooldown += current_spawn_interval


func _spawn_normal_enemy(enemy_type: String, spawn_position: Vector2) -> PooledEnemy:
	var definition: Dictionary = (ENEMY_DATABASE[enemy_type] as Dictionary).duplicate(true)
	definition["health"] = maxf(1.0, float(definition["health"]) * current_health_multiplier)
	definition["speed"] = float(definition["speed"]) * current_speed_multiplier
	definition["contact_damage"] = maxi(1, int(round(float(definition["contact_damage"]) * current_damage_multiplier))) if int(definition["contact_damage"]) > 0 else 0
	if definition.has("ranged_damage"):
		definition["ranged_damage"] = maxi(1, int(round(float(definition["ranged_damage"]) * current_damage_multiplier))) if int(definition["ranged_damage"]) > 0 else 0
	return enemy_pool.acquire(definition, player, spawn_position)


func _pick_enemy_type() -> String:
	var roll: float = rng.randf()
	if current_wave < 2:
		return "blobby"
	if current_wave < 4:
		return "ufo_head" if roll < 0.32 else "blobby"
	if current_wave < 6:
		if roll < 0.23: return "ufo_head"
		if roll < 0.52: return "laser_lemon"
		return "blobby"
	if roll < 0.18: return "space_donkey"
	if roll < 0.42: return "ufo_head"
	if roll < 0.70: return "laser_lemon"
	return "blobby"


func _random_spawn_position() -> Vector2:
	var points: Array[Node] = spawn_points.get_children()
	if points.is_empty():
		return arena_center.global_position + Vector2.RIGHT.rotated(rng.randf() * TAU) * 1650.0
	var marker: Node2D = points[rng.randi_range(0, points.size() - 1)] as Node2D
	return marker.global_position + Vector2(rng.randf_range(-28.0, 28.0), rng.randf_range(-28.0, 28.0))


func _pick_boss_id() -> String:
	if boss_bag.is_empty():
		boss_bag.assign(BOSS_ORDER)
		for index: int in range(boss_bag.size() - 1, 0, -1):
			var swap_index: int = rng.randi_range(0, index)
			var temporary: String = boss_bag[index]
			boss_bag[index] = boss_bag[swap_index]
			boss_bag[swap_index] = temporary
		# Yeni torbanın ilk Boss'u önceki torbanın son Boss'uyla aynı olmasın.
		if boss_bag.size() > 1 and boss_bag.back() == last_boss_id:
			var temporary: String = boss_bag[0]
			boss_bag[0] = boss_bag[boss_bag.size() - 1]
			boss_bag[boss_bag.size() - 1] = temporary
	var selected: String = boss_bag.pop_back()
	last_boss_id = selected
	return selected


func _on_enemy_defeated(_enemy_type: String, was_boss: bool, _death_position: Vector2, _exp_value: int) -> void:
	if not was_boss:
		return
	boss_alive = false
	enemy_pool.call_deferred("release_all_non_boss")
	boss_defeated.emit(active_boss_name)
	call_deferred("_finish_wave")


func _on_boss_health_changed(current_health: float, max_health: float) -> void:
	if boss_alive:
		boss_health_changed.emit(current_health, max_health)


func _on_summon_requested(enemy_type: String, spawn_position: Vector2) -> void:
	if not boss_alive or enemy_type != "blobby" or enemy_pool.get_active_count() >= max_active_enemies:
		return
	current_health_multiplier = 0.72 + float(current_wave / 10) * 0.16
	current_speed_multiplier = 1.08
	current_damage_multiplier = 0.85
	_spawn_normal_enemy(enemy_type, spawn_position)


func _finish_wave() -> void:
	if not wave_active:
		return
	wave_active = false
	waiting_for_next_wave = true
	intermission_remaining = intermission_duration
	wave_completed.emit(current_wave)
