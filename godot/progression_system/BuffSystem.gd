class_name BuffSystem
extends Node

signal modifiers_changed(modifiers: Dictionary)
signal choice_applied(choice: Dictionary, modifiers: Dictionary)

const RARITY_MULTIPLIERS: Dictionary = {
	"common": 1.0,
	"rare": 1.75,
	"epic": 3.0,
}

const RARITY_LABELS: Dictionary = {
	"common": "COMMON",
	"rare": "RARE",
	"epic": "EPIC",
}

const BUFF_DATABASE: Dictionary = {
	"projectile_count": {
		"name": "Çoğaltıcı Namlu", "icon": "projectiles", "base": 1.0, "max_stacks": 6,
		"description": "+%d ek mermi",
	},
	"fire_rate": {
		"name": "Hız Aşırtma", "icon": "fire_rate", "base": 0.06, "max_stacks": 9,
		"description": "Atış beklemesi %%%d azalır",
	},
	"damage": {
		"name": "Piksel Yumruk", "icon": "damage", "base": 0.10, "max_stacks": 10,
		"description": "Silah hasarı %%%d artar",
	},
	"critical": {
		"name": "Kritik Sinyal", "icon": "critical", "base": 0.025, "max_stacks": 8,
		"description": "Kritik şansı +%%%d",
	},
	"speed": {
		"name": "Turbo Terlik", "icon": "speed", "base": 0.05, "max_stacks": 7,
		"description": "Hareket hızı %%%d artar",
	},
	"lifesteal": {
		"name": "Kırmızı Devre", "icon": "lifesteal", "base": 0.004, "max_stacks": 7,
		"description": "Vuruş hasarının %%%.1f kadarı can olur (saniyede en çok 4)",
	},
	"magnet": {
		"name": "Hurda Mıknatısı", "icon": "magnet", "base": 45.0, "max_stacks": 7,
		"description": "EXP çekim alanı +%d px",
	},
	"luck": {
		"name": "Şanslı Anten", "icon": "luck", "base": 0.04, "max_stacks": 6,
		"description": "Nadir kart şansı +%%%d",
	},
	"armor": {
		"name": "Titan Gövde", "icon": "armor", "base": 18.0, "max_stacks": 6,
		"description": "+%d maksimum HP",
	},
	"plating": {
		"name": "Reaktif Zırh", "icon": "armor", "base": 0.035, "max_stacks": 6,
		"description": "Gelen hasar %%%d azalır",
	},
	"dash": {
		"name": "Faz Sıçraması", "icon": "dash", "base": 0.08, "max_stacks": 6,
		"description": "Dash beklemesi %%%d azalır",
	},
	"repair": {
		"name": "Alan Tamircisi", "icon": "repair", "base": 3.0, "max_stacks": 6,
		"description": "Dalga sonunda +%d HP onarımı",
	},
}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var run_seed: int = 0
var offer_counter: int = 0
var stack_counts: Dictionary = {}
var last_offered_choices: Array[Dictionary] = []
var selection_history: Array[Dictionary] = []
var modifiers: Dictionary = {}


func _ready() -> void:
	if modifiers.is_empty():
		reset_run(0)


func reset_run(seed_value: int = 0) -> void:
	run_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_msec()
	rng.seed = run_seed
	offer_counter = 0
	stack_counts.clear()
	last_offered_choices.clear()
	selection_history.clear()
	modifiers = {
		"damage_multiplier": 1.0,
		"cooldown_multiplier": 1.0,
		"bonus_projectiles": 0,
		"critical_chance": 0.0,
		"critical_multiplier": 1.5,
		"speed_multiplier": 1.0,
		"lifesteal_rate": 0.0,
		"lifesteal_cap_per_second": 4.0,
		"magnet_radius": 120.0,
		"luck": 0.0,
		"max_health_bonus": 0,
		"damage_reduction": 0.0,
		"dash_cooldown_multiplier": 1.0,
		"wave_repair": 8,
	}
	modifiers_changed.emit(get_modifiers())


func roll_choices(count: int = 4, level: int = 1) -> Array[Dictionary]:
	offer_counter += 1
	var candidates: Array[String] = []
	for key: Variant in BUFF_DATABASE.keys():
		var buff_id: String = String(key)
		var definition: Dictionary = BUFF_DATABASE[buff_id]
		if int(stack_counts.get(buff_id, 0)) < int(definition["max_stacks"]):
			candidates.append(buff_id)
	_shuffle_strings(candidates)
	last_offered_choices.clear()
	if candidates.is_empty():
		return []
	for index: int in range(count):
		# Koşunun çok geç safhasında yalnızca birkaç kategori açık kalırsa dört
		# kart kuralını korumak için adaylar tekrar dönebilir; rarity hâlâ ayrıdır.
		var buff_id: String = candidates[index % candidates.size()]
		var rarity: String = _roll_rarity()
		last_offered_choices.append(_build_choice(buff_id, rarity, level, offer_counter))
	return last_offered_choices.duplicate(true)


