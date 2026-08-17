class_name ModularRobotPlayer
extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal panic_mode_changed(active: bool)
signal dash_state_changed(cooldown_remaining: float, ready: bool)
signal died

const PLAYER_WALK_ATLAS: Texture2D = preload("res://assets/generated/player_walk_atlas_v4_silver.png")
const PLAYER_FRAME_SIZE: Vector2 = Vector2(362.0, 724.0)

@export_group("T.V.-80 Stats")
@export_range(1, 10000, 1) var max_health: int = 120
@export_range(50.0, 1000.0, 5.0) var normal_speed: float = 240.0

@export_group("Emotional Operating System")
@export_range(0.0, 2.0, 0.05) var panic_speed_bonus: float = 0.30
@export_range(0.1, 20.0, 0.1) var panic_duration: float = 3.0

@export_group("Combat")
@export var auto_fire: bool = true
@export_range(0.1, 2.0, 0.05) var damage_invulnerability: float = 0.65
@export_range(300.0, 1200.0, 10.0) var dash_speed: float = 760.0
@export_range(0.08, 0.5, 0.01) var dash_duration: float = 0.18
@export_range(0.5, 8.0, 0.1) var dash_cooldown: float = 2.4
@export_node_path("Node2D") var projectile_container_path: NodePath
@export var randomize_loadout: bool = false

@export_group("Arena Bounds")
@export var keep_inside_arena: bool = true
@export var arena_size: Vector2 = Vector2(3400.0, 1900.0)
@export_range(0.0, 200.0, 1.0) var arena_margin: float = 28.0

signal loadout_ready(loadout: Dictionary)

@onready var aim_pivot: Node2D = $AimPivot
@onready var hardpoints: Node2D = $AimPivot/Hardpoints
@onready var animated_sprite: AnimatedSprite2D = $AimPivot/TupKafaSprite
@onready var panic_timer: Timer = $PanicTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var weapon_manager: WeaponManager = $WeaponManager

var current_health: int = 120
var current_speed: float = 240.0
var panic_mode: bool = false
var dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var run_speed_multiplier: float = 1.0
var damage_invulnerability_remaining: float = 0.0
var dash_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var dash_input_held: bool = false
var base_max_health: int = 120
var run_damage_reduction: float = 0.0
var run_dash_cooldown_multiplier: float = 1.0
var run_wave_repair: int = 8
var _idle_time: float = 0.0


func _ready() -> void:
	base_max_health = max_health
	current_health = max_health
	_recalculate_current_speed()
	panic_timer.wait_time = panic_duration
	panic_timer.timeout.connect(_exit_panic_mode)
	_setup_marine_animation()
	weapon_manager.initialize(self, hardpoints, _get_projectile_parent())
	weapon_manager.slot_changed.connect(_on_weapon_slot_changed)
	var loadout: Dictionary = weapon_manager.roll_random_loadout() if randomize_loadout else {
		WeaponManager.WeaponSlot.MAIN: "w_ion_carbine",
	}
	for slot: int in loadout.keys():
		weapon_manager.equip_weapon(slot, String(loadout[slot]))
	health_changed.emit(current_health, max_health)
	loadout_ready.emit(weapon_manager.get_inventory_snapshot())


func _on_weapon_slot_changed(_slot: int, _weapon_id: String) -> void:
	loadout_ready.emit(weapon_manager.get_inventory_snapshot())


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	damage_invulnerability_remaining = maxf(0.0, damage_invulnerability_remaining - delta)
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	dash_remaining = maxf(0.0, dash_remaining - delta)
	_update_damage_flash()
	_update_movement(delta)
	_update_aim()
	if auto_fire:
		weapon_manager.shoot_all()
	dash_state_changed.emit(dash_cooldown_remaining, dash_cooldown_remaining <= 0.0)


func _update_movement(delta: float) -> void:
	var horizontal: float = 0.0
	var vertical: float = 0.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): horizontal += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): horizontal -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): vertical += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): vertical -= 1.0
	var input_direction: Vector2 = Vector2(horizontal, vertical)
	if input_direction.length_squared() > 1.0:
		input_direction = input_direction.normalized()
	var dash_pressed: bool = Input.is_key_pressed(KEY_SPACE)
	if dash_pressed and not dash_input_held and dash_cooldown_remaining <= 0.0 and input_direction.length_squared() > 0.01:
		_start_dash(input_direction)
	dash_input_held = dash_pressed
	if dash_remaining > 0.0:
		velocity = dash_direction * dash_speed + knockback_velocity
		animated_sprite.speed_scale = 1.8
		if not animated_sprite.is_playing(): animated_sprite.play(&"run")
	else:
		velocity = input_direction * current_speed + knockback_velocity
		animated_sprite.speed_scale = 1.0
		if input_direction.length_squared() > 0.01:
			if not animated_sprite.is_playing(): animated_sprite.play(&"run")
			animated_sprite.scale = Vector2.ONE * 0.115
		else:
			animated_sprite.pause()
			_idle_time += delta
			var breathe: float = sin(_idle_time * 2.2) * 0.006
			animated_sprite.scale = Vector2(0.115, 0.115 + breathe)
	move_and_slide()
	if keep_inside_arena:
		global_position.x = clampf(global_position.x, arena_margin, arena_size.x - arena_margin)
		global_position.y = clampf(global_position.y, arena_margin, arena_size.y - arena_margin)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 920.0 * delta)


func _update_aim() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()
	if mouse_position.distance_squared_to(global_position) <= 0.001:
		return
	# Görsel ve dört silah noktası hedefe döner. Sol tarafa bakarken dikey çevirme,
	# yan görünüm animasyonunun baş aşağı kalmasını engeller.
	var aim_angle: float = (mouse_position - global_position).angle()
	aim_pivot.rotation = aim_angle
	animated_sprite.flip_v = absf(aim_angle) > PI * 0.5


