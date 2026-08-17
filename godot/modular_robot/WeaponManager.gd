class_name WeaponManager
extends Node

signal slot_changed(slot: int, weapon_id: String)
signal run_modifiers_changed(modifiers: Dictionary)

enum WeaponSlot {
	MAIN = 1,
	AREA = 2,
	TACTICAL = 3,
	HEAVY = 4,
}

const MAX_WEAPONS: int = 4
const SLOT_MARKERS: Dictionary = {
	WeaponSlot.MAIN: &"Marker2D_RightArm",
	WeaponSlot.AREA: &"Marker2D_LeftArm",
	WeaponSlot.TACTICAL: &"Marker2D_Shoulders",
	WeaponSlot.HEAVY: &"Marker2D_Back",
}

const RARITY_COLORS: Dictionary = {
	"common": "d9e0eb", "rare": "43c8ff", "epic": "c66cff",
}
const RARITY_LABELS: Dictionary = {
	"common": "YAYGIN", "rare": "NADİR", "epic": "EPİK",
}
const SLOT_LABELS: Dictionary = {
	WeaponSlot.MAIN: "ANA", WeaponSlot.AREA: "ALAN",
	WeaponSlot.TACTICAL: "TAKTİK", WeaponSlot.HEAVY: "AĞIR",
}

const WEAPON_DATABASE: Dictionary = {
	"w_ion_carbine": {
		"weapon_id": "w_ion_carbine", "display_name": "İyon Karabina", "icon": "IK", "atlas_index": 0,
		"slot": WeaponSlot.MAIN, "type": "single", "fire_rate": 0.4, "damage": 10, "projectile_speed": 520,
		"effect": "Dengeli iyon darbesi ilk hedefi delip arkasındaki bir hedefe daha ulaşır.",
		"rarity": "common", "projectile_color": "8fe3ff",
	},
	"w_pulse_smg": {
		"weapon_id": "w_pulse_smg", "display_name": "Nabız SMG", "icon": "NS", "atlas_index": 1,
		"slot": WeaponSlot.MAIN, "type": "rapid", "fire_rate": 0.09, "damage": 3, "accuracy": 0.78, "projectile_speed": 690,
		"effect": "Çok hızlı, küçük ve hafif salınımlı nabız mermileri yağdırır.",
		"rarity": "rare", "projectile_color": "5ad2ff",
	},
	"w_photon_beam": {
		"weapon_id": "w_photon_beam", "display_name": "Foton Işını", "icon": "FI", "atlas_index": 2,
		"slot": WeaponSlot.MAIN, "type": "continuous", "tick_rate": 0.18, "damage": 7, "projectile_speed": 920,
		"effect": "İnce foton kesitleri aynı çizgide dört hedefe kadar deler.",
		"rarity": "epic", "projectile_color": "c9f2ff",
	},
	"w_scatter_flak": {
		"weapon_id": "w_scatter_flak", "display_name": "Dağıtıcı Flak", "icon": "DF", "atlas_index": 3,
		"slot": WeaponSlot.AREA, "type": "spread", "fire_rate": 1.15, "damage": 8, "projectiles": 5, "projectile_speed": 430,
		"effect": "Geniş koniye yayılan beş kısa ömürlü flak parçası fırlatır.",
		"rarity": "common", "projectile_color": "ffb34d",
	},
	"w_plasma_puddle": {
		"weapon_id": "w_plasma_puddle", "display_name": "Plazma Havuzu", "icon": "PH", "atlas_index": 4,
		"slot": WeaponSlot.AREA, "type": "dot_puddle", "fire_rate": 1.65, "damage": 5, "projectile_speed": 180,
		"effect": "Yavaş kapsül hedef bölgede durur ve sakin plazma alanıyla tekrar tekrar hasar verir.",
		"rarity": "rare", "projectile_color": "6cff9e",
	},
	"w_tesla_arc": {
		"weapon_id": "w_tesla_arc", "display_name": "Tesla Yayı", "icon": "TY", "atlas_index": 5,
		"slot": WeaponSlot.AREA, "type": "chain_lightning", "fire_rate": 1.05, "damage": 12, "projectile_speed": 560,
		"effect": "Hafif güdümlü yük ilk vuruştan sonra iki yakındaki düşmana zincirlenir.",
		"rarity": "epic", "projectile_color": "9a7dff",
	},
	"w_boomerang_blade": {
		"weapon_id": "w_boomerang_blade", "display_name": "Bumerang Bıçak", "icon": "BB", "atlas_index": 6,
		"slot": WeaponSlot.TACTICAL, "type": "returning", "fire_rate": 0.85, "damage": 15, "projectile_speed": 390,
		"effect": "Dönen bıçak ileri gider, geri gelir ve yolundaki her hedefe bir kez vurur.",
		"rarity": "common", "projectile_color": "d9e0eb",
	},
	"w_gravity_mine": {
		"weapon_id": "w_gravity_mine", "display_name": "Yerçekimi Mayını", "icon": "YM", "atlas_index": 7,
		"slot": WeaponSlot.TACTICAL, "type": "trap", "fire_rate": 2.1, "damage": 36, "projectile_speed": 125,
		"effect": "Kısa mesafeye kurulan mayın yaklaşan düşmanı algılayıp alan patlaması oluşturur.",
		"rarity": "rare", "projectile_color": "43c8ff",
	},
	"w_hunter_drones": {
		"weapon_id": "w_hunter_drones", "display_name": "Avcı Dronlar", "icon": "AD", "atlas_index": 8,
		"slot": WeaponSlot.TACTICAL, "type": "tracking", "fire_rate": 1.75, "damage": 18, "projectile_speed": 410,
		"effect": "Avcı dron oku en yakın düşmana güçlü biçimde yönelir.",
		"rarity": "epic", "projectile_color": "ff8fd6",
	},
	"w_singularity_launcher": {
		"weapon_id": "w_singularity_launcher", "display_name": "Tekillik Fırlatıcı", "icon": "TF", "atlas_index": 9,
		"slot": WeaponSlot.HEAVY, "type": "aoe_pull", "fire_rate": 3.0, "damage": 25, "projectile_speed": 270,
		"effect": "Tekillik çekirdeği çarpınca geniş alana hasar verir ve düşmanları merkeze çeker.",
		"rarity": "common", "projectile_color": "b389ff",
	},
	"w_sonic_repulsor": {
		"weapon_id": "w_sonic_repulsor", "display_name": "Sonik İtici", "icon": "Sİ", "atlas_index": 10,
		"slot": WeaponSlot.HEAVY, "type": "knockback", "fire_rate": 2.35, "damage": 7, "projectile_speed": 470,
		"effect": "Genişleyen sonik dalga çok sayıda hedefi deler ve geriye iter.",
		"rarity": "rare", "projectile_color": "ffe15a",
	},
	"w_railgun_overcharge": {
		"weapon_id": "w_railgun_overcharge", "display_name": "Railgun Aşırı Yük", "icon": "RA", "atlas_index": 11,
		"slot": WeaponSlot.HEAVY, "type": "charge", "charge_time": 2.0, "damage": 100, "projectile_speed": 980,
		"effect": "Uzun rail mızrağı yüksek hızla ilerler ve dokuz hedefe kadar deler.",
		"rarity": "epic", "projectile_color": "ff536f",
	},
}

