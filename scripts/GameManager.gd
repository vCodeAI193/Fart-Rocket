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
signal skill_unlocked(skill_id)             # FR-304/305: Skill/Upgrade freigeschaltet
signal prestige_changed(new_level)          # FR-306: Prestige-Stufe geändert
signal milestone_reached(milestone_id)      # FR-308: Meilenstein erreicht
signal weekly_goal_progress(goal_id, progress, target)  # FR-310: Wochenziel-Fortschritt
signal piggy_bank_changed(amount)           # FR-313: Sparschwein-Stand geändert

# --- Konstanten -------------------------------------------------
const TOTAL_LEVELS := 7

# FR-003: Zeitfenster (Sekunden), in dem Folge-Münzen die Combo erhöhen
const COMBO_WINDOW := 2.0
# FR-003: höchster Combo-Multiplikator
const COMBO_MAX_MULTIPLIER := 5

# Pfade zu den Level-Szenen (Index 0 = Level 1)
const LEVEL_SCENES := [
	"res://levels/Level1.tscn",
	"res://levels/Level2.tscn",
	"res://levels/Level3.tscn",
	"res://levels/Level4.tscn",
	"res://levels/Level5.tscn",
	"res://levels/Level6.tscn",
	"res://levels/Level7.tscn",
]

# --- Laufender Spielzustand -------------------------------------
var current_level: int = 1              # 1-basiert (Level 1, 2, 3)
var total_coins: int = 0                # gesammelte Münzen im aktuellen Level
var total_score: int = 0                # Punkte im aktuellen Level
var charges_remaining: int = 0          # übrige Furz-Ladungen im Level
var max_charges: int = 0                 # maximale Furz-Ladungen im aktuellen Level
var level_farts_used: int = 0            # FR-327: Furz-Stöße im aktuellen Level

# Bestwertung (Sterne 0..3) je Level, persistent während der Sitzung
var level_stars := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0}

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

# --- Einstellungen (FR-045 Haptik) -------
var haptics_enabled: bool = true
# FR-250: sound_muted lebt jetzt in SoundManager.gd (Master-Bus-Stummschaltung)

# --- FR-438: Gesamtlautstärke (Master-Bus) ---------------------------
# Bleibt bewusst hier statt in AccessibilityManager/SoundManager: steuert
# denselben Master-Bus (Index 0), den SoundManager.apply_mute() stumm-
# schaltet — beides zusammen aufzuteilen würde die Kontrolle über einen
# einzelnen Bus auf zwei Dateien verteilen.
var master_volume: float = 1.0                    # FR-438 (0.0..1.0)

# FR-421-440: Restliche Einstellungen & Barrierefreiheit (colorblind_mode,
# high_contrast, sprache, etc.) leben jetzt in AccessibilityManager.gd.


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	SaveManager.save_settings()


## FR-440: Setzt nur die Einstellungen (nicht den Spielfortschritt) auf
## die Ausgangswerte zurück. Dünner Orchestrator: eigene Felder direkt,
## Rest per Delegation an SoundManager/AccessibilityManager (analog zu
## SaveManager._reset_progress_vars_to_default() für den Spielfortschritt).
func reset_settings_to_default() -> void:
	control_scheme = "direct"
	left_handed_mode = false
	touch_sensitivity = 1.0
	touch_dead_zone = 20.0
	camera_shake_intensity = 1.0
	camera_smoothing = 8.0
	hud_minimal_mode = false
	hud_scale = 1.0
	shader_quality = "high"
	render_scale = 1.0
	pixel_perfect_mode = false
	crt_filter_enabled = false
	haptics_enabled = true
	master_volume = 1.0
	AudioServer.set_bus_volume_db(0, 0.0)
	SoundManager.reset_to_default()
	AccessibilityManager.reset_to_default()
	SaveManager.save_settings()

