class_name ExpOrb
extends Node2D

signal collected(orb: ExpOrb, value: int)

@export_range(20.0, 1200.0, 10.0) var attraction_speed: float = 440.0
@export_range(4.0, 100.0, 1.0) var pickup_radius: float = 24.0

var active: bool = false
var exp_value: int = 1
var target: Node2D
var magnet_radius: float = 120.0
var phase: float = 0.0


func _ready() -> void:
	deactivate()


func activate(spawn_position: Vector2, value: int, new_target: Node2D, new_magnet_radius: float) -> void:
	global_position = spawn_position
	exp_value = maxi(1, value)
	target = new_target
	magnet_radius = maxf(pickup_radius, new_magnet_radius)
	phase = randf() * TAU
	active = true
	visible = true
	set_physics_process(true)


func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	target = null


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		return
	phase += delta * 5.0
	rotation = sin(phase) * 0.16
	var to_target: Vector2 = target.global_position - global_position
	var distance_squared: float = to_target.length_squared()
	if distance_squared <= pickup_radius * pickup_radius:
		active = false
		set_physics_process(false)
		collected.emit(self, exp_value)
		return
	if distance_squared <= magnet_radius * magnet_radius:
		var distance: float = sqrt(distance_squared)
		var pull_scale: float = 1.0 + (1.0 - distance / magnet_radius) * 1.6
		global_position += to_target.normalized() * attraction_speed * pull_scale * delta
