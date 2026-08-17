class_name DatabaseWeapon
extends Weapon

const OUTLINE_RARITY_COLORS: Dictionary = {"common": Color("d9e0eb"), "rare": Color("43c8ff"), "epic": Color("c66cff")}
const SPACE_WEAPON_ATLAS: Texture2D = preload("res://assets/generated/space_weapon_atlas_v1.png")
const ATLAS_COLUMNS: int = 4
const ATLAS_ROWS: int = 3

@export var projectile_scene: PackedScene

@onready var muzzle: Marker2D = $Muzzle
@onready var body: Polygon2D = $Body
@onready var name_label: Label = $Name
@onready var weapon_sprite: Sprite2D = $WeaponSprite


func _ready() -> void:
	super._ready()
	_refresh_placeholder_visual()


func _perform_shot() -> void:
	if projectile_scene == null or muzzle == null:
		return
	var base_shot_total: int = projectile_count if weapon_type == "spread" else 1
	var shot_total: int = base_shot_total + run_bonus_projectiles
	for shot_index: int in range(shot_total):
		var spread: float = 0.0
		if shot_total > 1:
			spread = (float(shot_index) - float(shot_total - 1) * 0.5) * 0.14
		elif accuracy < 1.0:
			spread = randf_range(-(1.0 - accuracy) * 0.22, (1.0 - accuracy) * 0.22)
		var is_critical: bool = randf() < run_critical_chance
		var critical_scale: float = run_critical_multiplier if is_critical else 1.0
		var shot_damage: int = maxi(1, int(round(float(damage) * run_damage_multiplier * critical_scale)))
		_spawn_projectile(spread, shot_damage)


func _spawn_projectile(spread: float, shot_damage: int) -> void:
	var target_parent: Node2D = projectile_parent if projectile_parent != null else get_tree().current_scene as Node2D
	if target_parent == null:
		return
	var shot_rotation: float = muzzle.global_rotation + spread
	var shot_speed: float = float(projectile_speed)
	if target_parent is ProjectilePool:
		(target_parent as ProjectilePool).acquire_projectile(
			muzzle.global_position, shot_rotation, Vector2.RIGHT.rotated(shot_rotation),
			shot_damage, shot_speed, wielder, self
		)
		return
	var instance: Node = projectile_scene.instantiate()
	if not instance is RobotProjectile:
		instance.free()
		return
	var projectile: RobotProjectile = instance as RobotProjectile
	target_parent.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.global_rotation = shot_rotation
	projectile.launch(Vector2.RIGHT.rotated(shot_rotation), shot_damage, shot_speed, wielder, self)


func _refresh_placeholder_visual() -> void:
	if body == null or name_label == null:
		return
	body.color = projectile_color
	name_label.text = icon_code if not icon_code.is_empty() else "W"
	var outline: Line2D = get_node_or_null("Outline") as Line2D
	if outline != null:
		outline.default_color = OUTLINE_RARITY_COLORS.get(rarity, Color("0a0a12"))
	var cell_width: float = float(SPACE_WEAPON_ATLAS.get_width()) / float(ATLAS_COLUMNS)
	var base_cell_height: int = SPACE_WEAPON_ATLAS.get_height() / ATLAS_ROWS
	var column: int = atlas_index % ATLAS_COLUMNS
	var row: int = floori(float(atlas_index) / float(ATLAS_COLUMNS))
	var region_height: int = base_cell_height if row < ATLAS_ROWS - 1 else SPACE_WEAPON_ATLAS.get_height() - base_cell_height * row
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = SPACE_WEAPON_ATLAS
	atlas_texture.region = Rect2(float(column) * cell_width, float(row * base_cell_height), cell_width, float(region_height))
	weapon_sprite.texture = atlas_texture
	weapon_sprite.modulate = Color.WHITE
