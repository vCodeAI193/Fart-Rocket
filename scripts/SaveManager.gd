extends Node
## SaveManager (Autoload / Singleton)
## =====================================
## FR-401/403/404/406/407/409/410/411/413/414/416/417/418/420: Gehärtetes,
## Mehrfach-Profil-fähiges lokales Speichersystem. Ausgelagert aus
## GameManager.gd (das vorher als "God Object" Level-Zustand, Speicher-
## logik, Kosmetik und Einstellungen in einer 2100+-Zeilen-Datei
## vereinte), analog zum bereits bestehenden Muster von
## AchievementManager.gd/LocalizationManager.gd.
##
## SaveManager besitzt selbst kaum Spielzustand — er orchestriert nur das
## Lesen/Schreiben der eigentlichen Daten, die weiterhin in GameManager
## (Level-/Sitzungs-/Fortschritts-Variablen) und CosmeticsManager
## (Kosmetik-Katalog/Ausrüstung) liegen. Dadurch bleiben alle
## bestehenden `GameManager.xxx`-Zugriffe auf einzelne Werte im übrigen
## Projekt unverändert — nur die rund 15 öffentlichen Speicher-Aktionen
## (save_now, switch_save_slot, list_backups, ...) wandern zu
## `SaveManager.xxx`.

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
	for lvl in GameManager.level_stars.keys():
		cfg.set_value("stars", str(lvl), GameManager.level_stars[lvl])
	cfg.set_value("bestiary", "discovered", GameManager.discovered_enemies)
	cfg.set_value("daily", "last_coin_date", GameManager.last_daily_coin_date)  # FR-093
	cfg.set_value("stickers", "collected", GameManager.collected_stickers)  # FR-089
	cfg.set_value("hud", "attempt_times", GameManager.level_attempt_times)  # FR-219
	cfg.set_value("hud", "tutorial_hint_seen", GameManager.tutorial_hint_seen)  # FR-210
	cfg.set_value("stats", "total_farts", GameManager.stat_total_farts)  # FR-226
	cfg.set_value("stats", "total_deaths", GameManager.stat_total_deaths)  # FR-226
	cfg.set_value("menu", "favorites", GameManager.favorite_levels)  # FR-236
	cfg.set_value("menu", "last_played_level", GameManager.last_played_level)  # FR-238
	cfg.set_value("shop", "persistent_coins", GameManager.persistent_coins)  # FR-224
	CosmeticsManager.write_to_save(cfg)  # FR-224/334
	cfg.set_value("progression", "unlocked_skills", GameManager.unlocked_skills)          # FR-304/305
	cfg.set_value("progression", "prestige_level", GameManager.prestige_level)            # FR-306
	cfg.set_value("progression", "claimed_milestones", GameManager.claimed_milestones)    # FR-308
	cfg.set_value("progression", "lifetime_coins", GameManager.lifetime_coins)            # FR-308
	cfg.set_value("progression", "login_streak_day", GameManager.login_streak_day)        # FR-309
	cfg.set_value("progression", "last_login_date", GameManager._last_login_date)         # FR-309
	cfg.set_value("progression", "weekly_progress", GameManager.weekly_progress)          # FR-310
	cfg.set_value("progression", "weekly_claimed", GameManager.weekly_claimed)            # FR-310
	cfg.set_value("progression", "weekly_week_id", GameManager._weekly_week_id)           # FR-310
	cfg.set_value("progression", "season_xp", GameManager.season_xp)                      # FR-311
	cfg.set_value("progression", "season_claimed_tiers", GameManager.season_claimed_tiers)  # FR-311
	cfg.set_value("progression", "piggy_bank_amount", GameManager.piggy_bank_amount)      # FR-313
	cfg.set_value("progression", "hard_mode_enabled", GameManager.hard_mode_enabled)      # FR-316
	cfg.set_value("progression", "hard_mode_stars", GameManager.hard_mode_stars)          # FR-316
	cfg.set_value("progression", "earned_badges", GameManager.earned_badges)              # FR-318
	GameModeManager.write_to_save(cfg)  # FR-342-360
	cfg.set_value("meta", "checksum", _compute_checksum(cfg))  # FR-413
	_write_config_atomic(cfg, _save_path())
	_create_backup(_save_path())  # FR-406/411/417


## FR-404: Öffentlicher Alias, damit Aufrufer (z.B. nach jedem Level)
## nicht auf die intern-benannte Funktion zugreifen müssen.
func save_now() -> void:
	_save_progress()


## Test-Infrastruktur: Öffentlicher Alias für _load_progress(), analog zu
## save_now() — ermöglicht gezieltes Neuladen in Tests, ohne auf die
## konventionell private Funktion zuzugreifen.
func load_now() -> void:
	_load_progress()