# FR-341-360: Spielmodi (GameMode-Enum, aktiver Modus, Bestwerte je Modus,
# Zeitrennen/Geister-Pfade/Tages-Seed) leben jetzt in GameModeManager.gd —
# in sich geschlossener Block, wurde beim "God Object"-Refactoring als
# eigener Autoload ausgelagert (siehe README.md).

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

# --- FR-300: Performance-Schalter für Shader-Qualität --------------
signal render_settings_changed
var shader_quality: String = "high"  # "low" | "medium" | "high"
var crt_filter_enabled: bool = false  # FR-282

# --- FR-291: Auflösungsskalierung für schwache Geräte ---------------
var render_scale: float = 1.0  # 0.5..1.0

# --- FR-299: Pixel-Perfect-Render-Option ----------------------------
var pixel_perfect_mode: bool = false


## FR-300: Setzt die Shader-Qualitätsstufe (steuert, welche teuren
## Screen-Space-Shader in Main.gd aktiv sind).
func set_shader_quality(quality: String) -> void:
	shader_quality = quality
	render_settings_changed.emit()
	SaveManager.save_settings()  # FR-414


## FR-282: Schaltet den optionalen CRT-/Retro-Filter um.
func set_crt_filter_enabled(enabled: bool) -> void:
	crt_filter_enabled = enabled
	SaveManager.save_settings()  # FR-414


## FR-291: Setzt die Render-Auflösungsskalierung (niedriger = schneller,
## aber unschärfer — hilfreich auf schwachen Geräten).
func set_render_scale(scale: float) -> void:
	render_scale = clampf(scale, 0.5, 1.0)
	get_tree().root.content_scale_factor = render_scale
	SaveManager.save_settings()  # FR-414


## FR-299: Schaltet den Pixel-Perfect-Modus um (Nearest-Filter,
## kein Antialiasing an Kanten — retro-Optik).
func set_pixel_perfect_mode(enabled: bool) -> void:
	pixel_perfect_mode = enabled
	get_tree().root.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST if enabled
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	)
	SaveManager.save_settings()  # FR-414


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

# --- FR-303: Welt-Freischaltung über Sterne-Schwellen -----------------
# (Infrastruktur für zukünftige Welten — aktuell existiert nur Welt 1,
# die immer freigeschaltet ist; künftige Level-Design-Batches fügen
# weitere Welten mit echten Schwellenwerten hinzu.)
const WORLD_STAR_THRESHOLDS := {1: 0}

# --- FR-304/305: Skill-Baum / permanente Upgrades ----------------------
const SKILL_CATALOG := {
	"fart_power_1": {"name": "Stärkerer Furz I", "cost": 60, "requires": [], "effect": "fart_power"},
	"fart_power_2": {"name": "Stärkerer Furz II", "cost": 160, "requires": ["fart_power_1"], "effect": "fart_power"},
	"fart_power_3": {"name": "Stärkerer Furz III", "cost": 320, "requires": ["fart_power_2"], "effect": "fart_power"},
	"regen_speed_1": {"name": "Schnellere Regeneration I", "cost": 80, "requires": [], "effect": "regen_speed"},
	"regen_speed_2": {"name": "Schnellere Regeneration II", "cost": 200, "requires": ["regen_speed_1"], "effect": "regen_speed"},
	"shield_duration_1": {"name": "Längerer Schild I", "cost": 100, "requires": [], "effect": "shield_duration"},
	"shield_duration_2": {"name": "Längerer Schild II", "cost": 220, "requires": ["shield_duration_1"], "effect": "shield_duration"},
	"extra_charge_1": {"name": "Extra-Ladung I", "cost": 250, "requires": ["fart_power_1"], "effect": "extra_charge"},
	"extra_charge_2": {"name": "Extra-Ladung II", "cost": 500, "requires": ["extra_charge_1"], "effect": "extra_charge"},
}
var unlocked_skills: Array[String] = []

# --- FR-306: Prestige-/New-Game+-Modus ---------------------------------
var prestige_level: int = 0
const PRESTIGE_STAR_REQUIREMENT := 8  # von max. 9 (3 Level x 3 Sterne)

