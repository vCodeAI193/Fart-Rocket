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

# --- FR-215/216/220: HUD-Einstellungen -----------------------------
signal hud_settings_changed
var hud_minimal_mode: bool = false   # FR-215
var hud_scale: float = 1.0           # FR-216 (0.75..1.5)

# --- FR-219: Live-Ranglistenposition (lokale Versuchs-Historie) ----
var level_attempt_times: Dictionary = {}  # {level_index: Array[float]}

# --- FR-210: Tutorial-Hinweis-Overlays (dauerhaft, nicht pro Level) --
var tutorial_hint_seen: bool = false

# --- FR-226: Statistik-Bildschirm (dauerhafte Zähler) --------------
var stat_total_farts: int = 0
var stat_total_deaths: int = 0
var stat_total_playtime_sec: float = 0.0

# --- FR-236: Favoriten-Level ----------------------------------------
var favorite_levels: Array[int] = []

# --- FR-238: Schnellstart letztes Level ------------------------------
var last_played_level: int = 0

# --- FR-224: Shop / freischaltbare Skin-Farben -----------------------
var unlocked_skin_colors: Array[String] = ["default"]
var active_skin_color: String = "default"

# --- FR-180: Eigener Farb-Editor für den Standard-Skin -----------------
var custom_skin_color: Color = Color(0.95, 0.95, 0.95)


## FR-180: Setzt eine frei gewählte Skin-Farbe und rüstet sie sofort aus.
func set_custom_skin_color(color: Color) -> void:
	custom_skin_color = color
	active_skin_color = "custom"
	_save_progress()

# --- FR-161/163/166/167/175/176: Kosmetik-Ausrüstung (Mix&Match, FR-179) --
signal cosmetics_changed

var equipped_helmet: String = "helmet_none"
var equipped_outfit: String = "outfit_none"
var equipped_hat: String = "hat_none"
var equipped_face: String = "neutral"       # FR-167
var equipped_arrow_style: String = "arrow_classic"  # FR-175
var equipped_death_anim: String = "death_spin"      # FR-176
var equipped_victory_pose: String = "pose_wave"     # FR-177
var equipped_fart_color_style: String = "fart_classic"  # FR-164
var equipped_fart_sound: String = "fartsound_classic"    # FR-165

# FR-170: Seltenheitsstufen (beeinflussen Preis/Optik im Shop)
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

