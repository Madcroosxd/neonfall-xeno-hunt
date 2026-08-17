class_name PlasmaPeashooter
extends Weapon

@export var projectile_scene: PackedScene

@onready var muzzle: Marker2D = $Muzzle


func _perform_shot() -> void:
	if projectile_scene == null:
		push_warning("Plasma Peashooter için projectile_scene atanmadı.")
		return

	var target_parent: Node2D = projectile_parent
	if target_parent == null:
		target_parent = get_tree().current_scene as Node2D
	if target_parent == null:
		push_error("Merminin ekleneceği bir Node2D bulunamadı.")
		return
	if target_parent is ProjectilePool:
		(target_parent as ProjectilePool).acquire_projectile(
			muzzle.global_position, muzzle.global_rotation,
			Vector2.RIGHT.rotated(muzzle.global_rotation), damage,
			float(projectile_speed), wielder, self
		)
		return

	var instance: Node = projectile_scene.instantiate()
	if not instance is RobotProjectile:
		push_error("Plasma Peashooter yalnızca RobotProjectile kullanan bir sahne ateşleyebilir.")
		instance.free()
		return
	var projectile: RobotProjectile = instance as RobotProjectile

	# Mermiyi silahın altına değil dünya katmanına ekliyoruz; böylece oyuncuyla
	# birlikte dönmez ve namludan çıktığı dünya yönünde ilerlemeye devam eder.
	target_parent.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.global_rotation = muzzle.global_rotation
	projectile.launch(
		Vector2.RIGHT.rotated(muzzle.global_rotation),
		damage,
		float(projectile_speed),
		wielder,
		self
	)
