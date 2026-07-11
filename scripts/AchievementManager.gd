extends Node
## AchievementManager (Autoload / Singleton)
## ============================================
## FR-321: Lokales Achievement-Framework (ConfigFile-basiert). Die
## Google-Play-Games-Anbindung selbst ist zurückgestellt (siehe FR-340,
## Projektplan — benötigt echte GPGS-Zugangsdaten), die Datenstruktur ist
## aber so aufgebaut (stabile String-IDs), dass eine spätere
## Cloud-/Plattform-Synchronisierung ohne Umbau andocken könnte.

signal achievement_unlocked(id)  # FR-338: löst die Pop-up-Benachrichtigung aus

const SAVE_PATH := "user://fartrocket_achievements.cfg"

# --- Kategorien (FR-339: Filter in der UI) ---------------------------
enum Category { FARTS, COINS, CHALLENGE, SPEED, STARS, STREAK, COMBO, WORLD, HIDDEN }

# --- FR-322–328/333/335–337: Erfolgs-Katalog --------------------------
# "hidden": true -> Name/Beschreibung werden erst nach Freischaltung
# angezeigt (FR-333). "reward_coins"/"reward_cosmetic" -> FR-334.
const ACHIEVEMENTS := {
	"fart_100": {"name": "Warmgefurzt", "desc": "100 Mal gefurzt", "category": Category.FARTS, "hidden": false, "stat": "stat_total_farts", "target": 100, "reward_coins": 30},
	"fart_1000": {"name": "Dauerfurzer", "desc": "1000 Mal gefurzt", "category": Category.FARTS, "hidden": false, "stat": "stat_total_farts", "target": 1000, "reward_coins": 120},
	"fart_10000": {"name": "Furz-Legende", "desc": "10.000 Mal gefurzt", "category": Category.FARTS, "hidden": false, "stat": "stat_total_farts", "target": 10000, "reward_coins": 500},
	"coins_500": {"name": "Kleinsparer", "desc": "500 Münzen gesammelt", "category": Category.COINS, "hidden": false, "stat": "lifetime_coins", "target": 500, "reward_coins": 50},
	"coins_5000": {"name": "Großsparer", "desc": "5000 Münzen gesammelt", "category": Category.COINS, "hidden": false, "stat": "lifetime_coins", "target": 5000, "reward_coins": 300},
	"pacifist_run": {"name": "Pazifist", "desc": "Ein Level ohne eine einzige Münze abgeschlossen", "category": Category.CHALLENGE, "hidden": false, "reward_coins": 80},
	"perfect_run": {"name": "Makellos", "desc": "Ein Level mit 3 Sternen und ohne Schild-Verlust abgeschlossen", "category": Category.CHALLENGE, "hidden": false, "reward_coins": 100},
	"speedrun_30": {"name": "Blitzstart", "desc": "Ein Level unter 30 Sekunden abgeschlossen", "category": Category.SPEED, "hidden": false, "reward_coins": 80},
	"frugal_farts": {"name": "Sparfuchs", "desc": "Ein Level mit höchstens 3 Furz-Stößen abgeschlossen", "category": Category.CHALLENGE, "hidden": false, "reward_coins": 90},
	"all_stars": {"name": "Sternensammler", "desc": "Alle Level mit 3 Sternen abgeschlossen", "category": Category.STARS, "hidden": false, "reward_coins": 250, "reward_cosmetic": "hat_crown"},
	"secret_prestige": {"name": "Von vorn beginnen", "desc": "Einen Prestige-Durchlauf abgeschlossen", "category": Category.HIDDEN, "hidden": true, "reward_coins": 150},
	"secret_first_death": {"name": "Erste Bruchlandung", "desc": "Zum ersten Mal gestorben", "category": Category.HIDDEN, "hidden": true, "reward_coins": 10},
	"login_streak_7": {"name": "Treuer Astronaut", "desc": "7 Tage in Folge eingeloggt", "category": Category.STREAK, "hidden": false, "reward_coins": 150},
	"combo_5": {"name": "Combo-Meister", "desc": "Eine 5er-Münz-Combo erzielt", "category": Category.COMBO, "hidden": false, "reward_coins": 60},
	"world1_complete": {"name": "Welt 1 gemeistert", "desc": "Alle Level der ersten Welt abgeschlossen", "category": Category.WORLD, "hidden": false, "reward_coins": 100},
}

