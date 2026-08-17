class_name BossHealthUI
extends CanvasLayer

@export_node_path("Node") var wave_manager_path: NodePath

@onready var wave_manager: WaveManager = get_node(wave_manager_path) as WaveManager
@onready var wave_label: Label = $HUD/WaveLabel
@onready var boss_panel: PanelContainer = $HUD/BossPanel
@onready var boss_name_label: Label = $HUD/BossPanel/VBox/BossName
@onready var boss_health_bar: ProgressBar = $HUD/BossPanel/VBox/BossHealth
@onready var boss_health_text: Label = $HUD/BossPanel/VBox/BossHealthText


func _ready() -> void:
	boss_panel.hide()
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.boss_spawned.connect(_on_boss_spawned)
	wave_manager.boss_health_changed.connect(_on_boss_health_changed)
	wave_manager.boss_defeated.connect(_on_boss_defeated)


func _on_wave_started(wave_number: int, wave_kind: String, total_enemies: int) -> void:
	wave_label.text = "WAVE %02d  •  %s  •  %d HEDEF" % [wave_number, wave_kind, total_enemies]


func _on_boss_spawned(boss_name: String, max_health: float) -> void:
	boss_name_label.text = boss_name
	boss_health_bar.max_value = max_health
	boss_health_bar.value = max_health
	boss_health_text.text = "%d / %d" % [int(max_health), int(max_health)]
	boss_panel.show()


func _on_boss_health_changed(current_health: float, max_health: float) -> void:
	boss_health_bar.max_value = max_health
	boss_health_bar.value = current_health
	boss_health_text.text = "%d / %d" % [ceili(current_health), ceili(max_health)]


func _on_boss_defeated(_boss_name: String) -> void:
	boss_panel.hide()
