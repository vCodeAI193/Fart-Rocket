extends Control
## MainMenu – Hauptmenü mit Level-Auswahl
## ======================================
## Zeigt die drei Starter-Level zur Auswahl an, inklusive der bisher
## erreichten Stern-Bewertung. Ein Tippen auf ein Level startet es.

@onready var _level_buttons: HBoxContainer = $LevelButtons

var _settings_screen: SettingsScreen
var _onboarding: OnboardingScreen
var _bestiary_screen: BestiaryScreen  # FR-118


var _bg_node: Node2D  # FR-231: animierter Hintergrund


func _ready() -> void:
	# FR-231: Animierter Sternenhintergrund im Hauptmenü
	_bg_node = Node2D.new()
	_bg_node.z_index = -10
	add_child(_bg_node)
	_build_menu_bg()
	# FR-222: Einstellungs-Overlay erstellen
	_settings_screen = preload("res://scenes/SettingsScreen.tscn").instantiate()
	add_child(_settings_screen)
	# FR-240: Onboarding beim ersten Start
	_onboarding = preload("res://scenes/OnboardingScreen.tscn").instantiate()
	add_child(_onboarding)
	_onboarding.show_if_needed()
	# FR-118: Gegner-Bestiarium
	_bestiary_screen = preload("res://scenes/BestiaryScreen.tscn").instantiate()
	add_child(_bestiary_screen)
	_build_level_buttons()
	_build_settings_button()
	_build_bestiary_button()


## FR-231: Prozeduraler Sternenhintergrund mit Drift-Animation.
func _build_menu_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_node.add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(60):
		var star := ColorRect.new()
		var sz := rng.randf_range(2.0, 5.0)
		star.custom_minimum_size = Vector2(sz, sz)
		star.color = Color(0.8, 0.85, 1.0, rng.randf_range(0.3, 0.9))
		star.position = Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1200))
		_bg_node.add_child(star)
		# Langsam nach rechts driften lassen
		var drift_x := rng.randf_range(8.0, 28.0)
		var tween := star.create_tween()
		tween.set_loops()
		tween.tween_property(star, "position:x", star.position.x + 1920.0, 1920.0 / drift_x)
		tween.tween_callback(func() -> void: star.position.x = -8.0)


## FR-233: Android-Zurück-Taste schließt Einstellungen oder beendet das Spiel.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings_screen.visible:
			_settings_screen.visible = false
		else:
			get_tree().quit()


## Erzeugt für jedes Level einen Button samt Stern-Anzeige.
func _build_level_buttons() -> void:
	for i in range(1, GameManager.TOTAL_LEVELS + 1):
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 12)

		# Level-Button
		var button := Button.new()
		button.text = "Level %d" % i
		button.custom_minimum_size = Vector2(280, 200)
		button.add_theme_font_size_override("font_size", 52)
		button.pressed.connect(_on_level_selected.bind(i))
		box.add_child(button)

		# Stern-Anzeige unter dem Button
		var stars_label := Label.new()
		var stars: int = GameManager.level_stars.get(i, 0)
		stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		stars_label.add_theme_font_size_override("font_size", 48)
		stars_label.add_theme_color_override("font_color", Color(1, 0.82, 0.15))
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(stars_label)

		_level_buttons.add_child(box)


## FR-222: Einstellungs-Button oben rechts hinzufügen.
func _build_settings_button() -> void:
	var btn := Button.new()
	btn.text = "Einstellungen"
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = 20.0
	btn.offset_right = -20.0
	btn.offset_bottom = 92.0
	btn.pressed.connect(_on_settings_pressed)
	add_child(btn)


func _on_settings_pressed() -> void:
	GameManager.vibrate(15)  # FR-247: UI-Feedback
	_settings_screen.show_settings()


## FR-118: Bestiarium-Button unten rechts hinzufügen.
func _build_bestiary_button() -> void:
	var btn := Button.new()
	btn.text = "Bestiarium"
	btn.custom_minimum_size = Vector2(260, 72)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.offset_left = -280.0
	btn.offset_top = -92.0
	btn.offset_right = -20.0
	btn.offset_bottom = -20.0
	btn.pressed.connect(_on_bestiary_pressed)
	add_child(btn)


func _on_bestiary_pressed() -> void:
	GameManager.vibrate(15)
	_bestiary_screen.show_bestiary()


## Startet das gewählte Level: Auswahl merken und zur Main-Szene wechseln.
func _on_level_selected(level_index: int) -> void:
	GameManager.current_level = level_index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
