extends CanvasLayer
class_name ProgressionScreen
## ProgressionScreen – Fortschritts-Zentrale
## ==========================================
## FR-304/305: Skill-Baum / permanente Upgrades
## FR-306: Prestige-/New-Game+-Modus
## FR-310: Wöchentliche Ziele
## FR-311/312/320: Saison-Leiste, Freischalt-Roadmap, nächstes Ziel
## FR-313: Münz-Sparziel (Sparschwein)

var _tab_container: TabContainer
var _skills_list: VBoxContainer
var _goals_list: VBoxContainer
var _prestige_list: VBoxContainer
var _achievements_list: VBoxContainer
var _balance_label: Label

# FR-339: Filter/Sortierung für die Erfolge-Liste
var _achievement_filter: String = "all"  # all | unlocked | locked
var _category_names: Dictionary = {}


func _ready() -> void:
	layer = 93
	visible = false
	# FR-339: Kategorie-Namen zur Laufzeit aufbauen (Enum-Zugriff auf ein
	# anderes Autoload ist nur zur Laufzeit sicher, nicht in einer const-
	# Initialisierung).
	_category_names = {
		AchievementManager.Category.FARTS: "Fürze", AchievementManager.Category.COINS: "Münzen",
		AchievementManager.Category.CHALLENGE: "Herausforderung", AchievementManager.Category.SPEED: "Tempo",
		AchievementManager.Category.STARS: "Sterne", AchievementManager.Category.STREAK: "Serie",
		AchievementManager.Category.COMBO: "Combo", AchievementManager.Category.WORLD: "Welt",
		AchievementManager.Category.HIDDEN: "Geheim",
	}
	_build_ui()
	GameManager.persistent_coins_changed.connect(func(_v): _refresh_skills())
	GameManager.skill_unlocked.connect(func(_id): _refresh_skills())
	GameManager.prestige_changed.connect(func(_lvl): _refresh_prestige())
	AchievementManager.achievement_unlocked.connect(func(_id): _refresh_achievements())


func show_screen() -> void:
	_refresh_skills()
	_refresh_goals()
	_refresh_prestige()
	_refresh_achievements()
	visible = true
	AccessibilityManager.apply_menu_ui_scale(self, get_viewport().get_visible_rect().size)  # FR-424


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_balance_label = Label.new()
	_balance_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_balance_label.offset_left = 40
	_balance_label.offset_top = 24
	_balance_label.add_theme_font_size_override("font_size", 30)
	_balance_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	bg.add_child(_balance_label)

	_tab_container = TabContainer.new()
	_tab_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tab_container.offset_left = 40
	_tab_container.offset_top = 80
	_tab_container.offset_right = -40
	_tab_container.offset_bottom = -110
	bg.add_child(_tab_container)

	# --- Tab 1: Skills (FR-304/305) -----------------------------------
	var skills_scroll := ScrollContainer.new()
	skills_scroll.name = "Skills"
	_tab_container.add_child(skills_scroll)
	_skills_list = VBoxContainer.new()
	_skills_list.add_theme_constant_override("separation", 10)
	skills_scroll.add_child(_skills_list)

	# --- Tab 2: Saison & Ziele (FR-310/311/312/313/320) -----------------
	var goals_scroll := ScrollContainer.new()
	goals_scroll.name = "Ziele"
	_tab_container.add_child(goals_scroll)
	_goals_list = VBoxContainer.new()
	_goals_list.add_theme_constant_override("separation", 14)
	goals_scroll.add_child(_goals_list)

	# --- Tab 3: Prestige (FR-306) ---------------------------------------
	var prestige_scroll := ScrollContainer.new()
	prestige_scroll.name = "Prestige"
	_tab_container.add_child(prestige_scroll)
	_prestige_list = VBoxContainer.new()
	_prestige_list.add_theme_constant_override("separation", 14)
	prestige_scroll.add_child(_prestige_list)

	# --- Tab 4: Erfolge (FR-321-340) -------------------------------------
	var achievements_root := VBoxContainer.new()
	achievements_root.name = "Erfolge"
	_tab_container.add_child(achievements_root)

	# FR-339: Filter-Leiste (Alle / Freigeschaltet / Gesperrt)
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 10)
	achievements_root.add_child(filter_row)
	for filter_id in ["all", "unlocked", "locked"]:
		var fbtn := Button.new()
		fbtn.text = {"all": "Alle", "unlocked": "Freigeschaltet", "locked": "Gesperrt"}[filter_id]
		fbtn.custom_minimum_size = Vector2(180, 56)
		fbtn.add_theme_font_size_override("font_size", 22)
		fbtn.pressed.connect(func():
			_achievement_filter = filter_id
			GameManager.play_ui_click()
			_refresh_achievements()
		)
		filter_row.add_child(fbtn)

	var achievements_scroll := ScrollContainer.new()
	achievements_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	achievements_root.add_child(achievements_scroll)
	_achievements_list = VBoxContainer.new()
	_achievements_list.add_theme_constant_override("separation", 10)
	achievements_scroll.add_child(_achievements_list)

	_tab_container.tab_changed.connect(func(_i): GameManager.play_ui_click())

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(240, 70)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -260
	close_btn.offset_top = -90
	close_btn.offset_right = -20
	close_btn.offset_bottom = -20
	close_btn.pressed.connect(func(): GameManager.play_ui_click(); visible = false)
	bg.add_child(close_btn)