# --- FR-308: Meilenstein-Belohnungen ------------------------------------
const MILESTONES := [
	{"id": "coins_500", "stat": "lifetime_coins", "threshold": 500, "reward": 100},
	{"id": "coins_2000", "stat": "lifetime_coins", "threshold": 2000, "reward": 300},
	{"id": "farts_100", "stat": "stat_total_farts", "threshold": 100, "reward": 50},
	{"id": "farts_1000", "stat": "stat_total_farts", "threshold": 1000, "reward": 200},
	{"id": "deaths_50", "stat": "stat_total_deaths", "threshold": 50, "reward": 50},
]
var claimed_milestones: Array[String] = []
var lifetime_coins: int = 0  # kumulierte, jemals eingesammelte Münzen (FR-308-Basis)

# --- FR-309: Tägliche Login-Belohnungen ---------------------------------
const LOGIN_REWARD_COINS := [20, 30, 40, 60, 80, 100, 150]  # Tag 1..7, danach Wiederholung
var login_streak_day: int = 0
var _last_login_date: String = ""

# --- FR-310: Wöchentliche Ziele -----------------------------------------
const WEEKLY_GOALS := [
	{"id": "weekly_coins", "name": "500 Münzen sammeln", "target": 500, "reward": 150},
	{"id": "weekly_stars", "name": "10 Sterne erspielen", "target": 10, "reward": 150},
	{"id": "weekly_farts", "name": "200 Mal furzen", "target": 200, "reward": 100},
]
var weekly_progress := {}   # goal_id -> int
var weekly_claimed := {}    # goal_id -> bool
var _weekly_week_id: String = ""

# --- FR-311: Battle-Pass-/Saison-Fortschritt -----------------------------
const SEASON_XP_PER_TIER := 150
const SEASON_TIER_REWARDS := [50, 60, 70, 80, 100, 120, 150, 200]  # Münzen je Stufe
var season_xp: int = 0
var season_claimed_tiers: Array[int] = []

# --- FR-313: Münz-Sparziele (Sparschwein) --------------------------------
const PIGGY_BANK_CAP := 300
const PIGGY_BANK_SAVE_RATE := 0.1  # 10% jeder verdienten Münze wandert ins Sparschwein
var piggy_bank_amount: int = 0

# --- FR-316: Hard-Mode-Sterne ---------------------------------------------
var hard_mode_enabled: bool = false
var hard_mode_stars := {}  # level_index -> stars, getrennt von level_stars

# --- FR-318: Statistik-getriebene Abzeichen -------------------------------
const STAT_BADGES := [
	{"id": "badge_farter", "name": "Vielfurzer", "stat": "stat_total_farts", "threshold": 500},
	{"id": "badge_survivor", "name": "Überlebenskünstler", "stat": "stat_total_deaths", "threshold": 100},
	{"id": "badge_collector", "name": "Sammler", "stat": "lifetime_coins", "threshold": 1000},
]
var earned_badges: Array[String] = []

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
	# FR-414: Einstellungen zuerst laden (bestimmt u.a. den aktiven Speicherplatz)
	SaveManager.load_settings()
	# Beim Start einmal den gespeicherten Fortschritt laden (falls vorhanden)
	SaveManager.load_now()
	# Gespeicherte Audio-/Grafik-Einstellungen anwenden
	SoundManager.apply_mute()
	get_tree().root.content_scale_factor = render_scale  # FR-291
	get_tree().root.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST if pixel_perfect_mode
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	)  # FR-299
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))  # FR-438
	Engine.max_fps = AccessibilityManager.fps_limit  # FR-432
	TranslationServer.set_locale(AccessibilityManager.language)  # FR-439


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
	# FR-305/437: "Extra-Ladung"-Upgrades und der Schwierigkeits-Assist
	# erhöhen die verfügbaren Furz-Ladungen (die Sternebewertung bleibt am
	# ursprünglichen Level-Design gemessen, siehe calculate_stars-Aufruf in
	# Main.gd mit dem unveränderten Wert)
	var assist_bonus := 1 if AccessibilityManager.difficulty_assist_enabled else 0
	self.max_charges = max_charges + get_skill_effect_level("extra_charge") + assist_bonus
	charges_remaining = self.max_charges
	combo_count = 0
	_combo_elapsed = 0.0
	fart_letters_collected.clear()  # FR-092: Buchstaben pro Level zurücksetzen
	_level_start_ticks = Time.get_ticks_msec()  # FR-117: Basis für Schwierigkeitsskalierung
	level_coin_total = 0             # FR-099: Fortschritt pro Level zurücksetzen
	level_coin_collected = 0
	level_farts_used = 0             # FR-327: Furz-Stöße im aktuellen Level zählen
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
	SaveManager.save_settings()  # FR-414