@export var database_weapon_scene: PackedScene

var player: ModularRobotPlayer
var hardpoint_root: Node2D
var projectile_parent: Node2D
var inventory: Dictionary = {}
var run_modifiers: Dictionary = {
	"damage_multiplier": 1.0,
	"cooldown_multiplier": 1.0,
	"bonus_projectiles": 0,
	"critical_chance": 0.0,
	"critical_multiplier": 1.5,
	"lifesteal_rate": 0.0,
	"lifesteal_cap_per_second": 4.0,
}
var lifesteal_fraction: float = 0.0
var lifesteal_used_this_second: float = 0.0
var lifesteal_window_elapsed: float = 0.0
var selection_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _process(delta: float) -> void:
	lifesteal_window_elapsed += delta
	if lifesteal_window_elapsed >= 1.0:
		lifesteal_window_elapsed = fmod(lifesteal_window_elapsed, 1.0)
		lifesteal_used_this_second = 0.0


func initialize(new_player: ModularRobotPlayer, new_hardpoint_root: Node2D, new_projectile_parent: Node2D) -> void:
	player = new_player
	hardpoint_root = new_hardpoint_root
	projectile_parent = new_projectile_parent
	selection_rng.randomize()


func configure_selection_seed(seed_value: int) -> void:
	selection_rng.seed = seed_value ^ 0x5A17C9


