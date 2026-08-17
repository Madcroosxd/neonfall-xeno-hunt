class_name EnemyPool
extends Node2D

signal enemy_acquired(enemy: PooledEnemy)
signal enemy_released(enemy_type: String)
signal enemy_defeated(enemy_type: String, was_boss: bool, death_position: Vector2, exp_value: int)
signal boss_health_changed(current_health: float, max_health: float)
signal attack_visual_requested(from: Vector2, to: Vector2, attack_type: String, damage: int)
signal summon_requested(enemy_type: String, spawn_position: Vector2)

@export var enemy_scene: PackedScene

var available: Dictionary = {}
var active_enemies: Dictionary = {}


func prepare(enemy_types: Array, amount_per_type: int = 12) -> void:
	for type_value: Variant in enemy_types:
		var enemy_type: String = String(type_value)
		var bucket: Array = available.get(enemy_type, [])
		for _index: int in range(amount_per_type):
			bucket.append(_create_enemy())
		available[enemy_type] = bucket


func acquire(definition: Dictionary, player: ModularRobotPlayer, spawn_position: Vector2) -> PooledEnemy:
	var enemy_type: String = String(definition.get("enemy_type", "blobby"))
	var bucket: Array = available.get(enemy_type, [])
	var enemy: PooledEnemy
	if bucket.is_empty():
		enemy = _create_enemy()
	else:
		enemy = bucket.pop_back() as PooledEnemy
	available[enemy_type] = bucket
	active_enemies[enemy.get_instance_id()] = enemy
	enemy.activate(definition, player, spawn_position)
	enemy_acquired.emit(enemy)
	return enemy


func release(enemy: PooledEnemy) -> void:
	if not is_instance_valid(enemy) or not active_enemies.has(enemy.get_instance_id()):
		return
	active_enemies.erase(enemy.get_instance_id())
	var enemy_type: String = enemy.enemy_type
	enemy.deactivate()
	var bucket: Array = available.get(enemy_type, [])
	bucket.append(enemy)
	available[enemy_type] = bucket
	enemy_released.emit(enemy_type)


func release_all_non_boss() -> void:
	var active_copy: Array = active_enemies.values()
	for value: Variant in active_copy:
		var enemy: PooledEnemy = value as PooledEnemy
		if is_instance_valid(enemy) and not enemy.is_boss:
			release(enemy)


func release_all() -> void:
	var active_copy: Array = active_enemies.values()
	for value: Variant in active_copy:
		var enemy: PooledEnemy = value as PooledEnemy
		if is_instance_valid(enemy):
			release(enemy)


func get_active_count() -> int:
	return active_enemies.size()


func _create_enemy() -> PooledEnemy:
	if enemy_scene == null:
		push_error("EnemyPool.enemy_scene atanmadı.")
		return null
	var enemy: PooledEnemy = enemy_scene.instantiate() as PooledEnemy
	add_child(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.ranged_attack_requested.connect(_on_attack_visual_requested)
	enemy.summon_requested.connect(_on_summon_requested)
	enemy.deactivate()
	return enemy


func _on_enemy_defeated(enemy: PooledEnemy) -> void:
	var defeated_type: String = enemy.enemy_type
	var was_boss: bool = enemy.is_boss
	var death_position: Vector2 = enemy.global_position
	var exp_value: int = enemy.exp_value
	enemy_defeated.emit(defeated_type, was_boss, death_position, exp_value)
	call_deferred("release", enemy)


func _on_enemy_health_changed(enemy: PooledEnemy, current_health: float, max_health: float) -> void:
	if enemy.is_boss:
		boss_health_changed.emit(current_health, max_health)


func _on_attack_visual_requested(from: Vector2, to: Vector2, attack_type: String, damage: int) -> void:
	attack_visual_requested.emit(from, to, attack_type, damage)


func _on_summon_requested(enemy_type: String, spawn_position: Vector2) -> void:
	summon_requested.emit(enemy_type, spawn_position)