## Test-Infrastruktur: Öffentlicher Zugriff auf den Speicherpfad eines
## Profils (für Tests, die absichtlich Korruption simulieren wollen).
func get_save_path(slot: int = -1) -> String:
	return _save_path(slot)


## Öffentlicher Alias, damit Aufrufer (z.B. GameManager.gd bei jeder
## Einstellungsänderung) nicht auf die intern-benannte Funktion zugreifen
## müssen — analog zu save_now().
func save_settings() -> void:
	_save_settings()


## Öffentlicher Alias für _load_settings(), analog zu save_settings().
func load_settings() -> void:
	_load_settings()


## FR-414: Speichert Einstellungen (Steuerung/Kamera/HUD/Grafik/Audio +
## aktiver Speicherplatz) in einer eigenen, vom Spielfortschritt
## unabhängigen Datei — ein Fortschritts-Reset (FR-228/420) wirkt sich
## dadurch nie auf diese Einstellungen aus (und umgekehrt).
func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.set_value("profile", "current_slot", current_save_slot)  # FR-403
	cfg.set_value("input", "control_scheme", GameManager.control_scheme)  # FR-042/043/044
	cfg.set_value("input", "left_handed", GameManager.left_handed_mode)
	cfg.set_value("input", "touch_sensitivity", GameManager.touch_sensitivity)
	cfg.set_value("input", "touch_dead_zone", GameManager.touch_dead_zone)
	cfg.set_value("camera", "shake_intensity", GameManager.camera_shake_intensity)  # FR-189
	cfg.set_value("camera", "smoothing", GameManager.camera_smoothing)  # FR-200
	cfg.set_value("hud", "minimal_mode", GameManager.hud_minimal_mode)  # FR-215
	cfg.set_value("hud", "scale", GameManager.hud_scale)  # FR-216
	cfg.set_value("render", "shader_quality", GameManager.shader_quality)  # FR-300
	cfg.set_value("render", "render_scale", GameManager.render_scale)  # FR-291
	cfg.set_value("render", "pixel_perfect", GameManager.pixel_perfect_mode)  # FR-299
	cfg.set_value("render", "crt_filter", GameManager.crt_filter_enabled)  # FR-282
	cfg.set_value("render", "quality_auto_detected", GameManager.quality_auto_detected)  # FR-467
	cfg.set_value("audio", "haptics_enabled", GameManager.haptics_enabled)
	cfg.set_value("audio", "sound_muted", SoundManager.sound_muted)                 # FR-250
	cfg.set_value("audio", "master_volume", GameManager.master_volume)              # FR-438
	cfg.set_value("audio", "music_volume", SoundManager.music_volume)               # FR-249
	AccessibilityManager.write_to_save(cfg)
	_write_config_atomic(cfg, SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load_encrypted_pass(SETTINGS_PATH, SAVE_PASSPHRASE) != OK:
		return  # Noch keine Einstellungen gespeichert – Standardwerte gelten
	current_save_slot = cfg.get_value("profile", "current_slot", 1)  # FR-403
	GameManager.control_scheme = cfg.get_value("input", "control_scheme", "direct")
	GameManager.left_handed_mode = cfg.get_value("input", "left_handed", false)
	GameManager.touch_sensitivity = cfg.get_value("input", "touch_sensitivity", 1.0)
	GameManager.touch_dead_zone = cfg.get_value("input", "touch_dead_zone", 20.0)
	GameManager.camera_shake_intensity = cfg.get_value("camera", "shake_intensity", 1.0)
	GameManager.camera_smoothing = cfg.get_value("camera", "smoothing", 8.0)
	GameManager.hud_minimal_mode = cfg.get_value("hud", "minimal_mode", false)
	GameManager.hud_scale = cfg.get_value("hud", "scale", 1.0)
	GameManager.shader_quality = cfg.get_value("render", "shader_quality", "high")
	GameManager.render_scale = cfg.get_value("render", "render_scale", 1.0)
	GameManager.pixel_perfect_mode = cfg.get_value("render", "pixel_perfect", false)
	GameManager.crt_filter_enabled = cfg.get_value("render", "crt_filter", false)
	GameManager.quality_auto_detected = cfg.get_value("render", "quality_auto_detected", false)  # FR-467
	GameManager.haptics_enabled = cfg.get_value("audio", "haptics_enabled", true)
	SoundManager.sound_muted = cfg.get_value("audio", "sound_muted", false)                     # FR-250
	GameManager.master_volume = cfg.get_value("audio", "master_volume", 1.0)                    # FR-438
	SoundManager.music_volume = cfg.get_value("audio", "music_volume", 0.8)                     # FR-249
	SoundManager.apply_music_volume()
	AccessibilityManager.read_from_save(cfg)


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
	GameManager.level_stars = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0}
	GameManager.total_xp = 0
	GameManager.player_level = 1
	GameManager.discovered_enemies.clear()
	GameManager.collected_stickers.clear()
	GameManager.last_daily_coin_date = ""
	GameManager.tutorial_hint_seen = false
	GameManager.stat_total_farts = 0
	GameManager.stat_total_deaths = 0
	GameManager.favorite_levels.clear()
	GameManager.last_played_level = 0
	GameManager.persistent_coins = 0
	GameManager.level_attempt_times.clear()
	CosmeticsManager.reset_to_default()
	GameManager.unlocked_skills.clear()               # FR-304/305
	GameManager.prestige_level = 0                    # FR-306
	GameManager.claimed_milestones.clear()            # FR-308
	GameManager.lifetime_coins = 0                    # FR-308
	GameManager.login_streak_day = 0                  # FR-309
	GameManager._last_login_date = ""                 # FR-309
	GameManager.weekly_progress.clear()               # FR-310
	GameManager.weekly_claimed.clear()                # FR-310
	GameManager._weekly_week_id = ""                  # FR-310
	GameManager.season_xp = 0                         # FR-311
	GameManager.season_claimed_tiers.clear()          # FR-311
	GameManager.piggy_bank_amount = 0                 # FR-313
	GameManager.hard_mode_enabled = false             # FR-316
	GameManager.hard_mode_stars.clear()               # FR-316
	GameManager.earned_badges.clear()                 # FR-318
	GameModeManager.reset_to_default()                # FR-342-360


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
	for lvl in GameManager.level_stars.keys():
		GameManager.level_stars[lvl] = int(cfg.get_value("stars", str(lvl), 0))
	var saved: Array = cfg.get_value("bestiary", "discovered", [])
	GameManager.discovered_enemies.assign(saved)
	GameManager.last_daily_coin_date = cfg.get_value("daily", "last_coin_date", "")  # FR-093
	var saved_stickers: Array = cfg.get_value("stickers", "collected", [])  # FR-089
	GameManager.collected_stickers.assign(saved_stickers)
	GameManager.level_attempt_times = cfg.get_value("hud", "attempt_times", {})  # FR-219
	GameManager.tutorial_hint_seen = cfg.get_value("hud", "tutorial_hint_seen", false)  # FR-210
	GameManager.stat_total_farts = cfg.get_value("stats", "total_farts", 0)  # FR-226
	GameManager.stat_total_deaths = cfg.get_value("stats", "total_deaths", 0)  # FR-226
	var saved_favorites: Array = cfg.get_value("menu", "favorites", [])  # FR-236
	GameManager.favorite_levels.assign(saved_favorites)
	GameManager.last_played_level = cfg.get_value("menu", "last_played_level", 0)  # FR-238
	GameManager.persistent_coins = cfg.get_value("shop", "persistent_coins", 0)  # FR-224
	CosmeticsManager.read_from_save(cfg)  # FR-224/334
	var saved_skills: Array = cfg.get_value("progression", "unlocked_skills", [])       # FR-304/305
	GameManager.unlocked_skills.assign(saved_skills)
	GameManager.prestige_level = cfg.get_value("progression", "prestige_level", 0)                  # FR-306
	var saved_milestones: Array = cfg.get_value("progression", "claimed_milestones", [])  # FR-308
	GameManager.claimed_milestones.assign(saved_milestones)
	GameManager.lifetime_coins = cfg.get_value("progression", "lifetime_coins", 0)                  # FR-308
	GameManager.login_streak_day = cfg.get_value("progression", "login_streak_day", 0)              # FR-309
	GameManager._last_login_date = cfg.get_value("progression", "last_login_date", "")              # FR-309
	GameManager.weekly_progress = cfg.get_value("progression", "weekly_progress", {})               # FR-310
	GameManager.weekly_claimed = cfg.get_value("progression", "weekly_claimed", {})                 # FR-310
	GameManager._weekly_week_id = cfg.get_value("progression", "weekly_week_id", "")                # FR-310
	GameManager.season_xp = cfg.get_value("progression", "season_xp", 0)                            # FR-311
	var saved_tiers: Array = cfg.get_value("progression", "season_claimed_tiers", [])   # FR-311
	GameManager.season_claimed_tiers.assign(saved_tiers)
	GameManager.piggy_bank_amount = cfg.get_value("progression", "piggy_bank_amount", 0)            # FR-313
	GameManager.hard_mode_enabled = cfg.get_value("progression", "hard_mode_enabled", false)        # FR-316
	GameManager.hard_mode_stars = cfg.get_value("progression", "hard_mode_stars", {})               # FR-316
	var saved_badges: Array = cfg.get_value("progression", "earned_badges", [])         # FR-318
	GameManager.earned_badges.assign(saved_badges)
	GameModeManager.read_from_save(cfg)  # FR-342-360
