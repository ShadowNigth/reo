extends Node
var game: Node
var voices: Array[AudioStreamPlayer3D] = []
var ui_voice: AudioStreamPlayer
var ambience: AudioStreamPlayer
var cursor := 0
var last_played := {}

func setup(g: Node) -> void:
	game = g
	for i in range(20):
		var p := AudioStreamPlayer3D.new()
		p.max_distance = 42.0
		p.unit_size = 5.0
		p.max_polyphony = 1
		add_child(p); voices.append(p)
	ui_voice = AudioStreamPlayer.new(); add_child(ui_voice)
	ambience = AudioStreamPlayer.new(); add_child(ambience)
	ambience.stream = game.assets.random_sound("ambient_")
	ambience.volume_db = -19.0
	ambience.finished.connect(func(): ambience.play())
	ambience.play()

func stream_for(key: String) -> AudioStream:
	var a: Node = game.assets
	match key:
		"pistol": return a.sound("res://assets/audio/blaster.ogg")
		"rifle", "smg", "lmg": return a.sound("res://assets/audio/blaster_repeater.ogg")
		"shotgun": return a.random_sound("impactMetal_heavy")
		"sniper": return a.sound("res://assets/audio/blaster.ogg")
		"energy": return a.sound("res://assets/audio/blaster_repeater.ogg")
		"launcher", "explosion": return a.random_sound("explosion_")
		"flame": return a.random_sound("impactSoft_heavy")
		"swing": return a.random_sound("knifeSlice")
		"flesh": return a.random_sound("slime_")
		"glass": return a.random_sound("bfh1_glass_breaking")
		"break": return a.random_sound("bfh1_breaking")
		"stone": return a.random_sound("impactMetal_medium")
		"metal": return a.random_sound("impactMetal_light")
		"reload": return a.random_sound("metal")
		"empty": return a.sound("res://assets/audio/metalClick.ogg")
		"pickup": return a.sound("res://assets/audio/handleCoins.ogg")
		"step": return a.random_sound("footstep_concrete")
		"hurt": return a.random_sound("impactSoft_heavy")
		"growl": return a.random_sound("zombie-")
		"alarm": return a.random_sound("alarm_")
		"switch": return a.sound("res://assets/audio/weapon_change.ogg")
	return null

func play_at(key: String, pos: Vector3, pitch: float = 0.0, volume: float = -5.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(key,-1000)) < 45: return
	last_played[key] = now
	var s := stream_for(key)
	if not s: return
	var p := voices[cursor]; cursor = (cursor+1)%voices.size()
	p.stop(); p.stream = s; p.global_position = pos
	p.pitch_scale = randf_range(0.91,1.09) if pitch == 0.0 else pitch
	p.volume_db = volume
	p.play()

func play_ui(key: String, volume: float = -9.0) -> void:
	var s := stream_for(key)
	if s: ui_voice.stream = s; ui_voice.volume_db = volume; ui_voice.play()