# id -> {name, slot, cost, rarity, unlocked_by_default}
const COSMETIC_CATALOG := {
	"helmet_none": {"name": "Kein Helm", "slot": "helmet", "cost": 0, "rarity": Rarity.COMMON},
	"helmet_visor": {"name": "Visier-Helm", "slot": "helmet", "cost": 150, "rarity": Rarity.COMMON},
	"helmet_viking": {"name": "Wikinger-Hörner", "slot": "helmet", "cost": 350, "rarity": Rarity.RARE},
	"helmet_mohawk": {"name": "Iro-Helm", "slot": "helmet", "cost": 350, "rarity": Rarity.RARE},
	"helmet_crown": {"name": "Krone", "slot": "helmet", "cost": 900, "rarity": Rarity.LEGENDARY},

	"outfit_none": {"name": "Kein Anzug", "slot": "outfit", "cost": 0, "rarity": Rarity.COMMON},
	"outfit_astronaut": {"name": "Astronaut", "slot": "outfit", "cost": 400, "rarity": Rarity.RARE},
	"outfit_hero": {"name": "Superheld", "slot": "outfit", "cost": 400, "rarity": Rarity.RARE},
	"outfit_animal": {"name": "Tier-Kostüm", "slot": "outfit", "cost": 400, "rarity": Rarity.RARE},

	"hat_none": {"name": "Kein Hut", "slot": "hat", "cost": 0, "rarity": Rarity.COMMON},
	"hat_top": {"name": "Zylinder", "slot": "hat", "cost": 200, "rarity": Rarity.COMMON},
	"hat_cap": {"name": "Käppi", "slot": "hat", "cost": 150, "rarity": Rarity.COMMON},
	"hat_shades": {"name": "Sonnenbrille", "slot": "hat", "cost": 250, "rarity": Rarity.RARE},

	"arrow_classic": {"name": "Klassisch", "slot": "arrow", "cost": 0, "rarity": Rarity.COMMON},
	"arrow_neon": {"name": "Neon", "slot": "arrow", "cost": 200, "rarity": Rarity.COMMON},
	"arrow_rainbow": {"name": "Regenbogen", "slot": "arrow", "cost": 500, "rarity": Rarity.EPIC},

	"death_spin": {"name": "Taumeln", "slot": "death", "cost": 0, "rarity": Rarity.COMMON},
	"death_confetti": {"name": "Konfetti-Explosion", "slot": "death", "cost": 300, "rarity": Rarity.RARE},
	"death_ghost": {"name": "Geist-Verblassen", "slot": "death", "cost": 300, "rarity": Rarity.RARE},

	"pose_wave": {"name": "Winken", "slot": "pose", "cost": 0, "rarity": Rarity.COMMON},
	"pose_flex": {"name": "Muskeln zeigen", "slot": "pose", "cost": 250, "rarity": Rarity.RARE},
	"pose_dance": {"name": "Freuden-Tanz", "slot": "pose", "cost": 250, "rarity": Rarity.RARE},

	"fart_classic": {"name": "Klassisch", "slot": "fartcolor", "cost": 0, "rarity": Rarity.COMMON},
	"fart_toxic": {"name": "Toxisch-Grün", "slot": "fartcolor", "cost": 200, "rarity": Rarity.COMMON},
	"fart_rainbow": {"name": "Regenbogen", "slot": "fartcolor", "cost": 500, "rarity": Rarity.EPIC},

	"fartsound_classic": {"name": "Klassisch", "slot": "fartsound", "cost": 0, "rarity": Rarity.COMMON},
	"fartsound_deep": {"name": "Basslastig", "slot": "fartsound", "cost": 200, "rarity": Rarity.COMMON},
	"fartsound_squeaky": {"name": "Quietschig", "slot": "fartsound", "cost": 200, "rarity": Rarity.COMMON},
	"fartsound_robotic": {"name": "Robotisch", "slot": "fartsound", "cost": 400, "rarity": Rarity.RARE},
}

var unlocked_cosmetics: Array[String] = [
	"helmet_none", "outfit_none", "hat_none", "arrow_classic",
	"death_spin", "pose_wave", "fart_classic", "fartsound_classic",
]

# FR-172: Saisonale Skins — nur in bestimmten Monaten kaufbar
const SEASONAL_COSMETICS := {
	"helmet_viking": [12, 1],  # Winter (Dez/Jan)
	"hat_top": [10, 11],       # Herbst (Okt/Nov)
}

# FR-174: Skin-des-Tages — täglich rotierender Gratis-Skin
var daily_skin_claimed_date: String = ""


## FR-169/170: Schaltet ein Kosmetik-Item per Guthaben frei.
func unlock_cosmetic(id: String) -> bool:
	if id in unlocked_cosmetics:
		return true
	var info: Dictionary = COSMETIC_CATALOG.get(id, {})
	if info.is_empty():
		return false
	var cost: int = info["cost"]
	if persistent_coins < cost:
		return false
	persistent_coins -= cost
	persistent_coins_changed.emit(persistent_coins)
	unlocked_cosmetics.append(id)
	_save_progress()
	return true


## FR-179: Rüstet ein Kosmetik-Item in seinem Slot aus (Mix&Match).
func equip_cosmetic(id: String) -> void:
	if not id in unlocked_cosmetics:
		return
	var info: Dictionary = COSMETIC_CATALOG.get(id, {})
	if info.is_empty():
		return
	match info["slot"]:
		"helmet": equipped_helmet = id
		"outfit": equipped_outfit = id
		"hat": equipped_hat = id
		"arrow": equipped_arrow_style = id
		"death": equipped_death_anim = id
		"pose": equipped_victory_pose = id
		"fartcolor": equipped_fart_color_style = id
		"fartsound": equipped_fart_sound = id
	cosmetics_changed.emit()
	_save_progress()


