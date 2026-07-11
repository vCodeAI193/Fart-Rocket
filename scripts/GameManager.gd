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
var level_farts_used: int = 0            # FR-327: Furz-Stöße im aktuellen Level

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

# --- FR-342-360: Spielmodi -----------------------------------------
# FR-351/352 (Koop/Versus-Splitscreen) laut Projektplan zurückgestellt —
# Touch-Single-Screen-Multiplayer birgt hohe UX-Risiken für dieses Spiel.
enum GameMode {
	NORMAL, TIME_ATTACK, ENDLESS, SURVIVAL, HARDCORE, ZEN, COIN_HUNT,
	BOSS_RUSH, MIRROR, MUTATOR, DAILY_SEED, GHOST_RACE, NO_FUEL,
	PRECISION, MARATHON, DARK, REVERSE_GRAVITY, CHAOS, PRACTICE,
}
const GAME_MODE_INFO := {
	GameMode.NORMAL: {"name": "Normal", "desc": "Der reguläre Spielmodus."},
	GameMode.TIME_ATTACK: {"name": "Zeitrennen", "desc": "Gegen die eigene Bestzeit antreten."},
	GameMode.ENDLESS: {"name": "Endlos", "desc": "Das Level wiederholt sich mit steigendem Tempo, bis du stirbst."},
	GameMode.SURVIVAL: {"name": "Überleben", "desc": "Hindernisse werden mit der Zeit schneller — überlebe so lange wie möglich."},
	GameMode.HARDCORE: {"name": "Hardcore", "desc": "Nur eine einzige Furz-Ladung für das ganze Level."},
	GameMode.ZEN: {"name": "Zen", "desc": "Kein Tod möglich — einfach entspannt fliegen."},
	GameMode.COIN_HUNT: {"name": "Münzjagd", "desc": "Zählt nur: so viele Münzen wie möglich sammeln."},
	GameMode.BOSS_RUSH: {"name": "Boss-Rush", "desc": "Direkt zum Boss-Level, mit doppelter Boss-Ausdauer."},
	GameMode.MIRROR: {"name": "Spiegel", "desc": "Das Level ist horizontal gespiegelt."},
	GameMode.MUTATOR: {"name": "Mutator", "desc": "Ein zufälliger Modifikator verändert die Regeln."},
	GameMode.DAILY_SEED: {"name": "Tages-Lauf", "desc": "Gleiches Level und gleicher Modifikator für alle, einmal täglich."},
	GameMode.GHOST_RACE: {"name": "Geister-Rennen", "desc": "Ein Geist deiner Bestzeit fliegt mit."},
	GameMode.NO_FUEL: {"name": "Kein Treibstoff", "desc": "Keine Ladungs-Regeneration — nur die Start-Ladungen zählen."},
	GameMode.PRECISION: {"name": "Präzision", "desc": "Nur sehr genaue Winkel geben vollen Schub."},
	GameMode.MARATHON: {"name": "Marathon", "desc": "Alle Level am Stück, ohne Zwischenstopp im Menü."},
	GameMode.DARK: {"name": "Dunkel", "desc": "Nur ein enger Lichtkegel um das Männchen ist sichtbar."},
	GameMode.REVERSE_GRAVITY: {"name": "Umgekehrte Schwerkraft", "desc": "Die Schwerkraft zieht nach oben."},
	GameMode.CHAOS: {"name": "Chaos", "desc": "Schwerkraft und Hindernisse sind deutlich schneller."},
	GameMode.PRACTICE: {"name": "Übung", "desc": "Sofortiger Neustart am Levelanfang bei jedem Tod."},
}
var active_game_mode: GameMode = GameMode.NORMAL
var endless_loop_count: int = 0             # FR-342
var endless_best_loops: int = 0             # FR-342
var survival_best_time: float = 0.0         # FR-343
var coin_hunt_best_score: int = 0           # FR-346
var marathon_level_index: int = 0           # FR-356: Fortschritt im Marathon-Lauf
var ghost_paths := {}                       # FR-353: level_index -> PackedVector2Array
var daily_seed_date: String = ""            # FR-350
var daily_seed_modifier_id: String = "none" # FR-350


