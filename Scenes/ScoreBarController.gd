extends Control

func _ready():
	# Wait a frame to ensure all nodes are properly initialized
	await get_tree().process_frame
	
	# Get reference to the ScoreManager
	var score_manager = get_node_or_null("/root/ScoreManager")
	if not score_manager:
		push_error("ScoreBarController: ScoreManager not found!")
		return
	
	# Get reference to the progress bars
	var score_progress_bar = get_node_or_null("%ScoreProgressBar")
	var heat_progress_bar = get_node_or_null("%HeatProgressBar")
	
	# Connect score progress bar
	if score_progress_bar:
		print("ScoreBarController: Connecting score progress bar...")
		score_manager.set_progress_bar(score_progress_bar)
	else:
		push_error("ScoreBarController: ScoreProgressBar not found!")
	
	# Connect heat progress bar
	if heat_progress_bar:
		print("ScoreBarController: Connecting heat progress bar...")
		score_manager.set_heat_progress_bar(heat_progress_bar)
	else:
		push_error("ScoreBarController: HeatProgressBar not found!")
	
	print("ScoreBarController: Initialization complete")
	
	# Debug-Ausgabe, um den Status zu überprüfen
	if score_manager:
		print("\nScoreBarController - Debug Info:")
		print("  Heat Bonus Enabled: ", score_manager.is_heat_bonus_enabled())
		print("  Heat Progress Bar: ", score_manager._heat_progress_bar != null)
		if score_manager._heat_progress_bar:
			print("  Heat Progress Bar Value: ", score_manager._heat_progress_bar.value)
			print("  Heat Progress Bar Max: ", score_manager._heat_progress_bar.max_value)
