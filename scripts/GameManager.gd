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
signal fart_letters_changed(collected)     # FR-092: F-A-R-T Buchstaben gesammelt
signal coin_progress_changed(collected, total)  # FR-099: Sammel-Fortschritt x/y

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

# --- FR-092: F-A-R-T Buchstaben-Sammlung -------------------------
const FART_LETTERS := ["F", "A", "R", "T"]
var fart_letters_collected: Array[String] = []

# --- Einstellungen (FR-045 Haptik, FR-249 Stummschaltung) -------
var haptics_enabled: bool = true
var sound_muted: bool = false

# --- FR-341: Zeitrennen-Modus (Time Attack) ----------------------
var time_attack_mode: bool = false
var time_attack_best_times := {1: INF, 2: INF, 3: INF}  # Level -> beste Zeit (Sek.)

# --- FR-117: KI-Schwierigkeitsskalierung --------------------------
var _level_start_ticks: int = 0

# --- Steuerungs-Einstellungen (FR-042/043/044/059) ----------------
signal control_settings_changed
var control_scheme: String = "direct"    # "direct" | "slingshot" (FR-042)
var left_handed_mode: bool = false       # FR-043
var touch_sensitivity: float = 1.0       # FR-044 (0.5..2.0)
var touch_dead_zone: float = 20.0        # FR-044, Pixel

# --- FR-060: Geste zum Zurücksetzen der Kamera --------------------
signal camera_reset_requested

# --- FR-189/200: Kamera-Einstellungen -----------------------------
var camera_shake_intensity: float = 1.0   # FR-189 (0.0..2.0)
var camera_smoothing: float = 8.0         # FR-200 (2.0..16.0, höher = straffer)

# --- FR-099: Sammel-Fortschritt pro Level (x/y Münzen) ------------
var level_coin_total: int = 0
var level_coin_collected: int = 0

# --- FR-091: Schlüssel und Schlösser (pro Level zurückgesetzt) ----
var collected_keys: Array[String] = []

# --- FR-093: Tagesmünze als Login-Bonus ---------------------------
var last_daily_coin_date: String = ""
const DAILY_COIN_REWARD := 100

# --- FR-089: Sammelkarten-/Sticker-System -------------------------
const STICKER_SET := [
	"Rakete", "Furz-Wolke", "Goldmünze", "Sternenhimmel", "Astronaut",
	"Regenbogen", "Diamant", "Blitz", "Mond", "Komet",
]
var collected_stickers: Array[String] = []
signal sticker_collected(name)

# --- FR-100: Power-up-Inventar zum manuellen Einsetzen ------------
signal inventory_changed(stored_type)
signal inventory_use_requested(stored_type)
var stored_powerup: String = ""  # "" = leer, sonst z.B. "shield", "slowmo", "double_coins"

# --- FR-118: Gegner-Bestiarium/Sammlung ---------------------------
# Bekannte Gegner-Typen (Anzeigename je Klasse), erweiterbar bei neuen Gegnern.
const ENEMY_BESTIARY := {
	"ShooterEnemy": "Geschützturm",
	"PatrolEnemy": "Flug-Patrouille",
	"JumpingEnemy": "Hüpfer",
	"CoinThiefEnemy": "Münzdieb",
	"ChaserEnemy": "Verfolger",
	"StaticTurret": "Laser-Turm",
	"DodgingEnemy": "Ausweicher",
	"SwarmEnemy": "Schwarm",
	"ShieldedEnemy": "Schild-Wächter",
	"TeleportingEnemy": "Teleporter",
	"LungingEnemy": "Sprung-Angreifer",
	"StealthEnemy": "Tarn-Kriecher",
	"BlowableEnemy": "Flatterling",
	"MiniBoss": "Mini-Boss",
	"EndBoss": "End-Boss",
}
var discovered_enemies: Array[String] = []


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
	fart_letters_collected.clear()  # FR-092: Buchstaben pro Level zurücksetzen
	_level_start_ticks = Time.get_ticks_msec()  # FR-117: Basis für Schwierigkeitsskalierung
	level_coin_total = 0             # FR-099: Fortschritt pro Level zurücksetzen
	level_coin_collected = 0
	collected_keys.clear()           # FR-091: Schlüssel pro Level zurücksetzen
	# UI informieren
	coins_changed.emit(total_coins)
	score_changed.emit(total_score)
	charges_changed.emit(charges_remaining)
	charge_regen_progress.emit(0.0)
	combo_changed.emit(0, 1)
	fart_letters_changed.emit(fart_letters_collected)


