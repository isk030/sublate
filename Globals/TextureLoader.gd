extends Node

# Utility for loading and providing card textures
# ----------------------------------------------------------------------------

const CARD_TEXTURE_PATHS: Array[String] = [
	"res://assets/cards/cassettes.png",
	"res://assets/cards/ghetto-blaster.png",
	"res://assets/cards/spray-can.png",
	"res://assets/cards/vinyl.png",
	"res://assets/cards/cap.png",
	"res://assets/cards/player.png",
	"res://assets/cards/sneakers.png",
	"res://assets/cards/mic.png",

]

# UI Textures
const MATCHED_TEXTURE_PATH: String = "res://assets/ui/level_select_frame_select_128.png"

func load_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in CARD_TEXTURE_PATHS:
		var tex: Texture2D = load(path)
		if tex:
			textures.append(tex)
		else:
			push_error("TextureLoader: Failed to load texture '%s'" % path)
	return textures

func create_texture_pool(pair_count: int) -> Array[Texture2D]:
	var unique_textures := load_textures()
	if unique_textures.size() < pair_count:
		push_error("TextureLoader: Not enough unique textures (%d needed, %d available)." % [pair_count, unique_textures.size()])
		return []
	
	# Sicherstellen, dass wir einen konsistenten Seed haben
	var rng = RandomNumberGenerator.new()
	rng.seed = 42  # Gleicher Seed wie im GameManager
	
	# Mischen der einzigartigen Texturen
	var shuffled_textures = unique_textures.duplicate()
	shuffled_textures.sort_custom(func(a, b): return rng.randi() % 2 == 0)
	
	# Erstelle Paare
	var pool: Array[Texture2D] = []
	for i in range(pair_count):
		var t: Texture2D = shuffled_textures[i % shuffled_textures.size()]
		pool.append_array([t, t])
	
	# Mischen der Paare mit dem gleichen Seed
	pool.sort_custom(func(a, b): return rng.randi() % 2 == 0)
	
	return pool

# Get the matched texture for cards
static func get_matched_texture() -> Texture2D:
	return load(MATCHED_TEXTURE_PATH)