## FR-043: Schaltet den Linkshänder-Modus (gespiegeltes HUD) um.
func set_left_handed(enabled: bool) -> void:
	left_handed_mode = enabled
	control_settings_changed.emit()
	SaveManager.save_settings()  # FR-414


## FR-044: Setzt die Touch-Empfindlichkeit (0.5 = träge, 2.0 = sehr empfindlich).
func set_touch_sensitivity(value: float) -> void:
	touch_sensitivity = clampf(value, 0.5, 2.0)
	control_settings_changed.emit()
	SaveManager.save_settings()  # FR-414


## FR-044: Setzt die Dead-Zone in Pixeln (minimale Zugweite fürs Zielen).
func set_touch_dead_zone(value: float) -> void:
	touch_dead_zone = clampf(value, 0.0, 60.0)
	control_settings_changed.emit()
	SaveManager.save_settings()  # FR-414


## FR-189: Setzt die globale Kamera-Rüttel-Intensität (0.0 = aus, 2.0 = stark).
func set_camera_shake_intensity(value: float) -> void:
	camera_shake_intensity = clampf(value, 0.0, 2.0)
	SaveManager.save_settings()  # FR-414


## FR-200: Setzt die Kamera-Glättung (Lerp-Geschwindigkeit beim Folgen).
func set_camera_smoothing(value: float) -> void:
	camera_smoothing = clampf(value, 2.0, 16.0)
	SaveManager.save_settings()  # FR-414


## FR-226: Erhöht den Furz-Zähler (von Player bei jedem Stoß aufgerufen).
func record_fart() -> void:
	stat_total_farts += 1
	level_farts_used += 1  # FR-327
	add_weekly_progress("weekly_farts", 1)  # FR-310
	AchievementManager.advance_challenge_task("fart_count", 1)  # FR-329/330
	_check_milestones()  # FR-308
	_check_badges()      # FR-318


## FR-226: Erhöht den Tod-Zähler (von Main bei jedem Tod aufgerufen).
func record_death() -> void:
	stat_total_deaths += 1
	AccessibilityManager.show_sound_caption(tr("caption_crash"))  # FR-425
	_check_milestones()  # FR-308
	_check_badges()      # FR-318
	SaveManager.save_now()


## FR-236: Schaltet den Favoriten-Status eines Levels um.
func toggle_favorite_level(level_index: int) -> void:
	if level_index in favorite_levels:
		favorite_levels.erase(level_index)
	else:
		favorite_levels.append(level_index)
	SaveManager.save_now()


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
	SaveManager.save_now()


## FR-210: Markiert den Tutorial-Hinweis dauerhaft als gesehen.
func mark_tutorial_hint_seen() -> void:
	tutorial_hint_seen = true
	SaveManager.save_now()


## FR-215: Schaltet den minimalistischen HUD-Modus um.
func set_hud_minimal_mode(enabled: bool) -> void:
	hud_minimal_mode = enabled
	hud_settings_changed.emit()
	SaveManager.save_settings()  # FR-414


