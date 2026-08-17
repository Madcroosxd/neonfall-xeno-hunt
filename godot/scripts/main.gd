extends Node2D

const SCREEN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const WORLD_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const PLAYER_MIN: Vector2 = Vector2(58.0, 58.0)
const PLAYER_MAX: Vector2 = WORLD_SIZE - Vector2(58.0, 58.0)
const SPAWN_SAFE_DISTANCE: float = 520.0
const BOSS_NAMES: Array[String] = ["HARVESTER TAŞIYICI", "HALO AVCISI", "OBELISK DREADNOUGHT"]
const MAX_ACTIVE_WEAPONS: int = 3
const WEAPONS: Array[Dictionary] = [
	{"id": "pulse", "name": "PULSE RIFLE", "desc": "Hızlı ve dengeli tekli plazma atışı", "cooldown": 0.16},
	{"id": "scatter", "name": "VOID SCATTERGUN", "desc": "Yakın menzilli 7 saçmalı pompalı", "cooldown": 0.82},
	{"id": "trident", "name": "TRIDENT BLASTER", "desc": "Aynı anda üç koridora enerji yollar", "cooldown": 0.38},
	{"id": "rail", "name": "ION RAILGUN", "desc": "Düşmanları delen ağır tek atış", "cooldown": 1.22},
	{"id": "missile_weapon", "name": "SEEKER MISSILE", "desc": "Hedef takip eden patlayıcı füze", "cooldown": 1.85},
	{"id": "nova_weapon", "name": "NOVA ARRAY", "desc": "Her yöne yayılan savunma salvosu", "cooldown": 2.45}
]
const UPGRADES: Array[Dictionary] = [
	{"id": "damage", "name": "PLAZMA ÇEKİRDEĞİ", "desc": "+%22 silah hasarı", "max": 6},
	{"id": "fire_rate", "name": "HIZLI TETİK", "desc": "+%18 atış hızı", "max": 6},
	{"id": "armor", "name": "EXO-ZIRH", "desc": "+25 maksimum can ve 25 iyileşme", "max": 5},
	{"id": "multishot", "name": "ÇATALLI ATIŞ", "desc": "+1 plazma mermisi", "max": 3},
	{"id": "speed", "name": "JETPACK TAKVİYESİ", "desc": "+%14 hareket hızı", "max": 5},
	{"id": "crit", "name": "ZAYIF NOKTA", "desc": "+%8 kritik vuruş şansı", "max": 4},
	{"id": "lifesteal", "name": "CAN SÖMÜRÜSÜ", "desc": "Düşük oranlı iyileşme; saniyelik sınırı vardır", "max": 3},
	{"id": "dash", "name": "FAZ JETPACK", "desc": "Atılma bekleme süresi -%18", "max": 3},
	{"id": "aegis", "name": "AEGIS KALKAN UYDUSU", "desc": "Mermi durduran döner kalkan uyduları", "max": 8},
	{"id": "system_power", "name": "SİSTEM GÜCÜ", "desc": "Otomatik sistem hasarı +%12", "max": 20},
	{"id": "system_haste", "name": "SİSTEM HIZI", "desc": "Otomatik sistem bekleme süresi -%9", "max": 15},
	{"id": "magnet", "name": "ÇEKİM ALANI", "desc": "Toplama menzilini büyütür", "max": 12}
]
const EVOLUTIONS: Array[Dictionary] = [
	{"id": "rail", "name": "VOID RAILGUN", "requires": {"damage": 3, "crit": 2}},
	{"id": "nova", "name": "NOVA PROTOKOLÜ", "requires": {"fire_rate": 3, "multishot": 2}},
	{"id": "phase", "name": "FAZ İZİ", "requires": {"speed": 2, "dash": 2}}
]
const PROTOCOLS: Array[Dictionary] = [
	{"name": "OVERDRIVE", "desc": "Uzaylılar %20 hızlı • skor x1.35", "speed": 1.20, "count": 1.0, "score": 1.35, "hp": 1.0, "damage": 1.0},
	{"name": "CAM TOP", "desc": "Can -%25 • hasar +%30 • skor x1.45", "speed": 1.0, "count": 1.0, "score": 1.45, "hp": 0.75, "damage": 1.30},
	{"name": "SÜRÜ", "desc": "%35 daha fazla uzaylı • skor x1.30", "speed": 1.05, "count": 1.35, "score": 1.30, "hp": 1.0, "damage": 1.0}
]
const QUESTS: Array[Dictionary] = [
	{"id": "hunter", "name": "TEMİZLİK EMRİ", "desc": "40 uzaylı imha et", "target": 40},
	{"id": "elite", "name": "ALTIN KAN", "desc": "3 elit uzaylı avla", "target": 3},
	{"id": "boss", "name": "GEMİ KIRAN", "desc": "Bir boss gemisi düşür", "target": 1}
]

@onready var world: Node2D = $World
@onready var grid: Node2D = $World/Grid
@onready var entities: Node2D = $World/Entities
@onready var projectile_layer: Node2D = $World/Projectiles
@onready var pickup_layer: Node2D = $World/Pickups
@onready var info_label: Label = $CanvasLayer/HUD/StatusPanel/VBox/Info
@onready var health_text: Label = $CanvasLayer/HUD/StatusPanel/VBox/HealthText
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/StatusPanel/VBox/Health
@onready var wave_bar: ProgressBar = $CanvasLayer/HUD/StatusPanel/VBox/XP
@onready var protocol_label: Label = $CanvasLayer/HUD/StatusPanel/VBox/Protocol
@onready var stats_label: Label = $CanvasLayer/HUD/Stats
@onready var boss_panel: PanelContainer = $CanvasLayer/HUD/BossStatus
@onready var boss_name_label: Label = $CanvasLayer/HUD/BossStatus/VBox/Name
@onready var boss_health_bar: ProgressBar = $CanvasLayer/HUD/BossStatus/VBox/Health
@onready var wave_banner: Label = $CanvasLayer/HUD/WaveBanner
@onready var mission_label: Label = $CanvasLayer/HUD/Mission
@onready var level_panel: PanelContainer = $CanvasLayer/HUD/LevelUp
@onready var choice_buttons: Array[Button] = [
	$CanvasLayer/HUD/LevelUp/VBox/Choice1,
	$CanvasLayer/HUD/LevelUp/VBox/Choice2,
	$CanvasLayer/HUD/LevelUp/VBox/Choice3
]
@onready var reroll_button: Button = $CanvasLayer/HUD/LevelUp/VBox/Reroll
@onready var build_label: Label = $CanvasLayer/HUD/LevelUp/VBox/Build
@onready var pause_panel: PanelContainer = $CanvasLayer/HUD/Pause
@onready var game_over_panel: PanelContainer = $CanvasLayer/HUD/GameOver
@onready var game_over_stats: Label = $CanvasLayer/HUD/GameOver/VBox/Stats
@onready var restart_button: Button = $CanvasLayer/HUD/GameOver/VBox/Restart
@onready var audio_button: Button = $CanvasLayer/HUD/AudioButton
@onready var audio_panel: PanelContainer = $CanvasLayer/HUD/AudioPanel
@onready var music_slider: HSlider = $CanvasLayer/HUD/AudioPanel/VBox/Music
@onready var music_label: Label = $CanvasLayer/HUD/AudioPanel/VBox/MusicLabel
@onready var sfx_slider: HSlider = $CanvasLayer/HUD/AudioPanel/VBox/Sfx
@onready var sfx_label: Label = $CanvasLayer/HUD/AudioPanel/VBox/SfxLabel
@onready var audio_close_button: Button = $CanvasLayer/HUD/AudioPanel/VBox/Close
@onready var pause_music_slider: HSlider = $CanvasLayer/HUD/Pause/VBox/Music
@onready var pause_music_label: Label = $CanvasLayer/HUD/Pause/VBox/MusicLabel
@onready var pause_sfx_slider: HSlider = $CanvasLayer/HUD/Pause/VBox/Sfx
@onready var pause_sfx_label: Label = $CanvasLayer/HUD/Pause/VBox/SfxLabel

