extends Node

var voices: Array[AudioStreamPlayer] = []
var death_voice: AudioStreamPlayer
var cues: Dictionary = {}

func _ready() -> void:
	var music := AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	music.bus = &"Music"
	var ground: RegionData = Regions.get_region(MetaProgression.region)
	var extension: String = "wav" if ground.music >= 10 else "ogg"
	var path: String = "res://audio/region_%d.%s" % [ground.music, extension]
	var soundtrack: AudioStream = load(path) if ResourceLoader.exists(path) else load("res://audio/region_0.ogg")
	music.pitch_scale = ground.pitch
	if soundtrack is AudioStreamOggVorbis:
		(soundtrack as AudioStreamOggVorbis).loop = true
	elif soundtrack is AudioStreamWAV:
		var wav: AudioStreamWAV = soundtrack as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
	music.stream = soundtrack
	add_child(music)
	music.play()
	for i in 16:
		var voice := AudioStreamPlayer.new()
		voice.bus = &"SFX"
		add_child(voice)
		voices.append(voice)
	death_voice = AudioStreamPlayer.new()
	death_voice.process_mode = Node.PROCESS_MODE_ALWAYS
	death_voice.bus = &"SFX"
	add_child(death_voice)
	cues[&"hit"] = sweep(540, 260, .045, 0.16)
	cues[&"damage"] = sweep(180, 70, .16, .5)
	cues[&"death"] = sweep(105, 32, .72, .55)
	cues[&"pickup"] = sweep(620, 900, .055)
	cues[&"heal"] = sweep(450, 720, .16)
	cues[&"chest"] = sweep(330, 980, .23)
	cues[&"buff"] = sweep(430, 1150, .2)
	cues[&"level"] = sweep(390, 1170, .32)
	cues[&"beacon"] = sweep(270, 920, .4)
	cues[&"secret"] = sweep(720, 250, .33, .12)
	cues[&"guardian"] = sweep(150, 65, .48, .25)
	cues[&"cache"] = sweep(310, 680, .2, .12)
	GameEvents.damage_dealt.connect(func(_id, _amount, _at, heavy): play(&"guardian" if heavy else &"hit"))
	GameEvents.player_hurt.connect(func(_amount): play(&"damage"))
	GameEvents.player_died.connect(play_death)
	GameEvents.pickup_collected.connect(_pickup)
	GameEvents.level_up.connect(func(_level): play(&"level"))
	GameEvents.notice.connect(_notice)

func sweep(from_hz: float, to_hz: float, seconds: float, noise: float = 0.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count: int = int(22050 * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase: float = 0.0
	for i in count:
		var progress: float = float(i) / count
		var frequency: float = lerpf(from_hz, to_hz, progress)
		phase += TAU * frequency / 22050.0
		var envelope: float = pow(1.0 - progress, 2.0)
		var wave: float = sin(phase) * .75 + sin(phase * 2.01) * .25 + randf_range(-noise, noise)
		bytes.encode_s16(i * 2, int(clampf(wave * envelope, -1, 1) * 10500))
	stream.data = bytes
	return stream

func _pickup(kind: StringName, _value: int) -> void:
	match kind:
		&"heal": play(&"heal")
		&"chest": play(&"chest")
		&"fury", &"haste", &"ward", &"magnetism": play(&"buff")
		_: play(&"pickup")

func _notice(title: String, _detail: String, _color: Color) -> void:
	if title == "BEACON RESTORED":
		play(&"beacon")
	elif title in ["HIDDEN SITE FOUND", "SECRET ROOM", "HIDDEN LEGACY"]:
		play(&"secret")
	elif title == "GUARDIAN APPROACHING":
		play(&"guardian")
	elif title == "SUPPLY CACHE":
		play(&"cache")

func play_death() -> void:
	death_voice.stream = cues[&"death"]
	death_voice.play()

func play(cue: StringName) -> void:
	var count: int = 0
	var idle: AudioStreamPlayer = null
	for voice in voices:
		if voice.playing and voice.get_meta("cue", &"") == cue:
			count += 1
		elif not voice.playing:
			idle = voice
	if count >= 3 or idle == null:
		return
	idle.set_meta("cue", cue)
	idle.bus = &"UI" if cue in [&"pickup", &"heal", &"buff", &"level"] else &"SFX"
	idle.stream = cues[cue]
	idle.play()

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
