class_name CharacterMotion
extends Node2D

var speed_reference: float = 220.0
var boss_motion: bool = false
var phase: float = 0.0
var previous_position: Vector2 = Vector2.ZERO
var smoothed_speed: float = 0.0
var recoil: float = 0.0
var visual: Node2D
var shadow: Polygon2D
var trail: Polygon2D
var animation_direction: int = 1


func configure(reference_speed: float, is_boss: bool = false) -> void:
	speed_reference = reference_speed
	boss_motion = is_boss


func kick(amount: float) -> void:
	recoil = maxf(recoil, amount)


func _ready() -> void:
	var parent_node: Node2D = get_parent() as Node2D
	previous_position = parent_node.global_position
	visual = get_node_or_null("Visual") as Node2D
	shadow = get_node_or_null("Shadow") as Polygon2D
	trail = get_node_or_null("Trail") as Polygon2D


func _process(delta: float) -> void:
	if delta <= 0.0 or visual == null:
		return
	var parent_node: Node2D = get_parent() as Node2D
	var displacement: Vector2 = parent_node.global_position - previous_position
	var travelled: float = displacement.length()
	previous_position = parent_node.global_position
	var raw_speed: float = travelled / delta
	smoothed_speed = lerpf(smoothed_speed, minf(raw_speed, speed_reference * 1.8), minf(1.0, delta * 12.0))
	recoil = move_toward(recoil, 0.0, delta * 34.0)
	var motion: float = clampf(smoothed_speed / speed_reference, 0.0, 1.0)
	phase += delta * lerpf(2.8, 11.5, motion)
	if visual is AnimatedSprite2D:
		var animated: AnimatedSprite2D = visual as AnimatedSprite2D
		if motion > 0.055:
			var forward: Vector2 = Vector2.RIGHT.rotated(parent_node.global_rotation)
			var desired_direction: int = -1 if displacement.dot(forward) < -0.1 else 1
			if desired_direction != animation_direction or not animated.is_playing():
				if desired_direction < 0: animated.play_backwards("walk")
				else: animated.play("walk")
				animation_direction = desired_direction
			animated.speed_scale = lerpf(0.72, 1.48, motion)
		else:
			animated.pause()
			animated.frame = 1

	if boss_motion:
		var hover: float = sin(phase * 0.72)
		position = Vector2(-recoil, hover * 2.2)
		rotation = sin(phase * 0.31) * 0.025
		scale = Vector2.ONE * (1.0 + hover * 0.018)
	else:
		var stride: float = sin(phase)
		var impact: float = absf(cos(phase))
		position = Vector2(motion * 2.2 - recoil, stride * motion * 2.4 - impact * motion * 0.7)
		rotation = stride * motion * 0.055
		var stretch: float = motion * (0.025 + impact * 0.035)
		var breathe: float = sin(phase * 0.42) * (1.0 - motion) * 0.012
		scale = Vector2(1.0 + stretch + breathe, 1.0 - stretch + breathe)

	if shadow != null:
		shadow.scale = Vector2(lerpf(0.92, 1.12, motion), lerpf(1.0, 0.72, motion))
		shadow.modulate.a = lerpf(0.34, 0.20, motion)
	if trail != null:
		trail.modulate.a = motion * (0.26 if boss_motion else 0.18)
		trail.scale.x = lerpf(0.25, 1.0, motion)
