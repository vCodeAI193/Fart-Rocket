extends Node
## GameManager (Autoload / Singleton)
## ===================================
## Verwaltet den globalen Spielzustand über alle Szenen hinweg:
##  - Punktestand (Score) und gesammelte Münzen
##  - Aktuell ausgewähltes Level
##  - Übrige Furz-Ladungen im laufenden Level
##  - Erreichte Sterne pro Level (für die Level-Auswahl)
## Die Kommunikation mit der UI (HUD, Menüs) läuft über Signale.

# --- Signale ----------------------------------------------------
signal coins_changed(total_coins)        # Münzanzahl hat sich geändert
signal score_changed(total_score)        # Punktestand hat sich geändert
signal charges_changed(remaining)        # Furz-Ladungen haben sich geändert

# --- Konstanten -------------------------------------------------
const TOTAL_LEVELS := 3

# Pfade zu den Level-Szenen (Index 0 = Level 1)
const LEVEL_SCENES := [
	"res://levels/Level1.tscn",
	"res://levels/Level2.tscn",
	"res://levels/Level3.tscn",
]

# --- Laufender Spielzustand -------------------------------------
var current_level: int = 1              # 1-basiert (Level 1, 2, 3)
var total_coins: int = 0                # gesammelte Münzen im aktuellen Level
var total_score: int = 0                # Punkte im aktuellen Level
var charges_remaining: int = 0          # übrige Furz-Ladungen im Level

# Bestwertung (Sterne 0..3) je Level, persistent während der Sitzung
var level_stars := {1: 0, 2: 0, 3: 0}


func _ready() -> void:
	# Beim Start einmal den gespeicherten Fortschritt laden (falls vorhanden)
	_load_progress()


## Setzt die Zähler für ein neu gestartetes Level zurück.
func start_level(level_index: int, max_charges: int) -> void:
	current_level = level_index
	total_coins = 0
	total_score = 0
	charges_remaining = max_charges
	# UI informieren
	coins_changed.emit(total_coins)
	score_changed.emit(total_score)
	charges_changed.emit(charges_remaining)


## Eine Münze wurde eingesammelt.
func add_coin(value: int) -> void:
	total_coins += 1
	total_score += value
	coins_changed.emit(total_coins)
	score_changed.emit(total_score)


## Eine Furz-Ladung wurde verbraucht. Gibt true zurück,
## wenn noch eine Ladung verfügbar war.
func use_charge() -> bool:
	if charges_remaining <= 0:
		return false
	charges_remaining -= 1
	charges_changed.emit(charges_remaining)
	return true


## Berechnet die Stern-Bewertung (1..3) anhand der übrigen Ladungen.
func calculate_stars(max_charges: int) -> int:
	if max_charges <= 0:
		return 1
	var ratio := float(charges_remaining) / float(max_charges)
	if ratio >= 0.5:
		return 3
	elif charges_remaining >= 1:
		return 2
	else:
		return 1


## Speichert die beste Stern-Bewertung für ein Level.
func record_stars(level_index: int, stars: int) -> void:
	if not level_stars.has(level_index):
		level_stars[level_index] = 0
	if stars > level_stars[level_index]:
		level_stars[level_index] = stars
		_save_progress()


## Gibt true zurück, wenn ein nächstes Level existiert.
func has_next_level() -> bool:
	return current_level < TOTAL_LEVELS


## Liefert den Szenenpfad für ein 1-basiertes Level.
func get_level_scene_path(level_index: int) -> String:
	var idx := clampi(level_index - 1, 0, LEVEL_SCENES.size() - 1)
	return LEVEL_SCENES[idx]


# --- Speichern / Laden des Fortschritts -------------------------
const SAVE_PATH := "user://fartrocket_save.cfg"

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	for lvl in level_stars.keys():
		cfg.set_value("stars", str(lvl), level_stars[lvl])
	cfg.save(SAVE_PATH)


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return  # Noch kein Speicherstand vorhanden – das ist in Ordnung
	for lvl in level_stars.keys():
		level_stars[lvl] = int(cfg.get_value("stars", str(lvl), 0))