## FR-172: Prüft, ob ein saisonales Kosmetik-Item aktuell verfügbar ist.
func is_cosmetic_seasonally_available(id: String) -> bool:
	if not SEASONAL_COSMETICS.has(id):
		return true
	var current_month := Time.get_date_dict_from_system()["month"]
	return current_month in SEASONAL_COSMETICS[id]


## FR-174: Skin-des-Tages — liefert eine deterministische, täglich
## wechselnde Auswahl aus dem Katalog und schaltet sie beim Abholen frei.
func get_daily_skin_id() -> String:
	var pool := COSMETIC_CATALOG.keys().filter(func(id): return COSMETIC_CATALOG[id]["cost"] > 0)
	if pool.is_empty():
		return ""
	var day_seed := int(Time.get_unix_time_from_system() / 86400.0)
	return pool[day_seed % pool.size()]


func is_daily_skin_available() -> bool:
	return daily_skin_claimed_date != Time.get_date_string_from_system()


## FR-174: Schaltet den heutigen Skin-des-Tages kostenlos frei.
func claim_daily_skin() -> bool:
	if not is_daily_skin_available():
		return false
	var id := get_daily_skin_id()
	if id == "" or id in unlocked_cosmetics:
		daily_skin_claimed_date = Time.get_date_string_from_system()
		_save_progress()
		return false
	unlocked_cosmetics.append(id)
	daily_skin_claimed_date = Time.get_date_string_from_system()
	_save_progress()
	return true


## FR-178: Fortschritt der Kosmetik-Sammlung (freigeschaltet / gesamt).
func get_cosmetics_collection_progress() -> Vector2i:
	return Vector2i(unlocked_cosmetics.size(), COSMETIC_CATALOG.size())


# --- FR-224: Persistente Währung fürs Menü/Shop --------------------
# Hinweis: total_coins/total_score sind reine Session-Werte pro Level-
# Versuch (werden bei jedem start_level() zurückgesetzt). Für den Shop
# braucht es echtes dauerhaftes Guthaben, das beim Levelabschluss
# "eingezahlt" wird.
signal persistent_coins_changed(amount)
var persistent_coins: int = 0

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


## FR-226: Erhöht den Furz-Zähler (von Player bei jedem Stoß aufgerufen).
func record_fart() -> void:
	stat_total_farts += 1


## FR-226: Erhöht den Tod-Zähler (von Main bei jedem Tod aufgerufen).
func record_death() -> void:
	stat_total_deaths += 1
	_save_progress()


## FR-236: Schaltet den Favoriten-Status eines Levels um.
func toggle_favorite_level(level_index: int) -> void:
	if level_index in favorite_levels:
		favorite_levels.erase(level_index)
	else:
		favorite_levels.append(level_index)
	_save_progress()


## FR-237: Gesamtfortschritt in Prozent (erreichte Sterne / maximal mögliche).
func get_overall_progress_percent() -> float:
	var earned := 0
	for lvl in level_stars.keys():
		earned += level_stars[lvl]
	var max_possible := TOTAL_LEVELS * 3
	if max_possible <= 0:
		return 0.0
	return (float(earned) / float(max_possible)) * 100.0


## FR-224: Bankt den erspielten Punktestand eines abgeschlossenen Levels
## als dauerhaftes Guthaben ein (von Main beim Levelabschluss aufgerufen).
func bank_level_coins(score_amount: int) -> void:
	if score_amount <= 0:
		return
	persistent_coins += score_amount
	persistent_coins_changed.emit(persistent_coins)
	_save_progress()