## FR-120: Zufällige Belohnung für besiegte Gegner (Münzen oder XP).
## Wird von Gegner-Skripten (z.B. ShieldedEnemy) beim Besiegen aufgerufen.
func grant_enemy_defeat_reward(base_coin_value: int = 20) -> Dictionary:
	if randf() < 0.75:
		var amount := randi_range(int(base_coin_value * 0.7), int(base_coin_value * 1.3))
		add_coin(amount)
		return {"type": "coins", "amount": amount}
	else:
		var xp := base_coin_value
		add_xp(xp)
		return {"type": "xp", "amount": xp}


## FR-117: Liefert einen Schwierigkeits-Multiplikator (1.0..~1.8) für
## KI-Verhalten (Geschwindigkeit, Reaktionszeit etc.). Steigt mit dem
## Level-Index und je länger der aktuelle Versuch bereits dauert
## (bestraft "Trödeln" leicht, ohne unfair zu werden).
func get_difficulty_multiplier() -> float:
	var level_factor := 1.0 + (float(current_level - 1) * 0.15)
	var elapsed_sec := (Time.get_ticks_msec() - _level_start_ticks) / 1000.0
	var time_factor := 1.0 + clampf(elapsed_sec / 120.0, 0.0, 0.3)
	return clampf(level_factor * time_factor, 1.0, 1.8)


## FR-042: Wechselt zwischen "direct" (Stoß in Zugrichtung) und
## "slingshot" (Stoß entgegen der Zugrichtung, wie eine Steinschleuder).
func set_control_scheme(scheme: String) -> void:
	control_scheme = scheme
	control_settings_changed.emit()
	_save_progress()


## FR-043: Schaltet den Linkshänder-Modus (gespiegeltes HUD) um.
func set_left_handed(enabled: bool) -> void:
	left_handed_mode = enabled
	control_settings_changed.emit()
	_save_progress()


## FR-044: Setzt die Touch-Empfindlichkeit (0.5 = träge, 2.0 = sehr empfindlich).
func set_touch_sensitivity(value: float) -> void:
	touch_sensitivity = clampf(value, 0.5, 2.0)
	control_settings_changed.emit()
	_save_progress()


## FR-044: Setzt die Dead-Zone in Pixeln (minimale Zugweite fürs Zielen).
func set_touch_dead_zone(value: float) -> void:
	touch_dead_zone = clampf(value, 0.0, 60.0)
	control_settings_changed.emit()
	_save_progress()


## FR-189: Setzt die globale Kamera-Rüttel-Intensität (0.0 = aus, 2.0 = stark).
func set_camera_shake_intensity(value: float) -> void:
	camera_shake_intensity = clampf(value, 0.0, 2.0)
	_save_progress()


## FR-200: Setzt die Kamera-Glättung (Lerp-Geschwindigkeit beim Folgen).
func set_camera_smoothing(value: float) -> void:
	camera_smoothing = clampf(value, 2.0, 16.0)
	_save_progress()


## FR-089: Sammelt eine zufällige, noch nicht besessene Sticker-Karte.
## Gibt den Namen der gesammelten Karte zurück (oder "" wenn alle voll sind).
func collect_random_sticker() -> String:
	var missing := STICKER_SET.filter(func(s): return not s in collected_stickers)
	if missing.is_empty():
		return ""
	var picked: String = missing[randi() % missing.size()]
	collected_stickers.append(picked)
	sticker_collected.emit(picked)
	_save_progress()
	return picked


## FR-100: Speichert ein Power-up im Inventar statt es sofort zu aktivieren.
## Ist bereits eines gespeichert, wird das alte überschrieben.
func store_powerup(powerup_type: String) -> void:
	stored_powerup = powerup_type
	inventory_changed.emit(stored_powerup)


## FR-100: Löst das gespeicherte Power-up manuell aus (z.B. per HUD-Button).
func use_stored_powerup() -> void:
	if stored_powerup == "":
		return
	inventory_use_requested.emit(stored_powerup)
	stored_powerup = ""
	inventory_changed.emit(stored_powerup)


## FR-093: Prüft, ob die Tagesmünze heute noch nicht eingesammelt wurde.
func is_daily_coin_available() -> bool:
	var today := Time.get_date_string_from_system()
	return last_daily_coin_date != today


