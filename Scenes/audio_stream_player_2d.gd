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
	# DEAKTIVIERT: Das Musik-System wurde in Main.gd verlagert
	# und wird dort zentral verwaltet, um Konflikte zu vermeiden
	pass
	
	# Alter Code:
	# var paths = MUSIC_PATHS.duplicate()
	# var chosen_path = paths.pick_random()
	# stream = load(chosen_path) as AudioStream
	# play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