## FR-304/305: Skill-Baum-Liste mit Freischalt-Buttons.
func _refresh_skills() -> void:
	_balance_label.text = "%d Münzen" % GameManager.persistent_coins
	for child in _skills_list.get_children():
		child.queue_free()
	for id in GameManager.SKILL_CATALOG.keys():
		var data: Dictionary = GameManager.SKILL_CATALOG[id]
		var owned: bool = id in GameManager.unlocked_skills
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var name_label := Label.new()
		name_label.text = data["name"]
		name_label.custom_minimum_size = Vector2(420, 0)
		name_label.add_theme_font_size_override("font_size", 26)
		if owned:
			name_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		hbox.add_child(name_label)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 60)
		btn.add_theme_font_size_override("font_size", 24)
		if owned:
			btn.text = "Freigeschaltet"
			btn.disabled = true
		else:
			btn.text = "%d Münzen" % int(data["cost"])
			btn.disabled = not GameManager.can_unlock_skill(id)
			btn.pressed.connect(func():
				if GameManager.unlock_skill(id):
					GameManager.play_ui_click()
					GameManager.vibrate(20)
			)
		hbox.add_child(btn)
		_skills_list.add_child(row)


## FR-310/311/312/313/320: Wochenziele, Saison-Leiste, Sparschwein,
## nächstes Ziel als Textvorschau.
func _refresh_goals() -> void:
	for child in _goals_list.get_children():
		child.queue_free()

	var preview := Label.new()
	preview.text = "Nächstes Ziel: %s" % GameManager.get_next_goal_preview()  # FR-320
	preview.add_theme_font_size_override("font_size", 26)
	preview.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_goals_list.add_child(preview)

	# FR-311/312: Saison-Leiste
	var season_header := Label.new()
	season_header.text = "\nSaison-Fortschritt (Stufe %d / %d)" % [GameManager.get_season_tier(), GameManager.SEASON_TIER_REWARDS.size()]
	season_header.add_theme_font_size_override("font_size", 28)
	_goals_list.add_child(season_header)
	var season_claim_btn := Button.new()
	season_claim_btn.custom_minimum_size = Vector2(320, 64)
	season_claim_btn.add_theme_font_size_override("font_size", 24)
	season_claim_btn.text = "Saison-Belohnung abholen"
	season_claim_btn.pressed.connect(func():
		var reward := GameManager.claim_season_tier_reward()
		if reward > 0:
			GameManager.play_ui_click()
			GameManager.vibrate(30)
			_refresh_goals()
	)
	_goals_list.add_child(season_claim_btn)

	# FR-310: Wöchentliche Ziele
	var weekly_header := Label.new()
	weekly_header.text = "\nWöchentliche Ziele"
	weekly_header.add_theme_font_size_override("font_size", 28)
	_goals_list.add_child(weekly_header)
	for goal in GameManager.WEEKLY_GOALS:
		var progress: int = int(GameManager.weekly_progress.get(goal["id"], 0))
		var claimed: bool = GameManager.weekly_claimed.get(goal["id"], false)
		var row := HBoxContainer.new()
		var key_label := Label.new()
		key_label.text = str(goal["name"])
		key_label.custom_minimum_size = Vector2(360, 0)
		key_label.add_theme_font_size_override("font_size", 24)
		row.add_child(key_label)
		var value_label := Label.new()
		value_label.text = "✓ eingelöst" if claimed else "%d / %d" % [progress, int(goal["target"])]
		value_label.add_theme_font_size_override("font_size", 24)
		value_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if claimed else Color.WHITE)
		row.add_child(value_label)
		_goals_list.add_child(row)

	# FR-313: Sparschwein
	var piggy_header := Label.new()
	piggy_header.text = "\nSparschwein"
	piggy_header.add_theme_font_size_override("font_size", 28)
	_goals_list.add_child(piggy_header)
	var piggy_row := HBoxContainer.new()
	var piggy_label := Label.new()
	piggy_label.text = "%d / %d Münzen" % [GameManager.piggy_bank_amount, GameManager.PIGGY_BANK_CAP]
	piggy_label.custom_minimum_size = Vector2(360, 0)
	piggy_label.add_theme_font_size_override("font_size", 24)
	piggy_row.add_child(piggy_label)
	var piggy_btn := Button.new()
	piggy_btn.text = "Aufbrechen"
	piggy_btn.custom_minimum_size = Vector2(200, 56)
	piggy_btn.add_theme_font_size_override("font_size", 22)
	piggy_btn.disabled = GameManager.piggy_bank_amount < GameManager.PIGGY_BANK_CAP
	piggy_btn.pressed.connect(func():
		var payout := GameManager.break_piggy_bank()
		if payout > 0:
			GameManager.play_ui_click()
			GameManager.vibrate(40)
			_refresh_goals()
	)
	piggy_row.add_child(piggy_btn)
	_goals_list.add_child(piggy_row)


