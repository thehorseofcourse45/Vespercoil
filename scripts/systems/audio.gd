extends Node

const PLAYER_CUE_VOLUME_DB: float = 6.0
const CUE_RATE: int = 22050
const UI_CUES: Array[StringName] = [&"pickup", &"heal", &"buff", &"level", &"click", &"confirm", &"cancel"]

var voices: Array[AudioStreamPlayer] = []
var death_voice: AudioStreamPlayer
var cues: Dictionary = {}

func _ready() -> void:
	var music := AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	music.bus = &"Music"
	var ground: RegionData = Regions.get_region(MetaProgression.region)
	# Every region track ships as OGG. The fifteen original compositions are ~76 second
	# loops, and Vorbis is streamed from disk where a WAV stem would sit in RAM whole.
	var path: String = "res://audio/region_%d.ogg" % ground.music
	var soundtrack: AudioStream = load(path) if ResourceLoader.exists(path) else load("res://audio/region_0.ogg")
	music.pitch_scale = ground.pitch
	if soundtrack is AudioStreamOggVorbis:
		(soundtrack as AudioStreamOggVorbis).loop = true
	elif soundtrack is AudioStreamWAV:
		var wav: AudioStreamWAV = soundtrack as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		# Samples, not bytes: an imported WAV may be stored compressed, so data.size()
		# is not a sample count.
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
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
	# Combat cues are layered: a noise transient over a falling body reads as impact,
	# where a single sweep reads as a beep. All 27 weapons and 165 enemies share these.
	cues[&"hit"] = layer([
		{"from": 880.0, "to": 300.0, "seconds": .035, "gain": .28, "noise": .28},
		{"from": 240.0, "to": 118.0, "seconds": .085, "gain": .34},
	])
	cues[&"damage"] = layer([
		{"from": 190.0, "to": 62.0, "seconds": .18, "gain": .42},
		{"from": 430.0, "to": 120.0, "seconds": .05, "gain": .22, "noise": .35},
	])
	cues[&"death"] = layer([
		{"from": 110.0, "to": 28.0, "seconds": .78, "gain": .46},
		{"from": 330.0, "to": 40.0, "seconds": .34, "at": .05, "gain": .18, "noise": .22},
	])
	cues[&"guardian"] = layer([
		{"from": 150.0, "to": 52.0, "seconds": .5, "gain": .36},
		{"from": 620.0, "to": 180.0, "seconds": .16, "gain": .18, "noise": .3},
	])
	cues[&"pickup"] = sweep(620, 900, .055)
	cues[&"heal"] = sweep(450, 720, .16)
	cues[&"chest"] = sweep(330, 980, .23)
	cues[&"buff"] = sweep(430, 1150, .2)
	cues[&"level"] = sweep(390, 1170, .32)
	cues[&"beacon"] = sweep(270, 920, .4)
	cues[&"secret"] = sweep(720, 250, .33, .12)
	cues[&"cache"] = sweep(310, 680, .2, .12)
	# Menu cues are quiet: they fire on every press, and a 274-node chart is a lot of presses.
	cues[&"click"] = layer([{"from": 900.0, "to": 720.0, "seconds": .028, "gain": .15}])
	cues[&"confirm"] = layer([
		{"from": 620.0, "to": 780.0, "seconds": .07, "gain": .17},
		{"from": 930.0, "to": 1180.0, "seconds": .09, "at": .06, "gain": .13},
	])
	cues[&"cancel"] = layer([{"from": 430.0, "to": 250.0, "seconds": .1, "gain": .17}])
	GameEvents.damage_dealt.connect(func(_id, _amount, _at, heavy): play(&"guardian" if heavy else &"hit"))
	GameEvents.player_hurt.connect(func(_amount): play(&"damage"))
	GameEvents.player_died.connect(play_death)
	GameEvents.pickup_collected.connect(_pickup)
	GameEvents.level_up.connect(func(_level): play(&"level"))
	GameEvents.notice.connect(_notice)
	GameEvents.ui_cue.connect(play)

# Adds one swept partial into `samples` at `at` seconds, growing the buffer as needed.
func mix(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var start: int = int(float(spec.get("at", 0.0)) * CUE_RATE)
	var count: int = maxi(1, int(CUE_RATE * float(spec.get("seconds", .1))))
	var needed: int = start + count
	if samples.size() < needed:
		samples.resize(needed)
	var from_hz: float = float(spec.get("from", 440.0))
	var to_hz: float = float(spec.get("to", 440.0))
	var noise: float = float(spec.get("noise", 0.0))
	var gain: float = float(spec.get("gain", .32))
	var phase: float = 0.0
	for i in count:
		var progress: float = float(i) / count
		var frequency: float = lerpf(from_hz, to_hz, progress)
		phase += TAU * frequency / CUE_RATE
		var envelope: float = pow(1.0 - progress, 2.0)
		var wave: float = sin(phase) * .75 + sin(phase * 2.01) * .25 + randf_range(-noise, noise)
		samples[start + i] += wave * envelope * gain

func encode(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CUE_RATE
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1, 1) * 32767))
	stream.data = bytes
	return stream

func sweep(from_hz: float, to_hz: float, seconds: float, noise: float = 0.0) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	mix(samples, {"from": from_hz, "to": to_hz, "seconds": seconds, "noise": noise})
	return encode(samples)

func layer(parts: Array) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	for part in parts:
		mix(samples, part)
	return encode(samples)

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
	death_voice.volume_db = PLAYER_CUE_VOLUME_DB
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
	idle.bus = &"UI" if cue in UI_CUES else &"SFX"
	idle.volume_db = PLAYER_CUE_VOLUME_DB if cue == &"damage" else 0.0
	idle.stream = cues[cue]
	idle.play()

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