# --- FR-331: Herausforderungs-Modifikatoren (Mutatoren) ----------------
# Werden der täglichen/wöchentlichen Herausforderung zugelost, für
# zusätzliche Varianz (der vollständige "Mutator-Spielmodus" folgt in
# einem späteren Batch — hier nur die Modifikator-Definitionen selbst).
const MODIFIERS := [
	{"id": "none", "name": "Kein Modifikator"},
	{"id": "low_gravity", "name": "Schwache Schwerkraft"},
	{"id": "double_speed", "name": "Doppeltes Tempo"},
	{"id": "no_regen", "name": "Keine Ladungs-Regeneration"},
	{"id": "single_fart", "name": "Nur ein Furz-Stoß erlaubt"},
]

# --- FR-329/330: Tägliche/wöchentliche Herausforderungen ----------------
const CHALLENGE_TASKS := [
	{"id": "collect_coins", "name": "Sammle {n} Münzen", "n": 40},
	{"id": "no_death_level", "name": "Schließe ein Level ohne zu sterben ab", "n": 1},
	{"id": "fart_count", "name": "Furze {n} Mal", "n": 25},
	{"id": "finish_levels", "name": "Schließe {n} Level ab", "n": 2},
]

var unlocked: Array[String] = []
var _max_combo_seen: int = 0

# FR-329/330: rotierende Herausforderungen
var _daily_task_index: int = 0
var _daily_modifier_id: String = "none"
var daily_challenge_progress: int = 0
var daily_challenge_claimed: bool = false
var _daily_date_id: String = ""

var _weekly_task_index: int = 0
var weekly_challenge_progress: int = 0
var weekly_challenge_claimed: bool = false
var _weekly_week_id: String = ""


func _ready() -> void:
	_load()
	_ensure_daily_challenge()
	_ensure_weekly_challenge()
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.persistent_coins_changed.connect(func(_v): _check_all())


## FR-332: Fortschritt (aktuell, Ziel) für ein Erfolg mit Stat-Bindung.
func get_progress(id: String) -> Vector2i:
	var data: Dictionary = ACHIEVEMENTS.get(id, {})
	if not data.has("stat"):
		return Vector2i(0, 0)
	var value: int = GameManager.get(String(data["stat"]))
	return Vector2i(mini(value, int(data["target"])), int(data["target"]))


func is_unlocked(id: String) -> bool:
	return id in unlocked


func _unlock(id: String) -> void:
	if id in unlocked or not ACHIEVEMENTS.has(id):
		return
	unlocked.append(id)
	var data: Dictionary = ACHIEVEMENTS[id]
	if data.has("reward_coins"):
		GameManager.persistent_coins += int(data["reward_coins"])
		GameManager.persistent_coins_changed.emit(GameManager.persistent_coins)
	if data.has("reward_cosmetic"):
		GameManager.grant_cosmetic_free(String(data["reward_cosmetic"]))
	achievement_unlocked.emit(id)
	_show_unlock_toast(data)
	_save()