## FR-306: Prestige-Übersicht mit Bestätigungs-Button.
func _refresh_prestige() -> void:
	for child in _prestige_list.get_children():
		child.queue_free()

	var info := Label.new()
	info.text = "Prestige-Stufe: %d\nMünz-Bonus: +%.0f%%" % [
		GameManager.prestige_level, (GameManager.get_prestige_coin_multiplier() - 1.0) * 100.0
	]
	info.add_theme_font_size_override("font_size", 28)
	_prestige_list.add_child(info)

	var explain := Label.new()
	explain.text = "Setzt Level-Sterne zurück, erhöht dauerhaft die Münz-Belohnung.\nSkills, Kosmetik und Guthaben bleiben erhalten.\nBenötigt: %d Sterne insgesamt." % GameManager.PRESTIGE_STAR_REQUIREMENT
	explain.add_theme_font_size_override("font_size", 22)
	explain.autowrap_mode = TextServer.AUTOWRAP_WORD
	_prestige_list.add_child(explain)

	var prestige_btn := Button.new()
	prestige_btn.text = "Prestige starten"
	prestige_btn.custom_minimum_size = Vector2(320, 70)
	prestige_btn.add_theme_font_size_override("font_size", 26)
	prestige_btn.disabled = not GameManager.can_prestige()
	prestige_btn.pressed.connect(func():
		if GameManager.do_prestige():
			AchievementManager.report_prestige()  # FR-333
			GameManager.play_ui_click()
			GameManager.vibrate(60)
			_refresh_prestige()
	)
	_prestige_list.add_child(prestige_btn)