## FR-224: Schaltet eine Skin-Farbe per dauerhaftem Guthaben frei.
func unlock_skin_color(id: String, cost: int) -> bool:
	if id in unlocked_skin_colors:
		return true
	if persistent_coins < cost:
		return false
	persistent_coins -= cost
	persistent_coins_changed.emit(persistent_coins)
	unlocked_skin_colors.append(id)
	_save_progress()
	return true


## FR-210: Markiert den Tutorial-Hinweis dauerhaft als gesehen.
func mark_tutorial_hint_seen() -> void:
	tutorial_hint_seen = true
	_save_progress()


## FR-215: Schaltet den minimalistischen HUD-Modus um.
func set_hud_minimal_mode(enabled: bool) -> void:
	hud_minimal_mode = enabled
	hud_settings_changed.emit()
	_save_progress()


## FR-216: Setzt die HUD-Skalierung (0.75..1.5).
func set_hud_scale(value: float) -> void:
	hud_scale = clampf(value, 0.75, 1.5)
	hud_settings_changed.emit()
	_save_progress()


## FR-219: Registriert eine abgeschlossene Levelzeit für die lokale
## Rang-Historie und gibt zurück, auf welchem Rang sie sich einordnet.
func record_attempt_time(level_index: int, time_sec: float) -> int:
	if not level_attempt_times.has(level_index):
		level_attempt_times[level_index] = []
	var times: Array = level_attempt_times[level_index]
	times.append(time_sec)
	_save_progress()
	return get_live_rank(level_index, time_sec)


## FR-219: Liefert den (1-basierten) Rang einer Zeit unter den bisherigen
## Versuchen — je schneller, desto besser der Rang. Wird auch live während
## des laufenden Versuchs für die HUD-Anzeige genutzt.
func get_live_rank(level_index: int, current_time_sec: float) -> int:
	var times: Array = level_attempt_times.get(level_index, [])
	var better_count := 0
	for t in times:
		if t < current_time_sec:
			better_count += 1
	return better_count + 1


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


# --- FR-239: Prozedurales UI-Sound-Feedback (kein externes Audio) -
var _ui_click_stream: AudioStreamWAV
var _ui_click_players: Array[AudioStreamPlayer] = []
const UI_CLICK_POOL_SIZE := 4


## FR-239: Spielt einen kurzen, prozedural erzeugten Klick-Ton für
## Menü-Interaktionen ab (Button-Hover/-Press, Tab-Wechsel etc.).
func play_ui_click(pitch: float = 1.0) -> void:
	if sound_muted:
		return
	if _ui_click_stream == null:
		_ui_click_stream = _generate_click_tone()
	var player := _get_free_ui_player()
	player.stream = _ui_click_stream
	player.pitch_scale = pitch
	player.play()


func _get_free_ui_player() -> AudioStreamPlayer:
	for p in _ui_click_players:
		if not p.playing:
			return p
	if _ui_click_players.size() < UI_CLICK_POOL_SIZE:
		var new_player := AudioStreamPlayer.new()
		add_child(new_player)
		_ui_click_players.append(new_player)
		return new_player
	return _ui_click_players[0]  # Pool voll: ältesten wiederverwenden


## FR-239: Erzeugt einen kurzen, sich abklingenden Sinuston (kein Asset).
func _generate_click_tone() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.08
	var frequency := 880.0
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit mono
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / sample_count)  # linear ausklingend
		var sample := sin(TAU * frequency * t) * envelope * 0.5
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream


# --- FR-165: Prozedurale Furz-Sound-Pakete -------------------------
var _fart_sound_cache: Dictionary = {}  # pack_id -> AudioStreamWAV
var _fart_sound_players: Array[AudioStreamPlayer] = []
const FART_SOUND_POOL_SIZE := 3


