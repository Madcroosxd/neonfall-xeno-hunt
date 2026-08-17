class_name PooledEnemy
extends CharacterBody2D

signal defeated(enemy: PooledEnemy)
signal health_changed(enemy: PooledEnemy, current_health: float, max_health: float)
signal ranged_attack_requested(from: Vector2, to: Vector2, attack_type: String, damage: int)
signal summon_requested(enemy_type: String, spawn_position: Vector2)

const ALIEN_ATLAS: Texture2D = preload("res://assets/generated/alien_atlas_v3.png")
const BOSS_ATLAS: Texture2D = preload("res://assets/generated/boss_atlas_v2.png")
const ALIEN_FRAME_SIZE: Vector2 = Vector2(543.0, 724.0)
const BOSS_FRAME_SIZE: Vector2 = Vector2(724.0, 724.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var body: Polygon2D = $Visual/Body
@onready var face_label: Label = $Visual/Face

var enemy_type: String = "blobby"
var display_name: String = "Blobby"
var max_health: float = 20.0
var health: float = 20.0
var move_speed: float = 160.0
var contact_damage: int = 10
var knockback_strength: float = 0.0
var ranged_damage: int = 0
var exp_value: int = 1
var target_player: ModularRobotPlayer
var active: bool = false
var is_boss: bool = false
var phase: float = 0.0
var attack_cooldown: float = 0.0
var contact_cooldown: float = 0.0
var base_visual_scale: float = 1.0
var collision_radius: float = 18.0
var atlas_sprite: Sprite2D
var hit_flash_timer: float = 0.0


func _ready() -> void:
	_setup_atlas_sprite()
	deactivate()


func activate(definition: Dictionary, player: ModularRobotPlayer, spawn_position: Vector2) -> void:
	enemy_type = String(definition.get("enemy_type", "blobby"))
	display_name = String(definition.get("display_name", enemy_type))
	max_health = float(definition.get("health", 20.0))
	health = max_health
	move_speed = float(definition.get("speed", 160.0))
	contact_damage = int(definition.get("contact_damage", 0))
	knockback_strength = float(definition.get("knockback", 0.0))
	ranged_damage = int(definition.get("ranged_damage", 0))
	exp_value = maxi(1, int(definition.get("exp_value", 1)))
	is_boss = bool(definition.get("is_boss", false))
	target_player = player
	global_position = spawn_position
	phase = randf_range(0.0, TAU)
	attack_cooldown = randf_range(0.4, 1.2)
	contact_cooldown = 0.0
	active = true
	add_to_group("active_enemies")
	visible = true
	set_physics_process(true)
	collision_shape.set_deferred("disabled", false)
	base_visual_scale = 1.0
	visual.scale = Vector2.ONE
	visual.position = Vector2.ZERO
	var color_value: Variant = definition.get("color", "a75cff")
	body.color = color_value as Color if color_value is Color else Color(String(color_value))
	face_label.text = String(definition.get("face", "•ᴗ•"))
	collision_radius = float(definition.get("radius", 18.0))
	collision_shape.scale = Vector2.ONE * (collision_radius / 20.0)
	_configure_atlas_visual()
	hit_flash_timer = 0.0
	health_changed.emit(self, health, max_health)


func deactivate() -> void:
	active = false
	remove_from_group("active_enemies")
	visible = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)