## FR-338: Zeigt ein kurzes Pop-up mit dem freigeschalteten Erfolg — als
## eigene CanvasLayer direkt auf der Baumwurzel, damit sie unabhängig von
## der gerade aktiven Szene (Level oder Menü) sichtbar wird.
func _show_unlock_toast(data: Dictionary) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 110
	tree.root.add_child(layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_top = 30.0
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "🏆 Erfolg freigeschaltet!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)
	var name_label := Label.new()
	name_label.text = String(data["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(name_label)

	panel.modulate.a = 0.0
	var tween := tree.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.35)
	tween.tween_interval(2.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)


## FR-322/323/335/336/337: Prüft alle stat-gebundenen und einfachen
## Erfolge gegen den aktuellen Spielstand.
func _check_all() -> void:
	for id in ACHIEVEMENTS.keys():
		if id in unlocked:
			continue
		var data: Dictionary = ACHIEVEMENTS[id]
		if data.has("stat"):
			var value: int = GameManager.get(String(data["stat"]))
			if value >= int(data["target"]):
				_unlock(id)
		elif id == "login_streak_7" and GameManager.login_streak_day >= 7:
			_unlock(id)
		elif id == "combo_5" and _max_combo_seen >= 5:
			_unlock(id)
		elif id == "all_stars" and _all_levels_at_stars(3):
			_unlock(id)
		elif id == "world1_complete" and _all_levels_at_stars(1):
			_unlock(id)


func _all_levels_at_stars(min_stars: int) -> bool:
	for lvl in range(1, GameManager.TOTAL_LEVELS + 1):
		if int(GameManager.level_stars.get(lvl, 0)) < min_stars:
			return false
	return true


func _on_combo_changed(count: int, _multiplier: int) -> void:
	_max_combo_seen = maxi(_max_combo_seen, count)
	_check_all()


func _on_coins_changed(_total: int) -> void:
	_advance_challenge_progress("collect_coins", 1)  # FR-329/330
	_check_all()


## FR-324/325/326/327: Vom Level-Abschluss aus aufgerufen (Main.gd) mit
## den Kennzahlen des gerade abgeschlossenen Versuchs.
func report_level_complete(stars: int, coins_collected: int, farts_used: int, time_sec: float, took_hit: bool) -> void:
	if coins_collected == 0:
		_unlock("pacifist_run")            # FR-324
	if stars >= 3 and not took_hit:
		_unlock("perfect_run")             # FR-325
	if time_sec < 30.0:
		_unlock("speedrun_30")             # FR-326
	if farts_used > 0 and farts_used <= 3:
		_unlock("frugal_farts")            # FR-327
	_advance_challenge_progress("finish_levels", 1)
	if not took_hit:
		_advance_challenge_progress("no_death_level", 1)
	_check_all()


## FR-333: Vom ersten Tod aus aufgerufen (Main.gd).
func report_first_death() -> void:
	_unlock("secret_first_death")


## FR-306-Hook: Vom Prestige-Abschluss aus aufgerufen (MainMenu/ProgressionScreen).
func report_prestige() -> void:
	_unlock("secret_prestige")


# ----------------------------------------------------------------------
# FR-329/330: Tägliche/wöchentliche Herausforderungen mit Modifikator
# ----------------------------------------------------------------------
func _ensure_daily_challenge() -> void:
	var today := Time.get_date_string_from_system()
	if today == _daily_date_id:
		return
	_daily_date_id = today
	var seed_val := today.hash()
	_daily_task_index = seed_val % CHALLENGE_TASKS.size()
	_daily_modifier_id = MODIFIERS[seed_val % MODIFIERS.size()]["id"]  # FR-331
	daily_challenge_progress = 0
	daily_challenge_claimed = false
	_save()


func _ensure_weekly_challenge() -> void:
	var week_id := str(int(Time.get_unix_time_from_system() / 86400) / 7)
	if week_id == _weekly_week_id:
		return
	_weekly_week_id = week_id
	_weekly_task_index = week_id.hash() % CHALLENGE_TASKS.size()
	weekly_challenge_progress = 0
	weekly_challenge_claimed = false
	_save()


func get_daily_challenge() -> Dictionary:
	_ensure_daily_challenge()
	var task: Dictionary = CHALLENGE_TASKS[_daily_task_index]
	var modifier: Dictionary = MODIFIERS[0]
	for m in MODIFIERS:
		if m["id"] == _daily_modifier_id:
			modifier = m
			break
	return {
		"name": String(task["name"]).format({"n": task["n"]}),
		"target": int(task["n"]),
		"progress": daily_challenge_progress,
		"claimed": daily_challenge_claimed,
		"modifier_name": modifier["name"],
		"modifier_id": modifier["id"],
	}


func get_weekly_challenge() -> Dictionary:
	_ensure_weekly_challenge()
	var task: Dictionary = CHALLENGE_TASKS[_weekly_task_index]
	return {
		"name": String(task["name"]).format({"n": int(task["n"]) * 5}),
		"target": int(task["n"]) * 5,
		"progress": weekly_challenge_progress,
		"claimed": weekly_challenge_claimed,
	}


func _advance_challenge_progress(task_id: String, amount: int) -> void:
	_ensure_daily_challenge()
	_ensure_weekly_challenge()
	if CHALLENGE_TASKS[_daily_task_index]["id"] == task_id and not daily_challenge_claimed:
		daily_challenge_progress += amount
	if CHALLENGE_TASKS[_weekly_task_index]["id"] == task_id and not weekly_challenge_claimed:
		weekly_challenge_progress += amount
	_save()


## Für Fortschritts-Ereignisse, die nicht über report_level_complete laufen
## (Münzen sammeln, Furzen) — von GameManager/Player aus aufgerufen.
func advance_challenge_task(task_id: String, amount: int = 1) -> void:
	_advance_challenge_progress(task_id, amount)


func claim_daily_challenge() -> int:
	var data := get_daily_challenge()
	if data["claimed"] or int(data["progress"]) < int(data["target"]):
		return 0
	daily_challenge_claimed = true
	var reward := 60
	GameManager.persistent_coins += reward
	GameManager.persistent_coins_changed.emit(GameManager.persistent_coins)
	_save()
	return reward


func claim_weekly_challenge() -> int:
	var data := get_weekly_challenge()
	if data["claimed"] or int(data["progress"]) < int(data["target"]):
		return 0
	weekly_challenge_claimed = true
	var reward := 180
	GameManager.persistent_coins += reward
	GameManager.persistent_coins_changed.emit(GameManager.persistent_coins)
	_save()
	return reward


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.set_value("achievements", "max_combo_seen", _max_combo_seen)
	cfg.set_value("daily", "date_id", _daily_date_id)
	cfg.set_value("daily", "task_index", _daily_task_index)
	cfg.set_value("daily", "modifier_id", _daily_modifier_id)
	cfg.set_value("daily", "progress", daily_challenge_progress)
	cfg.set_value("daily", "claimed", daily_challenge_claimed)
	cfg.set_value("weekly", "week_id", _weekly_week_id)
	cfg.set_value("weekly", "task_index", _weekly_task_index)
	cfg.set_value("weekly", "progress", weekly_challenge_progress)
	cfg.set_value("weekly", "claimed", weekly_challenge_claimed)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var saved: Array = cfg.get_value("achievements", "unlocked", [])
	unlocked.assign(saved)
	_max_combo_seen = cfg.get_value("achievements", "max_combo_seen", 0)
	_daily_date_id = cfg.get_value("daily", "date_id", "")
	_daily_task_index = cfg.get_value("daily", "task_index", 0)
	_daily_modifier_id = cfg.get_value("daily", "modifier_id", "none")
	daily_challenge_progress = cfg.get_value("daily", "progress", 0)
	daily_challenge_claimed = cfg.get_value("daily", "claimed", false)
	_weekly_week_id = cfg.get_value("weekly", "week_id", "")
	_weekly_task_index = cfg.get_value("weekly", "task_index", 0)
	weekly_challenge_progress = cfg.get_value("weekly", "progress", 0)
	weekly_challenge_claimed = cfg.get_value("weekly", "claimed", false)


## FR-420: Setzt den kompletten Erfolgs-/Herausforderungs-Zustand im
## Speicher auf den Ausgangswert zurück (die Speicherdatei selbst wird
## vom Aufrufer separat gelöscht, siehe GameManager.delete_all_user_data()).
func reset_all() -> void:
	unlocked.clear()
	_max_combo_seen = 0
	_daily_date_id = ""
	_daily_task_index = 0
	_daily_modifier_id = "none"
	daily_challenge_progress = 0
	daily_challenge_claimed = false
	_weekly_week_id = ""
	_weekly_task_index = 0
	weekly_challenge_progress = 0
	weekly_challenge_claimed = false
