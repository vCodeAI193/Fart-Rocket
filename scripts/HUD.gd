extends CanvasLayer
class_name HUD
## HUD – Heads-Up-Display
## =====================
## Zeigt während des Spiels an:
##  - Übrige Furz-Ladungen als Icons (grüne Wölkchen)
##  - Münzzähler
##  - Verstrichene Zeit (Timer)
## Reagiert über Signale auf Änderungen im GameManager.

@onready var _charges_box: HBoxContainer = $Root/ChargesBox
@onready var _coin_label: Label = $Root/CoinBox/CoinLabel
@onready var _timer_label: Label = $Root/TimerLabel

var _max_charges: int = 0
var _charge_icons: Array[ColorRect] = []

var _elapsed: float = 0.0
var _timer_running: bool = false


func _ready() -> void:
	# Auf globale Zustandsänderungen lauschen
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.charges_changed.connect(_on_charges_changed)
	_on_coins_changed(GameManager.total_coins)


func _process(delta: float) -> void:
	if _timer_running:
		_elapsed += delta
		_timer_label.text = _format_time(_elapsed)


## Vom Level/Main aufgerufen: Anzahl der Furz-Icons festlegen.
func set_max_charges(value: int) -> void:
	_max_charges = value
	# Vorhandene Icons entfernen
	for icon in _charge_icons:
		icon.queue_free()
	_charge_icons.clear()
	# Neue Icons erzeugen (grüne Wölkchen)
	for i in range(_max_charges):
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.color = Color(0.45, 0.85, 0.35)
		_charges_box.add_child(icon)
		_charge_icons.append(icon)


## Startet den Level-Timer.
func start_timer() -> void:
	_elapsed = 0.0
	_timer_running = true


## Stoppt den Timer und gibt die verstrichene Zeit zurück.
func stop_timer() -> float:
	_timer_running = false
	return _elapsed


# --- Signal-Handler ---------------------------------------------
func _on_coins_changed(total: int) -> void:
	_coin_label.text = "x %d" % total


func _on_charges_changed(remaining: int) -> void:
	# Verbrauchte Ladungen ausgrauen
	for i in range(_charge_icons.size()):
		if i < remaining:
			_charge_icons[i].color = Color(0.45, 0.85, 0.35)      # aktiv (grün)
		else:
			_charge_icons[i].color = Color(0.3, 0.3, 0.3, 0.5)    # verbraucht


# --- Hilfsfunktionen --------------------------------------------
func _format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	return "%02d:%02d" % [minutes, seconds]