## FR-216: Setzt die HUD-Skalierung (0.75..1.5).
func set_hud_scale(value: float) -> void:
	hud_scale = clampf(value, 0.75, 1.5)
	hud_settings_changed.emit()
	SaveManager.save_settings()  # FR-414


## FR-219: Registriert eine abgeschlossene Levelzeit für die lokale
## Rang-Historie und gibt zurück, auf welchem Rang sie sich einordnet.
func record_attempt_time(level_index: int, time_sec: float) -> int:
	if not level_attempt_times.has(level_index):
		level_attempt_times[level_index] = []
	var times: Array = level_attempt_times[level_index]
	times.append(time_sec)
	SaveManager.save_now()
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
	SaveManager.save_now()
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
	SaveManager.save_now()
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
	AccessibilityManager.show_sound_caption(tr("caption_coin"))  # FR-425
	# Combo erhöhen, wenn die letzte Münze im Zeitfenster lag
	if _combo_elapsed <= COMBO_WINDOW:
		combo_count += 1
	else:
		combo_count = 1
	_combo_elapsed = 0.0
	var multiplier := clampi(combo_count, 1, COMBO_MAX_MULTIPLIER)

	total_coins += 1
	lifetime_coins += 1               # FR-308: Basis für Meilensteine/Abzeichen
	add_weekly_progress("weekly_coins", 1)  # FR-310
	add_to_piggy_bank(1)              # FR-313
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
	SaveManager.save_settings()  # FR-414 (vorher fälschlich gar nicht persistiert)


# FR-249/250: Stummschaltung (set_muted/toggle_muted/apply_mute) lebt jetzt
# in SoundManager.gd.


# FR-425: show_sound_caption() lebt jetzt in AccessibilityManager.gd
# (Bildschirm-Einblendung ist eine Barrierefreiheits-Funktion, kein
# Sound-Playback).

# FR-165: play_fart_sound() lebt jetzt vollständig in SoundManager.gd.


## FR-239: Dünner Weiterleitungs-Wrapper — die eigentliche Klick-Ton-
## Erzeugung/Wiedergabe lebt jetzt in SoundManager.gd. Bleibt hier als
## Alias erhalten, da über 45 Aufrufstellen in UI-Bildschirmen
## GameManager.play_ui_click() aufrufen; ein direktes Umbiegen aller
## Stellen auf SoundManager wäre eine unnötig große, risikoreiche Diff
## ohne echten Zusatznutzen (siehe SaveManager.save_now()-Alias-Muster).
func play_ui_click(pitch: float = 1.0) -> void:
	SoundManager.play_ui_click(pitch)


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


## FR-276: Wechselt die Szene mit einem diagonalen Wischeffekt statt eines
## harten Schnitts.
func change_scene_with_wipe(scene_path: String) -> void:
	await _run_scene_wipe(func(tree: SceneTree): tree.change_scene_to_file(scene_path))


## FR-276: Wie change_scene_with_wipe(), lädt aber die aktuelle Szene neu
## (für Retry/Nächstes-Level statt eines Szenenpfad-Wechsels).
func reload_scene_with_wipe() -> void:
	await _run_scene_wipe(func(tree: SceneTree): tree.reload_current_scene())


## FR-276: Gemeinsame Wisch-Animation (abdecken, `action` ausführen,
## wieder aufdecken) für Szenenwechsel/-neuladen.
func _run_scene_wipe(action: Callable) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	tree.root.add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/scene_wipe.gdshader")
	mat.set_shader_parameter("wipe_progress", 0.0)
	rect.material = mat
	layer.add_child(rect)

	var cover_tween := tree.create_tween()
	cover_tween.tween_method(func(v): mat.set_shader_parameter("wipe_progress", v), 0.0, 1.1, 0.3)
	await cover_tween.finished

	action.call(tree)
	await tree.process_frame
	await tree.process_frame

	var reveal_tween := tree.create_tween()
	reveal_tween.tween_method(func(v): mat.set_shader_parameter("wipe_progress", v), 1.1, -0.1, 0.3)
	await reveal_tween.finished
	layer.queue_free()


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
		add_season_xp(stars * XP_PER_STAR)  # FR-311
		SaveManager.save_now()
	# FR-310: Wochenziel "Sterne erspielen" zählt jeden erspielten Stern
	# (auch bei bereits erreichten Bestwertungen, damit Wiederholungen zählen)
	add_weekly_progress("weekly_stars", stars)
	if hard_mode_enabled:
		record_hard_mode_stars(level_index, stars)  # FR-316
	_check_milestones()   # FR-308
	_check_badges()       # FR-318


