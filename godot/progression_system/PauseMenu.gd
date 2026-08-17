class_name PauseMenu
extends CanvasLayer

@export_node_path("Node") var audio_path: NodePath

@onready var overlay: Control = $Overlay
@onready var neon_audio: NeonAudio = get_node(audio_path) as NeonAudio
@onready var music_down_button: Button = $Overlay/Center/Panel/Margin/VBox/VolumeRow/MusicDown
@onready var music_up_button: Button = $Overlay/Center/Panel/Margin/VBox/VolumeRow/MusicUp
@onready var music_volume_text: Label = $Overlay/Center/Panel/Margin/VBox/VolumeRow/MusicVolume
@onready var resume_button: Button = $Overlay/Center/Panel/Margin/VBox/Resume

var active: bool = false
var previous_tree_pause: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	music_down_button.pressed.connect(_on_music_down_pressed)
	music_up_button.pressed.connect(_on_music_up_pressed)
	resume_button.pressed.connect(close_menu)
	_update_music_display()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if active:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	if active:
		return
	previous_tree_pause = get_tree().paused
	active = true
	overlay.visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close_menu() -> void:
	if not active:
		return
	active = false
	overlay.visible = false
	get_tree().paused = previous_tree_pause


func _on_music_down_pressed() -> void:
	neon_audio.set_music_volume(neon_audio.get_music_volume() - 0.10)
	_update_music_display()


func _on_music_up_pressed() -> void:
	neon_audio.set_music_volume(neon_audio.get_music_volume() + 0.10)
	_update_music_display()


func _update_music_display() -> void:
	var music_volume: float = neon_audio.get_music_volume()
	music_volume_text.text = "MÜZİK  %%%02d" % roundi(music_volume * 100.0)
	music_down_button.disabled = music_volume <= 0.001
	music_up_button.disabled = music_volume >= 0.999
