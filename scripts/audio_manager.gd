extends Node

const MUSIC_FADE_DURATION: float = 1.0
const MUSIC_VOLUME: float = -2.0

const TRACKS: Array[String] = [
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_1.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_2.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_3.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_4.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_5.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_6.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_7.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_8.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_9.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_10.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_11.ogg",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_12.ogg",
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
