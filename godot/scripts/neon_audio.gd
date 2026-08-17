class_name NeonAudio
extends Node

const BACKGROUND_TRACK: AudioStream = preload("res://assets/audio/pursuit_super_slowed.mp3")
const MIX_RATE: float = 22050.0
const BASS_NOTES: Array[float] = [55.0, 55.0, 65.41, 49.0, 55.0, 82.41, 65.41, 49.0, 55.0, 73.42, 82.41, 49.0, 55.0, 98.0, 82.41, 65.41]
const LEAD_NOTES: Array[float] = [220.0, 261.63, 329.63, 293.66, 220.0, 392.0, 329.63, 261.63, 293.66, 329.63, 440.0, 392.0, 261.63, 493.88, 440.0, 329.63]
const SECTION_SPEEDS: Array[float] = [0.235, 0.215, 0.195, 0.178]

var stream_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var sample_clock: int = 0
var bass_phase: float = 0.0
var lead_phase: float = 0.0
var pulse_phase: float = 0.0
var pad_phase: float = 0.0
var current_intensity: float = 0.12
var target_intensity: float = 0.12
var boss_mode: bool = false
var effects: Array[Dictionary] = []
var enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 0.52


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	var music_stream: AudioStreamMP3 = BACKGROUND_TRACK.duplicate() as AudioStreamMP3
	music_stream.loop = true
	music_player.stream = music_stream
	music_player.volume_db = linear_to_db(music_volume)
	add_child(music_player)
	music_player.play()

	stream_player = AudioStreamPlayer.new()
	stream_player.name = "ProceduralEffects"
	stream_player.volume_db = linear_to_db(0.78)
	# Procedural generation needs stream playback in single-threaded Web exports.
	stream_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(stream_player)
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.35
	stream_player.stream = generator
	stream_player.play()
	playback = stream_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if playback == null:
		return
	var frames: int = playback.get_frames_available()
	for _frame: int in range(frames):
		var sample: float = _effects_sample() if sfx_enabled else 0.0
		sample = clampf(sample, -0.82, 0.82)
		playback.push_frame(Vector2(sample, sample))
		sample_clock += 1


func toggle() -> bool:
	enabled = not enabled
	if music_player != null:
		music_player.stream_paused = not enabled
	return enabled


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music_player != null:
		music_player.volume_db = -80.0 if music_volume <= 0.001 else linear_to_db(music_volume)


func get_music_volume() -> float:
	return music_volume


func set_sfx_volume(value: float) -> void:
	if stream_player != null:
		stream_player.volume_db = -80.0 if value <= 0.001 else linear_to_db(clampf(value, 0.0, 1.0))
	sfx_enabled = value > 0.001


func set_intensity(current_wave: int, is_boss: bool) -> void:
	target_intensity = clampf(0.14 + float(current_wave - 1) * 0.055, 0.14, 1.0)
	boss_mode = is_boss
	if boss_mode:
		target_intensity = 1.0


func trigger(kind: String, strength: float = 1.0) -> void:
	var frequency: float = 180.0
	var duration: float = 0.07
	var slide: float = -900.0
	var amplitude: float = 0.12 * strength
	if kind == "hit":
		frequency = 105.0
		duration = 0.10
		slide = -520.0
		amplitude = 0.16 * strength
	elif kind == "impact":
		frequency = 245.0
		duration = 0.055
		slide = -1650.0
		amplitude = 0.15 * strength
	elif kind == "kill":
		frequency = 170.0
		duration = 0.16
		slide = 1250.0
		amplitude = 0.12 * strength
	elif kind == "boss":
		frequency = 58.0
		duration = 0.65
		slide = -38.0
		amplitude = 0.22 * strength
	elif kind == "upgrade":
		frequency = 310.0
		duration = 0.25
		slide = 920.0
		amplitude = 0.13 * strength
	effects.append({
		"phase": 0.0,
		"frequency": frequency,
		"duration": duration,
		"remaining": duration,
		"slide": slide,
		"amplitude": amplitude
	})


func _music_sample() -> float:
	var time: float = float(sample_clock) / MIX_RATE
	current_intensity = move_toward(current_intensity, target_intensity, 0.35 / MIX_RATE)
	var section: int = int(time / 12.0) % SECTION_SPEEDS.size()
	var step_time: float = SECTION_SPEEDS[section] * lerpf(1.05, 0.92, current_intensity)
	var absolute_step: int = int(time / step_time)
	var step: int = absolute_step % BASS_NOTES.size()
	var step_position: float = fmod(time, step_time)
	var bass_frequency: float = BASS_NOTES[step] * (0.89 if boss_mode else 1.0)
	var lead_frequency: float = LEAD_NOTES[step]

	bass_phase = fmod(bass_phase + TAU * bass_frequency / MIX_RATE, TAU)
	lead_phase = fmod(lead_phase + TAU * lead_frequency / MIX_RATE, TAU)
	pulse_phase = fmod(pulse_phase + TAU * 110.0 / MIX_RATE, TAU)
	pad_phase = fmod(pad_phase + TAU * (bass_frequency * 2.0) / MIX_RATE, TAU)

	var bass_envelope: float = exp(-step_position * (8.0 + current_intensity * 5.0))
	var bass_wave: float = (2.0 * bass_phase / TAU) - 1.0
	var lead_gate: float = 1.0 if step % (2 if section >= 2 else 4) == 0 else 0.0
	var lead_envelope: float = exp(-step_position * 13.0) * lead_gate
	var beat_position: float = fmod(time, step_time * 4.0)
	var kick_envelope: float = exp(-beat_position * 20.0)
	var kick: float = sin(pulse_phase * 0.52) * kick_envelope
	var snare_gate: float = 1.0 if absolute_step % 8 in [4, 5] else 0.0
	var snare_envelope: float = exp(-step_position * 24.0) * snare_gate
	var noise: float = sin(float(sample_clock) * 12.9898) * sin(float(sample_clock) * 4.1414)
	var hat_gate: float = 1.0 if absolute_step % 2 == 1 else 0.0
	var hat: float = noise * exp(-step_position * 52.0) * hat_gate
	var pad: float = (sin(pad_phase) + sin(pad_phase * 1.498)) * 0.5
	var tension: float = sin(lead_phase * 0.5) * (0.025 if boss_mode else 0.0)

	return bass_wave * bass_envelope * (0.055 + current_intensity * 0.035) \
		+ sin(lead_phase) * lead_envelope * (0.025 + current_intensity * 0.035) \
		+ kick * (0.025 + current_intensity * 0.045) \
		+ snare_envelope * noise * current_intensity * 0.035 \
		+ hat * current_intensity * 0.018 \
		+ pad * (0.012 + float(section == 0) * 0.012) \
		+ tension


func _effects_sample() -> float:
	var output: float = 0.0
	for index: int in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		var remaining: float = float(effect["remaining"])
		var duration: float = float(effect["duration"])
		var age: float = duration - remaining
		var frequency: float = maxf(25.0, float(effect["frequency"]) + float(effect["slide"]) * age)
		var phase: float = float(effect["phase"]) + TAU * frequency / MIX_RATE
		var envelope: float = maxf(0.0, remaining / duration)
		output += sin(phase) * envelope * float(effect["amplitude"])
		effect["phase"] = fmod(phase, TAU)
		effect["remaining"] = remaining - 1.0 / MIX_RATE
		if float(effect["remaining"]) <= 0.0:
			effects.remove_at(index)
		else:
			effects[index] = effect
	return output
