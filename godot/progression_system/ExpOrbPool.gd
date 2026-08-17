class_name ExpOrbPool
extends Node2D

signal orb_collected(value: int)

@export var orb_scene: PackedScene
@export_range(8, 512, 1) var prewarm_count: int = 96

var available: Array[ExpOrb] = []
var active_orbs: Dictionary = {}


func _ready() -> void:
	for _index: int in range(prewarm_count):
		available.append(_create_orb())


func acquire(spawn_position: Vector2, value: int, target: Node2D, magnet_radius: float) -> ExpOrb:
	var orb: ExpOrb = available.pop_back() if not available.is_empty() else _create_orb()
	active_orbs[orb.get_instance_id()] = orb
	orb.activate(spawn_position, value, target, magnet_radius)
	return orb


func release(orb: ExpOrb) -> void:
	if not is_instance_valid(orb) or not active_orbs.has(orb.get_instance_id()):
		return
	active_orbs.erase(orb.get_instance_id())
	orb.deactivate()
	available.append(orb)


func release_all() -> void:
	var snapshot: Array = active_orbs.values()
	for value: Variant in snapshot:
		var orb: ExpOrb = value as ExpOrb
		if is_instance_valid(orb):
			release(orb)


func set_magnet_radius(radius: float) -> void:
	for value: Variant in active_orbs.values():
		var orb: ExpOrb = value as ExpOrb
		if is_instance_valid(orb):
			orb.magnet_radius = radius


func get_active_count() -> int:
	return active_orbs.size()


func _create_orb() -> ExpOrb:
	if orb_scene == null:
		push_error("ExpOrbPool.orb_scene atanmadı.")
		return null
	var orb: ExpOrb = orb_scene.instantiate() as ExpOrb
	add_child(orb)
	orb.collected.connect(_on_orb_collected)
	orb.deactivate()
	return orb


func _on_orb_collected(orb: ExpOrb, value: int) -> void:
	orb_collected.emit(value)
	call_deferred("release", orb)
