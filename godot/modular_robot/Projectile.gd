class_name RobotProjectile
extends Area2D

signal hit_target(target: Node, hit_damage: int)
signal recycle_requested(projectile: RobotProjectile)

@export_range(0.1, 10.0, 0.1, "or_greater") var lifetime: float = 2.5

var direction: Vector2 = Vector2.RIGHT
var base_direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var hit_damage: int = 10
var source: Node2D
var remaining_lifetime: float = 2.5
var launched: bool = false
var damage_reporter: Weapon
var projectile_profile: String = "default"
var age: float = 0.0
var pierces_remaining: int = 0
var pulse_cooldown: float = 0.0
var hit_targets: Dictionary = {}
var visual_color: Color = Color("8fe3ff")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var glow: Polygon2D = $Glow
@onready var core: Polygon2D = $Core
@onready var highlight: Line2D = $Highlight


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	deactivate()


func launch(new_direction: Vector2, new_damage: int, new_speed: float, new_source: Node2D, reporter: Weapon = null) -> void:
	direction = new_direction.normalized()
	base_direction = direction
	hit_damage = new_damage
	speed = new_speed
	source = new_source
	damage_reporter = reporter
	projectile_profile = reporter.weapon_id if is_instance_valid(reporter) else "default"
	visual_color = reporter.projectile_color if is_instance_valid(reporter) else Color.WHITE
	age = 0.0
	pulse_cooldown = 0.0
	hit_targets.clear()
	remaining_lifetime = _profile_lifetime()
	launched = true
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = direction.angle()
	_configure_profile()
	monitoring = true
	collision_shape.set_deferred("disabled", false)
	set_physics_process(true)


func deactivate() -> void:
	launched = false
	visible = false
	monitoring = false
	set_physics_process(false)
	damage_reporter = null
	hit_targets.clear()
	if collision_shape != null:
		collision_shape.scale = Vector2.ONE
		collision_shape.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	if not launched:
		return
	age += delta
	pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
	_update_profile_motion(delta)
	if not launched:
		return
	global_position += direction * speed * delta
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		if projectile_profile == "w_gravity_mine":
			_explode_aoe(112.0, 1.0, 0.0)
		_finish()


func _update_profile_motion(delta: float) -> void:
	match projectile_profile:
		"w_pulse_smg":
			direction = base_direction.rotated(sin(age * 26.0) * 0.025)
			rotation = direction.angle()
		"w_plasma_puddle":
			if age >= 0.42:
				speed = 0.0
				rotation += delta * 0.7
				var calm_pulse: float = 1.0 + sin(age * 4.0) * 0.08
				scale = Vector2.ONE * calm_pulse
				if pulse_cooldown <= 0.0:
					pulse_cooldown = 0.34
					_damage_enemies_in_radius(92.0, 1.0)
		"w_tesla_arc":
			_steer_toward_nearest(delta, 3.2, 520.0)
		"w_boomerang_blade":
			core.rotation += delta * 11.0
			glow.rotation = core.rotation
			if age >= 0.58 and is_instance_valid(source):
				direction = (source.global_position - global_position).normalized()
				if global_position.distance_squared_to(source.global_position) <= 30.0 * 30.0:
					_finish()
		"w_gravity_mine":
			core.rotation += delta * 2.2
			if age >= 0.30:
				speed = 0.0
				var target: Node2D = _nearest_enemy(112.0)
				if target != null:
					_explode_aoe(112.0, 1.0, 0.0)
					_finish()
		"w_hunter_drones":
			_steer_toward_nearest(delta, 7.2, 780.0)
			core.position.y = sin(age * 12.0) * 1.5
		"w_singularity_launcher":
			_steer_toward_nearest(delta, 1.6, 460.0)
			var gravity_pulse: float = 1.0 + sin(age * 7.0) * 0.10
			glow.scale = Vector2.ONE * gravity_pulse
		"w_sonic_repulsor":
			var wave_scale: float = 0.88 + minf(age, 0.8) * 0.55
			scale = Vector2.ONE * wave_scale
		"w_railgun_overcharge":
			glow.modulate.a = 0.14 + sin(age * 35.0) * 0.04


func _steer_toward_nearest(delta: float, strength: float, max_distance: float) -> void:
	var target: Node2D = _nearest_enemy(max_distance)
	if target == null:
		return
	var desired: Vector2 = (target.global_position - global_position).normalized()
	direction = direction.slerp(desired, clampf(strength * delta, 0.0, 1.0)).normalized()
	rotation = direction.angle()