func roll_weapon_choices(count: int, level: int) -> Array[Dictionary]:
	var snapshot: Dictionary = get_inventory_snapshot()
	var empty_slots: Array[int] = []
	for slot: int in range(WeaponSlot.MAIN, WeaponSlot.HEAVY + 1):
		if String(snapshot.get(slot, "")).is_empty():
			empty_slots.append(slot)
	if empty_slots.is_empty():
		return []
	_shuffle_weapon_slots(empty_slots)
	var choices: Array[Dictionary] = []
	for index: int in range(mini(count, empty_slots.size())):
		var slot: int = empty_slots[index]
		var candidates: Array[String] = get_weapon_ids_for_slot(slot)
		_shuffle_weapon_ids(candidates)
		if candidates.is_empty():
			continue
		var weapon_id: String = candidates[0]
		var definition: Dictionary = WEAPON_DATABASE[weapon_id]
		var slot_label: String = String(SLOT_LABELS[slot])
		choices.append({
			"choice_kind": "weapon",
			"level": level,
			"weapon_id": weapon_id,
			"slot": slot,
			"slot_label": slot_label,
			"name": String(definition["display_name"]),
			"icon": String(definition["icon"]),
			"atlas_index": int(definition["atlas_index"]),
			"rarity": String(definition["rarity"]),
			"rarity_label": String(RARITY_LABELS[definition["rarity"]]),
			"description": "%s\n%s yuvasını açar." % [String(definition.get("effect", "Özel silah sistemi.")), slot_label],
		})
	return choices


func _shuffle_weapon_ids(values: Array[String]) -> void:
	for index: int in range(values.size() - 1, 0, -1):
		var swap_index: int = selection_rng.randi_range(0, index)
		var temporary: String = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func _shuffle_weapon_slots(values: Array[int]) -> void:
	for index: int in range(values.size() - 1, 0, -1):
		var swap_index: int = selection_rng.randi_range(0, index)
		var temporary: int = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func get_weapon_ids_for_slot(slot: int) -> Array[String]:
	var ids: Array[String] = []
	for weapon_id: String in WEAPON_DATABASE.keys():
		if int((WEAPON_DATABASE[weapon_id] as Dictionary)["slot"]) == slot:
			ids.append(weapon_id)
	return ids


func roll_random_loadout() -> Dictionary:
	var loadout: Dictionary = {}
	for slot: int in range(WeaponSlot.MAIN, WeaponSlot.HEAVY + 1):
		var candidates: Array[String] = get_weapon_ids_for_slot(slot)
		if candidates.is_empty():
			continue
		loadout[slot] = candidates[randi_range(0, candidates.size() - 1)]
	return loadout


func equip_default_loadout() -> Dictionary:
	var loadout: Dictionary = {}
	for slot: int in range(WeaponSlot.MAIN, WeaponSlot.HEAVY + 1):
		var candidates: Array[String] = get_weapon_ids_for_slot(slot)
		for candidate: String in candidates:
			if String((WEAPON_DATABASE[candidate] as Dictionary)["rarity"]) == "common":
				loadout[slot] = candidate
				break
	return loadout


func reset_to_starter_loadout() -> void:
	for slot: int in range(WeaponSlot.MAIN, WeaponSlot.HEAVY + 1):
		unequip_slot(slot)
	equip_weapon(WeaponSlot.MAIN, "w_ion_carbine")


func equip_weapon(slot: int, weapon_id: String) -> Weapon:
	if slot < WeaponSlot.MAIN or slot > WeaponSlot.HEAVY:
		push_error("Geçersiz silah slotu: %d" % slot)
		return null
	if not WEAPON_DATABASE.has(weapon_id):
		push_error("Silah veritabanında bulunamadı: %s" % weapon_id)
		return null
	if database_weapon_scene == null or hardpoint_root == null or player == null:
		push_error("WeaponManager initialize edilmedi veya database_weapon_scene eksik.")
		return null

	var definition: Dictionary = WEAPON_DATABASE[weapon_id]
	if int(definition["slot"]) != slot:
		push_error("%s, SLOT %d kategorisine takılamaz." % [weapon_id, slot])
		return null

	var marker_name: StringName = SLOT_MARKERS[slot]
	var marker: Marker2D = hardpoint_root.get_node_or_null(NodePath(String(marker_name))) as Marker2D
	if marker == null:
		push_error("Silah Marker2D noktası bulunamadı: %s" % marker_name)
		return null

	unequip_slot(slot)
	var instance: Node = database_weapon_scene.instantiate()
	if not instance is Weapon:
		push_error("database_weapon_scene kökü Weapon sınıfından türemeli.")
		instance.free()
		return null

	var weapon: Weapon = instance as Weapon
	weapon.apply_definition(definition)
	marker.add_child(weapon)
	weapon.position = Vector2.ZERO
	weapon.rotation = 0.0
	weapon.configure_runtime(projectile_parent, player)
	weapon.apply_run_modifiers(run_modifiers)
	weapon.damage_dealt.connect(_on_weapon_damage_dealt)
	inventory[slot] = weapon
	slot_changed.emit(slot, weapon_id)
	return weapon