## FR-304/305: Prüft, ob ein Skill freigeschaltet werden kann (Kosten
## bezahlbar, alle Voraussetzungen erfüllt, noch nicht freigeschaltet).
func can_unlock_skill(id: String) -> bool:
	if id in unlocked_skills or not SKILL_CATALOG.has(id):
		return false
	var data: Dictionary = SKILL_CATALOG[id]
	if persistent_coins < int(data["cost"]):
		return false
	for req in data["requires"]:
		if not (req in unlocked_skills):
			return false
	return true


## FR-304/305: Schaltet einen Skill/permanentes Upgrade frei.
func unlock_skill(id: String) -> bool:
	if not can_unlock_skill(id):
		return false
	persistent_coins -= int(SKILL_CATALOG[id]["cost"])
	persistent_coins_changed.emit(persistent_coins)
	unlocked_skills.append(id)
	skill_unlocked.emit(id)
	SaveManager.save_now()
	return true


## FR-305: Anzahl freigeschalteter Skills eines Effekt-Typs (bestimmt die
## Stärke des jeweiligen Bonus in Player.gd, z.B. "fart_power").
func get_skill_effect_level(effect: String) -> int:
	var count := 0
	for id in unlocked_skills:
		if SKILL_CATALOG[id]["effect"] == effect:
			count += 1
	return count


## FR-303: Ob eine Welt anhand der insgesamt erspielten Sterne freigeschaltet ist.
func is_world_unlocked(world_index: int) -> bool:
	return get_total_stars_earned() >= int(WORLD_STAR_THRESHOLDS.get(world_index, 0))


## Summe aller je erspielten Sterne über alle Level (Normalwertung).
func get_total_stars_earned() -> int:
	var earned := 0
	for lvl in level_stars.keys():
		earned += level_stars[lvl]
	return earned


## FR-306: Ob genug Sterne für einen Prestige-Durchlauf vorhanden sind.
func can_prestige() -> bool:
	return get_total_stars_earned() >= PRESTIGE_STAR_REQUIREMENT


## FR-306: Setzt den Level-/Stern-Fortschritt zurück und erhöht die
## Prestige-Stufe (dauerhafter Münz-Bonus). Kosmetik, Skills und
## persistente Münzen bleiben dabei erhalten.
func do_prestige() -> bool:
	if not can_prestige():
		return false
	prestige_level += 1
	for lvl in level_stars.keys():
		level_stars[lvl] = 0
	current_level = 1
	prestige_changed.emit(prestige_level)
	SaveManager.save_now()
	return true


## FR-306: Dauerhafter Münz-Bonus-Multiplikator aus Prestige-Stufen.
func get_prestige_coin_multiplier() -> float:
	return 1.0 + prestige_level * 0.1


## FR-308: Prüft alle Meilensteine gegen die aktuellen Statistik-Werte und
## zahlt neu erreichte automatisch als Münz-Bonus aus.
func _check_milestones() -> void:
	for m in MILESTONES:
		if m["id"] in claimed_milestones:
			continue
		var value: int = get(String(m["stat"]))
		if value >= int(m["threshold"]):
			claimed_milestones.append(m["id"])
			persistent_coins += int(m["reward"])
			persistent_coins_changed.emit(persistent_coins)
			milestone_reached.emit(m["id"])
			SaveManager.save_now()