## FR-165: Spielt einen prozedural erzeugten Furz-Sound passend zum
## ausgerüsteten Sound-Paket ab, moduliert durch die Stoßstärke.
func play_fart_sound(strength: float = 1.0) -> void:
	if sound_muted:
		return
	var pack := equipped_fart_sound
	if not _fart_sound_cache.has(pack):
		_fart_sound_cache[pack] = _generate_fart_tone(pack)
	var player := _get_free_fart_player()
	player.stream = _fart_sound_cache[pack]
	player.pitch_scale = clampf(0.8 + strength * 0.4, 0.6, 1.8)
	player.play()


func _get_free_fart_player() -> AudioStreamPlayer:
	for p in _fart_sound_players:
		if not p.playing:
			return p
	if _fart_sound_players.size() < FART_SOUND_POOL_SIZE:
		var new_player := AudioStreamPlayer.new()
		add_child(new_player)
		_fart_sound_players.append(new_player)
		return new_player
	return _fart_sound_players[0]


## FR-165: Erzeugt einen kurzen, "brummenden" Ton mit paket-abhängiger
## Grundfrequenz und Modulation — vollständig prozedural, kein Asset.
func _generate_fart_tone(pack: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.35
	var base_freq := 110.0
	var wobble := 18.0
	match pack:
		"fartsound_deep":
			base_freq = 65.0
			wobble = 8.0
		"fartsound_squeaky":
			base_freq = 320.0
			wobble = 60.0
		"fartsound_robotic":
			base_freq = 150.0
			wobble = 0.0  # wird durch Bitcrush-Stufen ersetzt

	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / sample_count)
		var freq := base_freq + sin(t * 40.0) * wobble
		var raw := sin(TAU * freq * t)
		if pack == "fartsound_robotic":
			raw = sign(raw) * 0.6 + raw * 0.4  # grobe Rechteck-Beimischung
		var sample := raw * envelope * 0.6
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream


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
	cfg.set_value("hud", "minimal_mode", hud_minimal_mode)  # FR-215
	cfg.set_value("hud", "scale", hud_scale)  # FR-216
	cfg.set_value("hud", "attempt_times", level_attempt_times)  # FR-219
	cfg.set_value("hud", "tutorial_hint_seen", tutorial_hint_seen)  # FR-210
	cfg.set_value("stats", "total_farts", stat_total_farts)  # FR-226
	cfg.set_value("stats", "total_deaths", stat_total_deaths)  # FR-226
	cfg.set_value("menu", "favorites", favorite_levels)  # FR-236
	cfg.set_value("menu", "last_played_level", last_played_level)  # FR-238
	cfg.set_value("shop", "unlocked_skins", unlocked_skin_colors)  # FR-224
	cfg.set_value("shop", "active_skin", active_skin_color)  # FR-224
	cfg.set_value("shop", "custom_skin_color", custom_skin_color)  # FR-180
	cfg.set_value("shop", "persistent_coins", persistent_coins)  # FR-224
	cfg.set_value("cosmetics", "unlocked", unlocked_cosmetics)
	cfg.set_value("cosmetics", "helmet", equipped_helmet)
	cfg.set_value("cosmetics", "outfit", equipped_outfit)
	cfg.set_value("cosmetics", "hat", equipped_hat)
	cfg.set_value("cosmetics", "arrow", equipped_arrow_style)
	cfg.set_value("cosmetics", "death", equipped_death_anim)
	cfg.set_value("cosmetics", "pose", equipped_victory_pose)
	cfg.set_value("cosmetics", "fartcolor", equipped_fart_color_style)
	cfg.set_value("cosmetics", "fartsound", equipped_fart_sound)
	cfg.set_value("cosmetics", "daily_claimed_date", daily_skin_claimed_date)
	cfg.save(SAVE_PATH)