## FR-321-340: Erfolge-Liste (gefiltert/sortiert, FR-339) + tägliche/
## wöchentliche Herausforderungen (FR-329/330/331).
func _refresh_achievements() -> void:
	for child in _achievements_list.get_children():
		child.queue_free()

	# FR-329: Tägliche Herausforderung (inkl. Mutator, FR-331)
	var daily := AchievementManager.get_daily_challenge()
	_achievements_list.add_child(_build_challenge_row(
		"Heute: %s (Modifikator: %s)" % [daily["name"], daily["modifier_name"]],
		int(daily["progress"]), int(daily["target"]), bool(daily["claimed"]),
		func():
			var reward := AchievementManager.claim_daily_challenge()
			if reward > 0:
				GameManager.play_ui_click()
				GameManager.vibrate(30)
				_refresh_achievements()
	))

	# FR-330: Wöchentliche Herausforderung
	var weekly := AchievementManager.get_weekly_challenge()
	_achievements_list.add_child(_build_challenge_row(
		"Diese Woche: %s" % weekly["name"],
		int(weekly["progress"]), int(weekly["target"]), bool(weekly["claimed"]),
		func():
			var reward := AchievementManager.claim_weekly_challenge()
			if reward > 0:
				GameManager.play_ui_click()
				GameManager.vibrate(30)
				_refresh_achievements()
	))

	var sep := HSeparator.new()
	_achievements_list.add_child(sep)

	# FR-339: Erfolge nach Kategorie sortiert, gefiltert nach Status
	var ids: Array = AchievementManager.ACHIEVEMENTS.keys()
	ids.sort_custom(func(a, b):
		return int(AchievementManager.ACHIEVEMENTS[a]["category"]) < int(AchievementManager.ACHIEVEMENTS[b]["category"])
	)
	for id in ids:
		var owned: bool = AchievementManager.is_unlocked(id)
		if _achievement_filter == "unlocked" and not owned:
			continue
		if _achievement_filter == "locked" and owned:
			continue
		var data: Dictionary = AchievementManager.ACHIEVEMENTS[id]
		var is_hidden: bool = bool(data["hidden"]) and not owned
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var name_label := Label.new()
		name_label.text = "???" if is_hidden else String(data["name"])
		name_label.custom_minimum_size = Vector2(280, 0)
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if owned else Color(0.7, 0.7, 0.7))
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "???" if is_hidden else String(data["desc"])
		desc_label.custom_minimum_size = Vector2(360, 0)
		desc_label.add_theme_font_size_override("font_size", 20)
		hbox.add_child(desc_label)

		var status_label := Label.new()
		var cat_name: String = _category_names.get(int(data["category"]), "")
		if owned:
			status_label.text = "✓ %s" % cat_name
		elif data.has("stat"):
			var progress := AchievementManager.get_progress(id)
			status_label.text = "%d / %d" % [progress.x, progress.y]
		else:
			status_label.text = cat_name
		status_label.custom_minimum_size = Vector2(140, 0)
		status_label.add_theme_font_size_override("font_size", 20)
		hbox.add_child(status_label)

		_achievements_list.add_child(row)


func _build_challenge_row(text: String, progress: int, target: int, claimed: bool, on_claim: Callable) -> Control:
	var row := PanelContainer.new()
	var hbox := HBoxContainer.new()
	row.add_child(hbox)
	var label := Label.new()
	label.text = "%s (%d / %d)" % [text, mini(progress, target), target]
	label.custom_minimum_size = Vector2(600, 0)
	label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(label)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 56)
	btn.add_theme_font_size_override("font_size", 22)
	if claimed:
		btn.text = "Eingelöst"
		btn.disabled = true
	else:
		btn.text = "Abholen"
		btn.disabled = progress < target
		btn.pressed.connect(on_claim)
	hbox.add_child(btn)
	return row