## FR-342-360: Wechselt den aktiven Spielmodus (wirkt sich beim nächsten
## Levelstart in Main.gd/Player.gd aus).
func set_game_mode(mode: GameMode) -> void:
	active_game_mode = mode
	time_attack_mode = (mode == GameMode.TIME_ATTACK)  # bestehende Variable synchron halten
	if mode == GameMode.MARATHON:
		marathon_level_index = 1
		current_level = 1  # Marathon startet immer bei Level 1
	if mode == GameMode.BOSS_RUSH:
		current_level = TOTAL_LEVELS  # FR-347: direkt zum Boss-Level springen
	_save_progress()


## FR-350: Liefert einen für alle Spieler an diesem Kalendertag gleichen
## Seed sowie einen dazu passenden, ebenfalls tages-festen Modifikator.
func get_daily_seed_params() -> Dictionary:
	var today := Time.get_date_string_from_system()
	if today != daily_seed_date:
		daily_seed_date = today
		var h := today.hash()
		daily_seed_modifier_id = AchievementManager.MODIFIERS[h % AchievementManager.MODIFIERS.size()]["id"]
	return {"seed": daily_seed_date.hash(), "modifier_id": daily_seed_modifier_id}


## FR-353: Speichert die Positions-Aufzeichnung des schnellsten Laufs
## als Geister-Pfad für ein Level (nur überschrieben, wenn tatsächlich
## eine neue Bestzeit erzielt wurde — siehe record_time_attack()).
func store_ghost_path(level_index: int, path: PackedVector2Array) -> void:
	ghost_paths[level_index] = path
	_save_progress()


func get_ghost_path(level_index: int) -> PackedVector2Array:
	return ghost_paths.get(level_index, PackedVector2Array())

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
	_save_settings()  # FR-414


## FR-282: Schaltet den optionalen CRT-/Retro-Filter um.
func set_crt_filter_enabled(enabled: bool) -> void:
	crt_filter_enabled = enabled
	_save_settings()  # FR-414


## FR-291: Setzt die Render-Auflösungsskalierung (niedriger = schneller,
## aber unschärfer — hilfreich auf schwachen Geräten).
func set_render_scale(scale: float) -> void:
	render_scale = clampf(scale, 0.5, 1.0)
	get_tree().root.content_scale_factor = render_scale
	_save_settings()  # FR-414


## FR-299: Schaltet den Pixel-Perfect-Modus um (Nearest-Filter,
## kein Antialiasing an Kanten — retro-Optik).
func set_pixel_perfect_mode(enabled: bool) -> void:
	pixel_perfect_mode = enabled
	get_tree().root.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST if enabled
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	)
	_save_settings()  # FR-414


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

# --- FR-319: Stufenweise Freischaltung neuer Hindernisse -------------------
const OBSTACLE_UNLOCK_LEVELS := {
	"electric_fence": 1, "flame_jet": 1, "rotating_wheel": 1,
	"black_hole": 2, "lava_pool": 2, "proximity_mine": 3,
}

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
	# FR-334: Nicht im Shop kaufbar — nur als Erfolgs-Belohnung für
	# "Sternensammler" per grant_cosmetic_free() (siehe "achievement_only").
	"hat_crown": {"name": "Krone", "slot": "hat", "cost": 0, "rarity": Rarity.LEGENDARY, "achievement_only": true},

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


## FR-334: Schaltet ein Kosmetik-Item kostenlos frei (z.B. als
## Erfolgs-Belohnung) — im Gegensatz zu unlock_cosmetic() ohne Kaufpreis.
func grant_cosmetic_free(id: String) -> void:
	if id in unlocked_cosmetics:
		return
	unlocked_cosmetics.append(id)
	_save_progress()


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
	# FR-414: Einstellungen zuerst laden (bestimmt u.a. den aktiven Speicherplatz)
	_load_settings()
	# Beim Start einmal den gespeicherten Fortschritt laden (falls vorhanden)
	_load_progress()
	# Gespeicherte Audio-/Grafik-Einstellungen anwenden
	_apply_mute()
	get_tree().root.content_scale_factor = render_scale  # FR-291
	get_tree().root.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST if pixel_perfect_mode
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	)  # FR-299


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
	# FR-305: "Extra-Ladung"-Upgrades erhöhen die verfügbaren Furz-Ladungen
	# (die Sternebewertung bleibt am ursprünglichen Level-Design gemessen,
	# siehe calculate_stars-Aufruf in Main.gd mit dem unveränderten Wert)
	self.max_charges = max_charges + get_skill_effect_level("extra_charge")
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
	_save_settings()  # FR-414