## FR-228: Setzt den gesamten Spielstand auf den Ausgangszustand zurück
## (Sterne, Statistiken, Sammlungen, Guthaben, Einstellungen) und löscht
## die Speicherdatei. Wird nach Bestätigung im Reset-Dialog aufgerufen.
func reset_all_progress() -> void:
	level_stars = {1: 0, 2: 0, 3: 0}
	total_xp = 0
	player_level = 1
	discovered_enemies.clear()
	collected_stickers.clear()
	last_daily_coin_date = ""
	tutorial_hint_seen = false
	stat_total_farts = 0
	stat_total_deaths = 0
	favorite_levels.clear()
	last_played_level = 0
	unlocked_skin_colors = ["default"]
	active_skin_color = "default"
	custom_skin_color = Color(0.95, 0.95, 0.95)
	persistent_coins = 0
	level_attempt_times.clear()
	time_attack_best_times = {1: INF, 2: INF, 3: INF}
	unlocked_cosmetics = [
		"helmet_none", "outfit_none", "hat_none", "arrow_classic",
		"death_spin", "pose_wave", "fart_classic", "fartsound_classic",
	]
	equipped_helmet = "helmet_none"
	equipped_outfit = "outfit_none"
	equipped_hat = "hat_none"
	equipped_arrow_style = "arrow_classic"
	equipped_death_anim = "death_spin"
	equipped_victory_pose = "pose_wave"
	equipped_fart_color_style = "fart_classic"
	equipped_fart_sound = "fartsound_classic"
	daily_skin_claimed_date = ""

	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(SAVE_PATH.trim_prefix("user://")):
		dir.remove(SAVE_PATH.trim_prefix("user://"))
	_save_progress()


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
	hud_minimal_mode = cfg.get_value("hud", "minimal_mode", false)  # FR-215
	hud_scale = cfg.get_value("hud", "scale", 1.0)  # FR-216
	level_attempt_times = cfg.get_value("hud", "attempt_times", {})  # FR-219
	tutorial_hint_seen = cfg.get_value("hud", "tutorial_hint_seen", false)  # FR-210
	stat_total_farts = cfg.get_value("stats", "total_farts", 0)  # FR-226
	stat_total_deaths = cfg.get_value("stats", "total_deaths", 0)  # FR-226
	var saved_favorites: Array = cfg.get_value("menu", "favorites", [])  # FR-236
	favorite_levels.assign(saved_favorites)
	last_played_level = cfg.get_value("menu", "last_played_level", 0)  # FR-238
	var saved_skins: Array = cfg.get_value("shop", "unlocked_skins", ["default"])  # FR-224
	unlocked_skin_colors.assign(saved_skins)
	active_skin_color = cfg.get_value("shop", "active_skin", "default")  # FR-224
	custom_skin_color = cfg.get_value("shop", "custom_skin_color", Color(0.95, 0.95, 0.95))  # FR-180
	persistent_coins = cfg.get_value("shop", "persistent_coins", 0)  # FR-224
	var saved_cosmetics: Array = cfg.get_value("cosmetics", "unlocked", unlocked_cosmetics)
	unlocked_cosmetics.assign(saved_cosmetics)
	equipped_helmet = cfg.get_value("cosmetics", "helmet", "helmet_none")
	equipped_outfit = cfg.get_value("cosmetics", "outfit", "outfit_none")
	equipped_hat = cfg.get_value("cosmetics", "hat", "hat_none")
	equipped_arrow_style = cfg.get_value("cosmetics", "arrow", "arrow_classic")
	equipped_death_anim = cfg.get_value("cosmetics", "death", "death_spin")
	equipped_victory_pose = cfg.get_value("cosmetics", "pose", "pose_wave")
	equipped_fart_color_style = cfg.get_value("cosmetics", "fartcolor", "fart_classic")
	equipped_fart_sound = cfg.get_value("cosmetics", "fartsound", "fartsound_classic")
	daily_skin_claimed_date = cfg.get_value("cosmetics", "daily_claimed_date", "")


## FR-118: Registriert einen Gegner-Typ als entdeckt (persistiert).
func discover_enemy(class_id: String) -> void:
	if class_id in discovered_enemies:
		return
	discovered_enemies.append(class_id)
	_save_progress()
