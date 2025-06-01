extends AudioStreamPlayer2D

const MUSIC_PATHS = [
	"res://assets/music/Heartbeat AI Music.mp3",
	"res://assets/music/Schigisaga - AI Music.mp3",
	"res://assets/music/Sneek Up by Cruizer61.mp3",
	"res://assets/music/Suno AI Music Gut.mp3",
	"res://assets/music/Suno AI Music.mp3"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var paths = MUSIC_PATHS.duplicate()  # damit das const-Array unangetastet bleibt
	var chosen_path = paths.pick_random()  # hier wird chosen_path gesetzt

	# AudioStream laden und abspielen
	stream = load(chosen_path) as AudioStream
	
	play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