## FR-043: Schaltet den Linkshänder-Modus (gespiegeltes HUD) um.
func set_left_handed(enabled: bool) -> void:
	left_handed_mode = enabled
	control_settings_changed.emit()
	_save_settings()  # FR-414


## FR-044: Setzt die Touch-Empfindlichkeit (0.5 = träge, 2.0 = sehr empfindlich).
func set_touch_sensitivity(value: float) -> void:
	touch_sensitivity = clampf(value, 0.5, 2.0)
	control_settings_changed.emit()
	_save_settings()  # FR-414


## FR-044: Setzt die Dead-Zone in Pixeln (minimale Zugweite fürs Zielen).
func set_touch_dead_zone(value: float) -> void:
	touch_dead_zone = clampf(value, 0.0, 60.0)
	control_settings_changed.emit()
	_save_settings()  # FR-414


## FR-189: Setzt die globale Kamera-Rüttel-Intensität (0.0 = aus, 2.0 = stark).
func set_camera_shake_intensity(value: float) -> void:
	camera_shake_intensity = clampf(value, 0.0, 2.0)
	_save_settings()  # FR-414


## FR-200: Setzt die Kamera-Glättung (Lerp-Geschwindigkeit beim Folgen).
func set_camera_smoothing(value: float) -> void:
	camera_smoothing = clampf(value, 2.0, 16.0)
	_save_settings()  # FR-414


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
	_check_milestones()  # FR-308
	_check_badges()      # FR-318
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
	_save_settings()  # FR-414


## FR-216: Setzt die HUD-Skalierung (0.75..1.5).
func set_hud_scale(value: float) -> void:
	hud_scale = clampf(value, 0.75, 1.5)
	hud_settings_changed.emit()
	_save_settings()  # FR-414


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
	_save_settings()  # FR-414 (vorher fälschlich gar nicht persistiert)


# --- FR-249: Stummschaltung -------------------------------------
func set_muted(muted: bool) -> void:
	sound_muted = muted
	_apply_mute()
	_save_settings()  # FR-414 (vorher fälschlich gar nicht persistiert)


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
		_save_progress()
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
	_save_progress()
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
	_save_progress()
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
			_save_progress()


## FR-318: Prüft alle statistik-getriebenen Abzeichen und schaltet neu
## erreichte frei (keine Geld-Belohnung, reine Sammel-/Prestige-Anzeige).
func _check_badges() -> void:
	for b in STAT_BADGES:
		if b["id"] in earned_badges:
			continue
		var value: int = get(String(b["stat"]))
		if value >= int(b["threshold"]):
			earned_badges.append(b["id"])
			_save_progress()


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
	_save_progress()
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
			_save_progress()
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
			_save_progress()
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
	_save_progress()
	return payout


## FR-316: Schaltet den Hard-Mode um (wirkt sich auf Main.gd/Player.gd aus).
func set_hard_mode_enabled(enabled: bool) -> void:
	hard_mode_enabled = enabled
	_save_progress()


## FR-316: Speichert die im Hard-Mode erspielten Sterne getrennt von der
## Normalwertung und vergibt doppelte XP als zusätzlichen Anreiz.
func record_hard_mode_stars(level_index: int, stars: int) -> void:
	if not hard_mode_stars.has(level_index):
		hard_mode_stars[level_index] = 0
	if stars > hard_mode_stars[level_index]:
		hard_mode_stars[level_index] = stars
		add_xp(stars * XP_PER_STAR * 2)
		_save_progress()