var player: Node2D
var audio: NeonAudio
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var player_health: float = 110.0
var player_max_health: float = 110.0
var player_speed: float = 285.0
var player_damage: float = 24.0
var player_fire_rate: float = 5.0
var player_bullet_speed: float = 930.0
var player_multishot: int = 1
var player_crit: float = 0.08
var player_fire_cooldown: float = 0.0
var player_aim_angle: float = 0.0
var player_invulnerability: float = 0.0
var dash_cooldown: float = 0.0
var dash_base_cooldown: float = 2.25
var dash_requested: bool = false
var wave: int = 1
var wave_state: String = "spawning"
var spawn_left: int = 0
var spawn_total: int = 0
var spawn_cooldown: float = 0.0
var wave_defeated: int = 0
var elapsed: float = 0.0
var kills: int = 0
var score: int = 0
var best_score: int = 0
var gameplay_locked: bool = false
var run_over: bool = false
var banner_timer: float = 0.0
var camera_shake: float = 0.0
var camera_origin: Vector2 = Vector2.ZERO
var current_choices: Array[Dictionary] = []
var perks: Dictionary = {}
var heal_window: float = 0.0
var healed_this_window: float = 0.0
var daily_protocol: Dictionary = {}
var daily_quest: Dictionary = {}
var quest_progress: int = 0
var quest_completed: bool = false
var void_shards: int = 0
var archive_rank: int = 0
var best_wave: int = 1
var runs: int = 0
var rerolls: int = 2
var evolutions: Dictionary = {}
var buffs: Dictionary = {"rapid": 0.0, "damage": 0.0, "cryo": 0.0}
var shot_count: int = 0
var paused_game: bool = false
var wave_mutation: String = ""
var daily_key: String = ""
var completed_daily_key: String = ""
var combo: float = 1.0
var combo_timer: float = 0.0
var missile_timer: float = 0.8
var beam_timer: float = 1.4
var shield_tick: float = 0.0
var shield_nodes: Array[Node2D] = []
var active_weapons: Array[String] = ["pulse"]
var weapon_cooldowns: Dictionary = {"pulse": 0.0}
var event_spawn_timer: float = 180.0
var freeze_all_timer: float = 0.0
var invincible_timer: float = 0.0
var event_shield: Node2D
var music_volume_setting: float = 0.52
var sfx_volume_setting: float = 0.78
var impact_vfx_cooldown: float = 0.0
var web_bridge: Variant = null
var web_sync_timer: float = 0.0


func _ready() -> void:
	randomize()
	if OS.has_feature("web"):
		web_bridge = JavaScriptBridge.get_interface("NeonfallBridge")
	_build_background()
	_load_best_score()
	_select_daily_content()
	archive_rank = mini(3, int(float(void_shards) / 10.0))
	rerolls = 2 + archive_rank
	player_max_health = roundf(player_max_health * float(daily_protocol["hp"]))
	player_health = player_max_health
	player_damage *= float(daily_protocol["damage"])
	player = VisualFactory.create_player()
	entities.add_child(player)
	player.position = WORLD_SIZE * Vector2(0.5, 0.54)
	camera_origin = SCREEN_SIZE * 0.5 - player.position
	audio = NeonAudio.new()
	add_child(audio)
	audio.set_music_volume(music_volume_setting)
	audio.set_sfx_volume(sfx_volume_setting)
	music_slider.value = music_volume_setting * 100.0
	sfx_slider.value = sfx_volume_setting * 100.0
	pause_music_slider.value = music_volume_setting * 100.0
	pause_sfx_slider.value = sfx_volume_setting * 100.0
	for index: int in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_choose_upgrade.bind(index))
	reroll_button.pressed.connect(_reroll_upgrades)
	restart_button.pressed.connect(_restart)
	audio_button.pressed.connect(_toggle_audio_panel)
	audio_close_button.pressed.connect(_toggle_audio_panel)
	music_slider.value_changed.connect(_set_music_volume)
	sfx_slider.value_changed.connect(_set_sfx_volume)
	pause_music_slider.value_changed.connect(_set_music_volume)
	pause_sfx_slider.value_changed.connect(_set_sfx_volume)
	protocol_label.text = "GÜNLÜK: %s  •  %s" % [String(daily_protocol["name"]), String(daily_protocol["desc"])]
	_begin_wave(1)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_ESCAPE:
				if audio_panel.visible:
					audio_panel.visible = false
					paused_game = false
				else:
					paused_game = not paused_game
					pause_panel.visible = paused_game
			elif key_event.keycode == KEY_SPACE:
				dash_requested = true
			elif key_event.keycode == KEY_M and audio != null:
				var music_enabled: bool = audio.toggle()
				_show_banner("MÜZİK AÇIK" if music_enabled else "MÜZİK KAPALI", 1.1)


func _toggle_audio_panel() -> void:
	audio_panel.visible = not audio_panel.visible
	paused_game = audio_panel.visible
	if audio_panel.visible: pause_panel.visible = false


func _set_music_volume(value: float) -> void:
	music_volume_setting = clampf(value / 100.0, 0.0, 1.0)
	music_label.text = "MUSIC  %d%%" % int(round(value))
	pause_music_label.text = "MUSIC  %d%%" % int(round(value))
	music_slider.set_value_no_signal(value)
	pause_music_slider.set_value_no_signal(value)
	if audio != null: audio.set_music_volume(music_volume_setting)
	_save_best_score()


func _set_sfx_volume(value: float) -> void:
	sfx_volume_setting = clampf(value / 100.0, 0.0, 1.0)
	sfx_label.text = "SFX  %d%%" % int(round(value))
	pause_sfx_label.text = "SFX  %d%%" % int(round(value))
	sfx_slider.set_value_no_signal(value)
	pause_sfx_slider.set_value_no_signal(value)
	if audio != null: audio.set_sfx_volume(sfx_volume_setting)
	_save_best_score()


func _process(delta: float) -> void:
	_update_banner(delta)
	_update_camera(delta)
	if run_over or gameplay_locked or paused_game:
		return
	elapsed += delta
	event_spawn_timer -= delta
	freeze_all_timer = maxf(0.0, freeze_all_timer - delta)
	invincible_timer = maxf(0.0, invincible_timer - delta)
	if event_spawn_timer <= 0.0:
		event_spawn_timer += 180.0
		_spawn_map_events()
	_update_event_shield()
	web_sync_timer += delta
	if audio != null:
		var boss_active: bool = enemies.any(func(enemy: Dictionary) -> bool: return bool(enemy.get("boss", false)))
		audio.set_intensity(wave, boss_active)
	if web_sync_timer >= 10.0:
		web_sync_timer = 0.0
		_sync_web_progress(false)
	player_fire_cooldown = maxf(0.0, player_fire_cooldown - delta)
	impact_vfx_cooldown = maxf(0.0, impact_vfx_cooldown - delta)
	for weapon_id: String in weapon_cooldowns.keys():
		weapon_cooldowns[weapon_id] = maxf(0.0, float(weapon_cooldowns[weapon_id]) - delta)
	player_invulnerability = maxf(0.0, player_invulnerability - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0: combo = move_toward(combo, 1.0, delta * 2.0)
	heal_window -= delta
	for buff_id: String in buffs.keys():
		buffs[buff_id] = maxf(0.0, float(buffs[buff_id]) - delta)
	if heal_window <= 0.0:
		heal_window = 1.0
		healed_this_window = 0.0
	_update_player(delta)
	_update_weapon_systems(delta)
	_update_spawning(delta)
	_update_bullets(delta)
	_update_enemies(delta)
	_update_pickups(delta)
	_check_wave_clear()
	_update_hud()


func _update_player(delta: float) -> void:
	var horizontal: float = 0.0
	var vertical: float = 0.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): horizontal += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): horizontal -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): vertical += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): vertical -= 1.0
	var move_direction: Vector2 = Vector2(horizontal, vertical)
	var firing: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var aim_vector: Vector2 = get_global_mouse_position() - player.global_position
	if aim_vector.length_squared() > 0.001: player_aim_angle = aim_vector.angle()
	_move_player(move_direction, firing, delta)
	if firing:
		_fire_player_weapon()


func _move_player(move_direction: Vector2, firing: bool, delta: float) -> void:
	# Duvara doğru basılan ekseni iptal ederek kalan eksende tam hızla kaydırır.
	if player.position.x <= PLAYER_MIN.x + 2.0 and move_direction.x < 0.0: move_direction.x = 0.0
	if player.position.x >= PLAYER_MAX.x - 2.0 and move_direction.x > 0.0: move_direction.x = 0.0
	if player.position.y <= PLAYER_MIN.y + 2.0 and move_direction.y < 0.0: move_direction.y = 0.0
	if player.position.y >= PLAYER_MAX.y - 2.0 and move_direction.y > 0.0: move_direction.y = 0.0
	if move_direction.length_squared() > 1.0: move_direction = move_direction.normalized()
	var desired_facing: float = player_aim_angle
	if move_direction.length_squared() > 0.01 and not firing:
		desired_facing = move_direction.angle()
	player.rotation = lerp_angle(player.rotation, desired_facing, minf(1.0, delta * 14.0))
	if dash_requested:
		dash_requested = false
		if dash_cooldown <= 0.0:
			var dash_direction: Vector2 = move_direction
			if dash_direction.length_squared() < 0.01: dash_direction = Vector2.RIGHT.rotated(player_aim_angle)
			player.position += dash_direction.normalized() * 155.0
			player_invulnerability = 0.32
			dash_cooldown = dash_base_cooldown
			camera_shake = maxf(camera_shake, 5.0)
			audio.trigger("upgrade", 0.35)
			if bool(evolutions.get("phase", false)):
				_phase_blast(player.position)
	player.position += move_direction * player_speed * delta
	player.position.x = clampf(player.position.x, PLAYER_MIN.x, PLAYER_MAX.x)
	player.position.y = clampf(player.position.y, PLAYER_MIN.y, PLAYER_MAX.y)
	player.modulate.a = 0.42 if player_invulnerability > 0.0 else 1.0