func equip_weapon_by_id(weapon_id: String) -> Weapon:
	if not WEAPON_DATABASE.has(weapon_id):
		push_error("Silah veritabanında bulunamadı: %s" % weapon_id)
		return null
	return equip_weapon(int(WEAPON_DATABASE[weapon_id]["slot"]), weapon_id)


func unequip_slot(slot: int) -> void:
	if not inventory.has(slot):
		return
	var old_weapon: Weapon = inventory[slot] as Weapon
	inventory.erase(slot)
	if is_instance_valid(old_weapon):
		var marker: Node = old_weapon.get_parent()
		if marker != null:
			marker.remove_child(old_weapon)
		old_weapon.queue_free()
	slot_changed.emit(slot, "")


func shoot_all() -> void:
	# Sabit slot sırası, sonuçların ve testlerin öngörülebilir kalmasını sağlar.
	for slot: int in range(WeaponSlot.MAIN, WeaponSlot.HEAVY + 1):
		var weapon: Weapon = inventory.get(slot) as Weapon
		if is_instance_valid(weapon):
			weapon.shoot()


func get_weapon(slot: int) -> Weapon:
	return inventory.get(slot) as Weapon


func get_weapon_definition(weapon_id: String) -> Dictionary:
	if not WEAPON_DATABASE.has(weapon_id):
		return {}
	return (WEAPON_DATABASE[weapon_id] as Dictionary).duplicate(true)


func get_inventory_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for slot: int in range(WeaponSlot.MAIN, WeaponSlot.HEAVY + 1):
		var weapon: Weapon = inventory.get(slot) as Weapon
		snapshot[slot] = weapon.weapon_id if is_instance_valid(weapon) else ""
	return snapshot


func apply_run_modifiers(modifiers: Dictionary) -> void:
	for key: Variant in modifiers.keys():
		run_modifiers[key] = modifiers[key]
	for value: Variant in inventory.values():
		var weapon: Weapon = value as Weapon
		if is_instance_valid(weapon):
			weapon.apply_run_modifiers(run_modifiers)
	run_modifiers_changed.emit(run_modifiers.duplicate(true))


func reset_run_modifiers() -> void:
	apply_run_modifiers({
		"damage_multiplier": 1.0,
		"cooldown_multiplier": 1.0,
		"bonus_projectiles": 0,
		"critical_chance": 0.0,
		"critical_multiplier": 1.5,
		"lifesteal_rate": 0.0,
		"lifesteal_cap_per_second": 4.0,
	})
	lifesteal_fraction = 0.0
	lifesteal_used_this_second = 0.0
	lifesteal_window_elapsed = 0.0


func _on_weapon_damage_dealt(amount: int) -> void:
	if player == null or player.dead:
		return
	var lifesteal_rate: float = clampf(float(run_modifiers.get("lifesteal_rate", 0.0)), 0.0, 0.10)
	var heal_cap: float = maxf(0.0, float(run_modifiers.get("lifesteal_cap_per_second", 4.0)))
	if lifesteal_rate <= 0.0 or lifesteal_used_this_second >= heal_cap:
		return
	lifesteal_fraction += float(amount) * lifesteal_rate
	var whole_heal: int = floori(lifesteal_fraction)
	var remaining_budget: int = floori(heal_cap - lifesteal_used_this_second)
	var applied_heal: int = mini(whole_heal, remaining_budget)
	if applied_heal <= 0:
		return
	lifesteal_fraction -= float(applied_heal)
	lifesteal_used_this_second += float(applied_heal)
	player.heal(applied_heal)