## FR-317: Persönliche Bestzeit für ein Level aus allen normalen Versuchen
## (Sekunden), -1.0 falls das Level noch nicht abgeschlossen wurde. Getrennt
## von get_best_time(), das die Zeitrennen-Modus-Bestzeit liefert.
func get_best_attempt_time(level_index: int) -> float:
	var times: Array = level_attempt_times.get(level_index, [])
	if times.is_empty():
		return -1.0
	return times.min()


## FR-319: Ob ein Hindernis-Typ anhand des aktuellen Spielerlevels bereits
## freigeschaltet ist (steigende Vielfalt mit Spielfortschritt).
func is_obstacle_unlocked(obstacle_id: String) -> bool:
	return player_level >= int(OBSTACLE_UNLOCK_LEVELS.get(obstacle_id, 1))


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
const SAVE_VERSION := 1                                   # FR-416
const SETTINGS_PATH := "user://fartrocket_settings.cfg"    # FR-414
const BACKUP_DIR := "user://backups/"                       # FR-406/407/411/417
const MAX_BACKUPS_PER_SLOT := 5
const SAVE_SLOT_COUNT := 3                                  # FR-403
# FR-409: Rein clientseitige Verschleierung gegen beiläufiges Editieren
# der Speicherdatei mit einem Texteditor — kein Schutz vor einem
# entschlossenen Angreifer (der Schlüssel liegt im Spiel-Code selbst).
const SAVE_PASSPHRASE := "fartrocket-local-save-v1"

var current_save_slot: int = 1                              # FR-403


func _save_path(slot: int = -1) -> String:
	var s: int = current_save_slot if slot < 0 else slot
	return "user://fartrocket_save_slot%d.cfg" % s


## FR-401/409/413/416: Serialisiert den kompletten Fortschritt
## (Prüfsumme + Versionsnummer), verschlüsselt und atomar gespeichert,
## mit anschließendem Backup (FR-406/411/417).
func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SAVE_VERSION)  # FR-416
	for lvl in level_stars.keys():
		cfg.set_value("stars", str(lvl), level_stars[lvl])
	cfg.set_value("bestiary", "discovered", discovered_enemies)
	cfg.set_value("daily", "last_coin_date", last_daily_coin_date)  # FR-093
	cfg.set_value("stickers", "collected", collected_stickers)  # FR-089
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
	cfg.set_value("progression", "unlocked_skills", unlocked_skills)          # FR-304/305
	cfg.set_value("progression", "prestige_level", prestige_level)            # FR-306
	cfg.set_value("progression", "claimed_milestones", claimed_milestones)    # FR-308
	cfg.set_value("progression", "lifetime_coins", lifetime_coins)            # FR-308
	cfg.set_value("progression", "login_streak_day", login_streak_day)        # FR-309
	cfg.set_value("progression", "last_login_date", _last_login_date)         # FR-309
	cfg.set_value("progression", "weekly_progress", weekly_progress)          # FR-310
	cfg.set_value("progression", "weekly_claimed", weekly_claimed)            # FR-310
	cfg.set_value("progression", "weekly_week_id", _weekly_week_id)           # FR-310
	cfg.set_value("progression", "season_xp", season_xp)                      # FR-311
	cfg.set_value("progression", "season_claimed_tiers", season_claimed_tiers)  # FR-311
	cfg.set_value("progression", "piggy_bank_amount", piggy_bank_amount)      # FR-313
	cfg.set_value("progression", "hard_mode_enabled", hard_mode_enabled)      # FR-316
	cfg.set_value("progression", "hard_mode_stars", hard_mode_stars)          # FR-316
	cfg.set_value("progression", "earned_badges", earned_badges)              # FR-318
	cfg.set_value("modes", "active_game_mode", active_game_mode)              # FR-342-360
	cfg.set_value("modes", "endless_best_loops", endless_best_loops)          # FR-342
	cfg.set_value("modes", "survival_best_time", survival_best_time)          # FR-343
	cfg.set_value("modes", "coin_hunt_best_score", coin_hunt_best_score)      # FR-346
	cfg.set_value("modes", "ghost_paths", ghost_paths)                       # FR-353
	cfg.set_value("modes", "daily_seed_date", daily_seed_date)                # FR-350
	cfg.set_value("modes", "daily_seed_modifier_id", daily_seed_modifier_id)  # FR-350
	cfg.set_value("meta", "checksum", _compute_checksum(cfg))  # FR-413
	_write_config_atomic(cfg, _save_path())
	_create_backup(_save_path())  # FR-406/411/417


