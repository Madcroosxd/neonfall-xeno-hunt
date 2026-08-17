class_name VisualFactory
extends RefCounted

const PLAYER_TEXTURE: Texture2D = preload("res://assets/generated/player_marine_v2.png")
const PLAYER_WALK_ATLAS: Texture2D = preload("res://assets/generated/player_walk_atlas_v3.png")
const ALIEN_ATLAS: Texture2D = preload("res://assets/generated/alien_atlas_v2.png")
const BOSS_ATLAS: Texture2D = preload("res://assets/generated/boss_atlas_v2.png")

static func circle_polygon(center: Vector2, radius: float, points: int) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	for index: int in range(points):
		var angle: float = TAU * float(index) / float(points)
		polygon.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return polygon


static func add_polygon(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon: Polygon2D = Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon


static func add_line(parent: Node, from: Vector2, to: Vector2, width: float, color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = width
	line.default_color = color
	line.antialiased = true
	parent.add_child(line)
	return line


static func add_atlas_sprite(parent: Node, texture: Texture2D, region: Rect2, sprite_scale: float) -> Sprite2D:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Visual"
	sprite.texture = atlas
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.material = create_stylized_material()
	parent.add_child(sprite)
	return sprite


static func create_stylized_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float color_steps = 7.0;
uniform float saturation = 1.22;
uniform vec3 ink_color = vec3(0.025, 0.04, 0.075);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.02) {
		COLOR = vec4(0.0);
	} else {
		float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
		tex.rgb = mix(vec3(luminance), tex.rgb, saturation);
		tex.rgb = floor(tex.rgb * color_steps + 0.5) / color_steps;
		float ink = smoothstep(0.05, 0.34, tex.a) - smoothstep(0.34, 0.62, tex.a);
		tex.rgb = mix(tex.rgb, ink_color, ink * 0.58);
		COLOR = tex;
	}
}
"""
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	return material


static func add_player_walk_animation(parent: Node) -> AnimatedSprite2D:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 10.0)
	for frame_index: int in range(6):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = PLAYER_WALK_ATLAS
		atlas.region = Rect2(float(frame_index * 362), 0.0, 362.0, 724.0)
		frames.add_frame("walk", atlas)
	var animated: AnimatedSprite2D = AnimatedSprite2D.new()
	animated.name = "Visual"
	animated.sprite_frames = frames
	animated.animation = "walk"
	animated.frame = 1
	animated.scale = Vector2.ONE * 0.112
	animated.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	animated.material = create_stylized_material()
	parent.add_child(animated)
	return animated


static func create_motion_rig(root: Node2D, reference_speed: float, radius: float, glow: Color, is_boss: bool = false) -> CharacterMotion:
	var rig: CharacterMotion = CharacterMotion.new()
	rig.name = "MotionRig"
	root.add_child(rig)
	var trail_shape: PackedVector2Array = PackedVector2Array([
		Vector2(-radius * 2.6, -radius * 0.38), Vector2(-radius * 0.4, -radius * 0.18),
		Vector2.ZERO, Vector2(-radius * 0.4, radius * 0.18), Vector2(-radius * 2.6, radius * 0.38)
	])
	var trail: Polygon2D = add_polygon(rig, trail_shape, Color(glow, 0.0))
	trail.name = "Trail"
	var shadow: Polygon2D = add_polygon(rig, circle_polygon(Vector2(0.0, radius * 0.25), radius, 28), Color(0.01, 0.015, 0.035, 0.32))
	shadow.name = "Shadow"
	shadow.scale.y = 0.42
	rig.configure(reference_speed, is_boss)
	return rig


static func create_player() -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "Player"
	var rig: CharacterMotion = create_motion_rig(root, 285.0, 25.0, Color("52dcff"))
	add_polygon(rig, circle_polygon(Vector2.ZERO, 29.0, 28), Color(0.12, 0.75, 1.0, 0.11))
	add_player_walk_animation(rig)
	return root


static func create_enemy(kind: String, elite: bool = false) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "Alien_%s" % kind
	var kinds: Array[String] = ["drone", "spitter", "brute", "stalker"]
	var atlas_index: int = maxi(0, kinds.find(kind))
	var sprite_scale: float = 0.105
	if kind == "brute": sprite_scale = 0.132
	elif kind == "stalker": sprite_scale = 0.115
	var radius: float = 25.0 if kind == "brute" else 19.0
	var glow: Color = [Color("4deaff"), Color("ffb23e"), Color("a968ff"), Color("ff4fbd")][atlas_index]
	var rig: CharacterMotion = create_motion_rig(root, 135.0, radius, glow)
	var sprite: Sprite2D = add_atlas_sprite(rig, ALIEN_ATLAS, Rect2(float(atlas_index * 543), 0.0, 543.0, 724.0), sprite_scale)
	if elite:
		sprite.modulate = Color(1.35, 1.12, 0.58, 1.0)
		add_polygon(rig, circle_polygon(Vector2.ZERO, 31.0, 24), Color(1.0, 0.76, 0.22, 0.16))
	return root


static func create_boss(variant: int) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "Boss_%d" % variant
	var color: Color = [Color("ff466b"), Color("56f5ff"), Color("d477ff")][variant - 1]
	var rig: CharacterMotion = create_motion_rig(root, 78.0, 59.0, color, true)
	add_polygon(rig, circle_polygon(Vector2.ZERO, 66.0, 32), Color(color, 0.11))
	add_atlas_sprite(rig, BOSS_ATLAS, Rect2(float((variant - 1) * 724), 0.0, 724.0, 724.0), 0.18)
	return root


static func create_bullet(color: Color, hostile: bool = false, large: bool = false, kind: String = "") -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "HostileBullet" if hostile else "PlayerBullet"
	if kind == "missile":
		add_polygon(root, PackedVector2Array([Vector2(-25.0, -8.0), Vector2(-8.0, -5.0), Vector2(-4.0, 0.0), Vector2(-8.0, 5.0)]), Color(1.0, 0.28, 0.06, 0.28))
		add_polygon(root, PackedVector2Array([Vector2(-13.0, -7.0), Vector2(11.0, -7.0), Vector2(22.0, 0.0), Vector2(11.0, 7.0), Vector2(-13.0, 7.0)]), Color("26384c"))
		add_polygon(root, PackedVector2Array([Vector2(-11.0, -7.0), Vector2(-19.0, -13.0), Vector2(2.0, -7.0), Vector2(2.0, 7.0), Vector2(-19.0, 13.0), Vector2(-11.0, 7.0)]), Color("ff754f"))
		add_polygon(root, circle_polygon(Vector2(13.0, 0.0), 4.0, 14), Color("fff3c4"))
	elif hostile:
		var orb_radius: float = 9.0 if large else 6.0
		add_polygon(root, PackedVector2Array([Vector2(-25.0 if large else -18.0, -orb_radius * 0.55), Vector2(-2.0, -orb_radius), Vector2(4.0, 0.0), Vector2(-2.0, orb_radius), Vector2(-25.0 if large else -18.0, orb_radius * 0.55)]), Color(color, 0.2))
		add_polygon(root, circle_polygon(Vector2.ZERO, orb_radius + 4.0, 20), Color(color, 0.18))
		add_polygon(root, circle_polygon(Vector2.ZERO, orb_radius, 18), color)
		add_polygon(root, circle_polygon(Vector2(2.0, -1.0), orb_radius * 0.42, 14), Color(1.0, 0.92, 0.82, 0.95))
	else:
		var length: float = 21.0 if large else 15.0
		var width: float = 6.0 if large else 4.0
		add_polygon(root, PackedVector2Array([Vector2(-length * 2.1, -width * 0.75), Vector2(-length * 0.2, -width), Vector2(length, 0.0), Vector2(-length * 0.2, width), Vector2(-length * 2.1, width * 0.75)]), Color(color, 0.2))
		add_polygon(root, PackedVector2Array([Vector2(-length, -width), Vector2(length * 0.72, -width * 0.72), Vector2(length + 7.0, 0.0), Vector2(length * 0.72, width * 0.72), Vector2(-length, width)]), color)
		add_polygon(root, PackedVector2Array([Vector2(-length * 0.45, -width * 0.38), Vector2(length * 0.72, -width * 0.28), Vector2(length + 4.0, 0.0), Vector2(length * 0.72, width * 0.28), Vector2(-length * 0.45, width * 0.38)]), Color(0.92, 1.0, 1.0, 0.96))
		if kind == "nova":
			add_polygon(root, circle_polygon(Vector2.ZERO, 9.0, 18), Color(color, 0.18))
	return root


static func create_muzzle_flash(color: Color) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "MuzzleFlash"
	add_polygon(root, PackedVector2Array([Vector2(-5.0, -5.0), Vector2(24.0, -10.0), Vector2(16.0, 0.0), Vector2(29.0, 0.0), Vector2(15.0, 5.0), Vector2(22.0, 11.0), Vector2(-5.0, 5.0)]), Color(color, 0.62))
	add_polygon(root, PackedVector2Array([Vector2.ZERO, Vector2(18.0, -3.0), Vector2(25.0, 0.0), Vector2(18.0, 3.0)]), Color(1.0, 1.0, 0.92, 1.0))
	return root


static func create_impact(color: Color, critical: bool = false) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "CriticalImpact" if critical else "Impact"
	var rays: int = 10 if critical else 7
	var length: float = 27.0 if critical else 18.0
	for index: int in range(rays):
		var angle: float = TAU * float(index) / float(rays)
		add_line(root, Vector2.RIGHT.rotated(angle) * 4.0, Vector2.RIGHT.rotated(angle) * length, 3.0 if critical else 2.0, color)
	add_polygon(root, circle_polygon(Vector2.ZERO, 8.0 if critical else 5.0, 18), Color(1.0, 1.0, 0.94, 0.95))
	return root


static func create_spawn_telegraph(color: Color, boss_spawn: bool = false) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "BossTelegraph" if boss_spawn else "SpawnTelegraph"
	var radius: float = 72.0 if boss_spawn else 38.0
	for index: int in range(12):
		var angle: float = TAU * float(index) / 12.0
		add_line(root, Vector2.RIGHT.rotated(angle) * radius * 0.62, Vector2.RIGHT.rotated(angle) * radius, 3.0 if boss_spawn else 2.0, color)
	add_polygon(root, circle_polygon(Vector2.ZERO, radius * 0.42, 28), Color(color, 0.12))
	return root


static func create_event_pickup(kind: String) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "MapEvent_%s" % kind
	var color: Color = Color("ff704d") if kind == "blast" else (Color("76d9ff") if kind == "freeze" else Color("ae8cff"))
	add_polygon(root, circle_polygon(Vector2.ZERO, 27.0, 28), Color(0.02, 0.04, 0.09, 0.94))
	add_polygon(root, circle_polygon(Vector2.ZERO, 23.0, 28), Color(color, 0.2))
	for index: int in range(12):
		var angle: float = TAU * float(index) / 12.0
		add_line(root, Vector2.RIGHT.rotated(angle) * 26.0, Vector2.RIGHT.rotated(angle) * 33.0, 2.0, color)
	if kind == "blast":
		add_polygon(root, PackedVector2Array([Vector2(-15.0, -5.0), Vector2(-4.0, -8.0), Vector2(0.0, -19.0), Vector2(5.0, -7.0), Vector2(17.0, -3.0), Vector2(7.0, 4.0), Vector2(3.0, 17.0), Vector2(-5.0, 7.0), Vector2(-17.0, 4.0)]), Color("fff2c2"))
	elif kind == "freeze":
		for index: int in range(6):
			var angle: float = TAU * float(index) / 6.0
			add_line(root, Vector2.ZERO, Vector2.RIGHT.rotated(angle) * 18.0, 3.0, Color("e8fbff"))
	else:
		add_polygon(root, circle_polygon(Vector2.ZERO, 15.0, 24), Color(color, 0.3))
		add_polygon(root, circle_polygon(Vector2.ZERO, 9.0, 20), Color("f4edff"))
	return root


static func create_event_shield() -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "InvincibilityShield"
	add_polygon(root, circle_polygon(Vector2.ZERO, 47.0, 36), Color(0.48, 0.35, 1.0, 0.13))
	for index: int in range(16):
		var angle: float = TAU * float(index) / 16.0
		add_line(root, Vector2.RIGHT.rotated(angle) * 42.0, Vector2.RIGHT.rotated(angle) * 48.0, 2.5, Color(0.72, 0.62, 1.0, 0.86))
	return root


static func create_gem(value: int) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "VoidShard"
	var radius: float = 7.0 + minf(4.0, float(value) * 0.04)
	add_polygon(root, PackedVector2Array([
		Vector2(0.0, -radius), Vector2(radius * 0.75, 0.0), Vector2(0.0, radius), Vector2(-radius * 0.75, 0.0)
	]), Color("4fe9ff"))
	add_polygon(root, circle_polygon(Vector2.ZERO, 3.0, 8), Color("ffffff"))
	return root
