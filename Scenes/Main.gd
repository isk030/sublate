class_name Main
extends Control

# UI Elemente
@onready var _background_area: Control = $BackgroundArea
@onready var _ui_total_score_label: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/Label2
@onready var _ui_factor_one: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect/Label
@onready var _ui_factor_two: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect2/Label
@onready var _ui_card_area: Control = $BackgroundArea/VBoxContainer/HBoxContainer/CardArea
@onready var _menu: Control = $Menu
@onready var _shop_ui: Control = $ShopUI

func _ready() -> void:
	# Stelle sicher, dass der Node Eingaben empfängt
	print("Main scene ready")
	print("Input map has ui_cancel:", InputMap.has_action("ui_cancel"))
	_validate_nodes()
	_initialize_ui()
	_initialize_managers()
	_connect_menu_signals()
	# Aktiviere die Verarbeitung von Eingaben
	set_process_input(true)

func _validate_nodes() -> void:
	var missing_nodes: Array[String] = []
	
	if not _background_area:
		missing_nodes.append("BackgroundArea")
	if not _ui_total_score_label:
		missing_nodes.append("TotalScoreLabel")
	if not _ui_factor_one:
		missing_nodes.append("FactorOneLabel")
	if not _ui_factor_two:
		missing_nodes.append("FactorTwoLabel")
	if not _ui_card_area:
		missing_nodes.append("CardArea")
	
	if not missing_nodes.is_empty():
		push_error("Fehlende UI-Nodes: " + ", ".join(missing_nodes))

func _initialize_ui() -> void:
	# Hide background area at start, show menu
	toggle_menu(true)

func _initialize_managers() -> void:
	_initialize_score_manager()
	_initialize_game_manager()
	_connect_score_signals()

func _initialize_score_manager() -> void:
	if not ScoreManager:
		push_error("ScoreManager (Autoload) nicht gefunden!")
		return
	
	# Set up the score labels
	ScoreManager.set_score_labels(
		_ui_total_score_label, 
		_ui_factor_one, 
		_ui_factor_two
	)
	
	# Connect the progress bar - Look for ScoreBar as child of BackgroundArea
	var score_bar = _background_area.get_node_or_null("ScoreBar")
	print("Looking for ScoreBar as child of BackgroundArea")
	print("ScoreBar exists: ", score_bar != null)
	
	if not score_bar:
		push_error("Main: Could not find ScoreBar node")
		print("Children of BackgroundArea:")
		for child in _background_area.get_children():
			print(" - ", child.name, " (Type: ", child.get_class(), ")")
		return
	
	print("ScoreBar found: ", score_bar)
	print("ScoreBar children: ", score_bar.get_children())
	
	# Find the progress bar
	var progress_bar: ProgressBar = null
	
	# First try to find by node path
	progress_bar = score_bar.get_node_or_null("HBoxContainer/ScoreProgressBar")
	
	# If not found, search for any ProgressBar in the scene
	if not progress_bar:
		for child in score_bar.get_children():
			if child is ProgressBar:
				progress_bar = child
				break
			elif child.get_child_count() > 0:
				progress_bar = child.get_node_or_null("ScoreProgressBar")
				if progress_bar:
					break
	
	if not progress_bar:
		push_error("Main: Could not find any ProgressBar in the scene")
		return
	
	print("Found ProgressBar: ", progress_bar)
	
	# Set up the progress bar in ScoreManager
	ScoreManager.set_progress_bar(progress_bar)
	print("Main: Progress bar connected to ScoreManager")
	
	# Force an initial update
	progress_bar.value = ScoreManager._current_score
	
	# Find and update the score label
	var score_label = progress_bar.get_node_or_null("ScoreLabel")
	if not score_label:
		# Try to find any label in the progress bar
		for child in progress_bar.get_children():
			if child is Label:
				score_label = child
				break
	
	if score_label:
		score_label.text = str(ScoreManager._current_score)
		print("Score label updated to: ", score_label.text)
	else:
		print("Warning: Could not find score label in progress bar")

func _initialize_game_manager() -> void:
	if not GameManager:
		push_error("GameManager (Autoload) nicht gefunden!")
		return
	
	GameManager.set_card_area_ref(_ui_card_area)
	GameManager.init_game_elements()
	GameManager.init_player_panel()

func _connect_menu_signals() -> void:
	if _menu:
		_menu.game_start_requested.connect(_on_menu_start_pressed)
		_menu.exit_requested.connect(_on_menu_exit_requested)
		_menu.continue_requested.connect(_on_menu_continue_pressed)

func _connect_score_signals() -> void:
	if ScoreManager:
		if not ScoreManager.score_threshold_reached.is_connected(_on_score_threshold_reached):
			ScoreManager.score_threshold_reached.connect(_on_score_threshold_reached)
	
	# Connect shop UI signals if it exists
	if _shop_ui:
		if not _shop_ui.buff_selected.is_connected(_on_shop_buff_selected):
			_shop_ui.buff_selected.connect(_on_shop_buff_selected)

func _on_score_threshold_reached() -> void:
	if _shop_ui:
		print("Showing shop UI...")
		_shop_ui.visible = true
		_shop_ui.show_shop()
		get_tree().paused = true  # Pause the game while shop is open

func _on_shop_buff_selected(buff_type: String) -> void:
	print("Buff selected: ", buff_type)
	match buff_type:
		"heat_bonus":
			if ScoreManager:
				ScoreManager.set_heat_bonus_enabled(true)
				print("Heat bonus enabled!")
			
			# Aktiviere das Card-Highlighting für den Heat-Buff
			var rhythm_manager = get_node_or_null("Node")
			if rhythm_manager and rhythm_manager.get_script() and rhythm_manager.get_script().get_path().ends_with("CardRhythmManager.gd"):
				rhythm_manager.enable_highlighting = true
				print("Card highlighting enabled for heat bonus!")
		"base_point_increase":
			if ScoreManager:
				ScoreManager.set_base_point_increase_enabled(true)
				print("Base point increase enabled!")
	
	# Reset the game for a new run
	if GameManager:
		GameManager.reset_game()
		print("Game reset for new run after buff selection")
	
	# Resume the game
	if _shop_ui:
		_shop_ui.visible = false
	get_tree().paused = false

func _on_menu_start_pressed() -> void:
	toggle_menu(false)
	
	# Reset game state if needed
	if GameManager:
		GameManager.reset_game()

func _on_menu_continue_pressed() -> void:
	toggle_menu(false)

func _on_menu_exit_requested() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			print("ESC key pressed!")
			var show_menu = not _menu.visible
			toggle_menu(show_menu)
			if show_menu:
				_menu.set_opened_via_escape(true)
			get_viewport().set_input_as_handled()

func toggle_menu(show_menu: bool) -> void:
	if _menu:
		_menu.visible = show_menu
		if not show_menu:
			_menu.set_opened_via_escape(false)
	_background_area.visible = not show_menu
