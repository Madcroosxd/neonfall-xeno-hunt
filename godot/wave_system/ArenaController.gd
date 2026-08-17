class_name ArenaController
extends Node2D

@onready var player: ModularRobotPlayer = $Player as ModularRobotPlayer
@onready var enemy_pool: EnemyPool = $EnemyPool as EnemyPool
@onready var enemy_projectiles: ProjectilePool = $EnemyProjectiles as ProjectilePool
@onready var wave_manager: WaveManager = $WaveManager as WaveManager


func _ready() -> void:
	enemy_pool.attack_visual_requested.connect(_on_enemy_attack_requested)
	enemy_pool.enemy_defeated.connect(_on_enemy_defeated)
	wave_manager.wave_completed.connect(_on_wave_completed)
	player.died.connect(enemy_projectiles.release_all)
	_setup_camera()


func _setup_camera() -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(player.arena_size.x)
	camera.limit_bottom = int(player.arena_size.y)
	camera.make_current()


func _on_enemy_attack_requested(from: Vector2, to: Vector2, attack_type: String, damage: int) -> void:
	if player.dead:
		return
	_telegraph_and_fire(from, to, attack_type, damage)


func _telegraph_and_fire(from: Vector2, to: Vector2, attack_type: String, damage: int) -> void:
	var warning: Line2D = Line2D.new()
	warning.name = "AttackTelegraph"
	warning.z_index = 20
	warning.width = 2.0
	warning.antialiased = true
	warning.default_color = _attack_color(attack_type, 0.30)
	warning.points = PackedVector2Array([from, to])
	add_child(warning)
	var warning_tween: Tween = create_tween()
	warning_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	warning_tween.parallel().tween_property(warning, "width", 8.0, 0.34)
	warning_tween.parallel().tween_property(warning, "default_color", _attack_color(attack_type, 0.82), 0.34)
	await warning_tween.finished
	if is_instance_valid(warning):
		warning.queue_free()
	if player.dead:
		return
	_fire_pattern(from, to, attack_type, damage)


func _fire_pattern(from: Vector2, to: Vector2, attack_type: String, damage: int) -> void:
	var base_direction: Vector2 = (to - from).normalized()
	if base_direction.length_squared() <= 0.001:
		base_direction = Vector2.RIGHT
	match attack_type:
		"laser_ring":
			for shot_index: int in range(14):
				_spawn_enemy_projectile(from, Vector2.RIGHT.rotated(TAU * float(shot_index) / 14.0), damage, 245.0)
		"sound_wave":
			for angle_offset: float in [-0.28, -0.14, 0.0, 0.14, 0.28]:
				_spawn_enemy_projectile(from, base_direction.rotated(angle_offset), damage, 275.0)
		_:
			_spawn_enemy_projectile(from, base_direction, damage, 340.0)


func _spawn_enemy_projectile(from: Vector2, direction: Vector2, damage: int, speed: float) -> void:
	var normalized_direction: Vector2 = direction.normalized()
	enemy_projectiles.acquire_projectile(
		from + normalized_direction * 30.0,
		normalized_direction.angle(),
		normalized_direction,
		maxi(1, damage),
		speed,
		enemy_pool,
		null
	)


func _on_enemy_defeated(_enemy_type: String, was_boss: bool, death_position: Vector2, _exp_value: int) -> void:
	var shard_count: int = 18 if was_boss else 7
	for shard_index: int in range(shard_count):
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(shard_index) / float(shard_count) + randf_range(-0.16, 0.16))
		var shard: Polygon2D = Polygon2D.new()
		shard.z_index = 25
		shard.polygon = PackedVector2Array([Vector2(-5, -2), Vector2(7, 0), Vector2(-5, 2)])
		shard.color = Color("ff6fae") if was_boss else Color("63efff")
		shard.position = death_position
		shard.rotation = direction.angle()
		add_child(shard)
		var distance: float = randf_range(48.0, 120.0) * (1.45 if was_boss else 1.0)
		var burst_tween: Tween = create_tween()
		burst_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst_tween.parallel().tween_property(shard, "position", death_position + direction * distance, 0.34)
		burst_tween.parallel().tween_property(shard, "scale", Vector2.ZERO, 0.34)
		burst_tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.34)
		burst_tween.finished.connect(shard.queue_free)


func _on_wave_completed(_wave_number: int) -> void:
	enemy_projectiles.release_all()
	player.heal(player.get_wave_repair_amount())


func _attack_color(attack_type: String, alpha: float) -> Color:
	match attack_type:
		"laser_ring": return Color(1.0, 0.22, 0.38, alpha)
		"sound_wave": return Color(1.0, 0.62, 0.18, alpha)
		_: return Color(0.30, 0.92, 1.0, alpha)
