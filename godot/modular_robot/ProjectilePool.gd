class_name ProjectilePool
extends Node2D

@export var projectile_scene: PackedScene
@export_range(16, 512, 1) var prewarm_count: int = 128
@export_range(32, 1024, 1) var max_active_projectiles: int = 320

var available: Array[RobotProjectile] = []
var active_projectiles: Dictionary = {}


func _ready() -> void:
	for _index: int in range(prewarm_count):
		available.append(_create_projectile())


func acquire_projectile(
	spawn_position: Vector2,
	spawn_rotation: float,
	direction: Vector2,
	damage: int,
	speed: float,
	source: Node2D,
	reporter: Weapon
) -> RobotProjectile:
	if available.is_empty() and active_projectiles.size() >= max_active_projectiles:
		return null
	var projectile: RobotProjectile = available.pop_back() if not available.is_empty() else _create_projectile()
	active_projectiles[projectile.get_instance_id()] = projectile
	projectile.global_position = spawn_position
	projectile.global_rotation = spawn_rotation
	projectile.launch(direction, damage, speed, source, reporter)
	return projectile


func release(projectile: RobotProjectile) -> void:
	if not is_instance_valid(projectile) or not active_projectiles.has(projectile.get_instance_id()):
		return
	active_projectiles.erase(projectile.get_instance_id())
	projectile.deactivate()
	available.append(projectile)


func release_all() -> void:
	var snapshot: Array = active_projectiles.values()
	for value: Variant in snapshot:
		var projectile: RobotProjectile = value as RobotProjectile
		if is_instance_valid(projectile):
			release(projectile)


func get_active_count() -> int:
	return active_projectiles.size()


func _create_projectile() -> RobotProjectile:
	if projectile_scene == null:
		push_error("ProjectilePool.projectile_scene atanmadı.")
		return null
	var projectile: RobotProjectile = projectile_scene.instantiate() as RobotProjectile
	add_child(projectile)
	projectile.recycle_requested.connect(_on_recycle_requested)
	projectile.deactivate()
	return projectile


func _on_recycle_requested(projectile: RobotProjectile) -> void:
	call_deferred("release", projectile)