## FR-318: Prüft alle statistik-getriebenen Abzeichen und schaltet neu
## erreichte frei (keine Geld-Belohnung, reine Sammel-/Prestige-Anzeige).
func _check_badges() -> void:
	for b in STAT_BADGES:
		if b["id"] in earned_badges:
			continue
		var value: int = get(String(b["stat"]))
		if value >= int(b["threshold"]):
			earned_badges.append(b["id"])
			SaveManager.save_now()


## FR-309: Prüft/vergibt die tägliche Login-Belohnung (einmal pro
## Kalendertag, mit fortlaufender Streak bei täglichem Login). Gibt die
## Anzahl gutgeschriebener Münzen zurück (0 falls heute schon abgeholt).
func claim_daily_login_reward() -> int:
	var today := Time.get_date_string_from_system()
	if today == _last_login_date:
		return 0
	var yesterday := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	login_streak_day = (login_streak_day + 1) if _last_login_date == yesterday else 1
	_last_login_date = today
	var reward: int = LOGIN_REWARD_COINS[(login_streak_day - 1) % LOGIN_REWARD_COINS.size()]
	persistent_coins += reward
	persistent_coins_changed.emit(persistent_coins)
	SaveManager.save_now()
	return reward


## FR-309: Ob die heutige Login-Belohnung noch nicht abgeholt wurde.
func has_unclaimed_daily_login() -> bool:
	return Time.get_date_string_from_system() != _last_login_date


func _get_week_id() -> String:
	return str(int(Time.get_unix_time_from_system() / 86400) / 7)


## FR-310: Setzt den Wochenziel-Fortschritt bei Wochenwechsel automatisch zurück.
func _ensure_current_week() -> void:
	var week_id := _get_week_id()
	if week_id != _weekly_week_id:
		_weekly_week_id = week_id
		weekly_progress.clear()
		weekly_claimed.clear()


## FR-310: Trägt Fortschritt für ein Wochenziel ein und zahlt bei
## Erreichen automatisch die Belohnung aus.
func add_weekly_progress(goal_id: String, amount: int) -> void:
	if amount <= 0:
		return
	_ensure_current_week()
	weekly_progress[goal_id] = int(weekly_progress.get(goal_id, 0)) + amount
	for goal in WEEKLY_GOALS:
		if goal["id"] != goal_id:
			continue
		var progress: int = weekly_progress[goal_id]
		weekly_goal_progress.emit(goal_id, progress, goal["target"])
		if progress >= int(goal["target"]) and not weekly_claimed.get(goal_id, false):
			weekly_claimed[goal_id] = true
			persistent_coins += int(goal["reward"])
			persistent_coins_changed.emit(persistent_coins)
			SaveManager.save_now()
		break


## FR-311: Fügt der Saison-/Battle-Pass-Leiste XP hinzu.
func add_season_xp(amount: int) -> void:
	season_xp += amount


## FR-311: Aktuell erreichte Saison-Stufe (0 = noch keine).
func get_season_tier() -> int:
	return mini(season_xp / SEASON_XP_PER_TIER, SEASON_TIER_REWARDS.size())


## FR-311/320: Holt die Belohnung der nächsten noch nicht abgeholten
## Saison-Stufe ab (0, falls keine neue Stufe verfügbar ist).
func claim_season_tier_reward() -> int:
	var tier := get_season_tier()
	for t in range(1, tier + 1):
		if not (t in season_claimed_tiers):
			season_claimed_tiers.append(t)
			var reward: int = SEASON_TIER_REWARDS[t - 1]
			persistent_coins += reward
			persistent_coins_changed.emit(persistent_coins)
			SaveManager.save_now()
			return reward
	return 0


