extends Label

class_name FloatingLabel

# A simple label that floats upward and fades out, then queues itself for deletion.
# Usage:
#   var lbl = FloatingLabel.new()
#   lbl.text = "+50"
#   add_child(lbl)
#   lbl.start()

# Static array to keep track of all active floating labels for animation
static var active_labels: Array[FloatingLabel] = []
static var is_animation_to_factor_two_active: bool = false

@export var rise_distance: float = 50.0  # Pixels to move upward
@export var duration: float = 1.2  # Seconds for the whole animation
@export var start_color: Color = Color.WHITE

# Variables to track current tween and state
var current_tween: Tween = null
var is_animating_to_factor_two: bool = false

func _ready() -> void:
	# Apply initial visual state
	modulate = start_color
	
	# Add this label to the active labels list
	active_labels.append(self)
	print("FloatingLabel added to active_labels. Count: ", active_labels.size())
	
	# Remove from active labels when freed
	tree_exited.connect(func(): 
		active_labels.erase(self)
		print("FloatingLabel removed from active_labels. Count: ", active_labels.size())
	)
	
	# DEBUG: Automatically test animation for +50 and +10 labels after a delay
	if text == "+50" or text == "+10":
		print("DEBUG: " + text + " label created, will test animation in 1 second")
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func():
			if is_instance_valid(self):
				print("DEBUG: Testing label animation now for " + text)
				# Try to find the Factor-Two-Label
				var factor_two_label = null
				var score_manager = get_node_or_null("/root/ScoreManager")
				if score_manager:
					# Versuche, das Factor-Two-Label über den ScoreManager zu finden
					if "_factor_two_label" in score_manager and score_manager._factor_two_label:
						factor_two_label = score_manager._factor_two_label
						print("DEBUG: Found Factor-Two-Label through ScoreManager")
			
				# Wenn nicht im ScoreManager gefunden, suche in der Szene
				if not factor_two_label:
					var factor_labels = get_tree().get_nodes_in_group("factor_label")
					if factor_labels.size() > 0:
						factor_two_label = factor_labels[0]
						print("DEBUG: Found Factor-Two-Label in factor_label group")
						
				# Bestimme Zielposition
				var target_pos
				if factor_two_label and is_instance_valid(factor_two_label):
					# Berechne die Mitte des Labels
					target_pos = factor_two_label.global_position + factor_two_label.size / 2.0
					print("DEBUG: Target position set to Factor-Two-Label: ", target_pos)
				else:
					# Fallback: Berechne eine Position in der oberen rechten Ecke
					var screen_size = get_viewport().get_visible_rect().size
					target_pos = Vector2(screen_size.x * 0.8, screen_size.y * 0.2)
					print("DEBUG: Using fallback position in top-right: ", target_pos)
					
				# Animiere das Label
				animate_to_factor_two(target_pos)
		)

func start() -> void:
	# Defer animation to next frame so size is calculated
	call_deferred("_begin_animation")

func _begin_animation() -> void:
	pivot_offset = size / 2.0
	z_index = 5  # Niedrigerer z_index als die ShopUI (welche z_index 6 hat)
	
	# Start standard animation (floating upward)
	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(self, "position:y", position.y - rise_distance, duration)
	current_tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	current_tween.connect("finished", Callable(self, "queue_free"))

# Animates this label to fly toward the given target position
func animate_to_factor_two(target_position: Vector2) -> void:
	# If already animating to factor two or if we're about to be deleted, do nothing
	if is_animating_to_factor_two or not is_instance_valid(self):
		return
	
	print("FloatingLabel ", text, ": Starting animation to Factor-Two-Label")
	is_animating_to_factor_two = true
	
	# Kill the current tween if it exists
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	# Create new tween for flying to target
	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Calculate random slight offset for natural movement
	var random_offset = Vector2(
		randf_range(-10, 10),
		randf_range(-10, 10)
	)
	
	# Make sure we're visible
	modulate.a = 1.0
	
	# Add a slight delay based on position for staggered effect
	var delay = randf_range(0.0, 0.3)
	# In Godot 4, we need to create a dummy tween step for delay
	if delay > 0.0:
		current_tween.tween_interval(delay)
	
	# Get our global position and the global target position
	var global_start = global_position
	var global_target = target_position
	print("FloatingLabel: Global start: ", global_start)
	print("FloatingLabel: Global target: ", global_target)
	
	# Calculate the direction and distance to the target
	var to_target = global_target - global_start
	var direction = to_target.normalized()
	var distance = to_target.length()
	
	# If we can't determine a good direction, use default top-right
	if distance < 10 or direction == Vector2.ZERO:
		direction = Vector2(1.0, -1.0).normalized()
		distance = 400
	
	# Calculate movement in local coordinates
	# Convert the movement vector from global to local space
	var local_movement = distance * direction
	var local_target = position + local_movement
	
	# Add some randomness
	local_target += random_offset
	
	print("FloatingLabel: Moving from local ", position, " toward local ", local_target)
	
	# First scale up slightly and highlight
	current_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	current_tween.parallel().tween_property(self, "modulate", Color(1.0, 0.9, 0.2, 1.0), 0.2)
	
	# Then move toward the target position with arc effect (first up, then toward target)
	var mid_point = position + Vector2(local_movement.x * 0.4, -abs(local_movement.y) * 1.2)  # Arc upward
	current_tween.tween_property(self, "position", mid_point, 0.3)
	current_tween.tween_property(self, "position", local_target, 0.4)
	
	# Finally fade out
	current_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Delete after animation is complete
	current_tween.connect("finished", Callable(self, "queue_free"))

# Static method to animate all active floating labels to a target position
static func animate_all_to_factor_two(target_position: Vector2) -> void:
	print("FloatingLabel.animate_all_to_factor_two called with target: ", target_position)
	print("FloatingLabel: Number of active labels: ", active_labels.size())
	
	is_animation_to_factor_two_active = true
	
	# Create a copy of the array to prevent issues if labels get removed during iteration
	var labels_to_animate = active_labels.duplicate()
	print("FloatingLabel: Number of labels to animate: ", labels_to_animate.size())
	
	# Debug: Print all active labels
	if labels_to_animate.size() > 0:
		print("FloatingLabel: Active labels:")
		for i in range(labels_to_animate.size()):
			if is_instance_valid(labels_to_animate[i]):
				print("  Label ", i, ": ", labels_to_animate[i].text, " at ", labels_to_animate[i].global_position)
	
	# Animate each label
	if labels_to_animate.size() > 0:
		for label in labels_to_animate:
			if is_instance_valid(label):
				print("FloatingLabel: Animating label: ", label.text)
				label.animate_to_factor_two(target_position)
	else:
		print("FloatingLabel: No active labels to animate!")
	
	# Reset the flag after a delay
	var timer = Engine.get_main_loop().create_timer(1.5)
	timer.timeout.connect(func(): is_animation_to_factor_two_active = false)
