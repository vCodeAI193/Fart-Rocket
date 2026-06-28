extends CanvasLayer
class_name HUD
## HUD – Heads-Up-Display
## =====================
## Zeigt während des Spiels an:
##  - Übrige Furz-Ladungen als Icons (grüne Wölkchen)
##  - Münzzähler
##  - Verstrichene Zeit (Timer)
## Reagiert über Signale auf Änderungen im GameManager.

signal fart_type_selected(index)             # Spieler hat einen Furz-Typ gewählt (FR-002)

@onready var _charges_box: HBoxContainer = $Root/ChargesBox
@onready var _coin_label: Label = $Root/CoinBox/CoinLabel
@onready var _timer_label: Label = $Root/TimerLabel
@onready var _fart_types_box: HBoxContainer = $Root/FartTypesBox
@onready var _pause_btn: Button = $Root/PauseButton       # FR-201
@onready var _combo_label: Label = $Root/ComboLabel       # FR-003

var _max_charges: int = 0
var _charge_icons: Array[ColorRect] = []
var _fart_type_buttons: Array[Button] = []

var _elapsed: float = 0.0
var _timer_running: bool = false
var _is_paused: bool = false                               # FR-201


func _ready() -> void:
	# HUD bleibt auch im Pause-Modus aktiv
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Auf globale Zustandsänderungen lauschen
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.charges_changed.connect(_on_charges_changed)
	GameManager.charge_regen_progress.connect(_on_regen_progress)
	GameManager.combo_changed.connect(_on_combo_changed)   # FR-003
	_pause_btn.pressed.connect(_on_pause_pressed)          # FR-201
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


## FR-002: Baut die Auswahl-Buttons für die Furz-Typen auf.
func setup_fart_types(types: Array, current_index: int) -> void:
	for btn in _fart_type_buttons:
		btn.queue_free()
	_fart_type_buttons.clear()

	for i in range(types.size()):
		var data: Dictionary = types[i]
		var btn := Button.new()
		btn.text = str(data["name"])
		btn.custom_minimum_size = Vector2(200, 76)
		btn.add_theme_font_size_override("font_size", 34)
		# Einfärbung passend zum Furz-Typ
		btn.add_theme_color_override("font_color", data["color"])
		btn.pressed.connect(_on_fart_type_button.bind(i))
		_fart_types_box.add_child(btn)
		_fart_type_buttons.append(btn)

	highlight_fart_type(current_index)


## FR-002: Hebt den aktiven Furz-Typ-Button hervor.
func highlight_fart_type(index: int) -> void:
	for i in range(_fart_type_buttons.size()):
		# Aktiver Button voll sichtbar, inaktive abgedunkelt
		_fart_type_buttons[i].modulate = Color.WHITE if i == index else Color(0.6, 0.6, 0.6)


func _on_fart_type_button(index: int) -> void:
	fart_type_selected.emit(index)


## FR-201: Pausiert oder setzt das Spiel fort.
func _on_pause_pressed() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	_pause_btn.text = "▶" if _is_paused else "⏸"


## FR-003: Zeigt Combo-Multiplikator kurz in der Bildschirmmitte an.
func _on_combo_changed(count: int, multiplier: int) -> void:
	if count < 2:
		_combo_label.modulate.a = 0.0
		return
	_combo_label.text = "COMBO x%d!\n%dx PUNKTE" % [count, multiplier]
	var tween := create_tween()
	tween.tween_property(_combo_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.55)
	tween.tween_property(_combo_label, "modulate:a", 0.0, 0.35)


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


## FR-001: Füllt das nächste (nachladende) Icon entsprechend dem Fortschritt.
func _on_regen_progress(fraction: float) -> void:
	var idx := GameManager.charges_remaining
	if idx < 0 or idx >= _charge_icons.size():
		return
	# Von "verbraucht" (blass) zu "aktiv" (grün) überblenden
	_charge_icons[idx].color = Color(0.45, 0.85, 0.35, lerpf(0.25, 1.0, fraction))


# --- Hilfsfunktionen --------------------------------------------
func _format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	return "%02d:%02d" % [minutes, seconds]