## FR-093: Sammelt die Tagesmünze ein (nur einmal pro Kalendertag).
func claim_daily_coin() -> bool:
	if not is_daily_coin_available():
		return false
	last_daily_coin_date = Time.get_date_string_from_system()
	add_coin(DAILY_COIN_REWARD)
	_save_progress()
	return true


## FR-091: Sammelt einen Schlüssel für das laufende Level.
func collect_key(key_id: String) -> void:
	if not key_id in collected_keys:
		collected_keys.append(key_id)


## FR-091: Prüft, ob der Spieler einen bestimmten Schlüssel besitzt.
func has_key(key_id: String) -> bool:
	return key_id in collected_keys


## FR-099: Setzt die Gesamtzahl der Münzen im aktuellen Level (für x/y-Anzeige).
func set_level_coin_total(total: int) -> void:
	level_coin_total = total
	coin_progress_changed.emit(level_coin_collected, level_coin_total)


## FR-099: Zählt eine eingesammelte Münze für die Fortschrittsanzeige.
func record_coin_pickup() -> void:
	level_coin_collected += 1
	coin_progress_changed.emit(level_coin_collected, level_coin_total)


## FR-092: Sammelt einen F-A-R-T-Buchstaben. Bei vollständigem Satz Bonus.
func collect_fart_letter(letter: String) -> void:
	if letter in fart_letters_collected:
		return
	fart_letters_collected.append(letter)
	fart_letters_changed.emit(fart_letters_collected)
	if fart_letters_collected.size() >= FART_LETTERS.size():
		add_coin(200)  # Bonus für kompletten F-A-R-T Satz


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


## FR-341: Prüft und speichert eine neue Bestzeit für den Zeitrennen-Modus.
## Gibt true zurück, wenn eine neue Bestzeit erreicht wurde.
func record_time_attack(level_index: int, time_sec: float) -> bool:
	if not time_attack_best_times.has(level_index):
		time_attack_best_times[level_index] = INF
	if time_sec < time_attack_best_times[level_index]:
		time_attack_best_times[level_index] = time_sec
		_save_progress()
		return true
	return false


## FR-341: Liefert die Bestzeit für ein Level (INF, falls noch keine).
func get_best_time(level_index: int) -> float:
	return time_attack_best_times.get(level_index, INF)


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
	cfg.set_value("bestiary", "discovered", discovered_enemies)
	cfg.set_value("daily", "last_coin_date", last_daily_coin_date)  # FR-093
	cfg.set_value("stickers", "collected", collected_stickers)  # FR-089
	cfg.set_value("input", "control_scheme", control_scheme)  # FR-042/043/044
	cfg.set_value("input", "left_handed", left_handed_mode)
	cfg.set_value("input", "touch_sensitivity", touch_sensitivity)
	cfg.set_value("input", "touch_dead_zone", touch_dead_zone)
	cfg.set_value("camera", "shake_intensity", camera_shake_intensity)  # FR-189
	cfg.set_value("camera", "smoothing", camera_smoothing)  # FR-200
	cfg.save(SAVE_PATH)


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return  # Noch kein Speicherstand vorhanden – das ist in Ordnung
	for lvl in level_stars.keys():
		level_stars[lvl] = int(cfg.get_value("stars", str(lvl), 0))
	var saved: Array = cfg.get_value("bestiary", "discovered", [])
	discovered_enemies.assign(saved)
	last_daily_coin_date = cfg.get_value("daily", "last_coin_date", "")  # FR-093
	var saved_stickers: Array = cfg.get_value("stickers", "collected", [])  # FR-089
	collected_stickers.assign(saved_stickers)
	control_scheme = cfg.get_value("input", "control_scheme", "direct")  # FR-042/043/044
	left_handed_mode = cfg.get_value("input", "left_handed", false)
	touch_sensitivity = cfg.get_value("input", "touch_sensitivity", 1.0)
	touch_dead_zone = cfg.get_value("input", "touch_dead_zone", 20.0)
	camera_shake_intensity = cfg.get_value("camera", "shake_intensity", 1.0)  # FR-189
	camera_smoothing = cfg.get_value("camera", "smoothing", 8.0)  # FR-200


## FR-118: Registriert einen Gegner-Typ als entdeckt (persistiert).
func discover_enemy(class_id: String) -> void:
	if class_id in discovered_enemies:
		return
	discovered_enemies.append(class_id)
	_save_progress()