## FR-404: Öffentlicher Alias, damit Aufrufer (z.B. nach jedem Level)
## nicht auf die intern-benannte Funktion zugreifen müssen.
func save_now() -> void:
	_save_progress()


## FR-414: Speichert Einstellungen (Steuerung/Kamera/HUD/Grafik/Audio +
## aktiver Speicherplatz) in einer eigenen, vom Spielfortschritt
## unabhängigen Datei — ein Fortschritts-Reset (FR-228/420) wirkt sich
## dadurch nie auf diese Einstellungen aus (und umgekehrt).
func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.set_value("profile", "current_slot", current_save_slot)  # FR-403
	cfg.set_value("input", "control_scheme", control_scheme)  # FR-042/043/044
	cfg.set_value("input", "left_handed", left_handed_mode)
	cfg.set_value("input", "touch_sensitivity", touch_sensitivity)
	cfg.set_value("input", "touch_dead_zone", touch_dead_zone)
	cfg.set_value("camera", "shake_intensity", camera_shake_intensity)  # FR-189
	cfg.set_value("camera", "smoothing", camera_smoothing)  # FR-200
	cfg.set_value("hud", "minimal_mode", hud_minimal_mode)  # FR-215
	cfg.set_value("hud", "scale", hud_scale)  # FR-216
	cfg.set_value("render", "shader_quality", shader_quality)  # FR-300
	cfg.set_value("render", "render_scale", render_scale)  # FR-291
	cfg.set_value("render", "pixel_perfect", pixel_perfect_mode)  # FR-299
	cfg.set_value("render", "crt_filter", crt_filter_enabled)  # FR-282
	cfg.set_value("audio", "haptics_enabled", haptics_enabled)
	cfg.set_value("audio", "sound_muted", sound_muted)
	_write_config_atomic(cfg, SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load_encrypted_pass(SETTINGS_PATH, SAVE_PASSPHRASE) != OK:
		return  # Noch keine Einstellungen gespeichert – Standardwerte gelten
	current_save_slot = cfg.get_value("profile", "current_slot", 1)  # FR-403
	control_scheme = cfg.get_value("input", "control_scheme", "direct")
	left_handed_mode = cfg.get_value("input", "left_handed", false)
	touch_sensitivity = cfg.get_value("input", "touch_sensitivity", 1.0)
	touch_dead_zone = cfg.get_value("input", "touch_dead_zone", 20.0)
	camera_shake_intensity = cfg.get_value("camera", "shake_intensity", 1.0)
	camera_smoothing = cfg.get_value("camera", "smoothing", 8.0)
	hud_minimal_mode = cfg.get_value("hud", "minimal_mode", false)
	hud_scale = cfg.get_value("hud", "scale", 1.0)
	shader_quality = cfg.get_value("render", "shader_quality", "high")
	render_scale = cfg.get_value("render", "render_scale", 1.0)
	pixel_perfect_mode = cfg.get_value("render", "pixel_perfect", false)
	crt_filter_enabled = cfg.get_value("render", "crt_filter", false)
	haptics_enabled = cfg.get_value("audio", "haptics_enabled", true)
	sound_muted = cfg.get_value("audio", "sound_muted", false)


## FR-401: Schreibt eine ConfigFile verschlüsselt (FR-409) und atomar —
## zuerst in eine Temp-Datei, dann per Umbenennen an die Zielposition
## verschoben, damit ein Absturz mitten im Schreiben nie die vorherige,
## intakte Datei zerstört.
func _write_config_atomic(cfg: ConfigFile, path: String) -> void:
	var tmp_path := path + ".tmp"
	var err := cfg.save_encrypted_pass(tmp_path, SAVE_PASSPHRASE)
	if err != OK:
		push_warning("Speichern fehlgeschlagen (%s): Fehlercode %d" % [path, err])
		return
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	var rel_path := path.trim_prefix("user://")
	var rel_tmp := tmp_path.trim_prefix("user://")
	if dir.file_exists(rel_path):
		dir.remove(rel_path)
	dir.rename(rel_tmp, rel_path)


## FR-413: Einfache Prüfsumme über alle gespeicherten Werte (außer der
## Prüfsumme selbst), um grobe Speicher-Korruption beim Laden zu
## erkennen — kein Kryptografie-Anspruch, nur ein Korruptions-Indikator.
func _compute_checksum(cfg: ConfigFile) -> int:
	var parts := PackedStringArray()
	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			if section == "meta" and key == "checksum":
				continue
			parts.append("%s.%s=%s" % [section, key, cfg.get_value(section, key)])
	parts.sort()
	return "|".join(parts).hash()


func _verify_checksum(cfg: ConfigFile) -> bool:
	if not cfg.has_section_key("meta", "checksum"):
		return true  # ältere Speicherstände ohne Prüfsumme werden akzeptiert
	return _compute_checksum(cfg) == int(cfg.get_value("meta", "checksum"))


## FR-406/411/417: Legt eine Zeitstempel-Kopie der Speicherdatei im
## Backup-Verzeichnis an und behält nur die letzten MAX_BACKUPS_PER_SLOT.
func _create_backup(source_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(BACKUP_DIR)
	var dir := DirAccess.open("user://")
	if dir == null or not dir.file_exists(source_path.trim_prefix("user://")):
		return
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var backup_name := "slot%d_%s.cfg" % [current_save_slot, stamp]
	dir.copy(source_path, BACKUP_DIR + backup_name)
	_prune_backups()


func _list_slot_backup_files() -> Array:
	var dir := DirAccess.open(BACKUP_DIR)
	if dir == null:
		return []
	var files := []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.begins_with("slot%d_" % current_save_slot):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files


func _prune_backups() -> void:
	var dir := DirAccess.open(BACKUP_DIR)
	if dir == null:
		return
	var files := _list_slot_backup_files()
	while files.size() > MAX_BACKUPS_PER_SLOT:
		dir.remove(BACKUP_DIR + files[0])
		files.remove_at(0)


## FR-407/418: Liste vorhandener Backups für den aktuellen Speicherplatz,
## neueste zuerst — für die Speicher-Slot-Verwaltungs-UI.
func list_backups() -> Array:
	var files := _list_slot_backup_files()
	files.reverse()
	return files


## FR-407/411: Stellt den Fortschritt aus einer Backup-Datei wieder her.
func restore_backup(backup_filename: String) -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if dir.copy(BACKUP_DIR + backup_filename, _save_path()) != OK:
		return false
	_load_progress()
	return true


## FR-406: Exportiert den aktuellen Spielstand als benannte Backup-Datei
## (z.B. für einen manuellen "Jetzt sichern"-Button).
func export_save() -> String:
	_save_progress()
	var backups := list_backups()
	return backups[0] if not backups.is_empty() else ""


## FR-403: Wechselt zum angegebenen Speicherprofil (1..SAVE_SLOT_COUNT)
## und lädt dessen Stand (oder setzt auf Standardwerte zurück, falls das
## Profil noch leer ist).
func switch_save_slot(slot: int) -> void:
	current_save_slot = clampi(slot, 1, SAVE_SLOT_COUNT)
	_save_settings()
	# FR-403: Erst auf Standardwerte zurücksetzen, damit ein noch leeres
	# Zielprofil nicht versehentlich den Stand des vorherigen Profils
	# übernimmt (_load_progress() kehrt bei fehlender Datei früh zurück).
	_reset_progress_vars_to_default()
	_load_progress()


## FR-403/418: Ob für einen Speicherplatz bereits ein Spielstand existiert.
func save_slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_save_path(slot))


## FR-403/418: Löscht den Spielstand eines Profils (auch das aktuell
## aktive, das dann beim nächsten Laden leer erscheint).
func delete_save_slot(slot: int) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	var p := _save_path(slot).trim_prefix("user://")
	if dir.file_exists(p):
		dir.remove(p)


## FR-228: Setzt den gesamten Spielstand auf den Ausgangszustand zurück
## (Sterne, Statistiken, Sammlungen, Guthaben) und löscht die
## Speicherdatei des aktuellen Profils. Einstellungen (FR-414) sind
## davon unberührt. Wird nach Bestätigung im Reset-Dialog aufgerufen.
func reset_all_progress() -> void:
	_reset_progress_vars_to_default()
	var dir := DirAccess.open("user://")
	var p := _save_path().trim_prefix("user://")
	if dir != null and dir.file_exists(p):
		dir.remove(p)
	_save_progress()


## FR-401/403/411/417: Setzt alle Fortschritts-Variablen (nicht die
## Einstellungen) auf ihre Ausgangswerte — gemeinsam genutzt von
## reset_all_progress(), einem leeren Speicherplatz-Wechsel und als
## Fallback, wenn weder Primärdatei noch Backup lesbar sind.
func _reset_progress_vars_to_default() -> void:
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
	unlocked_skills.clear()               # FR-304/305
	prestige_level = 0                    # FR-306
	claimed_milestones.clear()            # FR-308
	lifetime_coins = 0                    # FR-308
	login_streak_day = 0                  # FR-309
	_last_login_date = ""                 # FR-309
	weekly_progress.clear()               # FR-310
	weekly_claimed.clear()                # FR-310
	_weekly_week_id = ""                  # FR-310
	season_xp = 0                         # FR-311
	season_claimed_tiers.clear()          # FR-311
	piggy_bank_amount = 0                 # FR-313
	hard_mode_enabled = false             # FR-316
	hard_mode_stars.clear()               # FR-316
	earned_badges.clear()                 # FR-318
	active_game_mode = GameMode.NORMAL    # FR-342-360
	endless_loop_count = 0                # FR-342
	endless_best_loops = 0                # FR-342
	survival_best_time = 0.0              # FR-343
	coin_hunt_best_score = 0              # FR-346
	marathon_level_index = 0              # FR-356
	ghost_paths.clear()                   # FR-353
	daily_seed_date = ""                  # FR-350
	daily_seed_modifier_id = "none"       # FR-350


## FR-420: DSGVO-konformes vollständiges Löschen aller lokal
## gespeicherten Daten dieser App — alle Speicherplätze, Einstellungen,
## Erfolge/Herausforderungen und Backups. Deutlich weitreichender als
## reset_all_progress() (die nur das aktive Profil zurücksetzt).
func delete_all_user_data() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		for slot in range(1, SAVE_SLOT_COUNT + 1):
			var p := _save_path(slot).trim_prefix("user://")
			if dir.file_exists(p):
				dir.remove(p)
		var settings_rel := SETTINGS_PATH.trim_prefix("user://")
		if dir.file_exists(settings_rel):
			dir.remove(settings_rel)
	var backup_dir := DirAccess.open(BACKUP_DIR)
	if backup_dir != null:
		backup_dir.list_dir_begin()
		var f := backup_dir.get_next()
		while f != "":
			if not backup_dir.current_is_dir():
				backup_dir.remove(f)
			f = backup_dir.get_next()
		backup_dir.list_dir_end()
	if FileAccess.file_exists(AchievementManager.SAVE_PATH):
		DirAccess.remove_absolute(AchievementManager.SAVE_PATH)
	AchievementManager.reset_all()
	_reset_progress_vars_to_default()
	current_save_slot = 1
	_save_settings()


## FR-401/411/413/417: Lädt den Fortschritt des aktuellen Speicherplatzes.
## Bei fehlender/beschädigter Primärdatei wird automatisch versucht, das
## neueste Backup wiederherzustellen, bevor auf Standardwerte
## zurückgefallen wird.
func _load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load_encrypted_pass(_save_path(), SAVE_PASSPHRASE)
	if err != OK or not _verify_checksum(cfg):
		if err != OK and err != ERR_FILE_NOT_FOUND:
			push_warning("Speicherstand beschädigt oder unlesbar — versuche Backup-Wiederherstellung.")
		elif err == OK:
			push_warning("Speicherstand-Prüfsumme ungültig — versuche Backup-Wiederherstellung.")
		var backups := list_backups()
		var restored := false
		for backup_name in backups:
			var candidate := ConfigFile.new()
			if candidate.load_encrypted_pass(BACKUP_DIR + backup_name, SAVE_PASSPHRASE) == OK \
					and _verify_checksum(candidate):
				cfg = candidate
				restored = true
				break
		if not restored:
			if err != ERR_FILE_NOT_FOUND:
				_reset_progress_vars_to_default()  # FR-417: kein brauchbarer Stand vorhanden
			return  # Erstinstallation (kein Fehler) oder unrettbar beschädigt
	for lvl in level_stars.keys():
		level_stars[lvl] = int(cfg.get_value("stars", str(lvl), 0))
	var saved: Array = cfg.get_value("bestiary", "discovered", [])
	discovered_enemies.assign(saved)
	last_daily_coin_date = cfg.get_value("daily", "last_coin_date", "")  # FR-093
	var saved_stickers: Array = cfg.get_value("stickers", "collected", [])  # FR-089
	collected_stickers.assign(saved_stickers)
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
	var saved_skills: Array = cfg.get_value("progression", "unlocked_skills", [])       # FR-304/305
	unlocked_skills.assign(saved_skills)
	prestige_level = cfg.get_value("progression", "prestige_level", 0)                  # FR-306
	var saved_milestones: Array = cfg.get_value("progression", "claimed_milestones", [])  # FR-308
	claimed_milestones.assign(saved_milestones)
	lifetime_coins = cfg.get_value("progression", "lifetime_coins", 0)                  # FR-308
	login_streak_day = cfg.get_value("progression", "login_streak_day", 0)              # FR-309
	_last_login_date = cfg.get_value("progression", "last_login_date", "")              # FR-309
	weekly_progress = cfg.get_value("progression", "weekly_progress", {})               # FR-310
	weekly_claimed = cfg.get_value("progression", "weekly_claimed", {})                 # FR-310
	_weekly_week_id = cfg.get_value("progression", "weekly_week_id", "")                # FR-310
	season_xp = cfg.get_value("progression", "season_xp", 0)                            # FR-311
	var saved_tiers: Array = cfg.get_value("progression", "season_claimed_tiers", [])   # FR-311
	season_claimed_tiers.assign(saved_tiers)
	piggy_bank_amount = cfg.get_value("progression", "piggy_bank_amount", 0)            # FR-313
	hard_mode_enabled = cfg.get_value("progression", "hard_mode_enabled", false)        # FR-316
	hard_mode_stars = cfg.get_value("progression", "hard_mode_stars", {})               # FR-316
	var saved_badges: Array = cfg.get_value("progression", "earned_badges", [])         # FR-318
	earned_badges.assign(saved_badges)
	active_game_mode = cfg.get_value("modes", "active_game_mode", GameMode.NORMAL)      # FR-342-360
	endless_best_loops = cfg.get_value("modes", "endless_best_loops", 0)                # FR-342
	survival_best_time = cfg.get_value("modes", "survival_best_time", 0.0)              # FR-343
	coin_hunt_best_score = cfg.get_value("modes", "coin_hunt_best_score", 0)            # FR-346
	ghost_paths = cfg.get_value("modes", "ghost_paths", {})                             # FR-353
	daily_seed_date = cfg.get_value("modes", "daily_seed_date", "")                     # FR-350
	daily_seed_modifier_id = cfg.get_value("modes", "daily_seed_modifier_id", "none")   # FR-350


## FR-118: Registriert einen Gegner-Typ als entdeckt (persistiert).
func discover_enemy(class_id: String) -> void:
	if class_id in discovered_enemies:
		return
	discovered_enemies.append(class_id)
	_save_progress()
