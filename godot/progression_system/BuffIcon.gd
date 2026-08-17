class_name BuffIcon
extends Control

@export var icon_id: String = "damage":
	set(value):
		icon_id = value
		queue_redraw()

var accent: Color = Color("66e4ff")


func set_icon(new_icon_id: String, new_accent: Color) -> void:
	icon_id = new_icon_id
	accent = new_accent
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, 31.0, Color(0.02, 0.04, 0.10, 0.92))
	draw_arc(center, 31.0, 0.0, TAU, 32, accent, 3.0, true)
	match icon_id:
		"projectiles": _draw_projectiles(center)
		"fire_rate": _draw_fire_rate(center)
		"damage": _draw_damage(center)
		"critical": _draw_critical(center)
		"speed": _draw_speed(center)
		"lifesteal": _draw_lifesteal(center)
		"magnet": _draw_magnet(center)
		"luck": _draw_luck(center)
		"armor": _draw_armor(center)
		"dash": _draw_dash(center)
		"repair": _draw_repair(center)
		_: draw_circle(center, 10.0, accent)


func _draw_projectiles(c: Vector2) -> void:
	for offset: Vector2 in [Vector2(-14, -11), Vector2(-14, 0), Vector2(-14, 11)]:
		draw_rect(Rect2(c + offset, Vector2(21, 5)), accent, true)
		draw_colored_polygon(PackedVector2Array([c + offset + Vector2(21, -3), c + offset + Vector2(29, 2.5), c + offset + Vector2(21, 8)]), accent)


func _draw_fire_rate(c: Vector2) -> void:
	var bolt: PackedVector2Array = PackedVector2Array([c + Vector2(4, -24), c + Vector2(-13, 2), c + Vector2(-2, 2), c + Vector2(-7, 24), c + Vector2(15, -7), c + Vector2(3, -7)])
	draw_colored_polygon(bolt, accent)


func _draw_damage(c: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(16):
		var radius: float = 24.0 if index % 2 == 0 else 12.0
		points.append(c + Vector2.RIGHT.rotated(float(index) * TAU / 16.0) * radius)
	draw_colored_polygon(points, accent)
	draw_circle(c, 7.0, Color("fff5bd"))


func _draw_critical(c: Vector2) -> void:
	for radius: float in [24.0, 15.0, 6.0]:
		draw_arc(c, radius, 0.0, TAU, 24, accent, 3.0, true)
	draw_line(c + Vector2(-29, 0), c + Vector2(29, 0), accent, 2.0)
	draw_line(c + Vector2(0, -29), c + Vector2(0, 29), accent, 2.0)


func _draw_speed(c: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-22, -10), c + Vector2(3, -10), c + Vector2(20, 2), c + Vector2(3, 10), c + Vector2(-22, 10), c + Vector2(-8, 1)]), accent)
	for y: float in [-16.0, 16.0]:
		draw_line(c + Vector2(-25, y), c + Vector2(-8, y), accent, 4.0)


func _draw_lifesteal(c: Vector2) -> void:
	var drop: PackedVector2Array = PackedVector2Array([c + Vector2(0, -25), c + Vector2(-17, 3), c + Vector2(-13, 18), c, c + Vector2(13, 18), c + Vector2(17, 3)])
	draw_colored_polygon(drop, accent)
	draw_line(c + Vector2(-7, 7), c + Vector2(7, 7), Color("fff4f4"), 3.0)
	draw_line(c + Vector2(0, 0), c + Vector2(0, 14), Color("fff4f4"), 3.0)


func _draw_magnet(c: Vector2) -> void:
	draw_arc(c, 20.0, 0.0, PI, 24, accent, 9.0, true)
	draw_rect(Rect2(c + Vector2(-25, -2), Vector2(10, 20)), accent, true)
	draw_rect(Rect2(c + Vector2(15, -2), Vector2(10, 20)), accent, true)


func _draw_luck(c: Vector2) -> void:
	for offset: Vector2 in [Vector2(-9, -9), Vector2(9, -9), Vector2(-9, 9), Vector2(9, 9)]:
		draw_circle(c + offset, 10.0, accent)
	draw_circle(c, 5.0, Color(0.02, 0.04, 0.10))


func _draw_armor(c: Vector2) -> void:
	var shield: PackedVector2Array = PackedVector2Array([c + Vector2(0, -27), c + Vector2(22, -17), c + Vector2(18, 10), c + Vector2(0, 27), c + Vector2(-18, 10), c + Vector2(-22, -17)])
	draw_colored_polygon(shield, accent)
	draw_polyline(PackedVector2Array([c + Vector2(0, -18), c + Vector2(0, 18)]), Color("fff5d8"), 3.0)


func _draw_dash(c: Vector2) -> void:
	for offset: float in [-11.0, 0.0, 11.0]:
		var alpha: float = 0.48 + (offset + 11.0) / 44.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(-24 + offset * 0.25, -7), c + Vector2(5 + offset * 0.25, -7), c + Vector2(22 + offset * 0.25, 0), c + Vector2(5 + offset * 0.25, 7), c + Vector2(-24 + offset * 0.25, 7)]), Color(accent.r, accent.g, accent.b, alpha))


func _draw_repair(c: Vector2) -> void:
	draw_rect(Rect2(c + Vector2(-7, -24), Vector2(14, 48)), accent, true)
	draw_rect(Rect2(c + Vector2(-24, -7), Vector2(48, 14)), accent, true)
	draw_circle(c, 6.0, Color("fff5d8"))
