extends Node

var sounds: Dictionary = {}
var bgm_player: AudioStreamPlayer = null

func _ready() -> void:
	load_sound("laser", "res://assets/audio/laser.wav")
	load_sound("spread", "res://assets/audio/spread.wav")
	load_sound("explosion", "res://assets/audio/explosion.wav")
	load_sound("pickup", "res://assets/audio/pickup.wav")
	load_sound("charm_burst", "res://assets/audio/charm_burst.wav")
	load_sound("hit", "res://assets/audio/hit.wav")
	play_bgm()

func play_bgm() -> void:
	if ResourceLoader.exists("res://assets/audio/bgm_space.wav"):
		bgm_player = AudioStreamPlayer.new()
		bgm_player.stream = load("res://assets/audio/bgm_space.wav")
		bgm_player.volume_db = -5.0
		add_child(bgm_player)
		bgm_player.finished.connect(func():
			if is_instance_valid(bgm_player):
				bgm_player.play()
		)
		bgm_player.play()

func load_sound(name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		sounds[name] = stream

func play(name: String, pitch_scale: float = 1.0) -> void:
	if not sounds.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = sounds[name]
	player.pitch_scale = pitch_scale
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
