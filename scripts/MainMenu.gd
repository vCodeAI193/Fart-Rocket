extends Control
## MainMenu – Hauptmenü mit Level-Auswahl
## ======================================
## Zeigt die drei Starter-Level zur Auswahl an, inklusive der bisher
## erreichten Stern-Bewertung. Ein Tippen auf ein Level startet es.

@onready var _level_buttons: HBoxContainer = $LevelButtons


func _ready() -> void:
	_build_level_buttons()


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


## Startet das gewählte Level: Auswahl merken und zur Main-Szene wechseln.
func _on_level_selected(level_index: int) -> void:
	GameManager.current_level = level_index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
