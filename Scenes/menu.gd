extends Control

# Testfunktion, um zu überprüfen, ob das Skript geladen wird
func _init() -> void:
	print("Menu-Skript wurde geladen!")

var main_scene = null

func _ready() -> void:
	print("=== Menu _ready() aufgerufen ===")
	
	# Lade die Hauptszene
	print("Lade Hauptszene...")
	main_scene = preload("res://Scenes/main.tscn")
	if main_scene == null:
		print("FEHLER: Konnte die Hauptszene nicht laden!")
		return
	else:
		print("✓ Hauptszene erfolgreich geladen")

	# Zeige die Node-Hierarchie
	print("\n=== Node-Hierarchie ===")
	print("Pfad dieser Node: ", get_path())
	print("Kinder dieser Node:")
	for child in get_children():
		print("- ", child.name, " (", child.get_class(), ")")
		if child.name == "VBoxContainer":
			print("  Kinder von VBoxContainer:")
			for grandchild in child.get_children():
				print("  - ", grandchild.name, " (", grandchild.get_class(), ")")

	# Verbinde die Buttons
	print("\nVerbinde Buttons...")
	var start_button = $VBoxContainer/StartButton
	var exit_button = $VBoxContainer/ExitButton
	
	if start_button:
		print("✓ StartButton gefunden")
		# Versuche, das Signal direkt zu verbinden
		start_button.pressed.connect(_on_start_button_pressed)
		print("✓ StartButton-Signal verbunden")
	else:
		print("FEHLER: StartButton nicht gefunden!")
		# Versuche, den Pfad zu debuggen
		var vbox = get_node_or_null("VBoxContainer")
		if vbox:
			print("VBoxContainer gefunden, Kinder:")
			for child in vbox.get_children():
				print("- ", child.name, " (", child.get_class(), ")")
		else:
			print("FEHLER: VBoxContainer nicht gefunden!")
			print("Verfügbare Kinder:")
			for child in get_children():
				print("- ", child.name, " (", child.get_class(), ")")

	if exit_button:
		print("✓ ExitButton gefunden")
		exit_button.pressed.connect(_on_exit_button_pressed)
	else:
		print("FEHLER: ExitButton nicht gefunden!")

	print("\n=== Menu _ready() abgeschlossen ===\n")

func _on_start_button_pressed() -> void:
	print("\n--- Start-Button wurde gedrückt ---")
	
	if main_scene == null:
		print("FEHLER: main_scene ist null!")
		return
	
	print("Versuche, die Hauptszene zu instanziieren...")
	var main_instance = main_scene.instantiate()
	
	if main_instance == null:
		print("FEHLER: Konnte die Hauptszene nicht instanziieren!")
		return
	
	print("Hauptszene erfolgreich instanziiert")
	
	# Füge die Hauptszene zum Szenenbaum hinzu
	var root = get_tree().root
	if root == null:
		print("FEHLER: Konnte den Wurzelknoten nicht finden!")
		return
	
	print("Füge Hauptszene zum Szenenbaum hinzu...")
	root.add_child(main_instance)
	print("Hauptszene erfolgreich zum Szenenbaum hinzugefügt")
	
	# Verstecke das Menü
	self.visible = false
	print("Menü erfolgreich versteckt")
	
	# Optional: Entferne das Menü komplett, falls es nicht mehr benötigt wird
	# queue_free()
	print("--- Start-Button-Verarbeitung abgeschlossen ---\n")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
