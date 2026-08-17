class_name RunHUD
extends CanvasLayer

@export_node_path("CharacterBody2D") var player_path: NodePath
@export_node_path("Node") var exp_manager_path: NodePath
@export_node_path("Node") var wave_manager_path: NodePath

@onready var player: ModularRobotPlayer = get_node(player_path) as ModularRobotPlayer
@onready var exp_manager: ExpManager = get_node(exp_manager_path) as ExpManager
@onready var wave_manager: WaveManager = get_node(wave_manager_path) as WaveManager
@onready var health_bar: ProgressBar = $HUD/Status/HealthBar
@onready var health_text: Label = $HUD/Status/HealthText
@onready var exp_bar: ProgressBar = $HUD/Status/ExpBar
@onready var exp_text: Label = $HUD/Status/ExpText
@onready var dash_bar: ProgressBar = $HUD/Status/DashBar
@onready var dash_text: Label = $HUD/Status/DashText
@onready var wave_text: Label = $HUD/WaveText
@onready var enemy_text: Label = $HUD/EnemyText
@onready var wave_banner: Label = $HUD/WaveBanner

var previous_health: int = -1


func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	exp_manager.exp_changed.connect(_on_exp_changed)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_progress.connect(_on_wave_progress)
	wave_manager.wave_completed.connect(_on_wave_completed)
	_on_health_changed(player.current_health, player.max_health)
	_on_exp_changed(exp_manager.level, exp_manager.current_exp, exp_manager.required_exp)
	wave_banner.modulate.a = 0.0


func _process(_delta: float) -> void:
	var dash_ratio: float = player.get_dash_cooldown_ratio()
	dash_bar.value = dash_ratio * 100.0
	if player.is_dash_ready():
		dash_text.text = "DASH HAZIR  //  SPACE"
		dash_bar.modulate = Color("b889ff")
	else:
		dash_text.text = "DASH DOLUM  %%%02d" % roundi(dash_ratio * 100.0)
		dash_bar.modulate = Color("7650ac")


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_text.text = "HP  %03d / %03d" % [current, maximum]
	var ratio: float = float(current) / maxf(1.0, float(maximum))
	health_bar.modulate = Color("46f58b") if ratio > 0.55 else (Color("ffd65a") if ratio > 0.25 else Color("ff4f6d"))
	if previous_health >= 0 and current < previous_health:
		var hit_tween: Tween = create_tween()
		$HUD/Status.modulate = Color(1.5, 0.48, 0.56, 1.0)
		hit_tween.tween_property($HUD/Status, "modulate", Color.WHITE, 0.22)
	previous_health = current


func _on_exp_changed(level: int, current: int, required: int) -> void:
	exp_bar.max_value = maxf(1.0, float(required))
	exp_bar.value = current
	exp_text.text = "LV %02d   EXP %d / %s" % [level, current, "MAX" if required == 0 else str(required)]


func _on_wave_started(number: int, kind: String, _total: int) -> void:
	wave_text.text = "WAVE %02d  //  %s" % [number, kind]
	_show_banner("WAVE %02d  //  %s" % [number, kind])


func _on_wave_progress(queued_remaining: int, active_enemies: int) -> void:
	enemy_text.text = "TEHDİT  %02d" % (queued_remaining + active_enemies)


func _on_wave_completed(number: int) -> void:
	enemy_text.text = "SEKTÖR TEMİZ"
	_show_banner("WAVE %02d TAMAMLANDI  //  +%d HP" % [number, player.get_wave_repair_amount()])


func _show_banner(message: String) -> void:
	wave_banner.text = message
	wave_banner.scale = Vector2(0.92, 0.92)
	wave_banner.modulate = Color(0.75, 0.96, 1.0, 0.0)
	var banner_tween: Tween = create_tween()
	banner_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.parallel().tween_property(wave_banner, "scale", Vector2.ONE, 0.22)
	banner_tween.parallel().tween_property(wave_banner, "modulate:a", 1.0, 0.18)
	banner_tween.tween_interval(1.15)
	banner_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.32)
