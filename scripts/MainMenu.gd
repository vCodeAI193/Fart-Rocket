extends Control
## MainMenu – Hauptmenü mit Level-Auswahl
## ======================================
## Zeigt die drei Starter-Level zur Auswahl an, inklusive der bisher
## erreichten Stern-Bewertung. Ein Tippen auf ein Level startet es.

@onready var _level_buttons: HBoxContainer = $LevelButtons

var _settings_screen: SettingsScreen
var _onboarding: OnboardingScreen


func _ready() -> void:
	# FR-222: Einstellungs-Overlay erstellen
	_settings_screen = preload("res://scenes/SettingsScreen.tscn").instantiate()
	add_child(_settings_screen)
	# FR-240: Onboarding beim ersten Start
	_onboarding = preload("res://scenes/OnboardingScreen.tscn").instantiate()
	add_child(_onboarding)
	_onboarding.show_if_needed()
	_build_level_buttons()
	_build_settings_button()


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
	_settings_screen.show_settings()


## Startet das gewählte Level: Auswahl merken und zur Main-Szene wechseln.
func _on_level_selected(level_index: int) -> void:
	GameManager.current_level = level_index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