func _nearest_enemy(max_distance: float) -> Node2D:
	var nearest: Node2D
	var nearest_distance_squared: float = max_distance * max_distance
	for candidate: Node in get_tree().get_nodes_in_group("active_enemies"):
		if not candidate is Node2D or not bool(candidate.get("active")):
			continue
		var candidate_2d: Node2D = candidate as Node2D
		var distance_squared: float = global_position.distance_squared_to(candidate_2d.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest = candidate_2d
	return nearest


func _on_body_entered(body: Node) -> void:
	_resolve_hit(body)


func _on_area_entered(area: Area2D) -> void:
	_resolve_hit(area)


func _resolve_hit(target: Node) -> void:
	if target == source or (source != null and source.is_ancestor_of(target)):
		return
	if projectile_profile == "w_plasma_puddle":
		return
	if not target.has_method("take_damage"):
		return
	var target_id: int = target.get_instance_id()
	if hit_targets.has(target_id):
		return
	hit_targets[target_id] = true

	match projectile_profile:
		"w_tesla_arc":
			_damage_target(target, 1.0)
			_chain_from(target, 2, 185.0)
			_finish()
		"w_gravity_mine":
			if age >= 0.30:
				_explode_aoe(112.0, 1.0, 0.0)
				_finish()
		"w_singularity_launcher":
			_explode_aoe(148.0, 1.0, 68.0)
			_finish()
		_:
			_damage_target(target, 1.0)
			if projectile_profile == "w_sonic_repulsor":
				_push_target(target, 62.0)
			if projectile_profile == "w_boomerang_blade":
				return
			_continue_or_finish()


func _continue_or_finish() -> void:
	if pierces_remaining > 0:
		pierces_remaining -= 1
		return
	_finish()


func _damage_target(target: Node, damage_scale: float) -> void:
	var applied_damage: int = maxi(1, roundi(float(hit_damage) * damage_scale))
	target.call("take_damage", applied_damage)
	if is_instance_valid(damage_reporter):
		damage_reporter.report_damage_dealt(applied_damage)
	hit_target.emit(target, applied_damage)


func _damage_enemies_in_radius(radius: float, damage_scale: float) -> void:
	var radius_squared: float = radius * radius
	for candidate: Node in get_tree().get_nodes_in_group("active_enemies"):
		if not candidate is Node2D or not bool(candidate.get("active")):
			continue
		var enemy: Node2D = candidate as Node2D
		if global_position.distance_squared_to(enemy.global_position) <= radius_squared:
			_damage_target(enemy, damage_scale)


func _explode_aoe(radius: float, damage_scale: float, pull_distance: float) -> void:
	var radius_squared: float = radius * radius
	for candidate: Node in get_tree().get_nodes_in_group("active_enemies"):
		if not candidate is Node2D or not bool(candidate.get("active")):
			continue
		var enemy: Node2D = candidate as Node2D
		if global_position.distance_squared_to(enemy.global_position) > radius_squared:
			continue
		_damage_target(enemy, damage_scale)
		if pull_distance > 0.0 and is_instance_valid(enemy):
			var pull_direction: Vector2 = (global_position - enemy.global_position).normalized()
			enemy.global_position += pull_direction * minf(pull_distance, enemy.global_position.distance_to(global_position) * 0.45)


func _chain_from(primary_target: Node, chain_count: int, chain_range: float) -> void:
	var current_position: Vector2 = (primary_target as Node2D).global_position if primary_target is Node2D else global_position
	for chain_index: int in range(chain_count):
		var next_target: Node2D
		var nearest_distance_squared: float = chain_range * chain_range
		for candidate: Node in get_tree().get_nodes_in_group("active_enemies"):
			if not candidate is Node2D or not bool(candidate.get("active")) or hit_targets.has(candidate.get_instance_id()):
				continue
			var enemy: Node2D = candidate as Node2D
			var distance_squared: float = current_position.distance_squared_to(enemy.global_position)
			if distance_squared < nearest_distance_squared:
				nearest_distance_squared = distance_squared
				next_target = enemy
		if next_target == null:
			break
		hit_targets[next_target.get_instance_id()] = true
		_draw_chain(current_position, next_target.global_position)
		_damage_target(next_target, 0.72 - float(chain_index) * 0.18)
		current_position = next_target.global_position


func _push_target(target: Node, distance: float) -> void:
	if not target is Node2D:
		return
	var target_2d: Node2D = target as Node2D
	var push_direction: Vector2 = (target_2d.global_position - global_position).normalized()
	target_2d.global_position += push_direction * distance


func _draw_chain(from: Vector2, to: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.top_level = true
	line.z_index = 28
	line.width = 2.2
	line.antialiased = true
	line.default_color = Color(visual_color, 0.58)
	line.points = PackedVector2Array([from, (from + to) * 0.5 + Vector2(0.0, -8.0), to])
	get_tree().current_scene.add_child(line)
	var fade: Tween = line.create_tween()
	fade.tween_property(line, "modulate:a", 0.0, 0.16)
	fade.finished.connect(line.queue_free)


func _profile_lifetime() -> float:
	match projectile_profile:
		"w_photon_beam": return 0.72
		"w_scatter_flak": return 0.82
		"w_plasma_puddle": return 2.65
		"w_boomerang_blade": return 1.45
		"w_gravity_mine": return 3.0
		"w_hunter_drones": return 2.8
		"w_sonic_repulsor": return 1.25
		"w_railgun_overcharge": return 1.15
		_: return lifetime


func _configure_profile() -> void:
	core.position = Vector2.ZERO
	core.rotation = 0.0
	glow.position = Vector2.ZERO
	glow.rotation = 0.0
	glow.scale = Vector2.ONE
	glow.modulate = Color.WHITE
	highlight.position = Vector2.ZERO
	highlight.rotation = 0.0
	highlight.visible = true
	core.color = visual_color
	glow.color = Color(visual_color, 0.18)
	highlight.default_color = Color(visual_color.lightened(0.42), 0.72)
	pierces_remaining = 0
	collision_shape.scale = Vector2.ONE

	match projectile_profile:
		"w_ion_carbine":
			_set_shape(PackedVector2Array([Vector2(-9, -3), Vector2(7, -3), Vector2(12, 0), Vector2(7, 3), Vector2(-9, 3)]), Vector2(1.4, 1.2))
			pierces_remaining = 1
		"w_pulse_smg":
			_set_shape(PackedVector2Array([Vector2(-5, 0), Vector2(0, -3), Vector2(6, 0), Vector2(0, 3)]), Vector2(0.75, 0.75))
		"w_photon_beam":
			_set_shape(PackedVector2Array([Vector2(-23, -1.5), Vector2(23, -1.5), Vector2(23, 1.5), Vector2(-23, 1.5)]), Vector2(2.5, 0.65))
			pierces_remaining = 3
		"w_scatter_flak":
			_set_shape(PackedVector2Array([Vector2(-7, -4), Vector2(8, 0), Vector2(-7, 4), Vector2(-3, 0)]), Vector2(0.9, 0.8))
		"w_plasma_puddle":
			_set_shape(_regular_polygon(9.0, 10), Vector2(1.6, 1.6))
			glow.polygon = _regular_polygon(15.0, 12)
		"w_tesla_arc":
			_set_shape(PackedVector2Array([Vector2(-10, -2), Vector2(-3, -5), Vector2(-1, -1), Vector2(7, -4), Vector2(3, 1), Vector2(10, 3), Vector2(1, 5), Vector2(-2, 2)]), Vector2(1.1, 0.9))
		"w_boomerang_blade":
			_set_shape(PackedVector2Array([Vector2(-10, -7), Vector2(-2, 0), Vector2(-10, 7), Vector2(-4, 9), Vector2(6, 0), Vector2(-4, -9)]), Vector2(1.3, 1.3))
		"w_gravity_mine":
			_set_shape(PackedVector2Array([Vector2(-9, 0), Vector2(0, -9), Vector2(9, 0), Vector2(0, 9)]), Vector2(1.55, 1.55))
			glow.polygon = _regular_polygon(16.0, 12)
		"w_hunter_drones":
			_set_shape(PackedVector2Array([Vector2(-10, -6), Vector2(10, 0), Vector2(-10, 6), Vector2(-5, 0)]), Vector2(1.15, 0.9))
		"w_singularity_launcher":
			_set_shape(_regular_polygon(8.0, 12), Vector2(1.45, 1.45))
			core.color = Color("25143f")
			glow.polygon = _regular_polygon(17.0, 14)
		"w_sonic_repulsor":
			_set_shape(PackedVector2Array([Vector2(-11, -13), Vector2(-4, -8), Vector2(2, 0), Vector2(-4, 8), Vector2(-11, 13), Vector2(-7, 0)]), Vector2(1.3, 1.6))
			core.color = Color(visual_color, 0.55)
			pierces_remaining = 7
		"w_railgun_overcharge":
			_set_shape(PackedVector2Array([Vector2(-30, -3), Vector2(22, -3), Vector2(32, 0), Vector2(22, 3), Vector2(-30, 3)]), Vector2(3.4, 0.8))
			pierces_remaining = 8
		_:
			_set_shape(PackedVector2Array([Vector2(-9, -3), Vector2(9, -3), Vector2(13, 0), Vector2(9, 3), Vector2(-9, 3)]), Vector2.ONE)


func _set_shape(points: PackedVector2Array, collision_scale: Vector2) -> void:
	core.polygon = points
	glow.polygon = _expanded_polygon(points, 1.45)
	highlight.points = PackedVector2Array([Vector2(-4.0, -1.0), Vector2(7.0, -1.0)])
	collision_shape.scale = collision_scale


func _expanded_polygon(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var expanded: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		expanded.append(point * factor)
	return expanded


func _regular_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(sides):
		points.append(Vector2.RIGHT.rotated(TAU * float(index) / float(sides)) * radius)
	return points


func _finish() -> void:
	if not launched:
		return
	launched = false
	visible = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	recycle_requested.emit(self)
