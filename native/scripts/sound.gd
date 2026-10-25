extends Node
## Original little synthesized melodies. No samples, external services or SDKs.
var muted: bool = false:
	set(value):
		muted = value
		if muted:
			stop_all()
var volume: float = 0.65:
	set(value):
		volume = clampf(value, 0.0, 1.0)
		for player in voices:
			if is_instance_valid(player):
				player.volume_db = linear_to_db(maxf(volume, 0.0001))
const RATE := 22050
var voices: Array[AudioStreamPlayer] = []

func _exit_tree() -> void:
	stop_all()

func stop_all() -> void:
	# Release AudioServer references before the scene/runtime goes away.
	for player in voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.queue_free()
	voices.clear()

func _retire(player: AudioStreamPlayer) -> void:
	voices.erase(player)
	if is_instance_valid(player):
		player.stop()
		player.stream = null
		player.queue_free()

func play_cue(kind: String) -> void:
	if muted or volume <= 0.0:
		return
	var notes: Array = [784.0]
	var seconds := 0.075
	match kind:
		"build":
			notes = [523.25, 659.25, 783.99]
			seconds = 0.085
		"start":
			notes = [392.0, 523.25, 783.99]
			seconds = 0.105
		"finish":
			notes = [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5]
			seconds = 0.13
		"undo":
			notes = [659.25, 523.25]
			seconds = 0.07
		"click":
			notes = [659.25]
			seconds = 0.045
	# Limit simultaneous cues so repeated menu presses stay gentle.
	while voices.size() >= 4:
		_retire(voices.front())
	var samples_per_note := int(RATE * seconds)
	var bytes := PackedByteArray()
	bytes.resize(samples_per_note * notes.size() * 2)
	for note_index in range(notes.size()):
		for sample_index in range(samples_per_note):
			var t := float(sample_index) / RATE
			var envelope := minf(1.0, t / 0.008) * pow(1.0 - float(sample_index) / samples_per_note, 1.6)
			var tone := sin(TAU * float(notes[note_index]) * t) + sin(TAU * float(notes[note_index]) * 2.0 * t) * 0.10
			var value := int(clampf(tone * envelope * 0.17, -1.0, 1.0) * 32767)
			bytes.encode_s16((note_index * samples_per_note + sample_index) * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(maxf(volume, 0.0001))
	add_child(player)
	voices.append(player)
	player.finished.connect(func(): _retire(player))
	player.play()