func take_damage(amount: int) -> void:
	if dead or amount <= 0 or damage_invulnerability_remaining > 0.0 or dash_remaining > 0.0:
		return
	var resolved_damage: int = maxi(1, ceili(float(amount) * (1.0 - run_damage_reduction)))
	current_health = maxi(0, current_health - resolved_damage)
	damage_invulnerability_remaining = damage_invulnerability
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		_die()
		return
	_enter_panic_mode()


func heal(amount: int) -> void:
	if dead or amount <= 0:
		return
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func apply_knockback(impulse: Vector2) -> void:
	if dead:
		return
	knockback_velocity += impulse.limit_length(680.0)


func _enter_panic_mode() -> void:
	panic_mode = true
	_recalculate_current_speed()
	panic_timer.start(panic_duration)
	animated_sprite.play(&"run")
	panic_mode_changed.emit(true)


func _exit_panic_mode() -> void:
	if dead:
		return
	panic_mode = false
	_recalculate_current_speed()
	animated_sprite.play(&"run")
	panic_mode_changed.emit(false)


func _die() -> void:
	dead = true
	panic_mode = false
	current_speed = 0.0
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	panic_timer.stop()
	auto_fire = false
	animated_sprite.stop()
	animated_sprite.modulate = Color(0.28, 0.34, 0.42, 0.78)
	collision_shape.set_deferred("disabled", true)
	panic_mode_changed.emit(false)
	died.emit()


func equip_weapon(slot: int, weapon_id: String) -> Weapon:
	return weapon_manager.equip_weapon(slot, weapon_id)


func unequip_weapon(slot: int) -> void:
	weapon_manager.unequip_slot(slot)


func get_weapon_inventory() -> Dictionary:
	return weapon_manager.get_inventory_snapshot()


func shoot_all_weapons() -> void:
	if not dead:
		weapon_manager.shoot_all()


func set_run_speed_multiplier(value: float) -> void:
	run_speed_multiplier = clampf(value, 0.25, 4.0)
	_recalculate_current_speed()


func set_run_survivability(max_health_bonus: int, damage_reduction: float, dash_cooldown_multiplier: float, wave_repair: int) -> void:
	var previous_maximum: int = max_health
	max_health = maxi(1, base_max_health + maxi(0, max_health_bonus))
	if max_health > previous_maximum:
		current_health = mini(max_health, current_health + max_health - previous_maximum)
	else:
		current_health = mini(current_health, max_health)
	run_damage_reduction = clampf(damage_reduction, 0.0, 0.55)
	run_dash_cooldown_multiplier = clampf(dash_cooldown_multiplier, 0.35, 1.0)
	run_wave_repair = maxi(0, wave_repair)
	health_changed.emit(current_health, max_health)


func get_dash_cooldown_ratio() -> float:
	var total: float = maxf(0.01, dash_cooldown * run_dash_cooldown_multiplier)
	return clampf(1.0 - dash_cooldown_remaining / total, 0.0, 1.0)


func is_dash_ready() -> bool:
	return dash_cooldown_remaining <= 0.0


func get_wave_repair_amount() -> int:
	return run_wave_repair


func _recalculate_current_speed() -> void:
	if dead:
		current_speed = 0.0
		return
	var panic_multiplier: float = 1.0 + panic_speed_bonus if panic_mode else 1.0
	current_speed = normal_speed * run_speed_multiplier * panic_multiplier


func _start_dash(input_direction: Vector2) -> void:
	dash_direction = input_direction.normalized()
	dash_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown * run_dash_cooldown_multiplier
	damage_invulnerability_remaining = maxf(damage_invulnerability_remaining, dash_duration + 0.12)
	knockback_velocity = Vector2.ZERO


func _update_damage_flash() -> void:
	if damage_invulnerability_remaining <= 0.0:
		aim_pivot.modulate = Color.WHITE
		return
	var pulse: bool = int(damage_invulnerability_remaining * 18.0) % 2 == 0
	aim_pivot.modulate = Color(1.45, 0.62, 0.68, 0.48) if pulse else Color.WHITE


func _setup_marine_animation() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"run")
	frames.set_animation_loop(&"run", true)
	frames.set_animation_speed(&"run", 11.0)
	for frame_index: int in range(6):
		var atlas_frame: AtlasTexture = AtlasTexture.new()
		atlas_frame.atlas = PLAYER_WALK_ATLAS
		atlas_frame.region = Rect2(Vector2(PLAYER_FRAME_SIZE.x * float(frame_index), 0.0), PLAYER_FRAME_SIZE)
		frames.add_frame(&"run", atlas_frame)
	animated_sprite.sprite_frames = frames
	animated_sprite.scale = Vector2.ONE * 0.115
	animated_sprite.position = Vector2(-2.0, -12.0)
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	animated_sprite.play(&"run")


func set_projectile_parent(new_parent: Node2D) -> void:
	weapon_manager.projectile_parent = new_parent
	for slot: int in range(WeaponManager.WeaponSlot.MAIN, WeaponManager.WeaponSlot.HEAVY + 1):
		var weapon: Weapon = weapon_manager.get_weapon(slot)
		if is_instance_valid(weapon):
			weapon.configure_runtime(new_parent, self)


func _get_projectile_parent() -> Node2D:
	if not projectile_container_path.is_empty():
		var configured_parent: Node2D = get_node_or_null(projectile_container_path) as Node2D
		if configured_parent != null:
			return configured_parent
	return get_tree().current_scene as Node2D