## FR-312/320: Kurzbeschreibung des nächstgelegenen, noch nicht erreichten
## Fortschritts-Ziels — für eine "Nächstes Ziel"-Vorschau in der UI.
func get_next_goal_preview() -> String:
	var next_tier := get_season_tier() + 1
	if next_tier <= SEASON_TIER_REWARDS.size():
		var needed: int = next_tier * SEASON_XP_PER_TIER - season_xp
		return "Saison-Stufe %d: noch %d XP" % [next_tier, needed]
	for m in MILESTONES:
		if not (m["id"] in claimed_milestones):
			var value: int = get(String(m["stat"]))
			return "%s: %d / %d" % [String(m["id"]).capitalize(), value, int(m["threshold"])]
	return "Alle Ziele erreicht!"


## FR-313: Ein Teil jeder verdienten Münze wandert automatisch ins
## Sparschwein, bis es voll ist.
func add_to_piggy_bank(coin_amount: int) -> void:
	if piggy_bank_amount >= PIGGY_BANK_CAP or coin_amount <= 0:
		return
	piggy_bank_amount = mini(piggy_bank_amount + int(coin_amount * PIGGY_BANK_SAVE_RATE), PIGGY_BANK_CAP)
	piggy_bank_changed.emit(piggy_bank_amount)


## FR-313: Leert ein volles Sparschwein und zahlt den Inhalt als Bonus aus.
func break_piggy_bank() -> int:
	if piggy_bank_amount < PIGGY_BANK_CAP:
		return 0
	var payout := piggy_bank_amount
	piggy_bank_amount = 0
	persistent_coins += payout
	persistent_coins_changed.emit(persistent_coins)
	piggy_bank_changed.emit(0)
	SaveManager.save_now()
	return payout


## FR-316: Schaltet den Hard-Mode um (wirkt sich auf Main.gd/Player.gd aus).
func set_hard_mode_enabled(enabled: bool) -> void:
	hard_mode_enabled = enabled
	SaveManager.save_now()


## FR-316: Speichert die im Hard-Mode erspielten Sterne getrennt von der
## Normalwertung und vergibt doppelte XP als zusätzlichen Anreiz.
func record_hard_mode_stars(level_index: int, stars: int) -> void:
	if not hard_mode_stars.has(level_index):
		hard_mode_stars[level_index] = 0
	if stars > hard_mode_stars[level_index]:
		hard_mode_stars[level_index] = stars
		add_xp(stars * XP_PER_STAR * 2)
		SaveManager.save_now()


## FR-317: Persönliche Bestzeit für ein Level aus allen normalen Versuchen
## (Sekunden), -1.0 falls das Level noch nicht abgeschlossen wurde. Getrennt
## von get_best_time(), das die Zeitrennen-Modus-Bestzeit liefert.
func get_best_attempt_time(level_index: int) -> float:
	var times: Array = level_attempt_times.get(level_index, [])
	if times.is_empty():
		return -1.0
	return times.min()


# FR-319: is_obstacle_unlocked()/OBSTACLE_UNLOCK_LEVELS wurden entfernt —
# tote Infrastruktur ohne einen einzigen Aufrufer im Projekt (Level werden
# als fertige, statische Szenen ausgeliefert statt zur Laufzeit anhand des
# Spielerlevels gefiltert zu werden). Siehe BACKLOG.md FR-319.


## Gibt true zurück, wenn ein nächstes Level existiert.
func has_next_level() -> bool:
	return current_level < TOTAL_LEVELS


# FR-341: record_time_attack()/get_best_time() leben jetzt in
# GameModeManager.gd.


## Liefert den Szenenpfad für ein 1-basiertes Level.
func get_level_scene_path(level_index: int) -> String:
	var idx := clampi(level_index - 1, 0, LEVEL_SCENES.size() - 1)
	return LEVEL_SCENES[idx]


## FR-118: Registriert einen Gegner-Typ als entdeckt (persistiert).
func discover_enemy(class_id: String) -> void:
	if class_id in discovered_enemies:
		return
	discovered_enemies.append(class_id)
	SaveManager.save_now()
