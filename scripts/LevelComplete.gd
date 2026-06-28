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
	_spawn_confetti()  # FR-268


## FR-268: Konfetti-Regen beim Levelende.
func _spawn_confetti() -> void:
	var colors := [
		Color(1.0, 0.25, 0.25), Color(1.0, 0.85, 0.15),
		Color(0.25, 0.85, 0.25), Color(0.3, 0.65, 1.0), Color(0.9, 0.3, 0.9)
	]
	for i in range(5):
		var p := CPUParticles2D.new()
		p.position = Vector2(200.0 + i * 310.0, -10.0)
		p.direction = Vector2(0.0, 1.0)
		p.spread = 55.0
		p.emitting = true
		p.one_shot = true
		p.explosiveness = 0.85
		p.amount = 28
		p.lifetime = 3.0
		p.initial_velocity_min = 180.0
		p.initial_velocity_max = 460.0
		p.gravity = Vector2(0.0, 180.0)
		p.scale_amount_min = 5.0
		p.scale_amount_max = 13.0
		p.color = colors[i % colors.size()]
		add_child(p)

	visible = true