func _fire_player_weapon() -> void:
	var base_angle: float = player_aim_angle
	var muzzle: Vector2 = player.position + Vector2.RIGHT.rotated(base_angle) * 48.0
	var haste: float = (player_fire_rate / 5.0) * (1.65 if float(buffs["rapid"]) > 0.0 else 1.0)
	var damage_power: float = player_damage * (1.55 if float(buffs["damage"]) > 0.0 else 1.0)
	var fired_any: bool = false
	var recoil_amount: float = 3.2
	for weapon_id: String in active_weapons:
		if float(weapon_cooldowns.get(weapon_id, 0.0)) > 0.0: continue
		var definition: Dictionary = _weapon_definition(weapon_id)
		weapon_cooldowns[weapon_id] = float(definition.get("cooldown", 0.5)) / maxf(0.55, haste)
		fired_any = true
		shot_count += 1
		if weapon_id == "pulse":
			for index: int in range(player_multishot):
				var spread: float = (float(index) - float(player_multishot - 1) * 0.5) * 0.095
				var critical: bool = randf() < player_crit
				var shot_damage: float = damage_power * (2.0 if critical else 1.0)
				_spawn_bullet(muzzle, Vector2.RIGHT.rotated(base_angle + spread) * player_bullet_speed, shot_damage, false, Color("ffe66d") if critical else Color("70eaff"), 1.8, critical, 2 if critical and bool(evolutions.get("rail", false)) else 0)
		elif weapon_id == "scatter":
			recoil_amount = maxf(recoil_amount, 8.5)
			for pellet: int in range(7):
				var scatter_angle: float = base_angle + (float(pellet) - 3.0) * 0.105 + randf_range(-0.025, 0.025)
				_spawn_bullet(muzzle, Vector2.RIGHT.rotated(scatter_angle) * randf_range(760.0, 890.0), damage_power * 0.52, false, Color("ffb56b"), 0.62)
		elif weapon_id == "trident":
			for lane: int in range(-1, 2):
				_spawn_bullet(muzzle, Vector2.RIGHT.rotated(base_angle + float(lane) * 0.14) * 880.0, damage_power * 0.78, false, Color("72ffa9"), 1.45, false, 1)
		elif weapon_id == "rail":
			recoil_amount = maxf(recoil_amount, 10.0)
			_spawn_bullet(muzzle, Vector2.RIGHT.rotated(base_angle) * 1320.0, damage_power * 2.9, false, Color("fff06a"), 1.35, true, 5)
			camera_shake = maxf(camera_shake, 5.0)
		elif weapon_id == "missile_weapon":
			recoil_amount = maxf(recoil_amount, 6.0)
			_spawn_bullet(muzzle, Vector2.RIGHT.rotated(base_angle) * 390.0, damage_power * 2.15, false, Color("ff7b52"), 3.4, true, 0, "missile", true, 62.0)
		elif weapon_id == "nova_weapon":
			for nova_index: int in range(12):
				var nova_angle: float = TAU * float(nova_index) / 12.0
				_spawn_bullet(player.position, Vector2.RIGHT.rotated(nova_angle) * 720.0, damage_power * 0.72, false, Color("bd8cff"), 1.4, false, 1, "nova")
			camera_shake = maxf(camera_shake, 7.0)
	if fired_any:
		_spawn_muzzle_flash(muzzle, base_angle, Color("70eaff"))
		var player_rig: CharacterMotion = player.get_node_or_null("MotionRig") as CharacterMotion
		if player_rig != null: player_rig.kick(recoil_amount)
		audio.trigger("shot", 0.6)


func _weapon_definition(weapon_id: String) -> Dictionary:
	for weapon: Dictionary in WEAPONS:
		if String(weapon["id"]) == weapon_id: return weapon
	return WEAPONS[0]


func _spawn_bullet(position: Vector2, velocity: Vector2, damage: float, hostile: bool, color: Color, life: float, large: bool = false, pierce: int = 0, kind: String = "", homing: bool = false, explosion_radius: float = 0.0) -> void:
	var bullet_node: Node2D = VisualFactory.create_bullet(color, hostile, large, kind)
	projectile_layer.add_child(bullet_node)
	bullet_node.position = position
	bullet_node.rotation = velocity.angle()
	bullets.append({"node": bullet_node, "velocity": velocity, "damage": damage, "life": life, "hostile": hostile, "color": color, "large": large, "radius": 8.0 if large else 5.0, "pierce": pierce, "hit_ids": [], "kind": kind, "homing": homing, "explosion_radius": explosion_radius})


func _spawn_muzzle_flash(position: Vector2, angle: float, color: Color) -> void:
	var flash: Node2D = VisualFactory.create_muzzle_flash(color)
	projectile_layer.add_child(flash)
	flash.position = position
	flash.rotation = angle
	flash.scale = Vector2(0.55, 0.55)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.25, 0.72), 0.075).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(flash, "modulate:a", 0.0, 0.09)
	tween.chain().tween_callback(flash.queue_free)


func _spawn_impact(position: Vector2, color: Color, critical: bool, damage: float) -> void:
	if not critical and impact_vfx_cooldown > 0.0: return
	if not critical: impact_vfx_cooldown = 0.035
	var impact: Node2D = VisualFactory.create_impact(color, critical)
	projectile_layer.add_child(impact)
	impact.position = position
	impact.rotation = randf_range(0.0, TAU)
	impact.scale = Vector2.ONE * 0.55
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(impact, "scale", Vector2.ONE * (1.65 if critical else 1.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(impact, "modulate:a", 0.0, 0.22).set_delay(0.04)
	tween.chain().tween_callback(impact.queue_free)
	if critical:
		_spawn_damage_number(position, damage, critical)


func _spawn_damage_number(position: Vector2, damage: float, critical: bool) -> void:
	var label: Label = Label.new()
	label.text = "%d%s" % [int(round(damage)), "!" if critical else ""]
	label.position = position + Vector2(randf_range(-10.0, 10.0), -24.0)
	label.z_index = 40
	label.add_theme_font_size_override("font_size", 21 if critical else 15)
	label.add_theme_color_override("font_color", Color("ffe66d") if critical else Color("bdf8ff"))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	projectile_layer.add_child(label)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0.0, -42.0), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.42).set_delay(0.12)
	tween.chain().tween_callback(label.queue_free)


func _phase_blast(center: Vector2) -> void:
	for index: int in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		var enemy_node: Node2D = enemy["node"] as Node2D
		if is_instance_valid(enemy_node) and enemy_node.position.distance_to(center) <= 105.0:
			enemy["health"] = float(enemy["health"]) - player_damage * 1.6
			enemies[index] = enemy
			if float(enemy["health"]) <= 0.0: _kill_enemy(index)


func _system_power() -> float:
	return 1.0 + float(perks.get("system_power", 0)) * 0.12


func _system_haste() -> float:
	return pow(0.91, float(perks.get("system_haste", 0)))


