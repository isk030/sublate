extends Node

@onready var _total_score_label: Label = null
# _factor_one_label and _factor_two_label can be used for future score multipliers or detailed stats
@onready var _factor_one_label: Label = null 
@onready var _factor_two_label: Label = null

var _current_score: int = 0
const POINTS_PER_PAIR: int = 100
var _game_won_message_label: Label = null # Optional: For displaying a 'Game Won!' message

func set_score_labels(total_label: Label, factor1_label: Label, factor2_label: Label) -> void:
	_total_score_label = total_label
	_factor_one_label = factor1_label
	_factor_two_label = factor2_label

func _ready() -> void:
	print("ScoreManager (Autoload) bereit.")
	EventManager.connect_to_event("pair_found", Callable(self, &"_on_pair_found"))
	EventManager.connect_to_event("mismatch_attempt", Callable(self, &"_on_mismatch_attempt"))
	EventManager.connect_to_event("all_pairs_found", Callable(self, &"_on_all_pairs_found"))
	# Optional: If you have a label in your scene for game won messages
	# Search for it. Make sure it's part of the scene tree where ScoreManager can find it.
	# This example assumes it might be a child of the main scene's root, or a sibling of ScoreManager's UI parent.
	# Adjust path as necessary, or set it up via set_game_won_message_label_ref from Main.gd
	# _game_won_message_label = get_tree().root.find_child("GameWonMessageLabel", true, false) 
	# if _game_won_message_label:
	# 	_game_won_message_label.visible = false # Hide initially

func reset_score_panel() -> void:
	_current_score = 0
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	# Reset other labels if they are used to show game-specific state
	if _factor_one_label:
		_factor_one_label.text = "" # Or some default like "Pairs: 0/X"
	if _factor_two_label:
		_factor_two_label.text = "" # Or some default like "Tries: 0"
	if _game_won_message_label:
		_game_won_message_label.text = ""
		_game_won_message_label.visible = false
	# Wir geben nur eine Debug-Nachricht aus, wenn das Haupt-Score-Label fehlt
	if not _total_score_label:
		print_debug("ScoreManager: _total_score_label ist nicht gesetzt. Das ist normal beim ersten Laden.")

func _on_pair_found(_data: Dictionary) -> void:
	_current_score += POINTS_PER_PAIR
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	print("ScoreManager: Pair found! Score: ", _current_score)
	# Optional: Update other labels based on data from GameManager
	# if _factor_one_label and data.has("pairs_found") and data.has("total_pairs"):
	# 	_factor_one_label.text = "Pairs: %d/%d" % [data.pairs_found, data.total_pairs]

func _on_mismatch_attempt() -> void:
	# Update score for mismatch attempt
	pass

func _on_all_pairs_found() -> void:
	# Update score for all pairs found
	if _game_won_message_label:
		_game_won_message_label.visible = true
