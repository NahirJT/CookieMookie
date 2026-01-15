extends Node

const MUSIC_FADE_DURATION: float = 1.0
const MUSIC_VOLUME: float = -8.0

const TRACKS: Array[String] = [
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 1.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 2.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 3.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 4.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 5.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 6.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 7.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 8.ogg",
	"res://assets/audio/tracks/870e1c9e-c290-4abb-a6e8-213e5b9632f9 9.ogg",
]

var _music_player: AudioStreamPlayer = null


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)


func play_random_track() -> void:
	if not _music_player:
		return
	var track_path = TRACKS.pick_random()
	_music_player.stream = load(track_path)
	_music_player.volume_db = -40.0
	_music_player.play()

	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", MUSIC_VOLUME, MUSIC_FADE_DURATION)


func fade_out_music() -> void:
	if not _music_player or not _music_player.playing:
		return
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_DURATION)


func stop_music() -> void:
	if _music_player:
		_music_player.stop()
