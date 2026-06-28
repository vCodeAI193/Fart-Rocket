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
signal charge_regen_progress(fraction)   # Fortschritt der nachladenden Ladung (0..1)
signal combo_changed(count, multiplier)  # Combo-Zähler/Multiplikator geändert (FR-003)
signal xp_changed(total_xp, player_level)  # FR-301: XP/Level geändert
signal double_coins_changed(active)        # FR-086: Doppel-Münzen-Status

# --- Konstanten -------------------------------------------------
const TOTAL_LEVELS := 3

# FR-003: Zeitfenster (Sekunden), in dem Folge-Münzen die Combo erhöhen
const COMBO_WINDOW := 2.0
# FR-003: höchster Combo-Multiplikator
const COMBO_MAX_MULTIPLIER := 5

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
var max_charges: int = 0                 # maximale Furz-Ladungen im aktuellen Level

# Bestwertung (Sterne 0..3) je Level, persistent während der Sitzung
var level_stars := {1: 0, 2: 0, 3: 0}

# --- FR-003: Combo-Zustand --------------------------------------
var combo_count: int = 0
var _combo_elapsed: float = 0.0

# --- FR-086: Doppel-Münzen-Status -------------------------------
var double_coins_active: bool = false
var _double_coins_remaining: float = 0.0

# --- FR-301: XP / Spieler-Level ---------------------------------
var total_xp: int = 0
var player_level: int = 1
const XP_PER_COIN := 5
const XP_PER_STAR := 20
const XP_PER_LEVEL := 100

# --- Einstellungen (FR-045 Haptik, FR-249 Stummschaltung) -------
var haptics_enabled: bool = true
var sound_muted: bool = false


func _ready() -> void:
	# Beim Start einmal den gespeicherten Fortschritt laden (falls vorhanden)
	_load_progress()
	# Gespeicherte Audio-Einstellung anwenden
	_apply_mute()


func _process(delta: float) -> void:
	# FR-003: Combo läuft nach dem Zeitfenster ab
	if combo_count > 0:
		_combo_elapsed += delta
		if _combo_elapsed >= COMBO_WINDOW:
			combo_count = 0
			combo_changed.emit(0, 1)
	# FR-086: Doppel-Münzen-Timer herunterzählen
	if _double_coins_remaining > 0.0:
		_double_coins_remaining = maxf(0.0, _double_coins_remaining - delta)
		if _double_coins_remaining == 0.0:
			double_coins_active = false
			double_coins_changed.emit(false)


## Setzt die Zähler für ein neu gestartetes Level zurück.
func start_level(level_index: int, max_charges: int) -> void:
	current_level = level_index
	total_coins = 0
	total_score = 0
	self.max_charges = max_charges
	charges_remaining = max_charges
	combo_count = 0
	_combo_elapsed = 0.0
	# UI informieren
	coins_changed.emit(total_coins)
	score_changed.emit(total_score)
	charges_changed.emit(charges_remaining)
	charge_regen_progress.emit(0.0)
	combo_changed.emit(0, 1)


## Eine Münze wurde eingesammelt (mit Combo-Multiplikator, FR-003).
func add_coin(value: int) -> void:
	# Combo erhöhen, wenn die letzte Münze im Zeitfenster lag
	if _combo_elapsed <= COMBO_WINDOW:
		combo_count += 1
	else:
		combo_count = 1
	_combo_elapsed = 0.0
	var multiplier := clampi(combo_count, 1, COMBO_MAX_MULTIPLIER)

	total_coins += 1
	# FR-086: Doppel-Münzen verdoppeln den Punktewert
	var effective_value := value * (2 if double_coins_active else 1)
	total_score += effective_value * multiplier
	coins_changed.emit(total_coins)
	score_changed.emit(total_score)
	combo_changed.emit(combo_count, multiplier)
	# FR-301: XP für gesammelte Münze
	add_xp(XP_PER_COIN)


## Eine Furz-Ladung wurde verbraucht. Gibt true zurück,
## wenn noch eine Ladung verfügbar war.
func use_charge() -> bool:
	return use_charges(1)


## Verbraucht mehrere Furz-Ladungen auf einmal (FR-002: Mega/Doppel kosten 2).
## Gibt true zurück, wenn genügend Ladungen vorhanden waren.
func use_charges(count: int) -> bool:
	if count <= 0:
		return true
	if charges_remaining < count:
		return false
	charges_remaining -= count
	charges_changed.emit(charges_remaining)
	return true


## Lädt eine Furz-Ladung nach (für die Regeneration, FR-001).
## Gibt true zurück, wenn tatsächlich nachgeladen wurde.
func add_charge() -> bool:
	if charges_remaining >= max_charges:
		return false
	charges_remaining += 1
	charges_changed.emit(charges_remaining)
	return true


## Meldet den Fortschritt der gerade nachladenden Ladung (0..1) an die UI.
func set_regen_progress(fraction: float) -> void:
	charge_regen_progress.emit(clampf(fraction, 0.0, 1.0))


# --- FR-045: Haptisches Feedback --------------------------------
## Löst eine kurze Vibration aus (sofern aktiviert und unterstützt).
func vibrate(duration_ms: int = 30) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms)


func set_haptics(enabled: bool) -> void:
	haptics_enabled = enabled


# --- FR-249: Stummschaltung -------------------------------------
func set_muted(muted: bool) -> void:
	sound_muted = muted
	_apply_mute()


func toggle_muted() -> void:
	set_muted(not sound_muted)


func _apply_mute() -> void:
	# Master-Bus stummschalten (Index 0)
	AudioServer.set_bus_mute(0, sound_muted)


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


## FR-086: Doppel-Münzen-Modus für `duration` Sekunden aktivieren.
func activate_double_coins(duration: float) -> void:
	double_coins_active = true
	_double_coins_remaining = duration
	double_coins_changed.emit(true)


## FR-301: XP hinzufügen und ggf. Level hochzählen.
func add_xp(amount: int) -> void:
	total_xp += amount
	var new_level := 1 + total_xp / XP_PER_LEVEL
	if new_level != player_level:
		player_level = new_level
	xp_changed.emit(total_xp, player_level)


## Speichert die beste Stern-Bewertung für ein Level.
func record_stars(level_index: int, stars: int) -> void:
	if not level_stars.has(level_index):
		level_stars[level_index] = 0
	if stars > level_stars[level_index]:
		level_stars[level_index] = stars
		# FR-301: XP für Sterne vergeben
		add_xp(stars * XP_PER_STAR)
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
