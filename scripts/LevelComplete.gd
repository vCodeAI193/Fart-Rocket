extends CanvasLayer
class_name LevelComplete
## LevelComplete – Abschlussbildschirm
## ===================================
## Zeigt nach erfolgreichem Level die Stern-Bewertung (1–3 Sterne),
## gesammelte Münzen und die Zeit. Bietet Buttons für "Nächstes Level",
## "Wiederholen" und "Hauptmenü".

signal next_level_pressed
signal retry_pressed
signal menu_pressed

@onready var _stars_label: Label = $Root/Panel/VBox/StarsLabel
@onready var _info_label: Label = $Root/Panel/VBox/InfoLabel
@onready var _next_button: Button = $Root/Panel/VBox/Buttons/NextButton
@onready var _retry_button: Button = $Root/Panel/VBox/Buttons/RetryButton
@onready var _menu_button: Button = $Root/Panel/VBox/Buttons/MenuButton


func _ready() -> void:
	visible = false
	_next_button.pressed.connect(func(): next_level_pressed.emit())
	_retry_button.pressed.connect(func(): retry_pressed.emit())
	_menu_button.pressed.connect(func(): menu_pressed.emit())


## Zeigt das Ergebnis an.
##  stars     : erreichte Sterne (1..3)
##  coins     : eingesammelte Münzen
##  time_sec  : benötigte Zeit in Sekunden
##  has_next  : ob ein nächstes Level existiert
func show_result(stars: int, coins: int, time_sec: float, has_next: bool) -> void:
	# Stern-Anzeige: gefüllte (★) und leere (☆) Sterne
	var filled := "★".repeat(stars)
	var empty := "☆".repeat(3 - stars)
	_stars_label.text = filled + empty

	var minutes := int(time_sec) / 60
	var seconds := int(time_sec) % 60
	_info_label.text = "Münzen: %d\nZeit: %02d:%02d" % [coins, minutes, seconds]

	# "Nächstes Level" nur anbieten, wenn es eines gibt
	_next_button.visible = has_next

	visible = true