func _nearest_enemies(count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var candidates: Array[Dictionary] = enemies.duplicate()
	while result.size() < count and not candidates.is_empty():
		var best_index: int = 0
		var best_distance: float = INF
		for index: int in range(candidates.size()):
			var candidate_node: Node2D = candidates[index]["node"] as Node2D
			if not is_instance_valid(candidate_node): continue
			var distance: float = candidate_node.position.distance_squared_to(player.position)
			if distance < best_distance:
				best_distance = distance
				best_index = index
		result.append(candidates[best_index])
		candidates.remove_at(best_index)
	return result


func _refresh_shields() -> void:
	var level: int = int(perks.get("aegis", 0))
	var desired: int = 0 if level <= 0 else 1 + int(float(level - 1) / 2.0)
	while shield_nodes.size() > desired:
		var removed: Node2D = shield_nodes.pop_back()
		removed.queue_free()
	while shield_nodes.size() < desired:
		var shield: Node2D = VisualFactory.create_gem(18)
		shield.name = "AegisShield"
		shield.modulate = Color("8fa7ff")
		shield.scale = Vector2.ONE * 1.35
		projectile_layer.add_child(shield)
		shield_nodes.append(shield)


func _update_weapon_systems(delta: float) -> void:
	var missile_level: int = int(perks.get("missile", 0))
	var beam_level: int = int(perks.get("beam", 0))
	var aegis_level: int = int(perks.get("aegis", 0))
	var power: float = _system_power() * float(daily_protocol["damage"])
	var haste: float = _system_haste()
	missile_timer -= delta
	beam_timer -= delta
	shield_tick -= delta

	if missile_level > 0 and missile_timer <= 0.0 and not enemies.is_empty():
		var missile_targets: Array[Dictionary] = _nearest_enemies(1)
		if not missile_targets.is_empty():
			var target_node: Node2D = missile_targets[0]["node"] as Node2D
			var direction: Vector2 = player.position.direction_to(target_node.position)
			_spawn_bullet(player.position, direction * 360.0, (32.0 + float(missile_level) * 11.0) * power, false, Color("ffb35c"), 3.2, true, 0, "missile", true, 42.0 + float(missile_level) * 5.0)
		missile_timer = maxf(0.42, 2.55 - float(missile_level) * 0.16) * haste

	if beam_level > 0 and beam_timer <= 0.0 and not enemies.is_empty():
		var beam_targets: Array[Dictionary] = _nearest_enemies(1 + int(float(beam_level - 1) / 3.0))
		for target: Dictionary in beam_targets:
			var target_node: Node2D = target["node"] as Node2D
			if not is_instance_valid(target_node): continue
			var line: Line2D = Line2D.new()
			line.add_point(player.position)
			line.add_point(target_node.position)
			line.width = 6.0
			line.default_color = Color("8af8ff")
			line.antialiased = true
			projectile_layer.add_child(line)
			var beam_tween: Tween = create_tween()
			beam_tween.tween_property(line, "modulate:a", 0.0, 0.18)
			beam_tween.tween_callback(line.queue_free)
			var enemy_index: int = enemies.find(target)
			if enemy_index >= 0:
				target["health"] = float(target["health"]) - (20.0 + float(beam_level) * 9.0) * power
				enemies[enemy_index] = target
				if float(target["health"]) <= 0.0: _kill_enemy(enemy_index)
		beam_timer = maxf(0.72, 3.25 - float(beam_level) * 0.19) * haste
		audio.trigger("upgrade", 0.28)

	for index: int in range(shield_nodes.size()):
		var angle: float = elapsed * (1.65 + float(aegis_level) * 0.04) + TAU * float(index) / float(maxi(1, shield_nodes.size()))
		shield_nodes[index].position = player.position + Vector2.RIGHT.rotated(angle) * (55.0 + minf(18.0, float(aegis_level) * 2.0))
		shield_nodes[index].rotation = angle * 1.7

	if aegis_level > 0 and shield_tick <= 0.0:
		var damaged: Dictionary = {}
		for shield: Node2D in shield_nodes:
			for enemy_index: int in range(enemies.size() - 1, -1, -1):
				var enemy: Dictionary = enemies[enemy_index]
				var enemy_node: Node2D = enemy["node"] as Node2D
				if not is_instance_valid(enemy_node): continue
				var instance_id: int = enemy_node.get_instance_id()
				if damaged.has(instance_id): continue
				if shield.position.distance_to(enemy_node.position) <= float(enemy["radius"]) + 13.0:
					damaged[instance_id] = true
					enemy["health"] = float(enemy["health"]) - (11.0 + float(aegis_level) * 5.0) * power
					enemies[enemy_index] = enemy
					if float(enemy["health"]) <= 0.0: _kill_enemy(enemy_index)
		shield_tick = 0.34


func _explode_missile(position: Vector2, damage: float, radius: float) -> void:
	var blast: Polygon2D = VisualFactory.add_polygon(projectile_layer, VisualFactory.circle_polygon(Vector2.ZERO, radius, 28), Color(1.0, 0.45, 0.18, 0.28))
	blast.position = position
	blast.scale = Vector2.ONE * 0.25
	var blast_tween: Tween = create_tween()
	blast_tween.set_parallel(true)
	blast_tween.tween_property(blast, "scale", Vector2.ONE, 0.18)
	blast_tween.tween_property(blast, "modulate:a", 0.0, 0.22)
	blast_tween.chain().tween_callback(blast.queue_free)
	for index: int in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		var enemy_node: Node2D = enemy["node"] as Node2D
		if not is_instance_valid(enemy_node): continue
		var distance: float = enemy_node.position.distance_to(position)
		if distance > radius + float(enemy["radius"]): continue
		var falloff: float = clampf(1.0 - distance / (radius + float(enemy["radius"])), 0.35, 1.0)
		enemy["health"] = float(enemy["health"]) - damage * falloff
		enemies[index] = enemy
		if float(enemy["health"]) <= 0.0: _kill_enemy(index)
	camera_shake = maxf(camera_shake, 8.0)
	audio.trigger("hit", 0.65)


func _begin_wave(next_wave: int) -> void:
	wave = next_wave
	wave_state = "spawning"
	wave_defeated = 0
	var boss_wave: bool = wave % 10 == 0
	wave_mutation = ""
	if not boss_wave and wave % 4 == 0: wave_mutation = "ZIRHLI SÜRÜ"
	elif not boss_wave and wave % 3 == 0: wave_mutation = "SALDIRI SÜRÜSÜ"
	spawn_total = int(round((5.0 + float(wave) * 2.6) * float(daily_protocol["count"])))
	if wave_mutation == "SALDIRI SÜRÜSÜ": spawn_total = int(round(float(spawn_total) * 1.25))
	if wave % 10 == 9:
		spawn_total = int(round(float(spawn_total) * 2.65))
		wave_mutation = "MASSIVE XENO SWARM"
	if boss_wave: spawn_total = 6 + int(float(wave) / 10.0) * 3
	spawn_left = spawn_total
	spawn_cooldown = 0.35
	boss_panel.visible = false
	var banner_text: String = "WAVE %02d" % wave
	if boss_wave: banner_text = "BOSS SİNYALİ — %s" % BOSS_NAMES[_boss_variant() - 1]
	elif not wave_mutation.is_empty(): banner_text = "%s — WAVE %02d" % [wave_mutation, wave]
	_show_banner(banner_text, 2.0)
	if boss_wave: audio.trigger("boss", 1.0)


func _update_spawning(delta: float) -> void:
	if wave_state != "spawning": return
	spawn_cooldown -= delta
	if spawn_cooldown > 0.0: return
	if spawn_left <= 0:
		wave_state = "combat"
		return
	var is_boss: bool = wave % 10 == 0 and spawn_left == 1
	if is_boss: _spawn_boss()
	else: _spawn_enemy()
	spawn_left -= 1
	spawn_cooldown = 0.52 if wave % 10 == 0 else (0.065 if wave % 10 == 9 else maxf(0.12, 0.50 - float(wave) * 0.018))


func _spawn_enemy() -> void:
	var roll: float = randf()
	var kind: String = "crawler"
	if wave >= 6 and roll > 0.84: kind = "stalker"
	elif wave >= 4 and roll > 0.65: kind = "brute"
	elif wave >= 2 and roll > 0.40: kind = "spitter"
	var elite: bool = wave >= 3 and randf() < minf(0.25, 0.04 + float(wave) * 0.012)
	var enemy_node: Node2D = VisualFactory.create_enemy(kind, elite)
	entities.add_child(enemy_node)
	enemy_node.position = _random_edge_position()
	_reveal_spawn(enemy_node, Color("ffd166") if elite else Color("5df4dc"), false)
	var base_health: float = 34.0
	var base_speed: float = 88.0
	var base_damage: float = 10.0
	var radius: float = 15.0
	var value: int = 120
	if kind == "spitter":
		base_health = 52.0; base_speed = 76.0; base_damage = 8.0; radius = 17.0; value = 190
	elif kind == "brute":
		base_health = 118.0; base_speed = 57.0; base_damage = 19.0; radius = 27.0; value = 360
	elif kind == "stalker":
		base_health = 78.0; base_speed = 122.0; base_damage = 14.0; radius = 20.0; value = 290
	var health_scale: float = 1.0 + float(wave - 1) * 0.17 + pow(float(maxi(0, wave - 7)), 1.18) * 0.035
	var speed_scale: float = minf(1.68, 1.0 + float(wave - 1) * 0.027)
	var damage_scale: float = 1.0 + float(wave - 1) * 0.055
	health_scale *= 1.35 if wave_mutation == "ZIRHLI SÜRÜ" else 1.0
	speed_scale *= float(daily_protocol["speed"])
	if wave_mutation == "SALDIRI SÜRÜSÜ": speed_scale *= 1.10
	if elite:
		health_scale *= 2.0; speed_scale *= 1.12; damage_scale *= 1.32; value = int(float(value) * 2.5)
	enemies.append({"node": enemy_node, "kind": kind, "health": base_health * health_scale, "max_health": base_health * health_scale, "speed": base_speed * speed_scale, "damage": base_damage * damage_scale, "radius": radius, "value": value, "hit_cooldown": 0.0, "shoot_cooldown": randf_range(0.8, 2.0), "phase": randf_range(0.0, TAU), "spawn_grace": 0.72, "boss": false, "elite": elite})


func _spawn_boss() -> void:
	var variant: int = _boss_variant()
	var boss_node: Node2D = VisualFactory.create_boss(variant)
	entities.add_child(boss_node)
	boss_node.position = _random_edge_position()
	_reveal_spawn(boss_node, [Color("ff466b"), Color("56f5ff"), Color("d477ff")][variant - 1], true)
	var scale: float = 1.0 + float(wave) * 0.16 + pow(float(wave), 1.15) * 0.04
	var health: float = (720.0 + float(wave) * 55.0) * scale
	enemies.append({"node": boss_node, "kind": "boss", "variant": variant, "health": health, "max_health": health, "speed": 43.0 + float(wave) * 0.7, "damage": 25.0 + float(wave) * 1.1, "radius": 58.0, "value": 2800 + wave * 180, "hit_cooldown": 0.0, "shoot_cooldown": 0.9, "phase": 0.0, "spawn_grace": 1.15, "boss": true, "elite": false})
	boss_name_label.text = BOSS_NAMES[variant - 1]
	boss_health_bar.max_value = health
	boss_health_bar.value = health
	boss_panel.visible = true


func _reveal_spawn(enemy_node: Node2D, color: Color, boss_spawn: bool) -> void:
	var telegraph: Node2D = VisualFactory.create_spawn_telegraph(color, boss_spawn)
	projectile_layer.add_child(telegraph)
	telegraph.position = enemy_node.position
	enemy_node.modulate.a = 0.0
	var reveal: Tween = create_tween().set_parallel(true)
	reveal.tween_property(enemy_node, "modulate:a", 1.0, 0.46 if not boss_spawn else 0.82).set_ease(Tween.EASE_OUT)
	reveal.tween_property(telegraph, "scale", Vector2.ONE * (1.9 if boss_spawn else 1.45), 0.62).set_trans(Tween.TRANS_QUAD)
	reveal.tween_property(telegraph, "modulate:a", 0.0, 0.62).set_ease(Tween.EASE_IN)
	reveal.chain().tween_callback(telegraph.queue_free)


func _boss_variant() -> int:
	return (int(float(wave) / 10.0) - 1) % 3 + 1


func _random_edge_position() -> Vector2:
	# Oyuncunun nişan yönünün tam arkasında ve görüş alanının içinde spawn olmaz.
	for _attempt: int in range(28):
		var spawn_angle: float = player_aim_angle + randf_range(-2.12, 2.12)
		var candidate: Vector2 = player.position + Vector2.RIGHT.rotated(spawn_angle) * randf_range(610.0, 760.0)
		candidate.x = clampf(candidate.x, 46.0, WORLD_SIZE.x - 46.0)
		candidate.y = clampf(candidate.y, 46.0, WORLD_SIZE.y - 46.0)
		if candidate.distance_to(player.position) >= SPAWN_SAFE_DISTANCE:
			return candidate
	# Çok nadir dar açı durumlarında oyuncudan en uzak arena köşesini seç.
	var corners: Array[Vector2] = [Vector2(54.0, 54.0), Vector2(WORLD_SIZE.x - 54.0, 54.0), Vector2(54.0, WORLD_SIZE.y - 54.0), WORLD_SIZE - Vector2(54.0, 54.0)]
	var safest: Vector2 = corners[0]
	for corner: Vector2 in corners:
		if corner.distance_squared_to(player.position) > safest.distance_squared_to(player.position): safest = corner
	return safest


func _update_enemies(delta: float) -> void:
	var spatial_grid: Dictionary = {}
	for grid_index: int in range(enemies.size()):
		var grid_node: Node2D = enemies[grid_index].get("node") as Node2D
		if not is_instance_valid(grid_node): continue
		var cell: Vector2i = Vector2i(floori(grid_node.position.x / 96.0), floori(grid_node.position.y / 96.0))
		var bucket: Array = spatial_grid.get(cell, [])
		bucket.append(grid_index)
		spatial_grid[cell] = bucket
	for index: int in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		var enemy_node: Node2D = enemy["node"] as Node2D
		if not is_instance_valid(enemy_node):
			enemies.remove_at(index); continue
		var kind: String = String(enemy["kind"])
		var direction: Vector2 = enemy_node.position.direction_to(player.position)
		var distance: float = enemy_node.position.distance_to(player.position)
		var movement: Vector2 = direction
		var phase: float = float(enemy["phase"]) + delta
		enemy["phase"] = phase
		if kind == "spitter" and distance < 250.0: movement = -direction * 0.38
		elif kind == "stalker": movement = (direction + direction.orthogonal() * sin(phase * 4.0) * 0.72).normalized()
		elif kind == "boss" and distance < 230.0: movement = -direction * 0.48
		var separation: Vector2 = Vector2.ZERO
		var own_cell: Vector2i = Vector2i(floori(enemy_node.position.x / 96.0), floori(enemy_node.position.y / 96.0))
		for cell_y: int in range(own_cell.y - 1, own_cell.y + 2):
			for cell_x: int in range(own_cell.x - 1, own_cell.x + 2):
				var nearby: Array = spatial_grid.get(Vector2i(cell_x, cell_y), [])
				for other_value: Variant in nearby:
					var other_index: int = int(other_value)
					if other_index == index or other_index >= enemies.size(): continue
					var other_node: Node2D = enemies[other_index].get("node") as Node2D
					if not is_instance_valid(other_node): continue
					var combined_radius: float = float(enemy["radius"]) + float(enemies[other_index].get("radius", 16.0)) + 8.0
					var gap: float = enemy_node.position.distance_to(other_node.position)
					if gap > 0.01 and gap < combined_radius:
						separation += other_node.position.direction_to(enemy_node.position) * (1.0 - gap / combined_radius)
		if separation.length_squared() > 0.001:
			movement = (movement + separation.normalized() * 1.15).normalized()
		var slow_factor: float = 0.0 if freeze_all_timer > 0.0 else (0.48 if float(buffs["cryo"]) > 0.0 else 1.0)
		if freeze_all_timer > 0.0:
			enemy_node.modulate = Color(0.52, 0.86, 1.35, enemy_node.modulate.a)
		elif enemy_node.modulate.b > 1.15 and enemy_node.modulate.r < 0.8:
			enemy_node.modulate = Color(1.0, 1.0, 1.0, enemy_node.modulate.a)
		enemy_node.position += movement * float(enemy["speed"]) * slow_factor * delta
		enemy_node.position.x = clampf(enemy_node.position.x, 32.0, WORLD_SIZE.x - 32.0)
		enemy_node.position.y = clampf(enemy_node.position.y, 32.0, WORLD_SIZE.y - 32.0)
		enemy_node.rotation = direction.angle()
		enemy["spawn_grace"] = maxf(0.0, float(enemy.get("spawn_grace", 0.0)) - delta)
		enemy["hit_cooldown"] = maxf(0.0, float(enemy["hit_cooldown"]) - delta)
		enemy["shoot_cooldown"] = float(enemy["shoot_cooldown"]) - delta
		if freeze_all_timer <= 0.0 and kind == "boss" and float(enemy["spawn_grace"]) <= 0.0: _update_boss_attack(enemy)
		elif freeze_all_timer <= 0.0 and kind == "spitter" and float(enemy["spawn_grace"]) <= 0.0 and float(enemy["shoot_cooldown"]) <= 0.0:
			_spawn_bullet(enemy_node.position, direction * (235.0 + float(wave) * 3.0), float(enemy["damage"]), true, Color("ff9a55"), 4.0)
			enemy["shoot_cooldown"] = maxf(0.85, 1.85 - float(wave) * 0.035)
		if freeze_all_timer <= 0.0 and float(enemy["spawn_grace"]) <= 0.0 and distance <= float(enemy["radius"]) + 18.0 and float(enemy["hit_cooldown"]) <= 0.0:
			enemy["hit_cooldown"] = 0.62
			_damage_player(float(enemy["damage"]))
		enemies[index] = enemy


func _update_boss_attack(enemy: Dictionary) -> void:
	if float(enemy["shoot_cooldown"]) > 0.0: return
	var boss_node: Node2D = enemy["node"] as Node2D
	var variant: int = int(enemy["variant"])
	var phase: float = float(enemy["phase"])
	var aimed_angle: float = boss_node.position.angle_to_point(player.position)
	if variant == 1:
		for shot: int in range(12):
			var radial_angle: float = TAU * float(shot) / 12.0 + phase * 0.18
			_spawn_bullet(boss_node.position, Vector2.RIGHT.rotated(radial_angle) * 185.0, 12.0 + float(wave) * 0.42, true, Color("ff5475"), 4.5, true)
		enemy["shoot_cooldown"] = 1.65
	elif variant == 2:
		for arm: int in range(4):
			var spiral_angle: float = phase * 2.4 + TAU * float(arm) / 4.0
			_spawn_bullet(boss_node.position, Vector2.RIGHT.rotated(spiral_angle) * 255.0, 9.0 + float(wave) * 0.34, true, Color("65f5ff"), 3.7)
		enemy["shoot_cooldown"] = 0.34
	else:
		for lane: int in range(-2, 3):
			var lane_angle: float = aimed_angle + float(lane) * 0.12
			var side_offset: Vector2 = Vector2.RIGHT.rotated(aimed_angle + PI * 0.5) * float(lane) * 13.0
			_spawn_bullet(boss_node.position + side_offset, Vector2.RIGHT.rotated(lane_angle) * 225.0, 14.0 + float(wave) * 0.45, true, Color("d985ff"), 4.2, true)
		enemy["shoot_cooldown"] = 1.18
	audio.trigger("boss", 0.18)


func _update_bullets(delta: float) -> void:
	for bullet_index: int in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[bullet_index]
		var bullet_node: Node2D = bullet["node"] as Node2D
		if not is_instance_valid(bullet_node):
			bullets.remove_at(bullet_index); continue
		var velocity: Vector2 = bullet["velocity"] as Vector2
		if bool(bullet["homing"]) and not enemies.is_empty():
			var targets: Array[Dictionary] = _nearest_enemies(1)
			if not targets.is_empty():
				var target_node: Node2D = targets[0]["node"] as Node2D
				var current_angle: float = velocity.angle()
				var desired_angle: float = bullet_node.position.angle_to_point(target_node.position)
				var turn: float = clampf(angle_difference(current_angle, desired_angle), -delta * 4.2, delta * 4.2)
				velocity = Vector2.RIGHT.rotated(current_angle + turn) * velocity.length()
				bullet["velocity"] = velocity
				bullet_node.rotation = velocity.angle()
		bullet_node.position += velocity * delta
		bullet["life"] = float(bullet["life"]) - delta
		var remove_bullet: bool = float(bullet["life"]) <= 0.0
		if remove_bullet and String(bullet["kind"]) == "missile":
			_explode_missile(bullet_node.position, float(bullet["damage"]), float(bullet["explosion_radius"]))
		if not remove_bullet and bool(bullet["hostile"]):
			for shield: Node2D in shield_nodes:
				if is_instance_valid(shield) and bullet_node.position.distance_to(shield.position) <= float(bullet["radius"]) + 13.0:
					remove_bullet = true
					break
			if not remove_bullet and bullet_node.position.distance_to(player.position) <= float(bullet["radius"]) + 16.0:
				var hostile_color: Color = bullet.get("color", Color("ff806b"))
				_spawn_impact(player.position, hostile_color, false, float(bullet["damage"]))
				_damage_player(float(bullet["damage"])); remove_bullet = true
		elif not remove_bullet:
			for enemy_index: int in range(enemies.size() - 1, -1, -1):
				var enemy: Dictionary = enemies[enemy_index]
				var enemy_node: Node2D = enemy["node"] as Node2D
				if not is_instance_valid(enemy_node): continue
				if float(enemy.get("spawn_grace", 0.0)) > 0.0: continue
				var hit_ids: Array = bullet["hit_ids"] as Array
				if enemy_node.get_instance_id() in hit_ids: continue
				if bullet_node.position.distance_to(enemy_node.position) <= float(enemy["radius"]) + float(bullet["radius"]):
					if String(bullet["kind"]) == "missile":
						_explode_missile(bullet_node.position, float(bullet["damage"]), float(bullet["explosion_radius"]))
						remove_bullet = true
						break
					var dealt: float = minf(float(enemy["health"]), float(bullet["damage"]))
					enemy["health"] = float(enemy["health"]) - float(bullet["damage"])
					enemies[enemy_index] = enemy
					var critical_hit: bool = bool(bullet.get("large", false))
					var impact_color: Color = bullet.get("color", Color("70eaff"))
					_spawn_impact(bullet_node.position, impact_color, critical_hit, dealt)
					enemy_node.position += velocity.normalized() * (13.0 if critical_hit else 6.0)
					var enemy_rig: CharacterMotion = enemy_node.get_node_or_null("MotionRig") as CharacterMotion
					if enemy_rig != null: enemy_rig.kick(5.5 if critical_hit else 2.8)
					camera_shake = maxf(camera_shake, 4.5 if critical_hit else 1.7)
					audio.trigger("impact", 0.75 if critical_hit else 0.34)
					enemy_node.modulate = Color(2.2, 2.2, 2.2, 1.0)
					var hit_tween: Tween = create_tween()
					hit_tween.tween_property(enemy_node, "modulate", Color.WHITE, 0.09)
					_apply_lifesteal(dealt)
					hit_ids.append(enemy_node.get_instance_id())
					bullet["hit_ids"] = hit_ids
					if int(bullet["pierce"]) > 0: bullet["pierce"] = int(bullet["pierce"]) - 1
					else: remove_bullet = true
					if bool(enemy["boss"]): boss_health_bar.value = maxf(0.0, float(enemy["health"]))
					if float(enemy["health"]) <= 0.0: _kill_enemy(enemy_index)
					break
		if remove_bullet:
			bullet_node.queue_free(); bullets.remove_at(bullet_index)
		else: bullets[bullet_index] = bullet


func _apply_lifesteal(damage_dealt: float) -> void:
	var level: int = int(perks.get("lifesteal", 0))
	if level <= 0 or player_health >= player_max_health: return
	var ratios: Array[float] = [0.0, 0.007, 0.010, 0.013]
	var caps: Array[float] = [0.0, 3.0, 4.0, 5.0]
	var available: float = maxf(0.0, caps[level] - healed_this_window)
	var healing: float = minf(damage_dealt * ratios[level], available)
	if healing <= 0.0: return
	player_health = minf(player_max_health, player_health + healing)
	healed_this_window += healing


func _kill_enemy(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size(): return
	var enemy: Dictionary = enemies[enemy_index]
	var enemy_node: Node2D = enemy["node"] as Node2D
	var death_position: Vector2 = Vector2.ZERO
	if is_instance_valid(enemy_node):
		death_position = enemy_node.position; enemy_node.queue_free()
	enemies.remove_at(enemy_index)
	combo = minf(5.0, combo + (0.18 if combo_timer > 0.0 else 0.0))
	combo_timer = 2.2
	kills += 1; wave_defeated += 1; score += int(round(float(enemy["value"]) * float(daily_protocol["score"]) * combo))
	_spawn_pickup(death_position, maxi(1, int(float(enemy["value"]) / 120.0)))
	if String(daily_quest["id"]) == "hunter": quest_progress += 1
	if bool(enemy["elite"]) and String(daily_quest["id"]) == "elite": quest_progress += 1
	if bool(enemy["boss"]) and String(daily_quest["id"]) == "boss": quest_progress += 1
	_check_quest_completion()
	if bool(enemy["elite"]) or bool(enemy["boss"]): _spawn_powerup(death_position)
	if bool(enemy["boss"]):
		void_shards += 5; boss_panel.visible = false; camera_shake = 18.0; score += wave * 500; audio.trigger("boss", 1.0)
	elif bool(enemy["elite"]):
		void_shards += 1; camera_shake = maxf(camera_shake, 6.0); audio.trigger("kill", 0.7)
	else:
		camera_shake = maxf(camera_shake, 3.0); audio.trigger("kill", 0.48)


func _check_quest_completion() -> void:
	if quest_completed or quest_progress < int(daily_quest["target"]): return
	quest_completed = true
	completed_daily_key = daily_key
	void_shards += 3
	_show_banner("GÜNLÜK GÖREV TAMAMLANDI — +3 VOID", 2.8)
	_save_best_score()


func _spawn_pickup(position: Vector2, value: int) -> void:
	var pickup_node: Node2D = VisualFactory.create_gem(value)
	pickup_layer.add_child(pickup_node)
	pickup_node.position = position
	pickups.append({"node": pickup_node, "kind": "shard", "value": value, "life": 12.0})


func _spawn_powerup(position: Vector2) -> void:
	var ids: Array[String] = ["rapid", "damage", "cryo"]
	var colors: Array[Color] = [Color("56f5ff"), Color("ff667f"), Color("9d8cff")]
	var selected: int = randi_range(0, ids.size() - 1)
	var pickup_node: Node2D = VisualFactory.create_gem(18)
	pickup_node.scale = Vector2.ONE * 1.55
	pickup_node.modulate = colors[selected]
	pickup_layer.add_child(pickup_node)
	pickup_node.position = position + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
	pickups.append({"node": pickup_node, "kind": ids[selected], "value": 0, "life": 15.0})


func _spawn_map_events() -> void:
	var used_positions: Array[Vector2] = []
	for event_kind: String in ["blast", "freeze", "shield"]:
		var event_node: Node2D = VisualFactory.create_event_pickup(event_kind)
		pickup_layer.add_child(event_node)
		event_node.position = _random_event_position(used_positions)
		used_positions.append(event_node.position)
		pickups.append({"node": event_node, "kind": "event_%s" % event_kind, "value": 0, "life": 75.0})
	_show_banner("MAP EVENTS ONLINE — BLAST • FREEZE • SHIELD", 3.0)
	audio.trigger("upgrade", 1.0)


func _random_event_position(used_positions: Array[Vector2]) -> Vector2:
	for _attempt: int in range(30):
		var candidate: Vector2 = Vector2(randf_range(130.0, WORLD_SIZE.x - 130.0), randf_range(130.0, WORLD_SIZE.y - 130.0))
		if candidate.distance_to(player.position) < 280.0: continue
		var separated: bool = true
		for used: Vector2 in used_positions:
			if candidate.distance_to(used) < 320.0: separated = false
		if separated: return candidate
	return WORLD_SIZE * Vector2(randf_range(0.25, 0.75), randf_range(0.25, 0.75))


func _activate_map_event(event_kind: String) -> void:
	if event_kind == "event_blast":
		_activate_blast()
	elif event_kind == "event_freeze":
		freeze_all_timer = 12.0
		for enemy: Dictionary in enemies:
			var enemy_node: Node2D = enemy["node"] as Node2D
			if is_instance_valid(enemy_node): enemy_node.modulate = Color(0.52, 0.86, 1.35, enemy_node.modulate.a)
		_show_banner("ABSOLUTE FREEZE — 12 SECONDS", 2.2)
	elif event_kind == "event_shield":
		invincible_timer = 30.0
		if event_shield == null or not is_instance_valid(event_shield):
			event_shield = VisualFactory.create_event_shield()
			projectile_layer.add_child(event_shield)
		_show_banner("VOID SHIELD — 30 SECONDS", 2.2)
	audio.trigger("upgrade", 1.0)


func _activate_blast() -> void:
	var blast: Polygon2D = VisualFactory.add_polygon(projectile_layer, VisualFactory.circle_polygon(Vector2.ZERO, 1120.0, 48), Color(1.0, 0.28, 0.08, 0.34))
	blast.position = player.position
	blast.scale = Vector2.ONE * 0.04
	var blast_tween: Tween = create_tween().set_parallel(true)
	blast_tween.tween_property(blast, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	blast_tween.tween_property(blast, "modulate:a", 0.0, 0.62).set_delay(0.18)
	blast_tween.chain().tween_callback(blast.queue_free)
	for index: int in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		if bool(enemy.get("boss", false)):
			enemy["health"] = maxf(1.0, float(enemy["health"]) - float(enemy["max_health"]) * 0.35)
			enemies[index] = enemy
			boss_health_bar.value = float(enemy["health"])
		else:
			_kill_enemy(index)
	camera_shake = 28.0
	_show_banner("TOTAL BLAST — MAP CLEARED", 2.4)


func _update_event_shield() -> void:
	if event_shield == null or not is_instance_valid(event_shield): return
	if invincible_timer <= 0.0:
		event_shield.queue_free()
		event_shield = null
		return
	event_shield.position = player.position
	event_shield.rotation += 0.025
	event_shield.modulate.a = 0.45 + sin(elapsed * 5.0) * 0.22


func _update_pickups(delta: float) -> void:
	for index: int in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[index]
		var pickup_node: Node2D = pickup["node"] as Node2D
		if not is_instance_valid(pickup_node): pickups.remove_at(index); continue
		pickup["life"] = float(pickup["life"]) - delta
		pickup_node.rotation += delta * 2.5
		var distance: float = pickup_node.position.distance_to(player.position)
		var magnet_range: float = 155.0 + float(perks.get("magnet", 0)) * 24.0
		if distance < magnet_range:
			pickup_node.position = pickup_node.position.move_toward(player.position, (520.0 + float(perks.get("magnet", 0)) * 22.0) * delta)
			distance = pickup_node.position.distance_to(player.position)
		if distance < 22.0:
			var pickup_kind: String = String(pickup["kind"])
			if pickup_kind == "shard": score += int(pickup["value"]) * 18
			elif pickup_kind.begins_with("event_"):
				_activate_map_event(pickup_kind)
			else:
				buffs[pickup_kind] = 8.0 if pickup_kind != "cryo" else 3.5
				_show_banner("GÜÇLENDİRME: %s" % pickup_kind.to_upper(), 1.2)
				audio.trigger("upgrade", 0.7)
			pickup_node.queue_free(); pickups.remove_at(index)
		elif float(pickup["life"]) <= 0.0:
			pickup_node.queue_free(); pickups.remove_at(index)
		else: pickups[index] = pickup


func _check_wave_clear() -> void:
	if wave_state == "combat" and spawn_left == 0 and enemies.is_empty():
		wave_state = "cleared"
		_show_upgrade_panel()


func _show_upgrade_panel() -> void:
	gameplay_locked = true
	level_panel.visible = true
	_roll_upgrade_offers()
	audio.trigger("upgrade", 0.8)


func _roll_upgrade_offers() -> void:
	current_choices.clear()
	if active_weapons.size() < MAX_ACTIVE_WEAPONS:
		var weapon_candidates: Array[Dictionary] = []
		for weapon: Dictionary in WEAPONS:
			if String(weapon["id"]) not in active_weapons: weapon_candidates.append(weapon.duplicate())
		weapon_candidates.shuffle()
		while current_choices.size() < 2 and not weapon_candidates.is_empty():
			var weapon_offer: Dictionary = weapon_candidates.pop_back()
			weapon_offer["id"] = "weapon:%s" % String(weapon_offer["id"])
			weapon_offer["rarity"] = "WEAPON"
			weapon_offer["levels"] = 1
			current_choices.append(weapon_offer)
	var available: Array[Dictionary] = []
	for upgrade: Dictionary in UPGRADES:
		if int(perks.get(String(upgrade["id"]), 0)) < int(upgrade["max"]): available.append(upgrade.duplicate())
	available.shuffle()
	while current_choices.size() < 3 and not available.is_empty():
		var offer: Dictionary = available.pop_back()
		var rarity_roll: float = randf() - minf(0.12, float(wave) * 0.004)
		var rarity: String = "STANDART"
		var levels: int = 1
		if rarity_roll < 0.08:
			rarity = "EFSANEVİ"; levels = 3
		elif rarity_roll < 0.30:
			rarity = "NADİR"; levels = 2
		levels = mini(levels, int(offer["max"]) - int(perks.get(String(offer["id"]), 0)))
		offer["rarity"] = rarity
		offer["levels"] = levels
		current_choices.append(offer)
	while current_choices.size() < 3: current_choices.append({"id": "repair", "name": "SAHA TAMİRİ", "desc": "+35 can", "max": 99, "rarity": "STANDART", "levels": 1})
	for index: int in range(3):
		var choice: Dictionary = current_choices[index]
		if String(choice["id"]).begins_with("weapon:"):
			choice_buttons[index].text = "WEAPON SLOT %d/%d  •  %s\n%s" % [active_weapons.size() + 1, MAX_ACTIVE_WEAPONS, String(choice["name"]), String(choice["desc"])]
			choice_buttons[index].modulate = Color("65eaff")
		else:
			var perk_level: int = int(perks.get(String(choice["id"]), 0))
			choice_buttons[index].text = "%s  •  %s  [Seviye %d→%d]\n%s" % [String(choice["rarity"]), String(choice["name"]), perk_level, perk_level + int(choice["levels"]), String(choice["desc"])]
			choice_buttons[index].modulate = Color("ffe07a") if String(choice["rarity"]) == "EFSANEVİ" else (Color("a987ff") if String(choice["rarity"]) == "NADİR" else Color.WHITE)
	reroll_button.disabled = rerolls <= 0
	reroll_button.text = "YENİDEN ÇEVİR  •  %d" % rerolls
	build_label.text = _build_summary()


func _reroll_upgrades() -> void:
	if not gameplay_locked or rerolls <= 0: return
	rerolls -= 1
	_roll_upgrade_offers()
	audio.trigger("upgrade", 0.45)


func _choose_upgrade(index: int) -> void:
	if not gameplay_locked or index < 0 or index >= current_choices.size(): return
	_apply_upgrade(String(current_choices[index]["id"]), int(current_choices[index]["levels"]))
	_check_evolutions()
	level_panel.visible = false
	gameplay_locked = false
	_begin_wave(wave + 1)
	_update_hud()


func _apply_upgrade(id: String, levels: int = 1) -> void:
	if id.begins_with("weapon:"):
		var weapon_id: String = id.trim_prefix("weapon:")
		if active_weapons.size() < MAX_ACTIVE_WEAPONS and weapon_id not in active_weapons:
			active_weapons.append(weapon_id)
			weapon_cooldowns[weapon_id] = 0.0
			_show_banner("WEAPON ACQUIRED — %s" % String(_weapon_definition(weapon_id)["name"]), 2.2)
		return
	if id == "repair":
		player_health = minf(player_max_health, player_health + 35.0); return
	for _level: int in range(levels):
		perks[id] = int(perks.get(id, 0)) + 1
		if id == "damage": player_damage *= 1.22
		elif id == "fire_rate": player_fire_rate *= 1.18
		elif id == "armor": player_max_health += 25.0; player_health = minf(player_max_health, player_health + 25.0)
		elif id == "multishot": player_multishot += 1
		elif id == "speed": player_speed *= 1.14
		elif id == "crit": player_crit = minf(0.48, player_crit + 0.08)
		elif id == "dash": dash_base_cooldown *= 0.82
	if id == "aegis": _refresh_shields()


func _check_evolutions() -> void:
	for evolution: Dictionary in EVOLUTIONS:
		var evolution_id: String = String(evolution["id"])
		if bool(evolutions.get(evolution_id, false)): continue
		var requirements: Dictionary = evolution["requires"] as Dictionary
		var unlocked: bool = true
		for perk_id: String in requirements.keys():
			if int(perks.get(perk_id, 0)) < int(requirements[perk_id]): unlocked = false
		if unlocked:
			evolutions[evolution_id] = true
			_show_banner("SİLAH EVRİMİ — %s" % String(evolution["name"]), 2.4)
			audio.trigger("upgrade", 1.0)


func _build_summary() -> String:
	var weapon_names: Array[String] = []
	for weapon_id: String in active_weapons: weapon_names.append(String(_weapon_definition(weapon_id)["name"]))
	var names: Array[String] = []
	for evolution: Dictionary in EVOLUTIONS:
		if bool(evolutions.get(String(evolution["id"]), false)): names.append(String(evolution["name"]))
	var evolution_text: String = "EVRİM YOK" if names.is_empty() else ", ".join(names)
	return "SİLAHLAR %d/%d: %s\nEVRİMLER: %s" % [active_weapons.size(), MAX_ACTIVE_WEAPONS, ", ".join(weapon_names), evolution_text]


func _damage_player(amount: float) -> void:
	if player_invulnerability > 0.0 or invincible_timer > 0.0 or run_over: return
	player_health -= amount
	player_invulnerability = 0.24
	camera_shake = maxf(camera_shake, 9.0)
	audio.trigger("hit", 0.85)
	if player_health <= 0.0:
		player_health = 0.0; _game_over()


func _game_over() -> void:
	run_over = true; gameplay_locked = true
	runs += 1
	best_score = maxi(best_score, score)
	best_wave = maxi(best_wave, wave)
	_save_best_score()
	game_over_stats.text = "Wave %d  •  %d imha  •  %d puan\nEn iyi: %d  •  %d VOID  •  Süre %02d:%02d" % [wave, kills, score, best_score, void_shards, int(elapsed / 60.0), int(elapsed) % 60]
	game_over_panel.visible = true
	_sync_web_progress(true)
	audio.trigger("boss", 0.7)


func _sync_web_progress(finished: bool) -> void:
	if web_bridge == null:
		return
	if finished:
		web_bridge.finish(score, wave, kills, int(elapsed))
	else:
		web_bridge.heartbeat(score, wave, kills, int(elapsed))


func _restart() -> void:
	get_tree().reload_current_scene()


func _show_banner(text: String, duration: float) -> void:
	wave_banner.text = text; wave_banner.visible = true; wave_banner.modulate.a = 1.0; banner_timer = duration


func _update_banner(delta: float) -> void:
	if banner_timer <= 0.0: return
	banner_timer -= delta
	wave_banner.modulate.a = clampf(banner_timer * 2.0, 0.0, 1.0)
	if banner_timer <= 0.0:
		wave_banner.visible = false; wave_banner.modulate.a = 1.0


func _update_camera(delta: float) -> void:
	var desired: Vector2 = SCREEN_SIZE * 0.5 - player.position
	desired.x = clampf(desired.x, SCREEN_SIZE.x - WORLD_SIZE.x, 0.0)
	desired.y = clampf(desired.y, SCREEN_SIZE.y - WORLD_SIZE.y, 0.0)
	var follow_weight: float = 1.0 - exp(-delta * 7.5)
	camera_origin = camera_origin.lerp(desired, follow_weight)
	var shake_offset: Vector2 = Vector2.ZERO
	if camera_shake > 0.05:
		shake_offset = Vector2(randf_range(-camera_shake, camera_shake), randf_range(-camera_shake, camera_shake))
		camera_shake = move_toward(camera_shake, 0.0, delta * 32.0)
	else:
		camera_shake = 0.0
	world.position = camera_origin + shake_offset


func _update_hud() -> void:
	info_label.text = "WAVE %02d   KILLS %d   SCORE %d" % [wave, kills, score]
	health_bar.max_value = player_max_health; health_bar.value = player_health
	health_text.text = "HEALTH  %d / %d" % [int(ceil(player_health)), int(player_max_health)]
	var health_ratio: float = player_health / maxf(1.0, player_max_health)
	health_bar.modulate = Color("3aff7d") if health_ratio > 0.55 else (Color("ffd54a") if health_ratio > 0.25 else Color("ff4f62"))
	health_text.modulate = health_bar.modulate
	wave_bar.max_value = maxi(1, spawn_total); wave_bar.value = mini(spawn_total, wave_defeated)
	var lifesteal_level: int = int(perks.get("lifesteal", 0))
	stats_label.text = "DMG %.0f   ROF %.1f   COMBO x%.1f\nWEAPONS %d/%d   AEGIS %d\nSYS +%d%%  HIZ %d  LS %d/3" % [player_damage, player_fire_rate, combo, active_weapons.size(), MAX_ACTIVE_WEAPONS, int(perks.get("aegis", 0)), int(float(perks.get("system_power", 0)) * 12.0), int(perks.get("system_haste", 0)), lifesteal_level]
	var quest_state: String = "TAMAMLANDI" if quest_completed else "%d/%d" % [quest_progress, int(daily_quest["target"])]
	var event_seconds: int = maxi(0, int(ceil(event_spawn_timer)))
	var status_text: String = ""
	if invincible_timer > 0.0: status_text = "  •  SHIELD %ds" % int(ceil(invincible_timer))
	elif freeze_all_timer > 0.0: status_text = "  •  FREEZE %ds" % int(ceil(freeze_all_timer))
	mission_label.text = "GÖREV: %s\n%s  •  %s\nEVENT %02d:%02d%s  •  VOID %d" % [String(daily_quest["name"]), String(daily_quest["desc"]), quest_state, int(event_seconds / 60.0), event_seconds % 60, status_text, void_shards]


func _build_background() -> void:
	for x_value: int in range(0, int(WORLD_SIZE.x) + 1, 112): VisualFactory.add_line(grid, Vector2(float(x_value), 0.0), Vector2(float(x_value), WORLD_SIZE.y), 1.0, Color(0.10, 0.34, 0.48, 0.06))
	for y_value: int in range(0, int(WORLD_SIZE.y) + 1, 112): VisualFactory.add_line(grid, Vector2(0.0, float(y_value)), Vector2(WORLD_SIZE.x, float(y_value)), 1.0, Color(0.10, 0.34, 0.48, 0.06))
	VisualFactory.add_line(grid, Vector2.ZERO, Vector2(WORLD_SIZE.x, 0.0), 4.0, Color(0.28, 0.88, 1.0, 0.28))
	VisualFactory.add_line(grid, Vector2(WORLD_SIZE.x, 0.0), WORLD_SIZE, 4.0, Color(0.28, 0.88, 1.0, 0.28))
	VisualFactory.add_line(grid, WORLD_SIZE, Vector2(0.0, WORLD_SIZE.y), 4.0, Color(0.28, 0.88, 1.0, 0.28))
	VisualFactory.add_line(grid, Vector2(0.0, WORLD_SIZE.y), Vector2.ZERO, 4.0, Color(0.28, 0.88, 1.0, 0.28))
	for _star: int in range(92):
		var star: Polygon2D = Polygon2D.new()
		star.polygon = VisualFactory.circle_polygon(Vector2.ZERO, randf_range(0.7, 2.2), 8)
		star.color = Color(0.45, 0.82, 1.0, randf_range(0.08, 0.28))
		star.position = Vector2(randf_range(18.0, WORLD_SIZE.x - 18.0), randf_range(18.0, WORLD_SIZE.y - 18.0))
		grid.add_child(star)
	for _crystal: int in range(18):
		var crystal: Polygon2D = VisualFactory.add_polygon(grid, PackedVector2Array([Vector2(0.0, -8.0), Vector2(5.0, 3.0), Vector2(0.0, 12.0), Vector2(-5.0, 3.0)]), Color(0.16, 0.82, 1.0, randf_range(0.10, 0.24)))
		crystal.position = Vector2(randf_range(80.0, WORLD_SIZE.x - 80.0), randf_range(80.0, WORLD_SIZE.y - 80.0))
		crystal.rotation = randf_range(0.0, TAU)


func _load_best_score() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://neonfall_save.cfg") == OK:
		best_score = int(config.get_value("records", "best_score", 0))
		best_wave = int(config.get_value("records", "best_wave", 1))
		void_shards = int(config.get_value("meta", "void_shards", 0))
		runs = int(config.get_value("meta", "runs", 0))
		completed_daily_key = String(config.get_value("daily", "completed_key", ""))
		music_volume_setting = float(config.get_value("audio", "music", 0.52))
		sfx_volume_setting = float(config.get_value("audio", "sfx", 0.78))


func _save_best_score() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("records", "best_score", best_score)
	config.set_value("records", "best_wave", best_wave)
	config.set_value("meta", "void_shards", void_shards)
	config.set_value("meta", "runs", runs)
	config.set_value("daily", "completed_key", completed_daily_key)
	config.set_value("audio", "music", music_volume_setting)
	config.set_value("audio", "sfx", sfx_volume_setting)
	config.save("user://neonfall_save.cfg")


func _select_daily_content() -> void:
	var date: Dictionary = Time.get_date_dict_from_system()
	daily_key = "%04d-%02d-%02d" % [int(date["year"]), int(date["month"]), int(date["day"])]
	var day_seed: int = int(date["year"]) * 372 + int(date["month"]) * 31 + int(date["day"])
	daily_protocol = PROTOCOLS[absi(day_seed) % PROTOCOLS.size()].duplicate(true)
	daily_quest = QUESTS[absi(day_seed + 1) % QUESTS.size()].duplicate(true)
	quest_completed = completed_daily_key == daily_key
	if quest_completed: quest_progress = int(daily_quest["target"])