func take_damage(amount: int) -> void:
	if not active or amount <= 0:
		return
	health = maxf(0.0, health - float(amount))
	hit_flash_timer = 0.10
	visual.modulate = Color(1.8, 1.8, 1.8, 1.0)
	health_changed.emit(self, health, max_health)
	if health <= 0.0:
		active = false
		set_physics_process(false)
		collision_shape.set_deferred("disabled", true)
		defeated.emit(self)


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target_player) or target_player.dead:
		return
	phase += delta
	attack_cooldown -= delta
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
	if hit_flash_timer <= 0.0:
		visual.modulate = Color.WHITE

	var to_player: Vector2 = target_player.global_position - global_position
	var distance: float = to_player.length()
	var direction: Vector2 = to_player.normalized() if distance > 0.001 else Vector2.ZERO
	var movement: Vector2 = direction
	var actual_speed: float = move_speed

	match enemy_type:
		"blobby":
			var bounce: float = sin(phase * 9.0)
			visual.scale = Vector2(1.0 + bounce * 0.08, 1.0 - bounce * 0.08) * base_visual_scale
			visual.position.y = -absf(sin(phase * 7.5)) * 7.0
		"ufo_head":
			var tangent: Vector2 = direction.orthogonal()
			movement = (direction * 0.90 + tangent * 0.28).normalized()
			visual.rotation += delta * 4.8
		"laser_lemon":
			if distance < 330.0:
				actual_speed *= 1.42
				visual.scale = Vector2.ONE * base_visual_scale * 1.08
			else:
				visual.scale = Vector2.ONE * base_visual_scale
		"space_donkey":
			movement = direction
		"mega_monitor":
			movement = direction
			if distance < 285.0:
				actual_speed *= 0.72
			_try_mega_monitor_attack(distance)
		"mixtape_mech":
			movement = (direction + direction.orthogonal() * sin(phase * 1.5) * 0.32).normalized()
			_try_mixtape_attack(distance, direction)
		"mother_disk":
			movement = (direction * 0.88 + direction.orthogonal() * sin(phase * 1.2) * 0.24).normalized()
			_try_mother_disk_summon()

	velocity = movement * actual_speed
	# CharacterBody2D mermi çarpışmaları için korunur; yüzlerce move_and_slide()
	# sorgusu açmak yerine sürü hareketi doğrudan ve deterministik güncellenir.
	global_position += velocity * delta
	_resolve_player_contact(direction)


func _try_mega_monitor_attack(distance: float) -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 2.4
	if distance <= 420.0:
		ranged_attack_requested.emit(global_position, target_player.global_position, "laser_ring", 12)


func _try_mixtape_attack(distance: float, direction: Vector2) -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 2.8
	if distance <= 360.0:
		ranged_attack_requested.emit(global_position, target_player.global_position, "sound_wave", 8)


func _try_mother_disk_summon() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 2.2
	summon_requested.emit("blobby", global_position + Vector2.RIGHT.rotated(randf() * TAU) * 72.0)


func _resolve_player_contact(direction: Vector2) -> void:
	if contact_cooldown > 0.0:
		return
	var combined_radius: float = collision_radius + 25.0
	if global_position.distance_squared_to(target_player.global_position) > combined_radius * combined_radius:
		return
	contact_cooldown = 0.75
	if contact_damage > 0:
		target_player.take_damage(contact_damage)
	if knockback_strength > 0.0:
		target_player.apply_knockback(direction * knockback_strength)


func _setup_atlas_sprite() -> void:
	atlas_sprite = Sprite2D.new()
	atlas_sprite.name = "AtlasSprite"
	atlas_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.add_child(atlas_sprite)
	body.visible = false
	$Visual/Outline.visible = false
	face_label.visible = false


func _configure_atlas_visual() -> void:
	if atlas_sprite == null:
		return
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	var frame_index: int = 0
	var frame_size: Vector2 = ALIEN_FRAME_SIZE
	if is_boss:
		atlas_texture.atlas = BOSS_ATLAS
		frame_size = BOSS_FRAME_SIZE
		match enemy_type:
			"mega_monitor": frame_index = 0
			"mixtape_mech": frame_index = 1
			"mother_disk": frame_index = 2
			_: frame_index = 0
	else:
		atlas_texture.atlas = ALIEN_ATLAS
		match enemy_type:
			"blobby": frame_index = 0
			"ufo_head": frame_index = 1
			"laser_lemon": frame_index = 2
			"space_donkey": frame_index = 3
			_: frame_index = 0
	atlas_texture.region = Rect2(Vector2(frame_size.x * float(frame_index), 0.0), frame_size)
	atlas_sprite.texture = atlas_texture
	var desired_size: float = collision_radius * (2.8 if is_boss else 2.65)
	atlas_sprite.scale = Vector2.ONE * (desired_size / frame_size.y)
	atlas_sprite.position = Vector2(0.0, -collision_radius * 0.18)
	atlas_sprite.modulate = Color.WHITE