func apply_choice(choice: Dictionary) -> bool:
	if last_offered_choices.is_empty():
		return false
	var matching_choice: Dictionary = {}
	for offered: Dictionary in last_offered_choices:
		if int(offered.get("offer_id", -1)) == int(choice.get("offer_id", -2)) \
		and String(offered.get("buff_id", "")) == String(choice.get("buff_id", "")) \
		and String(offered.get("rarity", "")) == String(choice.get("rarity", "")):
			matching_choice = offered
			break
	if matching_choice.is_empty():
		return false

	var buff_id: String = String(matching_choice["buff_id"])
	var effect: float = float(matching_choice["effect"])
	stack_counts[buff_id] = int(stack_counts.get(buff_id, 0)) + 1
	_apply_effect(buff_id, effect)
	selection_history.append({
		"offer_id": int(matching_choice["offer_id"]),
		"level": int(matching_choice["level"]),
		"buff_id": buff_id,
		"rarity": String(matching_choice["rarity"]),
	})
	last_offered_choices.clear()
	var snapshot: Dictionary = get_modifiers()
	modifiers_changed.emit(snapshot)
	choice_applied.emit(matching_choice.duplicate(true), snapshot)
	return true


func get_modifiers() -> Dictionary:
	return modifiers.duplicate(true)


func get_verification_payload() -> Dictionary:
	# Sunucu, seed ve seçim geçmişiyle teklifleri yeniden üreterek sahte kart
	# veya koşu dışı buff gönderimlerini kontrol edebilir.
	return {
		"run_seed": run_seed,
		"selections": selection_history.duplicate(true),
	}


func _roll_rarity() -> String:
	var luck: float = clampf(float(modifiers.get("luck", 0.0)), 0.0, 0.40)
	var epic_chance: float = 0.10 + luck * 0.12
	var rare_chance: float = 0.30 + luck * 0.18
	var roll: float = rng.randf()
	if roll < epic_chance:
		return "epic"
	if roll < epic_chance + rare_chance:
		return "rare"
	return "common"


func _build_choice(buff_id: String, rarity: String, level: int, current_offer_id: int) -> Dictionary:
	var definition: Dictionary = BUFF_DATABASE[buff_id]
	var multiplier: float = float(RARITY_MULTIPLIERS[rarity])
	var base_effect: float = float(definition["base"])
	var effect: float = base_effect * multiplier
	if buff_id == "projectile_count":
		effect = float(maxi(1, roundi(effect)))
	var description: String
	match buff_id:
		"lifesteal":
			description = String(definition["description"]) % (effect * 100.0)
		"magnet", "projectile_count", "armor", "repair":
			description = String(definition["description"]) % roundi(effect)
		_:
			description = String(definition["description"]) % roundi(effect * 100.0)
	return {
		"offer_id": current_offer_id,
		"level": level,
		"buff_id": buff_id,
		"name": String(definition["name"]),
		"icon": String(definition["icon"]),
		"rarity": rarity,
		"rarity_label": String(RARITY_LABELS[rarity]),
		"description": description,
		"effect": effect,
		"next_stack": int(stack_counts.get(buff_id, 0)) + 1,
		"max_stacks": int(definition["max_stacks"]),
	}


func _apply_effect(buff_id: String, effect: float) -> void:
	match buff_id:
		"projectile_count":
			modifiers["bonus_projectiles"] = int(modifiers["bonus_projectiles"]) + roundi(effect)
		"fire_rate":
			modifiers["cooldown_multiplier"] = maxf(0.35, float(modifiers["cooldown_multiplier"]) * (1.0 - effect))
		"damage":
			modifiers["damage_multiplier"] = float(modifiers["damage_multiplier"]) + effect
		"critical":
			modifiers["critical_chance"] = minf(0.55, float(modifiers["critical_chance"]) + effect)
			modifiers["critical_multiplier"] = minf(3.0, float(modifiers["critical_multiplier"]) + effect * 2.0)
		"speed":
			modifiers["speed_multiplier"] = minf(1.75, float(modifiers["speed_multiplier"]) + effect)
		"lifesteal":
			modifiers["lifesteal_rate"] = minf(0.04, float(modifiers["lifesteal_rate"]) + effect)
		"magnet":
			modifiers["magnet_radius"] = minf(720.0, float(modifiers["magnet_radius"]) + effect)
		"luck":
			modifiers["luck"] = minf(0.40, float(modifiers["luck"]) + effect)
		"armor":
			modifiers["max_health_bonus"] = int(modifiers["max_health_bonus"]) + roundi(effect)
		"plating":
			modifiers["damage_reduction"] = minf(0.45, float(modifiers["damage_reduction"]) + effect)
		"dash":
			modifiers["dash_cooldown_multiplier"] = maxf(0.45, float(modifiers["dash_cooldown_multiplier"]) * (1.0 - effect))
		"repair":
			modifiers["wave_repair"] = int(modifiers["wave_repair"]) + roundi(effect)


func _shuffle_strings(values: Array[String]) -> void:
	for index: int in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temporary: String = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary
