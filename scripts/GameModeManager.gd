extends Node
## GameModeManager (Autoload / Singleton)
## =====================================
## FR-341-360: Spielmodi (GameMode-Enum, aktiver Modus, Bestwerte je
## Modus, Zeitrennen-Bestzeiten, Geister-Pfade, Tages-Seed). Ausgelagert
## aus GameManager.gd im Rahmen des "God Object"-Refactorings (siehe
## README.md) — der größte in sich geschlossene Block der Datei: ein
## einzelnes Enum + ein einzelnes Dict + gut ein Dutzend eng verwandter
## Variablen/Funktionen, alle rund um "welcher Modus ist aktiv und was
## sind seine Bestwerte".

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

# --- FR-341: Zeitrennen-Modus (Time Attack) ----------------------
var time_attack_mode: bool = false
var time_attack_best_times := {1: INF, 2: INF, 3: INF, 4: INF, 5: INF, 6: INF, 7: INF}  # Level -> beste Zeit (Sek.)


## FR-342-360: Wechselt den aktiven Spielmodus (wirkt sich beim nächsten
## Levelstart in Main.gd/Player.gd aus).
func set_game_mode(mode: GameMode) -> void:
	active_game_mode = mode
	time_attack_mode = (mode == GameMode.TIME_ATTACK)  # bestehende Variable synchron halten
	if mode == GameMode.MARATHON:
		marathon_level_index = 1
		GameManager.current_level = 1  # Marathon startet immer bei Level 1
	if mode == GameMode.BOSS_RUSH:
		GameManager.current_level = GameManager.BOSS_LEVEL_INDEX  # FR-347: direkt zum Boss-Level springen
	SaveManager.save_now()


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
	SaveManager.save_now()


func get_ghost_path(level_index: int) -> PackedVector2Array:
	return ghost_paths.get(level_index, PackedVector2Array())


## FR-341: Prüft und speichert eine neue Bestzeit für den Zeitrennen-Modus.
## Gibt true zurück, wenn eine neue Bestzeit erreicht wurde.
func record_time_attack(level_index: int, time_sec: float) -> bool:
	if not time_attack_best_times.has(level_index):
		time_attack_best_times[level_index] = INF
	if time_sec < time_attack_best_times[level_index]:
		time_attack_best_times[level_index] = time_sec
		SaveManager.save_now()
		return true
	return false


## FR-341: Liefert die Bestzeit für ein Level (INF, falls noch keine).
func get_best_time(level_index: int) -> float:
	return time_attack_best_times.get(level_index, INF)


# --- Persistenz-Schnittstelle für SaveManager.gd ------------------------

## Schreibt alle Spielmodi-Felder in die übergebene ConfigFile — Abschnitt/
## Schlüssel exakt wie zuvor in SaveManager._save_progress(), damit
## bestehende Spielstände kompatibel bleiben. time_attack_best_times wird
## (wie zuvor in GameManager.gd) nicht persistiert — nur zurückgesetzt.
func write_to_save(cfg: ConfigFile) -> void:
	cfg.set_value("modes", "active_game_mode", active_game_mode)              # FR-342-360
	cfg.set_value("modes", "endless_best_loops", endless_best_loops)          # FR-342
	cfg.set_value("modes", "survival_best_time", survival_best_time)          # FR-343
	cfg.set_value("modes", "coin_hunt_best_score", coin_hunt_best_score)      # FR-346
	cfg.set_value("modes", "ghost_paths", ghost_paths)                       # FR-353
	cfg.set_value("modes", "daily_seed_date", daily_seed_date)                # FR-350
	cfg.set_value("modes", "daily_seed_modifier_id", daily_seed_modifier_id)  # FR-350


## Liest alle Spielmodi-Felder aus der ConfigFile — Abschnitt/Schlüssel
## exakt wie zuvor in SaveManager._load_progress().
func read_from_save(cfg: ConfigFile) -> void:
	active_game_mode = cfg.get_value("modes", "active_game_mode", GameMode.NORMAL)      # FR-342-360
	endless_best_loops = cfg.get_value("modes", "endless_best_loops", 0)                # FR-342
	survival_best_time = cfg.get_value("modes", "survival_best_time", 0.0)              # FR-343
	coin_hunt_best_score = cfg.get_value("modes", "coin_hunt_best_score", 0)            # FR-346
	ghost_paths = cfg.get_value("modes", "ghost_paths", {})                             # FR-353
	daily_seed_date = cfg.get_value("modes", "daily_seed_date", "")                     # FR-350
	daily_seed_modifier_id = cfg.get_value("modes", "daily_seed_modifier_id", "none")   # FR-350


## Setzt alle Felder auf ihre Werkseinstellung zurück. Wird von
## SaveManager._reset_progress_vars_to_default() aufgerufen.
func reset_to_default() -> void:
	active_game_mode = GameMode.NORMAL    # FR-342-360
	endless_loop_count = 0                # FR-342
	endless_best_loops = 0                # FR-342
	survival_best_time = 0.0              # FR-343
	coin_hunt_best_score = 0              # FR-346
	marathon_level_index = 0              # FR-356
	ghost_paths.clear()                   # FR-353
	daily_seed_date = ""                  # FR-350
	daily_seed_modifier_id = "none"       # FR-350
	time_attack_best_times = {1: INF, 2: INF, 3: INF, 4: INF, 5: INF, 6: INF, 7: INF}
