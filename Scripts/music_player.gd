class_name MusicPlayer
extends AudioStreamPlayer

signal beat(n: int)

var last_onset = 0
var beat_count = 0
var current_song: AudioStream
var current_interonset_ms: float

func bpm_to_interonset_ms(bpm: float) -> float:
	return 60 / bpm

func change_song(path: String, bpm: float):
	last_onset = 0
	beat_count = 0
	current_song = AudioStreamOggVorbis.load_from_file(path)
	current_interonset_ms = bpm_to_interonset_ms(bpm)
	set_stream(current_song)

func _ready():
	pass

func _process(_delta):
	# Use sound hardware clock for accurate timing
	# https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html
	var time = get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	
	var delta = time - last_onset
	if delta >= current_interonset_ms:
		# delta is always a bit greater than our ideal interval
		# due to process not being called fast enough or on time with
		# audio processing, causing the signal to be fired slower than
		# the tempo, so compensate
		last_onset = time - (delta - current_interonset_ms)

		beat.emit(beat_count)
		beat_count += 1
