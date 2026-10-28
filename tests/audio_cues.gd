extends SceneTree

# Proves the cue bank stays audible after the layered-cue refactor, and that a menu press
# actually reaches the audio node instead of stopping at the button.

const CUES: Array[StringName] = [&"click", &"confirm", &"cancel", &"hit", &"damage", &"death", &"guardian"]

func _initialize() -> void:
	call_deferred("run")

func peak_of(stream: AudioStreamWAV) -> int:
	var peak: int = 0
	var i: int = 0
	while i + 1 < stream.data.size():
		peak = maxi(peak, absi(stream.data.decode_s16(i)))
		i += 2
	return peak

func playing(audio: Node, cue: StringName) -> int:
	var count: int = 0
	for child in audio.get_children():
		if child is AudioStreamPlayer and child.playing and child.stream == audio.cues[cue]:
			count += 1
	return count

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var audio = game.get_node("Audio")
	for cue in CUES:
		assert(audio.cues.has(cue))
		var stream: AudioStreamWAV = audio.cues[cue]
		assert(stream.data.size() > 0)
		assert(peak_of(stream) > 1000) # Audible, not a silent buffer.
	# Menu presses are emitted through GameEvents so the audio node stays the only owner of playback.
	game.hud.clear_menu("AUDIO")
	var fired := [false]
	game.hud.button("Probe", func() -> void: fired[0] = true)
	var target: Button = null
	for child in game.hud.menu_column.get_children():
		if child is Button:
			target = child
	assert(target != null)
	target.pressed.emit()
	await process_frame
	assert(fired[0])
	assert(playing(audio, &"click") == 1)
	print("AUDIO CUES PASS: %d layered cues are audible and a hud button press plays the UI cue" % CUES.size())
	game.queue_free()
	await process_frame
	quit()
