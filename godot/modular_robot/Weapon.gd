class_name Weapon
extends Node2D

signal fired(weapon: Weapon)
signal damage_dealt(amount: int)

@export_group("Weapon Data")
@export var weapon_id: String = "weapon_base"
@export_enum("projectile_single", "projectile_spread", "beam", "orbit") var weapon_type: String = "projectile_single"
@export_range(0.02, 10.0, 0.01, "or_greater") var fire_rate: float = 0.4
@export_range(0, 100000, 1, "or_greater") var damage: int = 10
@export_range(1, 5000, 1, "or_greater") var projectile_speed: int = 400
@export_range(0.0, 1.0, 0.01) var accuracy: float = 1.0
@export_range(1, 64, 1) var projectile_count: int = 1
@export_range(0.0, 10.0, 0.01) var tick_rate: float = 0.0
@export_range(0.0, 10.0, 0.01) var charge_time: float = 0.0

var slot_index: int = 0
var display_name: String = "Weapon"
var rarity: String = "common"
var icon_code: String = "W"
var projectile_color: Color = Color("8fe3ff")
var atlas_index: int = 0

@onready var fire_cooldown: Timer = get_node_or_null("FireCooldown") as Timer

var projectile_parent: Node2D
var wielder: Node2D

# Bu değerler yalnızca mevcut koşuya aittir. Kalıcı silah verisi ve
# leaderboard tabanı değişmeden kalır.
var run_damage_multiplier: float = 1.0
var run_cooldown_multiplier: float = 1.0
var run_bonus_projectiles: int = 0
var run_critical_chance: float = 0.0
var run_critical_multiplier: float = 1.5


func _ready() -> void:
	# Silah sahnesine Timer eklenmemişse sınıf kendi Timer'ını oluşturur.
	if fire_cooldown == null:
		fire_cooldown = Timer.new()
		fire_cooldown.name = "FireCooldown"
		add_child(fire_cooldown)
	fire_cooldown.one_shot = true
	fire_cooldown.wait_time = maxf(0.02, fire_rate)


func configure_runtime(new_projectile_parent: Node2D, new_wielder: Node2D) -> void:
	projectile_parent = new_projectile_parent
	wielder = new_wielder


func apply_definition(definition: Dictionary) -> void:
	weapon_id = String(definition.get("weapon_id", definition.get("weaponId", weapon_id)))
	display_name = String(definition.get("display_name", weapon_id))
	weapon_type = String(definition.get("type", weapon_type))
	# Render Beam gibi sürekli silahlarda tick_rate aynı zamanda cooldown aralığıdır.
	tick_rate = float(definition.get("tick_rate", definition.get("tickRate", 0.0)))
	charge_time = float(definition.get("charge_time", definition.get("chargeTime", 0.0)))
	fire_rate = float(definition.get("fire_rate", definition.get("fireRate", tick_rate if tick_rate > 0.0 else charge_time if charge_time > 0.0 else fire_rate)))
	damage = int(definition.get("damage", damage))
	projectile_speed = int(definition.get("projectile_speed", definition.get("projectileSpeed", projectile_speed)))
	accuracy = float(definition.get("accuracy", accuracy))
	projectile_count = int(definition.get("projectiles", definition.get("projectile_count", projectile_count)))
	slot_index = int(definition.get("slot", slot_index))
	rarity = String(definition.get("rarity", rarity))
	icon_code = String(definition.get("icon", icon_code))
	atlas_index = int(definition.get("atlas_index", atlas_index))
	var color_value: Variant = definition.get("projectile_color", null)
	if color_value != null:
		projectile_color = Color(String(color_value))
	if fire_cooldown != null:
		fire_cooldown.wait_time = maxf(0.02, fire_rate)


func can_shoot() -> bool:
	return fire_cooldown != null and fire_cooldown.is_stopped()


func shoot() -> bool:
	if not can_shoot():
		return false
	fire_cooldown.start(maxf(0.02, fire_rate * run_cooldown_multiplier))
	_perform_shot()
	fired.emit(self)
	return true


func apply_run_modifiers(modifiers: Dictionary) -> void:
	run_damage_multiplier = maxf(0.0, float(modifiers.get("damage_multiplier", 1.0)))
	run_cooldown_multiplier = clampf(float(modifiers.get("cooldown_multiplier", 1.0)), 0.20, 4.0)
	run_bonus_projectiles = maxi(0, int(modifiers.get("bonus_projectiles", 0)))
	run_critical_chance = clampf(float(modifiers.get("critical_chance", 0.0)), 0.0, 1.0)
	run_critical_multiplier = maxf(1.0, float(modifiers.get("critical_multiplier", 1.5)))


func report_damage_dealt(amount: int) -> void:
	if amount > 0:
		damage_dealt.emit(amount)


func _perform_shot() -> void:
	# Alt silah sınıfları gerçek ateş davranışını burada uygular.
	pass
