extends Node
# Plays the generated sounds in assets/sfx and the music loop in assets/music.

const NAMES := ["jump", "bounce", "plate", "gate", "death", "checkpoint", "goal", "ui_move", "ui_select", "warn", "swap"]
var sounds := {}
var pool: Array = []
var music: AudioStreamPlayer
var music_on := false

func _ready() -> void:
	for n in NAMES:
		sounds[n] = load("res://assets/sfx/%s.wav" % n)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music = AudioStreamPlayer.new()
	var s: AudioStreamWAV = load("res://assets/music/theme.wav")
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.data.size() / 2)
	music.stream = s
	music.volume_db = -9.0
	add_child(music)

func play(n: String, vol := 0.0) -> void:
	var s = sounds.get(n)
	if s == null:
		return
	for p in pool:
		if not p.playing:
			p.stream = s
			p.volume_db = vol
			p.play()
			return

func start_music() -> void:
	if not music_on:
		music_on = true
		music.play()

func duck_music(on: bool) -> void:
	music.volume_db = -16.0 if on else -9.0
